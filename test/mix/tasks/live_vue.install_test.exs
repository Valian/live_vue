defmodule Mix.Tasks.LiveVue.InstallTest do
  use ExUnit.Case

  import Igniter.Test

  describe "live_vue.install" do
    test "installs successfully with core Vue components" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Verify core Vue files are created
      assert project.rewrite.sources["assets/vue/index.ts"] != nil, "assets/vue/index.ts should be created"
      assert project.rewrite.sources["assets/vue/VueDemo.vue"] != nil, "assets/vue/VueDemo.vue should be created"
      assert project.rewrite.sources["assets/js/server.js"] != nil, "assets/js/server.js should be created"

      # Verify content contains expected LiveVue patterns
      vue_index = project.rewrite.sources["assets/vue/index.ts"]
      assert String.contains?(vue_index.content, "createLiveVue"), "Vue index should contain createLiveVue"
      assert String.contains?(vue_index.content, "findComponent"), "Vue index should contain findComponent"

      vue_demo = project.rewrite.sources["assets/vue/VueDemo.vue"]
      assert String.contains?(vue_demo.content, "useLiveVue"), "VueDemo should use useLiveVue"

      server_js = project.rewrite.sources["assets/js/server.js"]
      assert String.contains?(server_js.content, "getRender"), "Server.js should contain getRender"

      # Note: LiveVue dependency is automatically added by igniter.install script
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
      assert String.contains?(web_file.content, "use LiveVue"), "Should add 'use LiveVue' to html_helpers"

      assert String.contains?(web_file.content, "use LiveVue.Components"),
             "Should add 'use LiveVue.Components' to html_helpers"
    end

    test "installs successfully with bun flag" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", ["--bun"])
        |> apply_igniter!()

      # Verify bun dependency is added
      mix_exs = project.rewrite.sources["mix.exs"]
      assert String.contains?(mix_exs.content, "{:bun,"), "Should add bun dependency with --bun flag"
    end

    test "updates Vite configuration plugins" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if Vite config was updated
      vite_config = project.rewrite.sources["assets/vite.config.mjs"]
      assert vite_config != nil, "Vite config file should exist"

      # Check for Vue plugin additions
      assert String.contains?(vite_config.content, "vue()"), "Should add vue() plugin"
      assert String.contains?(vite_config.content, "liveVuePlugin()"), "Should add liveVuePlugin()"
      assert String.contains?(vite_config.content, "import vue from"), "Should import vue plugin"
      assert String.contains?(vite_config.content, "import liveVuePlugin from"), "Should import liveVuePlugin"
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
      assert String.contains?(mix_exs.content, "defp set_build_path"), "Should add set_build_path function"
      assert String.contains?(mix_exs.content, "System.put_env(\"MIX_BUILD_PATH\""), "Should set MIX_BUILD_PATH env var"

      # Check for updated aliases
      assert String.contains?(mix_exs.content, "\"assets.build\": [&set_build_path/1,"),
             "Should update assets.build alias"

      assert String.contains?(mix_exs.content, ~s("phx.server": [&set_build_path/1, "phx.server"])),
             "Should add phx.server alias"
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
      assert String.contains?(router_file.content, "live(\"/vue_demo\", VueDemoLive)"),
             "Should add vue_demo route to dev section"
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
      assert String.contains?(home_template.content, "End-to-end reactivity for your Live Vue apps"),
             "Should update tagline"

      assert String.contains?(home_template.content, "VueDemo.vue"),
             "Should mention VueDemo.vue file"

      assert String.contains?(home_template.content, "vue_demo.ex"),
             "Should mention vue_demo.ex file"

      assert String.contains?(home_template.content, ~s(href={~p"/dev/vue_demo"})),
             "Should add Vue Demo button link"
    end

    test "creates VueDemo LiveView file" do
      project =
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()

      # Check if VueDemo LiveView was created
      live_view_file = project.rewrite.sources["lib/test_web/live/vue_demo_live.ex"]
      assert live_view_file != nil, "VueDemo LiveView file should be created"

      # Check for LiveView content
      assert String.contains?(live_view_file.content, "defmodule TestWeb.VueDemoLive"),
             "Should define VueDemoLive module"

      assert String.contains?(live_view_file.content, "v-component=\"VueDemo\""),
             "Should use VueDemo component"

      assert String.contains?(live_view_file.content, "handle_event(\"add_todo\""),
             "Should handle add_todo event"
    end

    test "basic functionality works without errors" do
      # This is a comprehensive smoke test that verifies the installer
      # runs all the way through without any exceptions
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
    end
  end
end
