defmodule Plug.Cowboy.Handler do
  @moduledoc false
  @connection Plug.Cowboy.Conn
  @already_sent {:plug_conn, :sent}

  def init(req, {plug, opts}) do
    conn = @connection.conn(req)

    try do
      conn
      |> plug.call(opts)
      |> maybe_send(plug)
      |> case do
        %Plug.Conn{adapter: {@connection, %{upgrade: {:websocket, websocket_args}} = req}} = conn ->
          {handler, state, cowboy_opts} = websocket_args
          {__MODULE__, copy_resp_headers(conn, req), {handler, state}, cowboy_opts}

        %Plug.Conn{adapter: {@connection, req}} ->
          {:ok, req, {plug, opts}}
      end
    catch
      kind, reason ->
        exit_on_error(kind, reason, __STACKTRACE__, {plug, :call, [conn, opts]})
    after
      receive do
        @already_sent -> :ok
      after
        0 -> :ok
      end
    end
  end

  def upgrade(req, env, __MODULE__, {handler, state}, opts) do
    :cowboy_websocket.upgrade(req, env, handler.module_info(:module), state, opts)
  end

  defp copy_resp_headers(%Plug.Conn{} = conn, req) do
    Enum.reduce(conn.resp_headers, req, fn {key, val}, acc ->
      :cowboy_req.set_resp_header(key, val, acc)
    end)
  end

  defp exit_on_error(
         :error,
         %Plug.Conn.WrapperError{kind: kind, reason: reason, stack: stack},
         _stack,
         call
       ) do
    exit_on_error(kind, reason, stack, call)
  end

  defp exit_on_error(:error, value, stack, call) do
    exception = Exception.normalize(:error, value, stack)
    :erlang.raise(:exit, {{exception, stack}, call}, [])
  end

  defp exit_on_error(:throw, value, stack, call) do
    :erlang.raise(:exit, {{{:nocatch, value}, stack}, call}, [])
  end

  defp exit_on_error(:exit, value, _stack, call) do
    :erlang.raise(:exit, {value, call}, [])
  end

  defp maybe_send(%Plug.Conn{state: :unset}, _plug), do: raise(Plug.Conn.NotSentError)
  defp maybe_send(%Plug.Conn{state: :set} = conn, _plug), do: Plug.Conn.send_resp(conn)
  defp maybe_send(%Plug.Conn{} = conn, _plug), do: conn

  defp maybe_send(other, plug) do
    raise "Cowboy2 adapter expected #{inspect(plug)} to return Plug.Conn but got: " <>
            inspect(other)
  end
end
