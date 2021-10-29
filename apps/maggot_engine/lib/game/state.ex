defmodule MaggotEngine.Game.State do
  alias MaggotEngine.Game.{Board, Player}
  import MaggotEngine.Game.Changes

  def new(width, height) do
    board  = Board.new(width, height)
    # player = Player.new(first_player_pid, board)

    %{
      players: %{},
      bugs:    [],
      board:   board
    }
  end

  def move_and_notify(state) do
    {changes, players} = move(state)
    notify_players(changes, players)

    %{state | players: players}
  end

  def change_direction(%{players: players} = state, player_pid, direction) do
    p = Player.change_direction(players[player_pid], direction)
    %{state | players: Map.replace(players, player_pid, p)}
  end

  defp move(state) do # TODO make it run parallel
    state.players
      |> Map.values()
      |> Enum.map(&Player.move/1)
      |> Enum.reduce(
        { empty_changes() , %{} },
        fn {c, p}, {acc_cs, acc_ps} ->
          { merge_changes(c, acc_cs),
            Map.put_new(acc_ps, p.pid, p) }
        end)
  end

  defp notify_players(changes, players) do
    players
      |> Map.keys()
      |> Enum.map(&send(&1, {:change, changes}))
  end

  def update_bugs(_state) do
    raise "not implemented yet"
  end

  def add_player(state, pid) do
    player  = Player.new(pid, state.board)
    players = Map.put_new(state.players, pid, player)
    %{state | players: players}
  end
end
