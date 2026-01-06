defmodule LiveVue.SSR.NodeJS do
  @moduledoc """
  Implements SSR by using NodeJS package.

  Under the hood, it invokes "render" function exposed by `server.js` file.
  You can see how `server.js` is created by looking at `assets.deploy` command
  and `package.json` build-server script.
  """

  @behaviour LiveVue.SSR

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
        {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(:your_app), pool_size: 4]},

        Replace :your_app with your application's atom name (e.g., :my_app).
        """

        raise %LiveVue.SSR.NotConfigured{message: message}
    end
  end

  @doc """
  Returns the path to the priv directory for NodeJS.Supervisor.

  ## Usage

  In your `application.ex`, pass your app's atom name explicitly:

      {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(:my_app), pool_size: 4]}

  The zero-argument version attempts to auto-detect the calling application,
  but this can fail in production releases where the process context may not
  be associated with an application during supervisor startup. For reliable
  production deployments, always use `server_path/1` with your app name.
  """
  def server_path(app) when is_atom(app) do
    Application.app_dir(app, "/priv")
  end

  @doc """
  Auto-detects the calling application and returns its priv directory path.

  > #### Warning {: .warning}
  >
  > This function can fail in production releases. Use `server_path/1` instead.

  This function uses `:application.get_application/0` which relies on the calling
  process belonging to an application. In production OTP releases, this may return
  `:undefined` during supervisor startup, causing a `MatchError`.

  See `server_path/1` for a more reliable alternative.
  """
  def server_path do
    {:ok, app} = :application.get_application()
    Application.app_dir(app, "/priv")
  end
end
