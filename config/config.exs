import Config

config :live_vue,
  # for dev LiveVue.SSR.ViteJS
  # for prod LiveVue.SSR.QuickBEAM (default) or LiveVue.SSR.NodeJS
  ssr_module: nil,

  # if we should by default use ssr or not.
  # can be overridden by v-ssr={true|false} attribute
  ssr: nil,

  # in dev most likely http://localhost:5173
  vite_host: nil,

  # it's relative to the current app priv directory for QuickBEAM
  # that file is created by the Mix assets build/deploy alias
  ssr_filepath: "./static/server.mjs",

  # it's a name of gettext module that will be used for translations
  # it's used in LiveVue.Form protocol implementation
  # by default it's not-enabled
  gettext_backend: nil,

  # if false, we will always update full props and not send diffs
  # defaults to true as it greatly reduces payload size
  enable_props_diff: true

if config_env() == :e2e do
  config :playwright, :expect, timeout: 1000
  # The Playwright suite in e2e_pw/
  config :playwright, :test,
    base_url: "http://localhost:4004/",
    trace: :retain_on_failure,
    screenshot: :only_on_failure
end
