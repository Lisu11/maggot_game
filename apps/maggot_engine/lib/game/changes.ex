defmodule MaggotEngine.Game.Changes do

  def new(pluses, minuses), do: %{"+" => pluses, "-" => minuses}
  def empty_changes, do: new([], [])

  def merge_changes(l, r) do
    Map.merge(l, r, fn _k, v1, v2 -> v1 ++ v2 end)
  end
end
