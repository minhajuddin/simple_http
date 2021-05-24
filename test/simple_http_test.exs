defmodule SimpleHTTPTest do
  use ExUnit.Case
  doctest SimpleHTTP

  test "greets the world" do
    assert SimpleHTTP.hello() == :world
  end
end
