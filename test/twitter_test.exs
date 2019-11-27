defmodule TwitterTest do
  use ExUnit.Case
  doctest TwitterEngine

  setup_all do
    IO.puts "Setup"
  end

  test "greets the world" do
    IO.puts "Running test 1"
    assert 1 == 2
  end
end
