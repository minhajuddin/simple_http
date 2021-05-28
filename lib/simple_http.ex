defmodule SimpleHTTP do
  defmodule Request do
    defstruct uri: nil, method: nil, headers: [], body: []

    def new(url, method \\ :get, headers \\ [], body \\ []) do
      %__MODULE__{uri: URI.parse(url), method: method, headers: headers, body: body}
    end
  end

  defmodule Response do
    defstruct status_code: nil, headers: nil, body: nil
  end

  defmodule HTTP1 do
    require Logger

    @space " "
    @crlf "\r\n"
    @user_agent "SimpleHTTP/#{Mix.Project.config()[:version]}"
    @recv_timeout 1000
    @http_version "HTTP/1.1"
    @http_1_0_version "HTTP/1.0"

    def connect(%URI{} = uri) do
      ## open a new TCP connection to the target server
      uri.host
      |> to_charlist()
      |> :gen_tcp.connect(uri.port, [:binary, {:active, false}, {:packet, :raw}])
    end

    def request(conn \\ nil, %Request{} = request, recv_timeout \\ @recv_timeout) do
      {:ok, conn} = if conn, do: {:ok, conn}, else: connect(request.uri)

      #########################################
      ## Send Request
      ## send request packet using the TCP connection
      request_packet = build_request_packet(request)
      Logger.debug(request_packet: :erlang.iolist_to_binary(request_packet))
      :ok = :gen_tcp.send(conn, request_packet)

      #########################################
      ## receive the response
      # read headers
      :ok = :inet.setopts(conn, packet: :line)

      # read lines till the end of the header
      read_response = fn length ->
        {:ok, resp_part} = :gen_tcp.recv(conn, length, recv_timeout)
        resp_part
      end

      {:ok, status_code, content_length, headers} =
        Stream.iterate(read_response.(0), fn _ -> read_response.(0) end)
        |> Enum.take_while(&(&1 != "\r\n"))
        |> parse_headers

      # stop reading line wise, since we are done reading the headers
      :ok = :inet.setopts(conn, packet: :raw)
      body = read_response.(content_length)

      %Response{
        status_code: status_code,
        headers: headers,
        body: body
      }
    end

    defp parse_headers([status_line | headers]) do
      status_code = parse_status_code(status_line)

      headers_map =
        headers
        |> Enum.map(fn header_line ->
          [key, value] =
            header_line
            |> String.split(":", parts: 2)

          {String.downcase(key), String.trim(value)}
        end)
        |> Enum.into(%{})

      {:ok, status_code, String.to_integer(Map.get(headers_map, "content-length", "0")),
       headers_map}
    end

    defp parse_status_code(@http_version <> @space <> <<status_code::binary-size(3)>> <> _),
      do: String.to_integer(status_code)

    defp parse_status_code(@http_1_0_version <> @space <> <<status_code::binary-size(3)>> <> _),
      do: String.to_integer(status_code)

    defp build_request_packet(request) do
      body = :erlang.iolist_to_binary(request.body)
      body_size = byte_size(body)

      headers =
        request.headers
        |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
        |> add_header("host", request_host(request.uri))
        |> add_default_header("accept", "*/*")
        |> add_default_header("user-agent", @user_agent)
        |> add_content_length_header(body_size)

      [
        # GET /products/1?foo=bar HTTP/1.1\r\n
        request_method(request.method),
        @space,
        request_path(request.uri),
        @space,
        @http_version,
        @crlf,
        # accept: */*\r\n
        # user-agent: SimpleHTTP\r\n
        for({k, v} <- headers, do: [k, ?:, @space, v, @crlf]),
        @crlf,
        body
      ]
    end

    defp add_default_header(headers, key, value) do
      if List.keymember?(headers, key, 0) do
        add_header(headers, key, value)
      else
        headers
      end
    end

    defp add_header(headers, key, value), do: [{key, value} | headers]

    defp add_content_length_header(headers, 0), do: headers

    defp add_content_length_header(headers, content_length),
      do: add_header(headers, "content-length", to_string(content_length))

    defp request_path(%URI{path: nil}), do: "/"
    defp request_path(%URI{path: path}), do: path

    defp request_host(%URI{host: host, scheme: "http", port: 80}), do: host
    defp request_host(%URI{host: host, scheme: "https", port: 443}), do: host
    defp request_host(%URI{host: host, port: port}), do: "#{host}:#{port}"

    defp request_method(:get), do: "GET"
    defp request_method(:post), do: "POST"
    defp request_method(:put), do: "PUT"
    defp request_method(:patch), do: "PATCH"
    defp request_method(:delete), do: "DELETE"
    defp request_method(:head), do: "HEAD"
  end
end
