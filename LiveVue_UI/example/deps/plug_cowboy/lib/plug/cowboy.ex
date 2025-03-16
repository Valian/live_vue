defmodule Plug.Cowboy do
  @moduledoc """
  Adapter interface to the [Cowboy webserver](https://github.com/ninenines/cowboy).

  ## Options

    * `:net` - if using `:inet` (IPv4 only, the default) or `:inet6` (IPv6).

    * `:ip` - the IP to bind the server to. Must be one of:

        * a tuple in the format `{a, b, c, d}` with each value in `0..255` for IPv4,
        * a tuple in the format `{a, b, c, d, e, f, g, h}` with each value in `0..65_535` for IPv6,
        * or a tuple in the format `{:local, path}` for a Unix socket at the given `path`.

      If you set an IPv6, the `:net` option will be automatically set to `:inet6`.
      If both `:net` and `:ip` options are given, make sure they are compatible
      (that is, give a IPv4 for `:inet` and IPv6 for `:inet6`).
      Also, see the [*Loopback vs Public IP Addresses*
      section](#module-loopback-vs-public-ip-addresses).

    * `:port` - the port to run the server.
      Defaults to `4000` (HTTP) and `4040` (HTTPS).
      Must be `0` when `:ip` is a `{:local, path}` tuple.

    * `:dispatch` - manually configure Cowboy's dispatch.
      If this option is used, the given plug won't be initialized
      nor dispatched to (and doing so becomes the user's responsibility).

    * `:ref` - the reference name to be used.
      Defaults to `plug.HTTP` (HTTP) and `plug.HTTPS` (HTTPS).
      The default reference name does not contain the port, so in order
      to serve the same plug on multiple ports you need to set the `:ref` accordingly.
      For example, `ref: MyPlug_HTTP_4000`, `ref: MyPlug_HTTP_4001`, and so on.
      This is the value that needs to be given on shutdown.

    * `:compress` - if `true`, Cowboy will attempt to compress the response body.
      Defaults to `false`.

    * `:stream_handlers` - List of Cowboy `stream_handlers`,
      see [Cowboy docs](https://ninenines.eu/docs/en/cowboy/2.12/manual/cowboy_http/).

    * `:protocol_options` - Specifies remaining protocol options,
      see the [Cowboy docs](https://ninenines.eu/docs/en/cowboy/2.12/manual/cowboy_http/).

    * `:transport_options` - A keyword list specifying transport options,
      see [Ranch docs](https://ninenines.eu/docs/en/ranch/1.7/manual/ranch/).
      By default `:num_acceptors` will be set to `100` and `:max_connections`
      to `16_384`.

  All other options given at the top level must configure the underlying
  socket. For HTTP connections, those options are listed under
  [`ranch_tcp`](https://ninenines.eu/docs/en/ranch/1.7/manual/ranch_tcp/).
  For example, you can set `:ipv6_v6only` to true if you want to bind only
  on IPv6 addresses.

  For HTTPS (SSL) connections, those options are described in
  [`ranch_ssl`](https://ninenines.eu/docs/en/ranch/1.7/manual/ranch_ssl/).
  See `https/3` for an example and read `Plug.SSL.configure/1` to
  understand about our SSL defaults.

  When using a Unix socket, OTP 21+ is required for `Plug.Static` and
  `Plug.Conn.send_file/3` to behave correctly.

  ## Safety Limits

  Cowboy sets different limits on URL size, header length, number of
  headers, and so on to protect your application from attacks. For example,
  the request line length defaults to 10k, which means Cowboy will return
  `414` if a larger URL is given. You can change this under `:protocol_options`:

      protocol_options: [max_request_line_length: 50_000]

  Keep in mind that increasing those limits can pose a security risk.
  Other times, browsers and proxies along the way may have equally strict
  limits, which means the request will still fail or the URL will be
  pruned. You can [consult all limits here](https://ninenines.eu/docs/en/cowboy/2.12/manual/cowboy_http/).

  ## Loopback vs Public IP Addresses

  Should your application bind to a loopback address, such as `::1` (IPv6) or
  `127.0.0.1` (IPv4), or a public one, such as `::0` (IPv6) or `0.0.0.0`
  (IPv4)? It depends on how (and whether) you want it to be reachable from
  other machines.

  Loopback addresses are only reachable from the same host (`localhost` is
  usually configured to resolve to a loopback address). You may wish to use one if:

    * Your app is running in a development environment (such as your laptop) and
      you don't want others on the same network to access it.
    * Your app is running in production, but behind a reverse proxy. For
      example, you might have [nginx](https://nginx.org/en/) bound to a public
      address and serving HTTPS, but forwarding the traffic to your application
      running on the same host. In that case, having your app bind to the
      loopback address means that nginx can reach it, but outside traffic can
      only reach it via nginx.

  Public addresses are reachable from other hosts. You may wish to use one if:

    * Your app is running in a container. In this case, its loopback address is
      reachable only from within the container; to be accessible from outside the
      container, it needs to bind to a public IP address.
    * Your app is running in production without a reverse proxy, using Cowboy's
      SSL support.

  ## Logging

  You can configure which exceptions are logged via `:log_exceptions_with_status_code`
  application environment variable. If the status code returned by `Plug.Exception.status/1`
  for the exception falls into any of the configured ranges, the exception is logged.
  By default it's set to `[500..599]`.

      config :plug_cowboy,
        log_exceptions_with_status_code: [400..599]

  By default, `Plug.Cowboy` includes the entire `conn` to the log metadata for exceptions.
  However, this metadata may contain sensitive information such as security headers or
  cookies, which may be logged in plain text by certain logging backends. To prevent this,
  you can configure the `:conn_in_exception_metadata` option to not include the `conn` in the metadata.

      config :plug_cowboy,
        conn_in_exception_metadata: false

  ## Instrumentation

  `Plug.Cowboy` uses the [`telemetry` library](https://github.com/beam-telemetry/telemetry)
  for instrumentation. The following span events are published during each request:

    * `[:cowboy, :request, :start]` - dispatched at the beginning of the request
    * `[:cowboy, :request, :stop]` - dispatched at the end of the request
    * `[:cowboy, :request, :exception]` - dispatched at the end of a request that exits

  A single event is published when the request ends with an early error:
    * `[:cowboy, :request, :early_error]` - dispatched for requests terminated early by Cowboy

  See [`cowboy_telemetry`](https://github.com/beam-telemetry/cowboy_telemetry#telemetry-events)
  for more details on the events and their measurements and metadata.

  To opt-out of this default instrumentation, you can manually configure
  Cowboy with the option:

      stream_handlers: [:cowboy_stream_h]

  ## WebSocket support

  `Plug.Cowboy` supports upgrading HTTP requests to WebSocket connections via
  the use of the `Plug.Conn.upgrade_adapter/3` function, called with `:websocket` as the second
  argument. Applications should validate that the connection represents a valid WebSocket request
  before calling this function (Cowboy will validate the connection as part of the upgrade
  process, but does not provide any capacity for an application to be notified if the upgrade is
  not successful). If an application wishes to negotiate WebSocket subprotocols or otherwise set
  any response headers, it should do so before calling `Plug.Conn.upgrade_adapter/3`.

  The third argument to `Plug.Conn.upgrade_adapter/3` defines the details of how Plug.Cowboy
  should handle the WebSocket connection, and must take the form `{handler, handler_opts,
  connection_opts}`, where values are as follows:

  * `handler` is a module which implements the
    [`:cowboy_websocket`](https://ninenines.eu/docs/en/cowboy/2.6/manual/cowboy_websocket/)
    behaviour. Note that this module will NOT have its `c:cowboy_websocket.init/2` callback
    called; only the 'later' parts of the `:cowboy_websocket` lifecycle are supported
  * `handler_opts` is an arbitrary term which will be passed as the argument to
    `c:cowboy_websocket.websocket_init/1`
  * `connection_opts` is a map with any of [Cowboy's websockets options](https://ninenines.eu/docs/en/cowboy/2.6/manual/cowboy_websocket/#_opts)

  """

  require Logger

  @doc false
  def start(_type, _args) do
    Logger.add_translator({Plug.Cowboy.Translator, :translate})
    Supervisor.start_link([], strategy: :one_for_one)
  end

  # Made public with @doc false for testing.
  @doc false
  def args(scheme, plug, plug_opts, cowboy_options) do
    {cowboy_options, non_keyword_options} = Enum.split_with(cowboy_options, &match?({_, _}, &1))

    cowboy_options
    |> normalize_cowboy_options(scheme)
    |> to_args(scheme, plug, plug_opts, non_keyword_options)
  end

  @doc """
  Runs cowboy under HTTP.

  ## Example

      # Starts a new interface:
      Plug.Cowboy.http(MyPlug, [], port: 80)

      # The interface above can be shut down with:
      Plug.Cowboy.shutdown(MyPlug.HTTP)

  """
  @spec http(module(), Keyword.t(), Keyword.t()) ::
          {:ok, pid} | {:error, :eaddrinuse} | {:error, term}
  def http(plug, opts, cowboy_options \\ []) do
    run(:http, plug, opts, cowboy_options)
  end

  @doc """
  Runs cowboy under HTTPS.

  Besides the options described in the module documentation,
  this function sets defaults and accepts all options defined
  in `Plug.SSL.configure/1`.

  ## Example

      # Starts a new interface:
      Plug.Cowboy.https(
        MyPlug,
        [],
        port: 443,
        password: "SECRET",
        otp_app: :my_app,
        keyfile: "priv/ssl/key.pem",
        certfile: "priv/ssl/cert.pem",
        dhfile: "priv/ssl/dhparam.pem"
      )

      # The interface above can be shut down with:
      Plug.Cowboy.shutdown(MyPlug.HTTPS)

  """
  @spec https(module(), Keyword.t(), Keyword.t()) ::
          {:ok, pid} | {:error, :eaddrinuse} | {:error, term}
  def https(plug, opts, cowboy_options \\ []) do
    Application.ensure_all_started(:ssl)
    run(:https, plug, opts, cowboy_options)
  end

  @doc """
  Shutdowns the given reference.
  """
  @spec shutdown(:ranch.ref()) :: :ok | {:error, :not_found}
  def shutdown(ref) do
    :cowboy.stop_listener(ref)
  end

  @doc """
  Returns a supervisor child spec to start Cowboy under a supervisor.

  It supports all options as specified in the module documentation plus it
  requires the following two options:

    * `:scheme` - either `:http` or `:https`
    * `:plug` - such as `MyPlug` or `{MyPlug, plug_opts}`

  ## Examples

  Assuming your Plug module is named `MyApp` you can add it to your
  supervision tree by using this function:

      children = [
        {Plug.Cowboy, scheme: :http, plug: MyApp, options: [port: 4040]}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)

  """
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    scheme = Keyword.fetch!(opts, :scheme)

    {plug, plug_opts} =
      case Keyword.fetch!(opts, :plug) do
        {_, _} = tuple -> tuple
        plug -> {plug, []}
      end

    # We support :options for backwards compatibility.
    cowboy_opts =
      opts
      |> Keyword.drop([:scheme, :plug, :options])
      |> Kernel.++(Keyword.get(opts, :options, []))

    cowboy_args = args(scheme, plug, plug_opts, cowboy_opts)
    [ref, transport_opts, proto_opts] = cowboy_args

    {ranch_module, cowboy_protocol, transport_opts} =
      case scheme do
        :http ->
          {:ranch_tcp, :cowboy_clear, transport_opts}

        :https ->
          %{socket_opts: socket_opts} = transport_opts

          socket_opts =
            socket_opts
            |> Keyword.put_new(:next_protocols_advertised, ["h2", "http/1.1"])
            |> Keyword.put_new(:alpn_preferred_protocols, ["h2", "http/1.1"])

          {:ranch_ssl, :cowboy_tls, %{transport_opts | socket_opts: socket_opts}}
      end

    case :ranch.child_spec(ref, ranch_module, transport_opts, cowboy_protocol, proto_opts) do
      {id, start, restart, shutdown, type, modules} ->
        %{
          id: id,
          start: start,
          restart: restart,
          shutdown: shutdown,
          type: type,
          modules: modules
        }

      child_spec when is_map(child_spec) ->
        child_spec
    end
  end

  ## Helpers

  @protocol_options [:compress, :stream_handlers]

  defp run(scheme, plug, opts, cowboy_options) do
    case Application.ensure_all_started(:cowboy) do
      {:ok, _} ->
        nil

      {:error, {:cowboy, _}} ->
        raise "could not start the Cowboy application. Please ensure it is listed as a dependency in your mix.exs"
    end

    start =
      case scheme do
        :http -> :start_clear
        :https -> :start_tls
        other -> :erlang.error({:badarg, [other]})
      end

    :telemetry.attach(
      :plug_cowboy,
      [:cowboy, :request, :early_error],
      &__MODULE__.handle_event/4,
      nil
    )

    apply(:cowboy, start, args(scheme, plug, opts, cowboy_options))
  end

  defp normalize_cowboy_options(cowboy_options, :http) do
    Keyword.put_new(cowboy_options, :port, 4000)
  end

  defp normalize_cowboy_options(cowboy_options, :https) do
    cowboy_options
    |> Keyword.put_new(:port, 4040)
    |> Plug.SSL.configure()
    |> case do
      {:ok, options} -> options
      {:error, message} -> fail(message)
    end
  end

  defp to_args(opts, scheme, plug, plug_opts, non_keyword_opts) do
    {timeout, opts} = Keyword.pop(opts, :timeout)

    if timeout do
      Logger.warning("the :timeout option for Cowboy webserver has no effect and must be removed")
    end

    opts = Keyword.delete(opts, :otp_app)
    {ref, opts} = Keyword.pop(opts, :ref)
    {dispatch, opts} = Keyword.pop(opts, :dispatch)
    {protocol_options, opts} = Keyword.pop(opts, :protocol_options, [])

    dispatch = :cowboy_router.compile(dispatch || dispatch_for(plug, plug_opts))
    {extra_options, opts} = Keyword.split(opts, @protocol_options)

    extra_options = set_stream_handlers(extra_options)
    protocol_and_extra_options = :maps.from_list(protocol_options ++ extra_options)
    protocol_options = Map.merge(%{env: %{dispatch: dispatch}}, protocol_and_extra_options)
    {transport_options, socket_options} = Keyword.pop(opts, :transport_options, [])

    {net, socket_options} = Keyword.pop(socket_options, :net)
    socket_options = List.wrap(net) ++ non_keyword_opts ++ socket_options

    transport_options =
      transport_options
      |> Keyword.put_new(:num_acceptors, 100)
      |> Keyword.put_new(:max_connections, 16_384)
      |> Keyword.update(
        :socket_opts,
        socket_options,
        &(&1 ++ socket_options)
      )
      |> Map.new()

    [ref || build_ref(plug, scheme), transport_options, protocol_options]
  end

  @default_stream_handlers [:cowboy_telemetry_h, :cowboy_stream_h]

  defp set_stream_handlers(opts) do
    compress = Keyword.get(opts, :compress)
    stream_handlers = Keyword.get(opts, :stream_handlers)

    case {compress, stream_handlers} do
      {true, nil} ->
        Keyword.put_new(opts, :stream_handlers, [:cowboy_compress_h | @default_stream_handlers])

      {true, _} ->
        raise "cannot set both compress and stream_handlers at once. " <>
                "If you wish to set compress, please add `:cowboy_compress_h` to your stream handlers."

      {_, nil} ->
        Keyword.put_new(opts, :stream_handlers, @default_stream_handlers)

      {_, _} ->
        opts
    end
  end

  defp build_ref(plug, scheme) do
    Module.concat(plug, scheme |> to_string |> String.upcase())
  end

  defp dispatch_for(plug, opts) do
    opts = plug.init(opts)
    [{:_, [{:_, Plug.Cowboy.Handler, {plug, opts}}]}]
  end

  defp fail(message) do
    raise ArgumentError, "could not start Cowboy2 adapter, " <> message
  end

  @doc false
  def handle_event(
        [:cowboy, :request, :early_error],
        _,
        %{reason: {:connection_error, :limit_reached, specific_reason}, partial_req: partial_req},
        _
      ) do
    Logger.error("""
    Cowboy returned 431 because it was unable to parse the request headers.

    This may happen because there are no headers, or there are too many headers
    or the header name or value are too large (such as a large cookie).

    More specific reason is:

        #{inspect(specific_reason)}

    You can customize those limits when configuring your http/https
    server. The configuration option and default values are shown below:

        protocol_options: [
          max_header_name_length: 64,
          max_header_value_length: 4096,
          max_headers: 100
        ]

    Request info:

        peer: #{format_peer(partial_req.peer)}
        method: #{partial_req.method || "<unable to parse>"}
        path: #{partial_req.path || "<unable to parse>"}
    """)
  end

  def handle_event(_, _, _, _) do
    :ok
  end

  defp format_peer({addr, port}) do
    "#{:inet_parse.ntoa(addr)}:#{port}"
  end
end
