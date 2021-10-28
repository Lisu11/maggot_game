defmodule MaggotEngine.Game.Player do
  defstruct [:maggot, :pid]
  alias MaggotEngine.Game.Maggot
  alias __MODULE__

  def new(pid, board) do
    %Player{pid: pid, maggot: gen_random_maggot(board)}
  end


  defp gen_random_maggot(board) do
    Maggot.new({5, 5})
  end

  def move(%Player{} = p) do
    {change, maggot} = Maggot.move(p.maggot)
    {change, %Player{p | maggot: maggot} }
  end

  def change_direction(%Player{} = p, direction) do
    %Player{p | maggot: Maggot.rotate(p.maggot, direction)}
  end
end
