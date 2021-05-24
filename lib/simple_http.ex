defmodule SimpleHTTP do
  # Constants
  @line_ending ["\r\n"]
  @user_agent "SimpleHTTP"
  @recv_timeout 1000

  defmodule Request do
    defstruct method: :get,
              headers: [],
              body: []
  end

  defmodule Response do
    defstruct status_code: nil,
              headers: nil,
              body: nil
  end

  def get(url) when is_binary(url) do
    uri = URI.parse(url)

    {:ok, conn} =
      :gen_tcp.connect(to_charlist(uri.authority), uri.port, [:binary, {:active, false}])

    :ok = :gen_tcp.send(conn, get_request(uri) |> tap(&IO.puts(&1)))

    %Response{}
    |> parse_status(conn)
    |> parse_headers(conn)

    {:ok}
  end

  defp get_request(uri) do
    [
      "GET ",
      request_path(uri),
      " HTTP/1.1",
      @line_ending,
      "host: ",
      request_host(uri),
      @line_ending,
      "user-agent: ",
      @user_agent,
      @line_ending,
      "accept: */*",
      @line_ending,
      @line_ending
    ]
  end

  defp request_path(%URI{path: nil}), do: "/"
  defp request_path(%URI{path: path}), do: path

  defp request_host(%URI{host: host, scheme: "http", port: 80}), do: host
  defp request_host(%URI{host: host, scheme: "https", port: 443}), do: host
  defp request_host(%URI{host: host, port: port}), do: "#{host}:#{port}"

  ## Response
  # Parse  "HTTP/1.1 200 OK\r\n"
  defp parse_status(%{status_code: nil} = response, conn) do
    {:ok, status_line} = :gen_tcp.recv(conn, 0, @recv_timeout)
    %{response | status_code: parse_status_code(status_line)}
  end

  defp parse_status_code("HTTP/1.1 " <> <<status_code::binary-size(3)>> <> _),
    do: String.to_integer(status_code)

  defp parse_headers(response, conn) do
    :ok = :inet.setopts(conn, packet: :line)
    {:ok, resp} = :gen_tcp.recv(conn, 0, @recv_timeout)
  end
end
