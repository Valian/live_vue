import Config

# Configure the endpoint for development
config :live_vue_ui_example, LiveVueUIExampleWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "abc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc123",
  live_view: [signing_salt: "abc123def456"],
  watchers: [
    # Start the esbuild watcher
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"lib/live_vue_ui_example_web/(live|views|components)/.*(ex|heex)$",
      ~r"lib/live_vue_ui_example/.*(ex)$",
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$"
    ]
  ]

# Add proper LiveVue configuration
config :live_vue,
  vite_host: "http://localhost:5173",
  # Re-enable SSR with the NodeJS module
  ssr_module: LiveVue.SSR.NodeJS,
  ssr: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime 