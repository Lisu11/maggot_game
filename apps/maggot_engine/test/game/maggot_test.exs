defmodule MaggotEngineTest.MaggotTest do
  use ExUnit.Case, async: true

  alias MaggotEngine.Game.Maggot

  setup_all do
    head = {1, 1}
    tip = {2, 1}
    m = Maggot.new(head)
    bugged_maggot = %Maggot{m | bugs: [tip]}
    [maggot: m, head: head, tip: tip, bugged_maggot: bugged_maggot]
  end
  describe "new/1" do
    test "should return maggot directed west and with length 2 and head at given point",
    %{maggot: m, head: head} do

      assert m.direction == :w
      assert Enum.count(m.segments) == 2
      assert List.first(m.segments) == head
    end
  end

  describe "move/1" do


    test "when maggot has not any bug as the last part his size should stay the same", %{maggot: maggot} do
      {_ , moved} = Maggot.move(maggot)
      assert Enum.count(maggot.segments) == Enum.count(moved.segments)
    end

    test "when maggot has a bug at the end his size should grow", %{bugged_maggot: maggot} do

      {_ , moved} = Maggot.move(maggot)

      assert Enum.count(maggot.segments) + 1 == Enum.count(moved.segments)
    end

    test "bugged maggot moved has only changes in '+' part", %{bugged_maggot: maggot}  do
      {%{"+" => [_ | _], "-" => []} , _} = Maggot.move(maggot)
    end

    test "not-bugged maggot moved has changes in both '+' and '-' part", %{maggot: maggot}  do
      {%{"+" => [_ | _], "-" => [_ | _]} , _} = Maggot.move(maggot)
    end
  end

  describe "forward/1" do

    test "forward peeking gives you next spot for the maggots head or :error when direction is messed up", %{maggot: maggot, head: {x, y}} do

      assert Maggot.forward(maggot) == {x-1, y}
      maggot = %Maggot{maggot | direction: :e}
      assert Maggot.forward(maggot) == :error
      maggot = %Maggot{maggot | direction: :n}
      assert Maggot.forward(maggot) == {x, y+1}
      maggot = %Maggot{maggot | direction: :s}
      assert Maggot.forward(maggot) == {x, y-1}
    end
  end

  describe "eat_bug/1" do
    test "maggot eats bug by adding it to its head", %{maggot: maggot, head: head} do
      assert maggot.bugs == []

      maggot = Maggot.eat_bug(maggot)
      assert maggot.bugs == [head]
    end
  end

end
