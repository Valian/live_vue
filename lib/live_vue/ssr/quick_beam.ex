defmodule LiveVue.SSR.QuickBEAM do
  @moduledoc """
  Implements SSR using an embedded [QuickBEAM](https://hex.pm/packages/quickbeam) JavaScript runtime.

  Unlike `LiveVue.SSR.NodeJS`, this module runs JavaScript inside the BEAM
  process — no external Node.js installation required.

  ## Setup

  1. Add `quickbeam` to your dependencies:

      ```elixir
      {:quickbeam, "~> 0.8"}
      ```

  2. Add the `stubNodeBuiltins` Vite plugin to your `vite.config`:

      ```javascript
      import stubNodeBuiltins from "live_vue/stubNodeBuiltins"

      export default defineConfig({
        plugins: [vue(), liveVuePlugin(), stubNodeBuiltins()],
      })
      ```

     This replaces Node.js built-in imports (`fs`, `path`, `node:stream`) with
     stubs at build time, producing a self-contained SSR bundle.

  3. Configure production SSR:

      ```elixir
      # config/prod.exs
      config :live_vue,
        ssr_module: LiveVue.SSR.QuickBEAM
      ```

  4. Add to your supervision tree in `application.ex`:

      ```elixir
      children = [
        LiveVue.SSR.QuickBEAM,
        # ...
      ]
      ```

  The module loads the SSR bundle from the path configured via `:ssr_filepath`
  (default `"./static/server.mjs"`), relative to the application's `priv` directory.
  """

  @behaviour LiveVue.SSR

  if Code.ensure_loaded?(QuickBEAM) do
    def child_spec(opts) do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [opts]},
        type: :worker
      }
    end

    def start_link(_opts \\ []) do
      {:ok, rt} = QuickBEAM.start(name: __MODULE__, apis: [:browser, :node])
      load_bundle(rt)
      {:ok, rt}
    end

    @impl true
    def render(name, props, slots) do
      case QuickBEAM.call(__MODULE__, "render", [name, props, slots]) do
        {:ok, html} ->
          html

        {:error, reason} ->
          raise "QuickBEAM SSR render failed for #{name}: #{inspect(reason)}"
      end
    end

    defp load_bundle(rt) do
      code = File.read!(ssr_filepath())

      # QuickBEAM's load_module evaluates ES module code but doesn't expose
      # exports as globals. Append a bridge line that assigns the render export
      # to globalThis so it's callable via QuickBEAM.call/3.
      bridged = code <> "\nglobalThis.render = render;\n"

      case QuickBEAM.load_module(rt, "server", bridged) do
        :ok -> :ok
        {:error, reason} -> raise "QuickBEAM SSR bundle evaluation failed: #{inspect(reason)}"
      end
    end
  else
    @quickbeam_missing "QuickBEAM is required for LiveVue.SSR.QuickBEAM. Add {:quickbeam, \"~> 0.8\"} to your dependencies."

    def child_spec(_opts), do: raise(@quickbeam_missing)
    def start_link(_opts \\ []), do: raise(@quickbeam_missing)

    @impl true
    def render(_name, _props, _slots), do: raise(@quickbeam_missing)
  end

  defp ssr_filepath do
    app =
      case :application.get_application(__MODULE__) do
        {:ok, app} -> app
        :undefined -> :live_vue
      end

    filepath = Application.get_env(:live_vue, :ssr_filepath, "./static/server.mjs")

    if Path.type(filepath) == :absolute do
      filepath
    else
      Application.app_dir(app, Path.join("priv", filepath))
    end
  end
end
