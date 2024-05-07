import Config

config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr_autoreload: false

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
