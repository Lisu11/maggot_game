defmodule MaggotEngineTest.MaggotTest do
  use ExUnit.Case, async: true

  alias MaggotEngine.Game.Maggot

  setup_all do
    head = {1, 1}
    tip = {0, 1}
    const_true = fn _ -> true end

    m = Maggot.new!(head, const_true)
    bugged_maggot = %Maggot{m | bugs: %{tip => true}}
    [maggot: m, bugged_maggot: bugged_maggot, tip: tip]
  end
  describe "new!/2" do
    test "should return maggot directed east and with length 2 and head at given point",
    %{maggot: m, tip: tip} do

      assert m.direction == :e
      assert Enum.count(m.mid_segments) == 0
      assert m.tail == tip
    end

    test "should raise MatchError when validator fails" do
      const_false = fn _ -> false end
      assert_raise(MatchError, fn -> Maggot.new!({1,1}, const_false) end)
    end
  end

  describe "move/1" do


    test "when maggot has not any bug as the last part his size should stay the same",
      %{maggot: maggot} do
        {_ , moved} = Maggot.move(maggot)
        assert Enum.count(maggot.mid_segments) == Enum.count(moved.mid_segments)
    end

    test "when maggot has a bug at the end his size should grow",
      %{bugged_maggot: maggot} do

        assert maggot.bugs[maggot.tail]
        {_ , moved} = Maggot.move(maggot)
        assert Enum.count(maggot.mid_segments) + 1 == Enum.count(moved.mid_segments)
    end

    test "bugged maggot moved has only changes in '+' part", %{bugged_maggot: maggot}  do
      {%{+: plus, -: minus} , _} = Maggot.move(maggot)
      assert minus == %{}
      assert plus != %{}
    end

    test "not-bugged maggot moved has changes in both '+' and '-' part", %{maggot: maggot}  do
      {%{+: plus, -: minus} , _} = Maggot.move(maggot)
      assert minus != %{}
      assert plus != %{}
    end
  end

  describe "forward/1" do
    @moduletag :capture_log
    test "forward peeking gives you next spot for the maggots head or :error when direction is messed up", %{maggot: maggot} do
      {x, y} = maggot.head

      assert Maggot.forward(maggot) == {x+1, y}
      maggot = %Maggot{maggot | direction: :w}
      assert Maggot.forward(maggot) == :error
      maggot = %Maggot{maggot | direction: :n}
      assert Maggot.forward(maggot) == {x, y-1}
      maggot = %Maggot{maggot | direction: :s}
      assert Maggot.forward(maggot) == {x, y+1}
    end
  end

  describe "eat_bug/1" do
    test "maggot eats bug by adding it to its head", %{maggot: maggot} do
      assert maggot.bugs == %{}

      maggot = Maggot.eat_bug(maggot)
      assert maggot.bugs[maggot.head]
    end
  end

end
