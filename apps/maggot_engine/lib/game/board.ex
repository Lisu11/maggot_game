defmodule MaggotEngine.Game.Board do
  @enforce_keys [:coords, :width, :height]
  defstruct [:coords, :width, :height]
  alias __MODULE__


  def new(width, height) when
    is_integer(width) and is_integer(height) do
      if width <= 0 or height <= 0 do
        raise ArgumentError,
          message: "Invalid argument. width and height need to be grate than 0 and were width:#{width}, height:#{height}"
      end
      %Board{width: width, height: height, coords: %{}}
  end

  def empty_spot(board, {x, y}) when
    x < board.width and x >= 0 and y < board.height and y >= 0 do
    board.coords[{x, y}] == nil
  end
  def empty_spot(_, _), do: false


end
