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

  def empty_spot(%Board{} = board, {x, y}) when
    x < board.width and x >= 0 and y < board.height and y >= 0 do
    board.coords[{x, y}] == nil
  end
  def empty_spot(%Board{} = _, _), do: false

  def collide(%Board{} = board, {x, y}) when
    x >= board.width or x < 0 or y >= board.height or y < 0, do: true
  def collide(%Board{coords: coords}, p) do
    coords[p] not in [nil, :bug]
  end

  def unset_all(%Board{} = board, points) do
    points = Map.new(points, &{&1, nil})
    coords = Map.merge(board.coords, points, fn _k, _v, v -> v end)
    %Board{board | coords: coords}
  end
  def unset(%Board{} = board, point), do: set(board, point)
  def set(%Board{coords: coords} = board, {_x, _y} = point, to \\ nil)
    when to in [nil, :bug, :pid] do
      %Board{board | coords:
        Map.put(coords, point, to)}
  end

  def spot_bugged?(%Board{} = board, {_x, _y} = point) do
    board[point] == :bug
  end
end
