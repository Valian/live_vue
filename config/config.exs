import Config

config :live_vue,
  # for dev LiveVue.SSR.ViteJS
  # for prod LiveVue.SSR.NodeJS
  ssr_module: nil,

  # if we should by default use ssr or not.
  # can be overriden by v-ssr={true|false} attribute
  ssr: nil,

  # in dev most likely http://localhost:5173
  vite_host: nil,

  # it's relative to LiveVue.SSR.NodeJS.server_path, so "priv" directory
  # that file is created by Vite "build-server" command
  ssr_filepath: "./vue/server.js"

if Mix.env() == :dev do
  # Configure esbuild
  config :esbuild,
    version: "0.20.2",
    client: [
      args: ~w(
        js/live_vue/index.ts
        --bundle
        --target=es2017
        --format=esm
        --outdir=../priv/static
        --external:vue
        --sourcemap
        --define:global=window
        --out-extension:.js=.mjs
      ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    server: [
      args: ~w(
        js/live_vue/server.ts
        --bundle
        --platform=node
        --format=esm
        --outdir=../priv/static
        --external:vue
        --sourcemap
        --define:global=globalThis
        --out-extension:.js=.mjs
      ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
end
