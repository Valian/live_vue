import Config

config :live_vue,
  # for dev LiveVue.SSR.ViteJS
  # for prod LiveVue.SSR.NodeJS
  ssr_module: nil,

  # if we should by default use ssr or not.
  # can be overridden by v-ssr={true|false} attribute
  ssr: nil,

  # in dev most likely http://localhost:5173
  vite_host: nil,

  # it's relative to LiveVue.SSR.NodeJS.server_path, so "priv" directory
  # that file is created by Vite "build-server" command
  ssr_filepath: "./vue/server.js",

  # it's a name of gettext module that will be used for translations
  # it's used in LiveVue.Form protocol implementation
  # by default it's not-enabled
  gettext_backend: nil,

  # if false, we will always update full props and not send diffs
  # defaults to true as it greatly reduces payload size
  enable_props_diff: true,

  # list of props that should be automatically added to all Vue components
  # their value is taken from socket assigns
  # examples:
  #   [:current_user]  # socket.assigns.current_user → prop current_user
  #   [{:theme, :ui_theme}]  # socket.assigns.ui_theme → prop theme
  shared_props: []
