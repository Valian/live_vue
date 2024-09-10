defmodule LiveVueExamples.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
      LiveVueExamplesWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:live_vue_examples, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveVueExamples.PubSub},
      # Start a worker by calling: LiveVueExamples.Worker.start_link(arg)
      # {LiveVueExamples.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveVueExamplesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveVueExamples.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveVueExamplesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
