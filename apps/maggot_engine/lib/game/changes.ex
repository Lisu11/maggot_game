defmodule MaggotEngine.Game.Changes do

  def new(pluses, minuses, type \\ :maggot)
  def new(pluses, minuses, :maggot) do
    %{
      +: Map.new(pluses, &transform(&1, :pid)),
      -: Map.new(minuses, &transform(&1, :pid))
     }
  end
  def new(pluses, minuses, :bug) do
    %{
      +: Map.new(pluses, &transform(&1, :bug)),
      -: Map.new(minuses, &transform(&1, :bug))
     }
  end

  def put_pid(changes, pid) do
    pider = fn {k, _}, acc -> Map.put(acc, k, pid) end
    %{ +: Enum.reduce(changes.+, %{}, pider),
       -: Enum.reduce(changes.+, %{}, pider)}
  end

  def empty, do: %{+: %{}, -: %{}}

  def merge(l, r) do
    Map.merge(l, r, fn _plus_minus, m1, m2 ->
      Map.merge(m1 , m2, fn conflict_point, v1, v2 -> #trzeba bedzie sobie jakos poradzic z konfliktami
        raise KeyError, "Conflicted keys #{inspect conflict_point} for values #{inspect v1}, #{inspect v2}"
      end)
    end)
  end

  defp transform({_, _} = point, value) do
    {point, value}
  end
end
