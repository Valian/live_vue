defmodule Mix.Tasks.LiveVue.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "live_vue.install" do
    test "installs successfully with core Vue components" do
      project =
        phx_test_project()
        |> Igniter.create_new_file(
          "AGENTS.md",
          "# My Project Agents\n\nExisting content here. <!-- usage-rules-end -->"
        )
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

      # Check if config.exs was updated
      config_exs = project.rewrite.sources["config/config.exs"]
      assert config_exs.content =~ ~r/\[args: \[\], cd: __DIR__\]/

      # Check if Vite config was updated
      vite_config = project.rewrite.sources["assets/vite.config.mjs"]
      assert vite_config.content =~ "vue()"
      assert vite_config.content =~ "liveVuePlugin()"
      assert vite_config.content =~ "import vue from"
      assert vite_config.content =~ "import liveVuePlugin from"
      assert vite_config.content =~ "manifest: false"
      assert vite_config.content =~ "ssrManifest: false"
      assert vite_config.content =~ "ssr: { noExternal: process.env.NODE_ENV === \"production\" ? true : undefined },"

      # Check if tsconfig.json was updated
      tsconfig = project.rewrite.sources["tsconfig.json"]
      assert tsconfig.content =~ ~s("baseUrl": ".")
      assert tsconfig.content =~ ~s("module": "ESNext")
      assert tsconfig.content =~ ~s("moduleResolution": "bundler")
      assert tsconfig.content =~ ~s("noEmit": true)
      assert tsconfig.content =~ ~s("skipLibCheck": true)

      assert tsconfig.content =~ """
                 "paths": {
                   "*": [ "./deps/*", "node_modules/*" ]
                 },\
             """

      assert tsconfig.content =~ ~s("types": [ "vite/client" ])

      # Check that tsconfig uses correct web folder (not hardcoded my_app_web)
      assert tsconfig.content =~ ~s("./lib/test_web/**/*")

      # Check if mix.exs was updated
      mix_exs = project.rewrite.sources["mix.exs"]
      assert mix_exs.content =~ ~r/build --manifest --emptyOutDir true/

      assert mix_exs.content =~
               ~r/build --ssrManifest --emptyOutDir false --ssr js\/server\.js --outDir \.\.\/priv\/static/

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

      # Check that SSR production setup was applied
      app_file = project.rewrite.sources["lib/test/application.ex"]
      assert app_file.content =~ ~r/NodeJS\.Supervisor/
      assert app_file.content =~ ~r/path: LiveVue\.SSR\.NodeJS\.server_path\(:test\)/
      assert app_file.content =~ ~r/pool_size: 4/

      # Check that AGENTS.md was updated with usage rules
      agents_md = project.rewrite.sources["AGENTS.md"]
      assert agents_md.content =~ "# My Project Agents"
      assert agents_md.content =~ "Existing content here."
      assert agents_md.content =~ "<!-- live_vue-start -->"
      assert agents_md.content =~ "<!-- live_vue-end -->"
      assert agents_md.content =~ "# LiveVue Usage Rules"
      assert agents_md.content =~ "Component Organization"
      assert String.ends_with?(agents_md.content, "<!-- live_vue-end -->\n<!-- usage-rules-end -->")
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
