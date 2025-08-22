defmodule Mix.Tasks.LiveVue.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "live_vue.install" do
    test "installs successfully with core Vue components" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Verify content contains expected LiveVue patterns
      vue_index = project.rewrite.sources["assets/vue/index.ts"]
      assert vue_index.content =~ "createLiveVue"
      assert vue_index.content =~ "findComponent"

      vue_demo = project.rewrite.sources["assets/vue/VueDemo.vue"]
      assert vue_demo.content =~ "useLiveVue"

      server_js = project.rewrite.sources["assets/js/server.js"]
      assert server_js.content =~ "getRender"

      # Check for LiveVue usage
      web_file = project.rewrite.sources["lib/test_web.ex"]
      assert web_file.content =~ "use LiveVue"
      assert web_file.content =~ "use LiveVue.Components"

      # Check if Vite config was updated
      vite_config = project.rewrite.sources["assets/vite.config.mjs"]
      assert vite_config.content =~ "vue()"
      assert vite_config.content =~ "liveVuePlugin()"
      assert vite_config.content =~ "import vue from"
      assert vite_config.content =~ "import liveVuePlugin from"

      # Check if mix.exs was updated
      mix_exs = project.rewrite.sources["mix.exs"]
      assert mix_exs.content =~ ~r/defp set_build_path/
      assert mix_exs.content =~ ~r/System.put_env\(\"MIX_BUILD_PATH"/

      # Check for updated aliases
      assert mix_exs.content =~ ~r/"assets.build": \[&set_build_path\/1,/
      assert mix_exs.content =~ ~s("phx.server": [&set_build_path/1, "phx.server"])

      # Check for vue_demo route in dev section
      router_file = project.rewrite.sources["lib/test_web/router.ex"]
      assert router_file.content =~ ~r/live "\/vue_demo", TestWeb.VueDemoLive/

      # Check for LiveVue-specific content
      home_template = project.rewrite.sources["lib/test_web/controllers/page_html/home.html.heex"]
      assert home_template.content =~ ~r/End-to-end reactivity for your Live Vue apps/
      assert home_template.content =~ ~r/VueDemo.vue/
      assert home_template.content =~ ~r/vue_demo.ex/
      assert home_template.content =~ ~s(href={~p"/dev/vue_demo"})

      # Check for LiveView content
      live_view_file = project.rewrite.sources["lib/test_web/live/vue_demo_live.ex"]
      assert live_view_file.content =~ ~r/defmodule TestWeb.VueDemoLive/
      assert live_view_file.content =~ ~r/v-component="VueDemo"/
      assert live_view_file.content =~ ~r/handle_event\(\"add_todo\"/
    end

    test "installs successfully with bun flag" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", ["--bun"])
        |> apply_igniter!()

      # Verify bun dependency is added
      mix_exs = project.rewrite.sources["mix.exs"]
      assert mix_exs.content =~ "{:bun,"
    end
  end
end
