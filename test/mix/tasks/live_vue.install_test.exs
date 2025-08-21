defmodule Mix.Tasks.LiveVue.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "live_vue.install" do
    test "installs successfully with core Vue components" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Verify core Vue files are created
      assert project.rewrite.sources["assets/vue/index.ts"] != nil
      assert project.rewrite.sources["assets/vue/VueDemo.vue"] != nil
      assert project.rewrite.sources["assets/js/server.js"] != nil

      # Verify content contains expected LiveVue patterns
      vue_index = project.rewrite.sources["assets/vue/index.ts"]
      assert vue_index.content =~ "createLiveVue"
      assert vue_index.content =~ "findComponent"

      vue_demo = project.rewrite.sources["assets/vue/VueDemo.vue"]
      assert vue_demo.content =~ "useLiveVue"

      server_js = project.rewrite.sources["assets/js/server.js"]
      assert server_js.content =~ "getRender"
    end

    test "adds LiveVue to html_helpers" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if LiveVue was added to the web module
      web_file = project.rewrite.sources["lib/test_web.ex"]
      assert web_file != nil, "Web module file should exist"

      # Check for LiveVue usage
      assert web_file.content =~ "use LiveVue"
      assert web_file.content =~ "use LiveVue.Components"
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

    test "updates Vite configuration plugins" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if Vite config was updated
      vite_config = project.rewrite.sources["assets/vite.config.mjs"]
      assert vite_config != nil

      # Check for Vue plugin additions
      assert vite_config.content =~ "vue()"
      assert vite_config.content =~ "liveVuePlugin()"
      assert vite_config.content =~ "import vue from"
      assert vite_config.content =~ "import liveVuePlugin from"
    end

    test "updates mix.exs aliases with set_build_path" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if mix.exs was updated
      mix_exs = project.rewrite.sources["mix.exs"]
      assert mix_exs != nil, "mix.exs file should exist"

      # Check for set_build_path function
      assert mix_exs.content =~ ~r/defp set_build_path/
      assert mix_exs.content =~ ~r/System.put_env\(\"MIX_BUILD_PATH"/

      # Check for updated aliases
      assert mix_exs.content =~ ~r/"assets.build": \[&set_build_path\/1,/

      assert mix_exs.content =~ ~s("phx.server": [&set_build_path/1, "phx.server"])
    end

    test "adds vue_demo route to dev section" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if router was updated
      router_file = project.rewrite.sources["lib/test_web/router.ex"]
      assert router_file != nil, "Router file should exist"

      # Check for vue_demo route in dev section
      assert router_file.content =~ ~r/live "\/vue_demo", TestWeb.VueDemoLive/
    end

    test "updates home template with LiveVue content" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if home template was updated
      home_template = project.rewrite.sources["lib/test_web/controllers/page_html/home.html.heex"]
      assert home_template != nil, "Home template should exist"

      # Check for LiveVue-specific content
      assert home_template.content =~ ~r/End-to-end reactivity for your Live Vue apps/
      assert home_template.content =~ ~r/VueDemo.vue/
      assert home_template.content =~ ~r/vue_demo.ex/
      assert home_template.content =~ ~s(href={~p"/dev/vue_demo"})
    end

    test "creates VueDemo LiveView file" do
      project =
        [app_name: :vue_demo]
        |> phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if VueDemo LiveView was created
      live_view_file = project.rewrite.sources["lib/vue_demo_web/live/vue_demo_live.ex"]
      assert live_view_file != nil, "VueDemo LiveView file should be created"

      # Check for LiveView content
      assert live_view_file.content =~ ~r/defmodule VueDemoWeb.VueDemoLive/
      assert live_view_file.content =~ ~r/v-component="VueDemo"/
      assert live_view_file.content =~ ~r/handle_event\(\"add_todo\"/
    end
  end
end
