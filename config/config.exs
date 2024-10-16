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
  ssr_filepath: "./vue/server.js"
