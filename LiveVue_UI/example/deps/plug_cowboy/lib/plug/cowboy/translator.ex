defmodule Plug.Cowboy.Translator do
  @moduledoc false

  # Cowboy 2.12.0 and below error format
  @doc """
  The `translate/4` function expected by custom Logger translators.
  """
  def translate(
        min_level,
        :error,
        :format,
        {~c"Ranch listener" ++ _, [ref, conn_pid, stream_id, stream_pid, reason, stack]}
      ) do
    extra = [" (connection ", inspect(conn_pid), ", stream id ", inspect(stream_id), ?)]
    translate_ranch(min_level, ref, extra, stream_pid, reason, stack)
  end

  # Cowboy 2.13.0 error format
  def translate(
        min_level,
        :error,
        :format,
        {~c"Ranch listener" ++ _, [ref, conn_pid, stream_id, stream_pid, {reason, stack}]}
      ) do
    extra = [" (connection ", inspect(conn_pid), ", stream id ", inspect(stream_id), ?)]
    translate_ranch(min_level, ref, extra, stream_pid, reason, stack)
  end

  def translate(_min_level, _level, _kind, _data) do
    :none
  end

  ## Ranch/Cowboy

  defp translate_ranch(
         min_level,
         _ref,
         extra,
         pid,
         {reason, {mod, :call, [%Plug.Conn{} = conn, _opts]}},
         _stack
       ) do
    if log_exception?(reason) do
      message = [
        inspect(pid),
        " running ",
        inspect(mod),
        extra,
        " terminated\n",
        conn_info(min_level, conn)
        | Exception.format(:exit, reason, [])
      ]

      metadata =
        [
          crash_reason: reason,
          domain: [:cowboy]
        ] ++ maybe_conn_metadata(conn)

      {:ok, message, metadata}
    else
      :skip
    end
  end

  defp translate_ranch(_min_level, ref, extra, pid, reason, stack) do
    {:ok,
     [
       "Ranch protocol ",
       inspect(pid),
       " of listener ",
       inspect(ref),
       extra,
       " terminated\n"
       | Exception.format_exit({reason, stack})
     ], crash_reason: {reason, stack}, domain: [:cowboy]}
  end

  defp log_exception?({%{__exception__: true} = exception, _}) do
    status_ranges =
      Application.get_env(:plug_cowboy, :log_exceptions_with_status_code, [500..599])

    status = Plug.Exception.status(exception)

    Enum.any?(status_ranges, &(status in &1))
  end

  defp log_exception?(_), do: true

  defp conn_info(_min_level, conn) do
    [server_info(conn), request_info(conn)]
  end

  defp server_info(%Plug.Conn{host: host, port: :undefined, scheme: scheme}) do
    ["Server: ", host, ?\s, ?(, Atom.to_string(scheme), ?), ?\n]
  end

  defp server_info(%Plug.Conn{host: host, port: port, scheme: scheme}) do
    ["Server: ", host, ":", Integer.to_string(port), ?\s, ?(, Atom.to_string(scheme), ?), ?\n]
  end

  defp request_info(%Plug.Conn{method: method, query_string: query_string} = conn) do
    ["Request: ", method, ?\s, path_to_iodata(conn.request_path, query_string), ?\n]
  end

  defp maybe_conn_metadata(conn) do
    if Application.get_env(:plug_cowboy, :conn_in_exception_metadata, true) do
      [conn: conn]
    else
      []
    end
  end

  defp path_to_iodata(path, ""), do: path
  defp path_to_iodata(path, qs), do: [path, ??, qs]
end
