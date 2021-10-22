defmodule MaggotEngine.Game.State do
  alias MaggotEngine.Game.{Board, Player}
  @empty_changes %{"+" => [], "-" => []}

  def new(width, height) do
    board  = Board.new(width, height)
    # player = Player.new(first_player_pid, board)

    %{
      players: [],
      bugs:    [],
      board:   board
    }
  end

  def move_and_notify(state) do
    {changes, players} = move(state)
    notify_players(changes, players)

    %{state | players: players}
  end

  defp move(state) do
    state.players
      |> Enum.map(&Player.move/1)
      |> Enum.reduce(
        { @empty_changes, [] },
        fn {c, p}, {acc_cs, acc_ps} ->
          { Map.merge(acc_cs, c, fn _k, v1, v2 -> v1 ++ v2 end), [p | acc_ps] }
        end)
  end

  defp notify_players(changes, players) do
    Enum.each(players,  &{send(&1.pid, {:change, changes})})
  end

  def update_bugs(_state) do
    raise "not implemented yet"
  end

  def add_player(state, pid) do
    player  = Player.new(pid, state.board)
    players = [player | state.players]
    %{state | players: players}
  end
end
