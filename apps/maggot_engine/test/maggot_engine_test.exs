defmodule MaggotEngineTest do
  use ExUnit.Case
  doctest MaggotEngine

  test "greets the world" do
    assert MaggotEngine.hello() == :world
  end
end
