defmodule LiveVueUIExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveVueUIExampleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveVueUIExample.PubSub},
      # Start the Endpoint (http/https)
      LiveVueUIExampleWeb.Endpoint
      # Start a worker by calling: LiveVueUIExample.Worker.start_link(arg)
      # {LiveVueUIExample.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveVueUIExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveVueUIExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end 