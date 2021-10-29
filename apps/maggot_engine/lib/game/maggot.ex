defmodule MaggotEngine.Game.Maggot do
  @enforce_keys [:head, :mid_segments, :tail, :direction]
  defstruct [:head, :mid_segments, :tail, :direction, :bugs]

  alias __MODULE__
  alias MaggotEngine.Game.Changes
  require Logger


  def new!({x, y} = head, validator) do
    tail = {x-1, y}
    with  true <- validator.(head),
          true <- validator.(tail) do
      %Maggot{
        head: {x, y},
        mid_segments: [],
        tail: {x-1, y},
        direction: :e,
        # len: 2,
        bugs: %{}
      }
    end
  end


  def eat_bug(%Maggot{} = maggot) do
    [head | _ ] = maggot.mid_segments
    %Maggot{maggot | bugs: [head | maggot.bugs]}
  end


  def move(%Maggot{mid_segments: [], tail: t} = maggot) do
    new_head = forward(maggot)
    if t in maggot.bugs do
      bugs = Map.delete(maggot.bugs, t)
      { Changes.new([new_head], []),
        %Maggot{maggot | bugs: bugs, head: new_head, mid_segments: [maggot.head]}}
    else
      { Changes.new([new_head], [t]),
        %Maggot{maggot | head: new_head, tail: maggot.head}}
    end
  end
  def move(%Maggot{mid_segments: segments, tail: t} = maggot) do
    new_head = forward(maggot)
    if t in maggot.bugs do
      bugs = Map.delete(maggot.bugs, t)
      segments = [maggot.head | maggot.mid_segments]
      { Changes.new([new_head], []),
        %Maggot{maggot | bugs: bugs, head: new_head, mid_segments: segments}}
    else
      [last | rest] = Enum.reverse segments
      segments = [maggot.head | Enum.reverse(rest)]
      { Changes.new([new_head], [t]),
        %Maggot{maggot | head: new_head, mid_segments: segments, tail: last} }

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

  def forward(%Maggot{head: h, mid_segments: [], direction: d, tail: t}), do: forward(d, h, t)
  def forward(%Maggot{head: h, mid_segments: [n | _], direction: d}), do: forward(d, h, n)
  defp forward(:w, {x, y}, {x2, _}) when x <= x2, do: {x-1, y}
  defp forward(:n, {x, y}, {_, y2}) when y <= y2, do: {x, y-1}
  defp forward(:s, {x, y}, {_, y2}) when y >= y2, do: {x, y+1}
  defp forward(:e, {x, y}, {x2, _}) when x >= x2, do: {x+1, y}
  defp forward( _direction, _head_position, _neck_position) do
    Logger.debug(forward_error: "MaggotEngine.Game.Maggot.forward")
    :error
  end
end
