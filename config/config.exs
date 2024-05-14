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
  ssr_filepath: "./vue/server.mjs"

if Mix.env() == :dev do
  esbuild = fn args ->
    [
      args: args,
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
  end

  config :esbuild,
    version: "0.17.11",
    module:
      esbuild.(
        ~w(./js/live_vue --bundle --format=esm --sourcemap --outfile=../priv/static/live_vue.esm.js --external:vue  --external:vue/server-renderer)
      ),
    server:
      esbuild.(
        ~w(./js/live_vue/server.js --platform=node --bundle --format=esm --sourcemap --outfile=../priv/static/server.js --external:vue  --external:vue/server-renderer)
      ),
    vite:
      esbuild.(
        ~w(./js/live_vue/vitePlugin.js --platform=node --bundle --format=cjs --sourcemap --outfile=../priv/static/vitePlugin.js)
      )
end
