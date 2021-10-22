defmodule MaggotEngine.Game.Maggot do
  @enforce_keys [:segments, :direction, :len]
  defstruct [:segments, :direction, :len, :bugs]

  alias __MODULE__


  def new({x, y}) do
    %Maggot{
      segments: [{x, y}, {x+1, y}],
      direction: :w,
      len: 2,
      bugs: []
    }
  end

  def move(%Maggot{} = maggot) do
    {deletes, segments} = maybe_remove_last(maggot.segments, maggot.bugs)
    new_head = forward(maggot)
    changes = %{"+" => [new_head], "-" => deletes}
    {changes, %Maggot{maggot | segments: [new_head | segments]}}
  end

  def add_bug(%Maggot{} = maggot) do
    [head | _ ] = maggot.segments
    %Maggot{maggot | bugs: [head | maggot.bugs]}
  end

  defp maybe_remove_last(segments, bugs) do
    case Enum.reverse segments do
      [h | t] ->
        if h in bugs do
          {[], Enum.reverse(t)}
        else
          {[h], Enum.reverse(t)}
        end
    end
  end


  def forward(%Maggot{segments: [h | _], direction: d}), do: forward(d, h)
  defp forward(:w = _direction, {x, y} = _head_position), do: {x+1, y}
  defp forward(:n = _direction, {x, y} = _head_position), do: {x, y+1}
  defp forward(:s = _direction, {x, y} = _head_position), do: {x, y-1}
  defp forward(:e = _direction, {x, y} = _head_position), do: {x-1, y}
end
