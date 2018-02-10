defmodule VeilTest do
  use ExUnit.Case
  doctest Veil

  test "greets the world" do
    assert Veil.hello() == :world
  end
end
