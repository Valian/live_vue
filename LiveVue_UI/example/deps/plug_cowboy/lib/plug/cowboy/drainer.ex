defmodule Plug.Cowboy.Drainer do
  @moduledoc """
  Process to drain cowboy connections at shutdown.

  When starting `Plug.Cowboy` in a supervision tree, it will create a listener that receives
  requests and creates a connection process to handle that request. During shutdown, a
  `Plug.Cowboy` process will immediately exit, closing the listener and any open connections
  that are still being served. However, in most cases, it is desirable to allow connections
  to complete before shutting down.

  This module provides a process that during shutdown will close listeners and wait
  for connections to complete. It should be placed after other supervised processes that
  handle cowboy connections.

  ## Options

  The following options can be given to the child spec:

    * `:refs` - A list of refs to drain. `:all` is also supported and will drain all cowboy
      listeners, including those started by means other than `Plug.Cowboy`.

    * `:id` - The ID for the process.
      Defaults to `Plug.Cowboy.Drainer`.

    * `:shutdown` - How long to wait for connections to drain.
      Defaults to 5000ms.

    * `:check_interval` - How frequently to check if a listener's
      connections have been drained. Defaults to 1000ms.

  ## Examples

      # In your application
      def start(_type, _args) do
        children = [
          {Plug.Cowboy, scheme: :http, plug: MyApp, options: [port: 4040]},
          {Plug.Cowboy, scheme: :https, plug: MyApp, options: [port: 4041]},
          {Plug.Cowboy.Drainer, refs: [MyApp.HTTP, MyApp.HTTPS]}
        ]

        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
      end
  """
  use GenServer

  @doc false
  @spec child_spec(opts :: Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) when is_list(opts) do
    {spec_opts, opts} = Keyword.split(opts, [:id, :shutdown])

    Supervisor.child_spec(
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [opts]},
        type: :worker
      },
      spec_opts
    )
  end

  @doc false
  def start_link(opts) do
    opts
    |> Keyword.fetch!(:refs)
    |> validate_refs!()

    GenServer.start_link(__MODULE__, opts)
  end

  @doc false
  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, opts}
  end

  @doc false
  @impl true
  def terminate(_reason, opts) do
    opts
    |> Keyword.fetch!(:refs)
    |> drain(opts[:check_interval] || opts[:drain_check_interval] || 1_000)
  end

  defp drain(:all, check_interval) do
    :ranch.info()
    |> Enum.map(&elem(&1, 0))
    |> drain(check_interval)
  end

  defp drain(refs, check_interval) do
    refs
    |> Enum.filter(&suspend_listener/1)
    |> Enum.each(&wait_for_connections(&1, check_interval))
  end

  defp suspend_listener(ref) do
    :ranch.suspend_listener(ref) == :ok
  end

  defp wait_for_connections(ref, check_interval) do
    :ranch.wait_for_connections(ref, :==, 0, check_interval)
  end

  defp validate_refs!(:all), do: :ok
  defp validate_refs!(refs) when is_list(refs), do: :ok

  defp validate_refs!(refs) do
    raise ArgumentError,
          ":refs should be :all or a list of references, got: #{inspect(refs)}"
  end
end
