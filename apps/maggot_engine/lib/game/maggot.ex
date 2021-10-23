defmodule MaggotEngine.Game.Maggot do
  @enforce_keys [:segments, :direction]
  defstruct [:segments, :direction, :bugs]

  alias __MODULE__


  def new({x, y}) do
    %Maggot{
      segments: [{x, y}, {x+1, y}],
      direction: :w,
      # len: 2,
      bugs: []
    }
  end

  def move(%Maggot{} = maggot) do
    {deletes, segments} = maybe_remove_last(maggot.segments, maggot.bugs)
    new_head = forward(maggot)
    changes = %{"+" => [new_head], "-" => deletes}
    {changes, %Maggot{maggot | segments: [new_head | segments]}}
  end

  def eat_bug(%Maggot{} = maggot) do
    [head | _ ] = maggot.segments
    %Maggot{maggot | bugs: [head | maggot.bugs]}
  end

  defp maybe_remove_last(segments, bugs) do
    case Enum.reverse segments do
      [h | t] ->
        if h in bugs do
          {[], Enum.reverse([h | t])}
        else
          {[h], Enum.reverse(t)}
        end
    end
  end


  def forward(%Maggot{segments: [h , n | _], direction: d}), do: forward(d, h, n)
  defp forward(:w, {x, y}, {x2, _}) when x <= x2, do: {x-1, y}
  defp forward(:n, {x, y}, {_, y2}) when y2 <= y, do: {x, y+1}
  defp forward(:s, {x, y}, {_, y2}) when y2 >= y, do: {x, y-1}
  defp forward(:e, {x, y}, {x2, _}) when x >= x2, do: {x+1, y}
  defp forward( _direction, _head_position, _neck_position), do: :error
end
