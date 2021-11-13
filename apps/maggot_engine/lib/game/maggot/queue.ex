defmodule MaggotEngine.Game.Maggot.Queue do
  @enforce_keys [:front, :back, :size]
  defstruct [:front, :back, :size ]
  alias __MODULE__

  def new, do: %Queue{front: [], back: [], size: 0}
  def new(l) when is_list(l) do
    %Queue{front: l, back: [], size: Enum.count(l)}
  end

  def next(queue, element) do
    queue
      |> push(element)
      |> pop!()
  end

  def add(queue, element) do
    queue
      |> push(element)
      |> inc_size()
  end

  def as_list(%Queue{front: f, back: b}) do
    f ++ Enum.reverse(b)
  end

  def peek_head(%Queue{front: []}), do: :error
  def peek_head(%Queue{front: [h | _]}), do: h

  def empty?(%Queue{back: [], front: []}), do: true
  def empty?(%Queue{}), do: false

  # def peek_tail(%Queue{back: [], front: []}), do: :error
  # def peek_tail(%Queue{back: []}), do: h
  # def peek_tail(%Queue{back: [h | _]}), do: h


  # push O(1)
  # this operation does not change size parameter
  # you need to explicitly call inc_size/1
  defp push(%Queue{front: f} = queue, element), do: %Queue{queue | front: [element | f] }


  # this operation does not change size parameter
  # you need to explicitly call inc_size/1
  defp pop!(%Queue{} = q) do
    {:ok, return} = pop(q)
    return
  end
  defp pop(%Queue{back: [], front: []}), do: {:error, :dequeuing_empty_queue}
  defp pop(%Queue{back: [_ | t]} = q), do: {:ok,  %Queue{q | back: t}}
  defp pop(%Queue{back: [], front: [_]} = q), do: {:ok, %Queue{q | front: []}}
  defp pop(%Queue{back: [], front: [h | ft]} = q) do
    [_ | t] = Enum.reverse(ft)
    queue   = %Queue{q | back: t, front: [h]}
    {:ok, queue}
  end

  defp inc_size(%Queue{size: size} = q), do: %Queue{q | size: size + 1}


end

defimpl Enumerable, for: MaggotEngine.Game.Maggot.Queue do
  alias MaggotEngine.Game.Maggot.Queue

  def count(%Queue{size: size}), do: {:ok, size}

  def member?(%Queue{front: f, back: b}, element) do
    {:ok, member?(f, element) or member?(b, element)}
  end


  def slice(%Queue{front: f, back: b}), do: {:error, __MODULE__}

  def reduce(%Queue{front: f, back: b}, acc, fun) do
     acc = Enumerable.List.reduce(f, acc, fun)
     Enumerable.List.reduce(b, acc, fun)
  end

end
