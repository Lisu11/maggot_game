defmodule MaggotEngine.Game.Maggot do
  @enforce_keys [:head, :mid_segments, :tail, :direction, :queue]
  defstruct [:head, :mid_segments, :tail, :direction, :bugs, :queue]

  alias __MODULE__
  alias MaggotEngine.Game.Changes
  alias MaggotEngine.Game.Maggot.Queue
  require Logger


  def new([{x, y}, {x_, y_}], direction)
   when direction in [:n, :e, :s] do
      head = {x, y}
      tail = {x_, y_}
      %Maggot{
        head: head,
        mid_segments: [],
        tail: tail,
        direction: direction,
        bugs: %{},
        queue: Queue.new([{head, :e}, {tail, :e}])
      }
  end
  def new([head, _, _ | _] = seg, direction) do
    tail = List.last(seg)
    mid = seg |> List.delete(tail) |> List.delete(head)
    maggot = new([head, tail], direction)
    %Maggot{maggot | mid_segments: mid}
  end

  def as_points_list_fast(%Maggot{head: h, tail: t, mid_segments: seg}) do
    [h , t | seg]
  end

  def as_directed_list(%Maggot{queue: q}) do
    Queue.as_list(q)
  end

  def eat_bug(%Maggot{bugs: bugs, head: head} = maggot) do
    %Maggot{maggot | bugs: Map.put_new(bugs, head, true) }
  end

  def move(%Maggot{mid_segments: [], tail: t, queue: q} = maggot) do
    new_head = forward(maggot)
    if maggot.bugs[t] do
      bugs = Map.delete(maggot.bugs, t)
      q = Queue.add(q, {new_head, maggot.direction})
      { Changes.new([new_head], []),
        %Maggot{maggot | bugs: bugs,
                         head: new_head,
                         mid_segments: [maggot.head],
                         queue: q}}
    else
      q = Queue.next(q, {new_head, maggot.direction})
      { Changes.new([new_head], [t]),
        %Maggot{maggot | head: new_head,
                         tail: maggot.head,
                         queue: q}}
    end
  end
  def move(%Maggot{mid_segments: segments, tail: t, queue: q} = maggot) do
    new_head = forward(maggot)
    if maggot.bugs[t] do
      bugs = Map.delete(maggot.bugs, t)
      q = Queue.add(q, {new_head, maggot.direction})
      segments = [maggot.head | maggot.mid_segments]
      { Changes.new([new_head], []),
        %Maggot{maggot | bugs: bugs,
                         head: new_head,
                         mid_segments: segments,
                         queue: q}}
    else
      [last | rest] = Enum.reverse segments
      segments = [maggot.head | Enum.reverse(rest)]
      q = Queue.next(q, {new_head, maggot.direction})
      { Changes.new([new_head], [t]),
        %Maggot{maggot | head: new_head,
                         mid_segments: segments,
                         tail: last,
                         queue: q} }

    end
  end



  def rotate(%Maggot{queue: queue} = m, direction) do
    {_point, last_direction} = Queue.peek_head(queue)
    if validate_rotation(last_direction, direction) do
      %Maggot{m | direction: direction}
    else
      Logger.info("Player wants to change direction to #{direction}")
      m
    end
  end
  def rotate(nil, _) do
    Logger.error(error: :nil_maggot)
    {:error, :nil_maggot}
  end
  defp validate_rotation(:n, :s), do: false
  defp validate_rotation(:s, :n), do: false
  defp validate_rotation(:e, :w), do: false
  defp validate_rotation(:w, :e), do: false
  defp validate_rotation(_last_step_direction, _expected_direction), do: true



  def forward(%Maggot{head: h, mid_segments: [], direction: d, tail: t} = m), do: forward(d, h, t) |> log_errors(m)
  def forward(%Maggot{head: h, mid_segments: [n | _], direction: d} = m),     do: forward(d, h, n) |> log_errors(m)
  defp forward(:w, {x, y}, {x2, _}) when x <= x2, do: {x-1, y}
  defp forward(:n, {x, y}, {_, y2}) when y <= y2, do: {x, y-1}
  defp forward(:s, {x, y}, {_, y2}) when y >= y2, do: {x, y+1}
  defp forward(:e, {x, y}, {x2, _}) when x >= x2, do: {x+1, y}
  defp forward(direction, _head_position, _neck_position) do
    {:error, "MaggotEngine.Game.Maggot.forward  heading #{direction}"}
  end

  defp log_errors({:error, msg}, %Maggot{} = m) do
    Logger.error(error: msg)
    Logger.error(inspect(as_directed_list(m)))
    :error
  end
  defp log_errors(return, _maggot), do: return

end
