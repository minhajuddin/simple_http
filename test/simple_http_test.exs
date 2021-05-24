defmodule SimpleHTTPTest do
  use ExUnit.Case
  doctest SimpleHTTP

  alias SimpleHTTP.{Request, Response, HTTP1}

  ## HTTP1
  test "get" do
    for status <- [200, 201, 202, 203, 204] do
      assert %Response{status_code: ^status, headers: [], body: []} =
               Request.new("http://httpstat.us/#{status}") |> HTTP1.request()
    end
  end
end
