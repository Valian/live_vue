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
      assert project.rewrite.sources["assets/vue/Counter.vue"] != nil, "assets/vue/Counter.vue should be created"
      assert project.rewrite.sources["assets/js/server.js"] != nil, "assets/js/server.js should be created"
      
      # Verify content contains expected LiveVue patterns
      vue_index = project.rewrite.sources["assets/vue/index.ts"]
      assert String.contains?(vue_index.content, "createLiveVue"), "Vue index should contain createLiveVue"
      assert String.contains?(vue_index.content, "findComponent"), "Vue index should contain findComponent"
      
      counter_vue = project.rewrite.sources["assets/vue/Counter.vue"]
      assert String.contains?(counter_vue.content, "defineProps<{count: number}>"), "Counter should have props"
      
      server_js = project.rewrite.sources["assets/js/server.js"]
      assert String.contains?(server_js.content, "getRender"), "Server.js should contain getRender"
      
      # Note: LiveVue dependency is automatically added by igniter.install script
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

    test "basic functionality works without errors" do
      # This is a comprehensive smoke test that verifies the installer
      # runs all the way through without any exceptions
      phx_test_project()
      |> Igniter.compose_task("live_vue.install", [])
      |> apply_igniter!()
    end
  end
end