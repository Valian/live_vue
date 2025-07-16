defmodule Mix.Tasks.LiveVue.InstallTest do
  use ExUnit.Case
  import Igniter.Test

  describe "live_vue.install" do
    test "skeleton installer works" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()
    end

    test "installer composes phoenix_vite.install" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions that phoenix_vite.install was run
    end

    test "configures environments" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for config/dev.exs and config/prod.exs
    end

    test "adds live_vue to html_helpers" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for lib/my_app_web.ex modifications
    end

    test "updates javascript configuration" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for app.js modifications
    end

    test "configures tailwind for vue" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for tailwind.config.js modifications
    end

    test "removes esbuild and tailwind deps" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for mix.exs dependency removal
    end

    test "updates mix aliases" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for mix.exs alias updates
    end

    test "removes esbuild tailwind config" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for config/config.exs cleanup
    end

    test "configures watchers" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for config/dev.exs watcher configuration
    end

    test "sets up ssr for production" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for application.ex modifications
    end

    test "adds live_vue reload to root layout" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for root.html.heex modifications
    end

    test "works with --bun flag" do
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", ["--bun"])
      |> apply_igniter!()
      |> assert_unchanged()

      # TODO: Add assertions for bun-specific configuration
    end
  end
end
