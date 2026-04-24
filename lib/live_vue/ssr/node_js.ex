defmodule LiveVue.SSR.NodeJS do
  @moduledoc """
  Implements SSR by using NodeJS package.

  Under the hood, it invokes "render" function exposed by `server.js` file.
  You can see how `server.js` is created by looking at the `assets.deploy`
  Mix alias configured by the installer.
  """

  @behaviour LiveVue.SSR

  if Code.ensure_loaded?(NodeJS) do
    def render(name, props, slots) do
      filename = Application.get_env(:live_vue, :ssr_filepath, "./static/server.mjs")

      try do
        NodeJS.call!({filename, "render"}, [name, props, slots],
          binary: true,
          esm: true
        )
      catch
        :exit, {:noproc, _} ->
          message = """
          NodeJS is not configured. Please add the following to your application.ex:
          {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
          """

          raise %LiveVue.SSR.NotConfigured{message: message}
      end
    end

    def server_path do
      {:ok, path} = :application.get_application()
      Application.app_dir(path, "/priv")
    end
  else
    @nodejs_missing "NodeJS is required for LiveVue.SSR.NodeJS. Add {:nodejs, \"~> 3.1\"} to your dependencies."

    @impl true
    def render(_name, _props, _slots), do: raise(@nodejs_missing)

    def server_path, do: raise(@nodejs_missing)
  end
end
