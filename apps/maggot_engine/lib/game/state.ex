defmodule MaggotEngine.Game.State do
  # use Constants

  alias MaggotEngine.Game.{Board, Maggot}
  alias MaggotEngine.Game.Changes
  require Logger

  @bugs_freq 10

  def new(width, height) do
    %{
      players: %{}, # player_pid => maggot
      stopped_players: [],
      board:   Board.new(width, height),
      changes: Changes.empty(),
      counter: 0
    }
  end

  def update_board(state) do
    state
      |> clear_subtracted()
      |> mark_added()
  end

  def change_direction(%{players: players} = state, player_pid, direction) do
    with %Maggot{} = m <- Maggot.rotate(players[player_pid], direction) do
      %{state | players: Map.replace(players, player_pid, m)}
    else
      {:error, reason} ->
        Logger.info("player #{inspect(player_pid)} wants to move but #{inspect(reason)}")
        state
    end
  end


  def update_counter(%{counter: @bugs_freq} = state), do: %{state | counter: 0}
  def update_counter(%{counter: counter} = state), do: %{state | counter: counter + 1}

  def add_stopped_player(%{stopped_players: sp} = state, pid) do
    %{state | stopped_players: [pid | sp]}
  end

  def remove_stopped_player(%{stopped_players: sp} = state, pid) do
    %{state | stopped_players: List.delete(sp, pid)}
  end

  def add_player(%{board: board, players: players, stopped_players: sp} = state, pid) do
    if pid in sp do
      maggot  = random_maggot(board)
      players = Map.put_new(players, pid, maggot)
      { :ok,
        %{state | players: players,
                  stopped_players: List.delete(sp, pid)}
      }
    else
      {:error, :subscribe_first}
    end

  end

  def remove_player(%{players: players, stopped_players: sp, changes: changes} = state, pid) do
    %{state | players: Map.delete(players, pid),
              stopped_players: [pid | sp],
              changes: Changes.merge(changes, Changes.new(pid))}
  end

  def update_bugs(%{counter: 0, board: board, changes: changes} = state) do
    bug = random_bug(board)
    %{state | changes: Changes.add_change(changes, :+, {bug, :bug}),
              board: Board.set(board, bug, :bug) }
  end
  def update_bugs(state), do: state

  def init_changes(state), do: %{state | changes: Changes.empty() }


  def clear_stopped_players(%{players: players, changes: changes, stopped_players: sp} = state) do
    {stopped, active} = changes
        |> Changes.stops()
        |> Map.keys()
        |> then(&Map.split(players, &1))
    %{state | players: active, stopped_players: Map.keys(stopped) ++ sp}
  end

  def detect_next_step_collisions(state) do
    state
      |> get_pids_for_same_heads()
      |> stop_colliding_pids(state)
  end


  def step(%{changes: changes} = state) do # TODO make it run parallel
    state.players
      # |> Stream.filter(&elem(&1, 1))
      |> Enum.map(&maybe_move_maggot(&1, state))
      |> combine_moves_and_changes(changes)
      |> then(fn {c, p} ->
           %{state | players: p, changes: c}
         end)
  end

  def add_rest_of_the_stopped_maggot_to_changes(%{changes: changes, players: players} = state) do
    Changes.stops(changes)
      |> Enum.map(fn {pid, true} ->
        Maggot.as_list_fast(players[pid]) end)
      |> Enum.reduce(changes, fn points, changes ->
          Changes.new([], points)
            |> Changes.merge(changes)
        end)
      |> then(&%{state | changes: Changes.merge(&1, changes)})
  end

  def notify_players(%{players: players, stopped_players: sp} = state) do
    players
      |> Map.keys()
      |> Kernel.++(sp)
      |> Enum.each(&send(&1, {:change, state.changes}))
    state
  end

  defp get_pids_for_same_heads(%{players: players}) do
    repetitions = players
              |> Enum.map(fn {_k, v} -> v.head end)
              |> then(&(&1 -- Enum.uniq(&1)))

    Enum.filter(players, fn {_k, v} -> v.head in repetitions end)
  end


  defp stop_colliding_pids(ps, %{changes: changes} = state) when is_list(ps) do
    changes = ps
      |> Enum.map(&elem(&1, 0))
      |> Enum.reduce(changes, fn pid, chs ->
          Changes.add_change(chs, :stops, pid)
        end)

    %{state | changes: changes}
  end

  defp clear_subtracted(%{changes: changes, board: board} = state) do
    Changes.subtractions(changes)
      |> Map.keys()
      |> then(&Board.unset_all(board, &1))
      |> then(&%{state | board: &1})
  end

  defp mark_added(%{changes: changes, board: board} = state) do
    Changes.additions(changes)
      |> Enum.reduce(board, fn {point, value}, board ->
          Board.set(board, point, value)
        end)
      |> then(&%{state | board: &1})
  end

  defp combine_moves_and_changes(collection, changes) do
    Enum.reduce(
      collection,
      { changes , %{} },
      fn {p, {c, m}}, {acc_c, acc_m} ->
          { Changes.merge(
              c, #Changes.put_pid(c, p),
            acc_c),
            Map.put_new(acc_m, p, m) }
      end)
  end

  defp maybe_move_maggot({pid, maggot}, %{board: board}) do
    head = Maggot.forward(maggot)
    cond do
      Board.collide(board, head) ->
        { pid,
          {Changes.new(pid), maggot}}
      true ->
        { pid,
          maybe_eat_bug_and_move(maggot, board)}
    end
  end

  defp maybe_eat_bug_and_move(maggot, board) do
    head = Maggot.forward(maggot)
    if Board.spot_bugged?(board, head) do
      maggot
        |> Maggot.move()
        |> then(fn {%Changes{} = c, %Maggot{} = m} ->
            { Changes.add_change(c, :-, {head, :bug}),
              Maggot.eat_bug(m)}
           end)
    else
      Maggot.move(maggot)
    end
  end

  defp random_bug(board) do
    x = :rand.uniform(board.width + 1) - 1
    y = :rand.uniform(board.height + 1) - 1
    if Board.empty_spot(board, {x, y}) do
      {x, y}
    else
      random_bug(board)
    end
  end

  defp random_maggot(board) do # it can take long time figure out better solution
    x = :rand.uniform(board.width + 1) - 1
    y = :rand.uniform(board.height + 1) - 1
    try do
      Maggot.new!({x, y}, &Board.empty_spot(board, &1))
    rescue
      MatchError ->
        random_maggot(board)
    end
  end
end
