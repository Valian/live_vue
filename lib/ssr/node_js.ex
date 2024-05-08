defmodule LiveVue.SSR.NodeJS do
  @moduledoc false
  @behaviour LiveVue.SSR

  def render(name, props, slots) do
    filename = Application.get_env(:live_vue, :ssr_filepath, "./vue/server.mjs")

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
