defmodule ChattSlackTest do
  use ExUnit.Case
  doctest ChattSlack

  test "greets the world" do
    assert ChattSlack.hello() == :world
  end
end
