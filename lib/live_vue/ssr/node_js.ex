defmodule LiveVue.SSR.NodeJS do
  @moduledoc """
  Implements SSR by using `NodeJS` package.

  Under the hood, it invokes "render" function exposed by `server.js` file.
  You can see how `server.js` is created by looking at `assets.deploy` command
  and `package.json` build-server script.
  """

  @behaviour LiveVue.SSR

  def render(name, props, slots) do
    filename = Application.get_env(:live_vue, :ssr_filepath, "./vue/server.js")

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

  def server_path() do
    {:ok, path} = :application.get_application()
    Application.app_dir(path, "/priv")
  end
end
