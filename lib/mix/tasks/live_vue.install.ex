defmodule Mix.Tasks.LiveVue.Install do
  @moduledoc """
  Installer for LiveVue with Vite.

  This task first installs Vite using the PhoenixVite installer,
  then configures the project for LiveVue.

  ## Options

    * `--bun` - Use Bun instead of Node.js/npm

  ## Examples

      mix live_vue.install
      mix live_vue.install --bun

  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      composes: ["phoenix_vite.install"],
      schema: [bun: :boolean],
      aliases: [b: :bun]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> Igniter.compose_task("phoenix_vite.install", igniter.args.argv)
    |> configure_environments()
    |> add_live_vue_to_html_helpers()
    |> update_javascript_configuration()
    |> configure_tailwind_for_vue()
    |> update_mix_aliases()
    |> setup_ssr_for_production()
  end

  # Configure environments (config/dev.exs and config/prod.exs)
  defp configure_environments(igniter) do
    # TODO: Add LiveVue config to config/dev.exs
    # config :live_vue,
    #   vite_host: "http://localhost:5173",
    #   ssr_module: LiveVue.SSR.ViteJS,
    #   ssr: true

    # TODO: Add LiveVue config to config/prod.exs
    # config :live_vue,
    #   ssr_module: LiveVue.SSR.NodeJS,
    #   ssr: true

    igniter
  end

  # Add LiveVue to html_helpers in lib/my_app_web.ex
  defp add_live_vue_to_html_helpers(igniter) do
    # TODO: Add `use LiveVue` and `use LiveVue.Components` to html_helpers
    igniter
  end

  # Update JavaScript configuration (app.js)
  defp update_javascript_configuration(igniter) do
    # TODO: Update app.js to:
    # - import topbar from "topbar" instead of ../vendor/topbar
    # - import {getHooks} from "live_vue"
    # - import liveVueApp from "../vue"
    # - Add hooks: getHooks(liveVueApp) to LiveSocket
    igniter
  end

  # Configure Tailwind to include Vue files
  defp configure_tailwind_for_vue(igniter) do
    # TODO: Update tailwind.config.js to include Vue files in content
    igniter
  end

  # Remove esbuild and tailwind packages from dependencies
  defp remove_esbuild_and_tailwind_deps(igniter) do
    # TODO: Remove :esbuild and :tailwind from mix.exs deps
    igniter
  end

  # Update mix.exs aliases
  defp update_mix_aliases(igniter) do
    # TODO: Update aliases in mix.exs to use npm commands
    igniter
  end

  # Remove esbuild and tailwind config from config/config.exs
  defp remove_esbuild_tailwind_config(igniter) do
    # TODO: Remove esbuild and tailwind config from config/config.exs
    igniter
  end

  # Configure watchers in config/dev.exs
  defp configure_watchers(igniter) do
    # TODO: Configure watchers to use npm run dev
    igniter
  end

  # Setup SSR for production in application.ex
  defp setup_ssr_for_production(igniter) do
    # TODO: Add NodeJS.Supervisor to children in application.ex
    igniter
  end

  # Add LiveVue.Reload.vite_assets to root layout
  defp add_live_vue_reload_to_root_layout(igniter) do
    # TODO: Update root.html.heex to use LiveVue.Reload.vite_assets
    igniter
  end
end
