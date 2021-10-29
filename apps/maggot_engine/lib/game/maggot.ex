defmodule MaggotEngine.Game.Maggot do
  @enforce_keys [:segments, :direction]
  defstruct [:segments, :direction, :bugs]

  alias __MODULE__
  alias MaggotEngine.Game.Changes
  require Logger


  def new!({x, y} = head, validator) do
    tail = {x-1, y}
    with  true <- validator.(head),
          true <- validator.(tail) do
      %Maggot{
        segments: [{x, y}, {x-1, y}],
        direction: :e,
        # len: 2,
        bugs: []
      }
    end
  end

  def move(%Maggot{} = maggot) do
    {deletes, segments} = maybe_remove_last(maggot.segments, maggot.bugs)
    new_head = forward(maggot)
    changes = Changes.new([new_head], deletes)
    {changes, %Maggot{maggot | segments: [new_head | segments]}}
  end

  def eat_bug(%Maggot{} = maggot) do
    [head | _ ] = maggot.segments
    %Maggot{maggot | bugs: [head | maggot.bugs]}
  end

  defp maybe_remove_last(segments, bugs) do
    case Enum.reverse segments do
      [last | t] ->
        if last in bugs do
          {[], Enum.reverse([last | t])}
        else
          {[last], Enum.reverse(t)}
        end
    end
  end

  def rotate(%Maggot{direction: :n} = m, :e), do: %Maggot{m | direction: :e}
  def rotate(%Maggot{direction: :n} = m, :w), do: %Maggot{m | direction: :w}
  def rotate(%Maggot{direction: :s} = m, :e), do: %Maggot{m | direction: :e}
  def rotate(%Maggot{direction: :s} = m, :w), do: %Maggot{m | direction: :w}
  def rotate(%Maggot{direction: :e} = m, :n), do: %Maggot{m | direction: :n}
  def rotate(%Maggot{direction: :e} = m, :s), do: %Maggot{m | direction: :s}
  def rotate(%Maggot{direction: :w} = m, :n), do: %Maggot{m | direction: :n}
  def rotate(%Maggot{direction: :w} = m, :s), do: %Maggot{m | direction: :s}
  def rotate(%Maggot{} = m, _) do
    Logger.debug(maggot_did_not_change_direction: m)
    m
  end

  def forward(%Maggot{segments: [h , n | _], direction: d}), do: forward(d, h, n)
  defp forward(:w, {x, y}, {x2, _}) when x <= x2, do: {x-1, y}
  defp forward(:n, {x, y}, {_, y2}) when y <= y2, do: {x, y-1}
  defp forward(:s, {x, y}, {_, y2}) when y >= y2, do: {x, y+1}
  defp forward(:e, {x, y}, {x2, _}) when x >= x2, do: {x+1, y}
  defp forward( _direction, _head_position, _neck_position) do
    Logger.debug(forward_error: "MaggotEngine.Game.Maggot.forward")
    :error
  end
end
