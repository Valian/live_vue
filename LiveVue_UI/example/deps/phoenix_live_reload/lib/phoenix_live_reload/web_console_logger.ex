defmodule Phoenix.LiveReloader.WebConsoleLogger do
  @moduledoc false

  @registry Phoenix.LiveReloader.WebConsoleLoggerRegistry
  @compile {:no_warn_undefined, {Logger, :default_formatter, 0}}

  def attach_logger do
    if function_exported?(Logger, :default_formatter, 0) do
      :ok =
        :logger.add_handler(__MODULE__, __MODULE__, %{
          formatter: Logger.default_formatter(colors: [enabled: false])
        })
    end
  end

  def child_spec(_args) do
    Registry.child_spec(name: @registry, keys: :duplicate)
  end

  def subscribe(prefix) do
    {:ok, _} = Registry.register(@registry, :all, prefix)
    :ok
  end

  # Erlang/OTP log handler
  def log(%{meta: meta, level: level} = event, config) do
    %{formatter: {formatter_mod, formatter_config}} = config
    iodata = formatter_mod.format(event, formatter_config)
    msg = IO.iodata_to_binary(iodata)

    Registry.dispatch(@registry, :all, fn entries ->
      event = %{level: level, msg: msg, file: meta[:file], line: meta[:line]}

      for {pid, prefix} <- entries do
        send(pid, {prefix, event})
      end
    end)
  end
end
