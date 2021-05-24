defmodule SimpleHTTPTest do
  use ExUnit.Case
  doctest SimpleHTTP

  test "response" do
    assert SimpleHTTP.hello() == :world
  end
end
