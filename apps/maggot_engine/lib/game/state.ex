defmodule MaggotEngine.Game.State do
  alias MaggotEngine.Game.{Board, Maggot}
  alias MaggotEngine.Game.Changes

  @bugs_freq 100

  def new(width, height) do
    %{
      players: %{}, # player_pid => maggot
      bugs:    [],
      board:   Board.new(width, height),
      changes: %{},
      counter: 0
    }
  end

  def make_move_and_notify_players(state) do
    state
      |> move()
      |> notify_players()
  end

  def update_board(state, changes) do
    raise "not implemented yet"
  end

  def update_counter(%{counter: @bugs_freq} = state), do: %{state | counter: 0}
  def update_counter(%{counter: counter} = state), do: %{state | counter: counter + 1}


  def change_direction(%{players: players} = state, player_pid, direction) do
    m = Maggot.rotate(players[player_pid], direction)
    %{state | players: Map.replace(players, player_pid, m)}
  end

  defp move(%{bugs: bugs, changes: changes} = state) do # TODO make it run parallel
    state.players
      |> Enum.map(fn {pid, m} -> {pid, move_maggot(m, bugs)} end)
      |> Enum.reduce(
        { changes , %{} },
        fn {p, {c, m}}, {acc_c, acc_m} ->
          { Changes.merge(
              c, #Changes.put_pid(c, p),
            acc_c),
            Map.put_new(acc_m, p, m) }
        end)
      |> then(fn {c, p} ->
           %{state | players: p, changes: c}
         end)
  end

  defp move_maggot(maggot, bugs) do # TODO to nie dziala bo nie usuwamy zjedzonego buga ze stanu
    if Maggot.forward(maggot) in bugs do
      maggot
        |> Maggot.move()
        |> then(fn {c, m} ->
            { c,
              Maggot.eat_bug(m)}
           end)
    else
      Maggot.move(maggot)
    end
  end

  defp notify_players(state) do
    state.players
      |> Map.keys()
      |> Enum.each(&send(&1, {:change, state.changes}))
    state
  end

  def update_bugs(%{counter: 0, bugs: bugs, board: board} = state) do
    bug = random_bug(board)
    %{state | bugs: [bug | bugs], changes: Changes.new([bug], [], :bug) }
  end
  def update_bugs(state), do: %{state | changes: Changes.empty() }

  def add_player(state, pid) do
    maggot  = random_maggot(state.board)
    players = Map.put_new(state.players, pid, maggot)
    %{state | players: players}
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
