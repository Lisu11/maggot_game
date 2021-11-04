defmodule MaggotEngineTest.ChangesTest do
  use ExUnit.Case, async: true

  alias MaggotEngine.Game.Changes
  setup_all do
    adds = %{
      {82, 60} => :pid,
      {75, 36} => :bug,
      {80, 48} => :pid,
      {15, 26} => :pid,
      {75, 23} => :bug}
    subs = %{
      {98, 9} => :pid,
      {96, 45} => :bug,
      {114, 29} => :pid,
      {103, 8} => :bug,
      {173, 26} => :pid,
      {183, 26} => :pid}
    stopped = %{}
    pid = self()
    c = %Changes{+: adds, -: subs}
    [adds: adds, subs: subs, stopped: stopped, pid: pid, changes: c]
  end

  describe "new/1" do
    test "should create new changes with one stopped map", %{pid: pid} do
      c = Changes.new({pid, {1,1}})
      assert c.stops[pid] == {1,1}
    end
  end

  describe "additions/1 , stops/1 , subtractions/1" do
    test "addition getter should never return nil",
      %{pid: pid, subs: subs, changes: c} do
        assert Changes.additions(c) != nil
        c = Changes.new([], Map.keys(subs))
        assert Changes.additions(c) == %{}
        c = Changes.new([], [], :bug)
        assert Changes.additions(c) == %{}
        c = Changes.new({pid, {1,1}})
        assert Changes.additions(c) == %{}

    end

    test "subtraction getter should never return nil",
      %{pid: pid, adds: adds, changes: c} do
        assert Changes.subtractions(c) != nil
        c = Changes.new(Map.keys(adds), [])
        assert Changes.subtractions(c) == %{}
        c = Changes.new([], [], :bug)
        assert Changes.subtractions(c) == %{}
        c = Changes.new({pid, {1,1}})
        assert Changes.subtractions(c) == %{}

    end

    test "stops getter should never return nil",
      %{pid: pid, adds: adds, changes: c} do

        assert Changes.stops(c) == %{}
        c = Changes.new(Map.keys(adds), [])
        assert Changes.stops(c) == %{}
        c = Changes.new([], [], :bug)
        assert Changes.stops(c) == %{}
        c = Changes.new({pid, {1,1}})
        assert Changes.stops(c) != nil
    end

  end

  describe "empty/0" do
    test "should return empty struct" do
      c = Changes.empty()
      assert Changes.additions(c) == %{}
      assert Changes.subtractions(c) == %{}
      assert Changes.stops(c) == %{}
    end
  end

  describe "get_removed_bugs/1" do
    test "should return only points from '-' with value :bug",
      %{subs: subs, changes: changes} do
          bugs = Changes.get_removed_bugs(changes)
          assert Enum.count(bugs) <= Enum.count(subs)

          for {p, v} <- subs do
            if v == :bug do
              assert p in bugs
            end
          end
          Enum.each(bugs, fn bug ->
            assert subs[bug] == :bug
          end)
    end
  end

  describe "merge/2" do
    test "two empty Changes are still empty" do
      e1 = Changes.empty()
      e2 = Changes.empty()
      c  = Changes.merge(e1, e2)

      assert Changes.additions(c) == %{}
      assert Changes.subtractions(c) == %{}
      assert Changes.stops(c) == %{}
    end

    test "empty is neutral element of magma of (maps, merge)",
      %{changes: changes} do
      assert Changes.merge(changes, Changes.empty)
      assert Changes.merge(Changes.empty, changes)
    end

    test "merge is idempotent",  %{changes: changes} do
      assert Changes.merge(changes, changes) == changes
    end

    test "merge adds new entities to old map",  %{changes: changes} do
      %Changes{+: %{{1,1} => :pid}} =
        Changes.merge(%Changes{+: %{{1,1} => :pid}}, changes)
      %Changes{+: %{{1,1} => :pid}} =
        Changes.merge(changes, %Changes{+: %{{1,1} => :pid}})
    end

    test "combine adds and subs",
      %{adds: adds, subs: subs, changes: changes} do
        c1 = %Changes{-: subs}
        c2 = %Changes{+: adds}
        assert changes == Changes.merge(c1, c2)
    end
  end

  describe "put_pid/2" do
    test "should replace all values in + and - with pid",
      %{changes: changes, pid: pid} do
        c = Changes.put_pid(changes, pid)
        for {_k, v} <- Changes.additions(c) do
          assert v == pid
        end
        for {_k, v} <- Changes.subtractions(c) do
          assert v == pid
        end
    end

    test "wont change empty", %{pid: pid} do
      assert Changes.empty() == Changes.put_pid(Changes.empty(), pid)
    end
  end
end
