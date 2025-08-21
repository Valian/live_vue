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

    test "adds LiveVue to html_helpers" do
      project = 
        phx_test_project()
        |> Igniter.compose_task("live_vue.install", [])
        |> apply_igniter!()
        
      # Check if LiveVue was added to the web module
      web_file = project.rewrite.sources["lib/test_web.ex"]
      assert web_file != nil, "Web module file should exist"
      
      # Debug: Print the content to see what's happening
      IO.puts("=== WEB FILE CONTENT ===")
      IO.puts(web_file.content)
      IO.puts("=== END WEB FILE CONTENT ===")
      
      # Check for LiveVue usage
      assert String.contains?(web_file.content, "use LiveVue"), "Should add 'use LiveVue' to html_helpers"
      assert String.contains?(web_file.content, "use LiveVue.Components"), "Should add 'use LiveVue.Components' to html_helpers"
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
      
      # Debug: Print the content to see what's happening
      IO.puts("=== VITE CONFIG CONTENT ===")
      IO.puts(vite_config.content)
      IO.puts("=== END VITE CONFIG CONTENT ===")
      
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
      
      # Debug: Print the content to see what's happening
      IO.puts("=== MIX.EXS CONTENT ===")
      IO.puts(mix_exs.content)
      IO.puts("=== END MIX.EXS CONTENT ===")
      
      # Check for set_build_path function
      assert String.contains?(mix_exs.content, "defp set_build_path"), "Should add set_build_path function"
      assert String.contains?(mix_exs.content, "System.put_env(\"MIX_BUILD_PATH\""), "Should set MIX_BUILD_PATH env var"
      
      # Check for updated aliases
      assert String.contains?(mix_exs.content, "\"assets.build\": [&set_build_path/1,"), "Should update assets.build alias"
      assert String.contains?(mix_exs.content, "\"phx.server\": [&set_build_path/1, \"phx.server\"]"), "Should add phx.server alias"
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