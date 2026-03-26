defmodule LiveVue.SSR.QuickJS do
  @moduledoc """
  Implements SSR using an embedded QuickJS-NG JavaScript engine via `quickjs_ex`.

  Unlike `LiveVue.SSR.NodeJS`, this module runs JavaScript inside the BEAM
  process via a NIF — no external Node.js installation required.

  ## Setup

  1. Add `quickjs_ex` to your dependencies:

      ```elixir
      {:quickjs_ex, "~> 0.2"}
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
        ssr_module: LiveVue.SSR.QuickJS
      ```

  4. Add to your supervision tree in `application.ex`:

      ```elixir
      children = [
        LiveVue.SSR.QuickJS,
        # ...
      ]
      ```

  The module loads the SSR bundle from the path configured via `:ssr_filepath`
  (default `"./static/server.mjs"`), relative to the application's `priv` directory.
  """

  @behaviour LiveVue.SSR

  if Code.ensure_loaded?(QuickJSEx) do
    def child_spec(opts) do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [opts]},
        type: :worker
      }
    end

    def start_link(_opts \\ []) do
      {:ok, rt} = QuickJSEx.start(name: __MODULE__, browser_stubs: true)
      load_bundle(rt)
      {:ok, rt}
    end

    @impl true
    def render(name, props, slots) do
      case QuickJSEx.call(__MODULE__, "render", [name, props, slots]) do
        {:ok, html} ->
          html

        {:error, reason} ->
          raise "QuickJS SSR render failed for #{name}: #{reason}"
      end
    end

    defp load_bundle(rt) do
      code = File.read!(ssr_filepath())

      case QuickJSEx.load_module(rt, "server", code) do
        :ok -> :ok
        {:error, reason} -> raise "QuickJS SSR bundle evaluation failed: #{reason}"
      end
    end
  else
    @quickjs_missing "QuickJSEx is required for LiveVue.SSR.QuickJS. Add {:quickjs_ex, \"~> 0.2\"} to your dependencies."

    def child_spec(_opts), do: raise(@quickjs_missing)
    def start_link(_opts \\ []), do: raise(@quickjs_missing)

    @impl true
    def render(_name, _props, _slots), do: raise(@quickjs_missing)
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
