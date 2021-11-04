defmodule MaggotEngine.Game.Changes do
  defstruct [+: %{}, -: %{}, stops: %{}]
  alias __MODULE__

  def new(pluses, minuses, type \\ :maggot)
  def new(pluses, minuses, :maggot)
    when is_list(pluses) and is_list(minuses) do
    %Changes{
      +: Map.new(pluses, &transform(&1, :pid)),
      -: Map.new(minuses, &transform(&1, :pid))
     }
  end
  def new(pluses, minuses, :bug)
    when is_list(pluses) and is_list(minuses) do
    %Changes{
      +: Map.new(pluses, &transform(&1, :bug)),
      -: Map.new(minuses, &transform(&1, :bug))
     }
  end
  def new({pid, head}) do
    %Changes{stops: %{pid => head}}
  end

  def add_change(%Changes{} = changes, :+, {k, v}) do
      updated = Map.put_new(additions(changes), k, v)
      %Changes{changes | +: updated}
  end
  def add_change(%Changes{} = changes, :-, {k, v}) do
      updated = Map.put_new(subtractions(changes), k, v)
      %Changes{changes | -: updated}
  end
  def add_change(%Changes{} = changes, :stops, {k, v}) do
      updated = Map.put_new(stops(changes), k, v)
      %Changes{changes | stops: updated}
  end

  def additions(%Changes{} = changes) do
    changes.+
  end

  def subtractions(%Changes{} = changes) do
    changes.-
  end

  def stops(%Changes{} = changes) do
    changes.stops
  end

  def put_pid(%Changes{} = changes, pid) do
    pider = fn {k, _}, acc -> Map.put(acc, k, pid) end
    %Changes{ +: Enum.reduce(changes.+, %{}, pider),
       -: Enum.reduce(changes.+, %{}, pider)}
  end

  def empty, do: %Changes{+: %{}, -: %{}, stops: %{}}

  def get_removed_bugs(%Changes{} = changes) do
    changes.-
      |> Enum.flat_map(fn {k, v} ->
        case v do
          :bug -> [k]
          _    -> []
        end
      end)

  end

  def merge(%Changes{} = l, %Changes{} = r) do
    Map.merge(l, r, fn struct_plus_minus, m1, m2 ->
      if struct_plus_minus == :__struct__ do
        m1
      else
        Map.merge(m1 , m2, fn conflict_point, v1, v2 -> #trzeba bedzie sobie jakos poradzic z konfliktami
          if v1 != v2 do
            raise KeyError, "Conflicted keys #{inspect conflict_point} for values #{inspect v1}, #{inspect v2}"
          else
            v1
          end
        end)
      end
    end)
  end

  defp transform({_, _} = point, value) do
    {point, value}
  end
end
