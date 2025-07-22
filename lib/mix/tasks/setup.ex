defmodule Mix.Tasks.LiveVue.Setup do
  @shortdoc "copy setup files to assets"

  @moduledoc """
  Copies files from assets/copy of the live_vue dependency to phoenix project assets folder
  """
  use Mix.Task

  @impl Mix.Task
  # Adapted from live_svelte mix task at https://github.com/woutdp/live_svelte/blob/master/lib/mix/tasks/configure_esbuild.ex
  def run(_args) do
    [depth: 1]
    |> Mix.Project.deps_paths()
    |> Map.fetch!(:live_vue)
    |> Path.join("assets/copy/**/{*.*}")
    |> Path.wildcard(match_dot: true)
    |> Enum.each(fn full_path ->
      [_beginning, relative_path] = String.split(full_path, "copy", parts: 2)
      new_path = "assets" <> relative_path

      if File.exists?(new_path) do
        log_info(~s/Did not copy `#{full_path}` to `#{new_path}` since file already exists/)
      else
        Mix.Generator.copy_file(full_path, new_path)
      end
    end)
  end

  # Copied from live_svelte logger file at https://github.com/woutdp/live_svelte/blob/master/lib/logger.ex
  defp log_info(status), do: Mix.shell().info([status, :reset])
end
