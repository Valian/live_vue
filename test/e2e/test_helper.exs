# Configure Phoenix JSON encoder
Application.put_env(:phoenix, :json_library, Jason)

# Configure the test endpoint
Application.put_env(:live_vue, LiveVue.E2E.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4004],
  adapter: Bandit.PhoenixAdapter,
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64),
  debug_errors: true,
  pubsub_server: LiveVue.E2E.PubSub
)

Process.register(self(), :e2e_helper)

defmodule LiveVue.E2E.ErrorHTML do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule LiveVue.E2E.Layout do
  @moduledoc false
  use Phoenix.Component

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>LiveVue E2E</title>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end

  def render("live.html", assigns) do
    ~H"""
    <script src="https://unpkg.com/vue@3/dist/vue.global.js">
    </script>
    <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.21/priv/static/phoenix.min.js">
    </script>
    <script src="/assets/app.js">
    </script>
    {@inner_content}
    """
  end
end

defmodule LiveVue.E2E.Hooks do
  @moduledoc false
  import Phoenix.LiveView

  alias Phoenix.LiveView.Socket

  require Logger

  def on_mount(:default, _params, _session, socket) do
    socket
    |> attach_hook(:eval_handler, :handle_event, &handle_eval_event/3)
    |> then(&{:cont, &1})
  end

  defp handle_eval_event("sandbox:eval", %{"value" => code}, socket) do
    {result, _} = Code.eval_string(code, [socket: socket], __ENV__)
    Logger.debug("lv:#{inspect(self())} eval result: #{inspect(result)}")

    case result do
      {:noreply, %Socket{} = socket} -> {:halt, %{}, socket}
      %Socket{} = socket -> {:halt, %{}, socket}
      result -> {:halt, %{"result" => result}, socket}
    end
  end

  defp handle_eval_event(_, _, socket), do: {:cont, socket}
end

defmodule LiveVue.E2E.HealthController do
  import Plug.Conn

  def init(opts), do: opts

  def index(conn, _params) do
    send_resp(conn, 200, "OK")
  end
end

defmodule LiveVue.E2E.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  alias LiveVue.E2E.Layout

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_root_layout, html: {Layout, :root}
  end

  live_session :default,
    layout: {Layout, :live},
    on_mount: {LiveVue.E2E.Hooks, :default} do
    scope "/", LiveVue.E2E do
      pipe_through(:browser)

      live "/test", TestLive
      live "/prop-diff-test", PropDiffTestLive
    end
  end

  scope "/", LiveVue.E2E do
    pipe_through(:browser)

    get "/health", HealthController, :index
  end
end

defmodule LiveVue.E2E.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_vue

  @session_options [
    store: :cookie,
    key: "_lv_e2e_key",
    signing_salt: "aaaaaaaa",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix"
  plug Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view"
  plug Plug.Static, from: "test/e2e/priv/static/assets", at: "/assets"

  plug :health_check
  plug :halt

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.Session, @session_options
  plug LiveVue.E2E.Router

  defp health_check(%{request_path: "/health"} = conn, _opts) do
    conn
    |> Plug.Conn.send_resp(200, "OK")
    |> Plug.Conn.halt()
  end

  defp health_check(conn, _opts), do: conn

  defp halt(%{request_path: "/halt"}, _opts) do
    send(:e2e_helper, :halt)
    Process.sleep(:infinity)
  end

  defp halt(conn, _opts), do: conn
end

# Start PubSub and Endpoint
{:ok, _} =
  Supervisor.start_link(
    [
      LiveVue.E2E.Endpoint,
      {Phoenix.PubSub, name: LiveVue.E2E.PubSub}
    ],
    strategy: :one_for_one
  )

IO.puts("Starting e2e server on port #{LiveVue.E2E.Endpoint.config(:http)[:port]}")

if not IEx.started?() do
  spawn(fn ->
    IO.read(:stdio, :line)
    send(:e2e_helper, :halt)
  end)

  receive do
    :halt -> :ok
  end
end
