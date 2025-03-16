import Config

# Configure the endpoint
config :live_vue_ui_example, LiveVueUIExampleWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: LiveVueUIExampleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LiveVueUIExample.PubSub,
  live_view: [signing_salt: "abc123"]

# Configure LiveView
config :phoenix, :json_library, Jason

# Use Bandit as the web server
config :live_vue_ui_example, LiveVueUIExampleWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  server: true,
  adapter: Bandit.PhoenixAdapter

# Configure esbuild
config :esbuild,
  version: "0.14.29",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs" 