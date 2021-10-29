defmodule MaggotEngine.Game.State do
  alias MaggotEngine.Game.{Board, Maggot}
  import MaggotEngine.Game.Changes

  def new(width, height) do
    board  = Board.new(width, height)
    # player = Player.new(first_player_pid, board)

    %{
      players: %{}, # player_pid => maggot
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
    m = Maggot.rotate(players[player_pid], direction)
    %{state | players: Map.replace(players, player_pid, m)}
  end

  defp move(state) do # TODO make it run parallel
    state.players
      |> Enum.map(fn {pid, m} -> {pid, Maggot.move(m)} end)
      |> Enum.reduce(
        { empty_changes() , %{} },
        fn {p, {c, m}}, {acc_c, acc_m} ->
          { merge_changes(c, acc_c),
            Map.put_new(acc_m, p, m) }
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
    maggot  = Maggot.new({5, 5})
    players = Map.put_new(state.players, pid, maggot)
    %{state | players: players}
  end
end
