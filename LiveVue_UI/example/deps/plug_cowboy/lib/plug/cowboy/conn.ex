defmodule Plug.Cowboy.Conn do
  @behaviour Plug.Conn.Adapter
  @moduledoc false

  def conn(req) do
    %{
      path: path,
      host: host,
      port: port,
      method: method,
      headers: headers,
      qs: qs,
      peer: {remote_ip, _}
    } = req

    %Plug.Conn{
      adapter: {__MODULE__, req},
      host: host,
      method: method,
      owner: self(),
      path_info: split_path(path),
      port: port,
      remote_ip: remote_ip,
      query_string: qs,
      req_headers: to_headers_list(headers),
      request_path: path,
      scheme: String.to_atom(:cowboy_req.scheme(req))
    }
  end

  @impl true
  def send_resp(req, status, headers, body) do
    req = to_headers_map(req, headers)
    status = Integer.to_string(status) <> " " <> Plug.Conn.Status.reason_phrase(status)
    req = :cowboy_req.reply(status, %{}, body, req)
    {:ok, nil, req}
  end

  @impl true
  def send_file(req, status, headers, path, offset, length) do
    %File.Stat{type: :regular, size: size} = File.stat!(path)

    length =
      cond do
        length == :all -> size
        is_integer(length) -> length
      end

    body = {:sendfile, offset, length, path}
    req = to_headers_map(req, headers)
    req = :cowboy_req.reply(status, %{}, body, req)
    {:ok, nil, req}
  end

  @impl true
  def send_chunked(req, status, headers) do
    req = to_headers_map(req, headers)
    req = :cowboy_req.stream_reply(status, %{}, req)
    {:ok, nil, req}
  end

  @impl true
  def chunk(req, body) do
    :cowboy_req.stream_body(body, :nofin, req)
  end

  @impl true
  def read_req_body(req, opts) do
    length = Keyword.get(opts, :length, 8_000_000)
    read_length = Keyword.get(opts, :read_length, 1_000_000)
    read_timeout = Keyword.get(opts, :read_timeout, 15_000)

    opts = %{length: read_length, period: read_timeout}
    read_req_body(req, opts, length, [])
  end

  defp read_req_body(req, opts, length, acc) when length >= 0 do
    case :cowboy_req.read_body(req, opts) do
      {:ok, data, req} -> {:ok, IO.iodata_to_binary([acc | data]), req}
      {:more, data, req} -> read_req_body(req, opts, length - byte_size(data), [acc | data])
    end
  end

  defp read_req_body(req, _opts, _length, acc) do
    {:more, IO.iodata_to_binary(acc), req}
  end

  @impl true
  def inform(req, status, headers) do
    :cowboy_req.inform(status, to_headers_map(headers), req)
  end

  @impl true
  def upgrade(req, :websocket, args) do
    case args do
      {handler, _state, cowboy_opts} when is_atom(handler) and is_map(cowboy_opts) ->
        :ok

      _ ->
        raise ArgumentError,
              "expected websocket upgrade on Cowboy to be on the format {handler :: atom(), arg :: term(), opts :: map()}, got: " <>
                inspect(args)
    end

    {:ok, Map.put(req, :upgrade, {:websocket, args})}
  end

  def upgrade(_req, _protocol, _args), do: {:error, :not_supported}

  @impl true
  def push(req, path, headers) do
    opts =
      case {req.port, req.sock} do
        {:undefined, {_, port}} -> %{port: port}
        {port, _} when port in [80, 443] -> %{}
        {port, _} -> %{port: port}
      end

    req = to_headers_map(req, headers)
    :cowboy_req.push(path, %{}, req, opts)
  end

  @impl true
  def get_peer_data(%{peer: {ip, port}, cert: cert}) do
    %{
      address: ip,
      port: port,
      ssl_cert: if(cert == :undefined, do: nil, else: cert)
    }
  end

  @impl true
  def get_http_protocol(req) do
    :cowboy_req.version(req)
  end

  ## Helpers

  defp to_headers_list(headers) when is_list(headers) do
    headers
  end

  defp to_headers_list(headers) when is_map(headers) do
    :maps.to_list(headers)
  end

  defp to_headers_map(req, headers) do
    headers = to_headers_map(headers)
    Map.update(req, :resp_headers, headers, &Map.merge(&1, headers))
  end

  defp to_headers_map(headers) when is_list(headers) do
    # Group set-cookie headers into a list for a single `set-cookie`
    # key since cowboy 2 requires headers as a map.
    Enum.reduce(headers, %{}, fn
      {key = "set-cookie", value}, acc ->
        case acc do
          %{^key => existing} -> %{acc | key => [value | existing]}
          %{} -> Map.put(acc, key, [value])
        end

      {key, value}, acc ->
        case acc do
          %{^key => existing} -> %{acc | key => existing <> ", " <> value}
          %{} -> Map.put(acc, key, value)
        end
    end)
  end

  defp split_path(path) do
    segments = :binary.split(path, "/", [:global])
    for segment <- segments, segment != "", do: segment
  end
end
