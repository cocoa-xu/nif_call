defmodule NifCallTest do
  use ExUnit.Case
  doctest NifCall

  test "greets the world" do
    assert NifCall.hello() == :world
  end
end
