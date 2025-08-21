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

  alias Igniter.Code.Common
  alias Igniter.Code.Function
  alias Igniter.Project.Config

  # Template file contents
  @vue_index_content """
  // polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
  import "vite/modulepreload-polyfill"
  import { Component, h } from "vue"
  import { createLiveVue, findComponent, type LiveHook, type ComponentMap } from "live_vue"

  // needed to make $live available in the Vue component
  declare module "vue" {
    interface ComponentCustomProperties {
      $live: LiveHook
    }
  }

  export default createLiveVue({
    // name will be passed as-is in v-component of the .vue HEEX component
    resolve: name => {
      // we're importing from ../../lib to allow collocating Vue files with LiveView files
      // eager: true disables lazy loading - all these components will be part of the app.js bundle
      // more: https://vite.dev/guide/features.html#glob-import
      const components = {
        ...import.meta.glob("./**/*.vue", { eager: true }),
        ...import.meta.glob("../../lib/**/*.vue", { eager: true }),
      } as ComponentMap

      // finds component by name or path suffix and gives a nice error message.
      // `path/to/component/index.vue` can be found as `path/to/component` or simply `component`
      // `path/to/Component.vue` can be found as `path/to/Component` or simply `Component`
      return findComponent(components as ComponentMap, name)
    },
    // it's a default implementation of creating and mounting vue app, you can easily extend it to add your own plugins, directives etc.
    setup: ({ createApp, component, props, slots, plugin, el }) => {
      const app = createApp({ render: () => h(component as Component, props, slots) })
      app.use(plugin)
      // add your own plugins here
      // app.use(pinia)
      app.mount(el)
      return app
    },
  })
  """

  @counter_vue_content """
  <script setup lang="ts">
    import {ref} from "vue"
    const props = defineProps<{count: number}>()
    const emit = defineEmits<{inc: [{value: number}]}>()
    const diff = ref<string>("1")
  </script>

  <template>
    Current count
    <div class="text-2xl text-bold">{{ props.count }}</div>
    <label class="block mt-8">Diff: </label>
    <input v-model="diff" class="mt-4" type="range" min="1" max="10">

    <button
      @click="emit('inc', {value: parseInt(diff)})"
      class="mt-4 bg-black text-white rounded p-2 block">
      Increase counter by {{ diff }}
    </button>
  </template>
  """

  @server_js_content """
  import components from "../vue"
  import { getRender, loadManifest } from "live_vue/server"

  // present only in prod build. Returns empty obj if doesn't exist
  // used to render preload links
  const manifest = loadManifest("../priv/vue/.vite/ssr-manifest.json")
  export const render = getRender(components, manifest)
  """

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
    app_name = Igniter.Project.Application.app_name(igniter)

    igniter
    |> Igniter.compose_task("phoenix_vite.install", igniter.args.argv)
    |> configure_environments(app_name)
    |> add_live_vue_to_html_helpers(app_name)
    |> update_javascript_configuration()
    |> update_vite_configuration()
    |> configure_tailwind_for_vue()
    |> update_package_json_for_vue()
    |> create_vue_files()
    |> setup_ssr_for_production(app_name)
    |> update_mix_aliases()
    |> Igniter.Mix.Task.configure_and_run("phoenix_vite.install", igniter.args.argv)
  end

  # Configure environments (config/dev.exs and config/prod.exs)
  defp configure_environments(igniter, _app_name) do
    igniter
    |> Config.configure("config.exs", :live_vue, [:shared_props], [])
    |> Config.configure("config.exs", :live_vue, [:ssr], true)
    |> Config.configure("dev.exs", :live_vue, [:vite_host], "http://localhost:5173")
    |> Config.configure("dev.exs", :live_vue, [:ssr_module], {:code, Sourceror.parse_string!("LiveVue.SSR.ViteJS")})
    |> Config.configure("prod.exs", :live_vue, [:ssr_module], {:code, Sourceror.parse_string!("LiveVue.SSR.NodeJS")})
    |> Config.configure("prod.exs", :live_vue, [:ssr], true)
  end

  # Add LiveVue to html_helpers in lib/app_web.ex
  defp add_live_vue_to_html_helpers(igniter, _app_name) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    web_folder = Macro.underscore(web_module)
    web_file = Path.join(["lib", web_folder <> ".ex"])

    Igniter.update_file(igniter, web_file, fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        # Check if LiveVue is already added to avoid duplicate additions
        if String.contains?(content, "use LiveVue") do
          content
        else
          # Get the short module name (without Elixir. prefix)
          web_module_name = web_module |> Module.split() |> Enum.join(".")

          # Add LiveVue support only in the html_helpers function
          String.replace(
            content,
            ~r/(defp html_helpers do\s+quote do\s+# Translation\s+use Gettext, backend: #{Regex.escape(web_module_name)}\.Gettext)/,
            "\\1\n\n      # Add support for Vue components\n      use LiveVue\n\n      # Generate component for each vue file, so you can use <.ComponentName> syntax\n      # instead of <.vue v-component=\"ComponentName\">\n      use LiveVue.Components, vue_root: [\"./assets/vue\", \"./lib/#{web_folder}\"]"
          )
        end
      end)
    end)
  end

  # Update JavaScript configuration (app.js)
  defp update_javascript_configuration(igniter) do
    Igniter.update_file(igniter, "assets/js/app.js", fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        content
        |> add_live_vue_imports()
        |> update_live_socket_hooks()
      end)
    end)
  end

  defp add_live_vue_imports(content) do
    if String.contains?(content, "import {getHooks} from \"live_vue\"") do
      content
    else
      String.replace(
        content,
        "import topbar from \"topbar\"",
        ~s(import topbar from "topbar"\nimport {getHooks} from "live_vue"\nimport liveVueApp from "../vue")
      )
    end
  end

  defp update_live_socket_hooks(content) do
    String.replace(
      content,
      "hooks: {...colocatedHooks},",
      "hooks: {...colocatedHooks, ...getHooks(liveVueApp)},"
    )
  end

  # Update Vite configuration
  defp update_vite_configuration(igniter) do
    Igniter.update_file(igniter, "assets/vite.config.mjs", fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        content
        |> add_vite_imports()
        |> update_vite_server_config()
        |> update_vite_optimized_deps()
        |> update_vite_plugins()
      end)
    end)
  end

  defp add_vite_imports(content) do
    if String.contains?(content, "import vue from") do
      content
    else
      String.replace(
        content,
        "import { phoenixVitePlugin } from 'phoenix_vite'",
        ~s(import vue from "@vitejs/plugin-vue";\nimport liveVuePlugin from "live_vue/vitePlugin";)
      )
    end
  end

  defp update_vite_server_config(content) do
    if String.contains?(content, "host: \"127.0.0.1\"") do
      content
    else
      String.replace(
        content,
        "port: 5173,",
        "host: \"127.0.0.1\",\n    port: 5173,"
      )
    end
  end

  defp update_vite_optimized_deps(content) do
    String.replace(
      content,
      ~s(include: ["phoenix", "phoenix_html", "phoenix_live_view"],),
      ~s(include: ["live_vue", "phoenix", "phoenix_html", "phoenix_live_view"],)
    )
  end

  defp update_vite_plugins(content) do
    # Replace the phoenixVitePlugin call with the Vue plugins while keeping tailwindcss
    String.replace(
      content,
      ~r/phoenixVitePlugin\(\{\s*pattern: \/\\.\(ex\|heex\)\$\/\s*\}\)/s,
      "vue(),\n    liveVuePlugin()"
    )
  end

  # Configure Tailwind to include Vue files
  defp configure_tailwind_for_vue(igniter) do
    Igniter.update_file(igniter, "assets/css/app.css", fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        if String.contains?(content, "@source \"../vue\";") do
          content
        else
          String.replace(
            content,
            "@source \"../js\";",
            ~s(@source "../js";\n@source "../vue";)
          )
        end
      end)
    end)
  end

  # Update package.json for Vue dependencies
  defp update_package_json_for_vue(igniter) do
    Igniter.update_file(igniter, "assets/package.json", fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        decoded = Jason.decode!(content)
        # Add Vue dependencies
        dependencies =
          decoded
          |> Map.get("dependencies", %{})
          |> Map.put("live_vue", "file:../deps/live_vue")
          |> Map.put("vue", "^3.4.21")

        # Add Vue dev dependencies
        dev_dependencies =
          decoded
          |> Map.get("devDependencies", %{})
          |> Map.put("@vitejs/plugin-vue", "^5.0.4")
          |> Map.put("typescript", "^5.4.5")
          |> Map.put("vue-tsc", "^2.0.13")

        updated =
          decoded
          |> Map.put("dependencies", dependencies)
          |> Map.put("devDependencies", dev_dependencies)

        Jason.encode!(updated, pretty: true)
      end)
    end)
  end

  # Create Vue files from templates
  defp create_vue_files(igniter) do
    igniter
    |> Igniter.mkdir("assets/vue")
    |> Igniter.create_new_file("assets/vue/index.ts", @vue_index_content)
    |> Igniter.create_new_file("assets/vue/Counter.vue", @counter_vue_content)
    |> Igniter.create_new_file("assets/js/server.js", @server_js_content)
    |> Igniter.create_new_file(
      "assets/vue/.gitignore",
      "# Ignore automatically generated Vue files by the ~V sigil\n_build/"
    )
    |> update_tsconfig_for_vue()
  end

  defp update_tsconfig_for_vue(igniter) do
    Igniter.update_file(igniter, "assets/tsconfig.json", fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        # Split the content by lines that start with "//"
        {commented, uncommented} =
          content
          |> String.split(~r/\R/)
          |> Enum.split_with(&String.starts_with?(&1, "//"))

        # Parse the uncommented lines (i.e., the actual JSON)
        decoded = uncommented |> Enum.join("\n") |> Jason.decode!()

        # Update compiler options
        compiler_options =
          decoded
          |> Map.get("compilerOptions", %{})
          |> Map.put("module", "ESNext")
          |> Map.put("types", ["vite/client"])
          |> Map.put("moduleResolution", "bundler")
          |> Map.put("strict", true)

        # Update include array
        include =
          decoded
          |> Map.get("include", [])
          |> Enum.concat(["vue/**/*"])
          |> Enum.uniq()

        updated =
          decoded
          |> Map.put("compilerOptions", compiler_options)
          |> Map.put("include", include)

        result = Jason.encode!(updated, pretty: true)
        Enum.join(commented, "\n") <> "\n" <> result
      end)
    end)
  end

  # Setup SSR for production in application.ex
  defp setup_ssr_for_production(igniter, _app_name) do
    app_module = igniter |> Igniter.Project.Application.app_name() |> to_string()
    app_file = "lib/#{Macro.underscore(app_module)}/application.ex"

    Igniter.update_elixir_file(igniter, app_file, fn zipper ->
      with {:ok, zipper} <- Igniter.Code.Module.move_to_defmodule(zipper, app_module),
           {:ok, zipper} <- Common.move_to_do_block(zipper) do
        case Function.move_to_function_call_in_current_scope(
               zipper,
               :def,
               [2],
               fn call ->
                 Function.argument_equals?(call, 0, :start)
               end
             ) do
          {:ok, zipper} ->
            case Common.move_to_do_block(zipper) do
              {:ok, zipper} ->
                case Common.move_to_cursor_match_in_scope(zipper, "children = [") do
                  {:ok, zipper} ->
                    {:ok,
                     Common.add_code(
                       zipper,
                       "{NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},",
                       :after
                     )}

                  :error ->
                    {:ok, zipper}
                end

              :error ->
                {:ok, zipper}
            end

          :error ->
            {:ok, zipper}
        end
      else
        _ -> {:ok, zipper}
      end
    end)
  end

  # Update mix.exs aliases to include set_build_path function
  defp update_mix_aliases(igniter) do
    Igniter.update_file(igniter, "mix.exs", fn source ->
      Rewrite.Source.update(source, :content, fn content ->
        # Check if set_build_path function already exists
        content =
          if String.contains?(content, "defp set_build_path") do
            content
          else
            # Add the set_build_path function at the end of the module (before final end)
            String.replace(
              content,
              ~r/(\nend\s*$)/,
              ~s{\n  defp set_build_path(_args) do\n    System.put_env("MIX_BUILD_PATH", System.get_env("MIX_BUILD_PATH") || Mix.Project.build_path())\n  end\\1}
            )
          end

        # Update assets.build alias to include set_build_path
        content =
          if String.contains?(content, "&set_build_path/1") and String.contains?(content, "assets.build") do
            content
          else
            String.replace(
              content,
              ~r/("assets\.build": \[)"([^"]+)"/,
              "\\1&set_build_path/1, \"\\2\""
            )
          end

        # Add or update phx.server alias
        content =
          if String.contains?(content, "\"phx.server\"") and String.contains?(content, "&set_build_path/1") do
            content
          else
            if String.contains?(content, "\"phx.server\":") do
              # Update existing phx.server alias
              String.replace(
                content,
                ~r/"phx\.server": .+/,
                ~s("phx.server": [&set_build_path/1, "phx.server"])
              )
            else
              # Add new phx.server alias before the closing bracket of aliases
              # Look for the pattern where aliases ends
              if String.contains?(content, "precommit:") do
                String.replace(
                  content,
                  ~r/(precommit: \[.*?\])/s,
                  ~s(\\1,\n      "phx.server": [&set_build_path/1, "phx.server"])
                )
              else
                # Fallback: add before the end of aliases block
                String.replace(
                  content,
                  ~r/(\s+)(\]\s*\n\s+end)/,
                  ~s(\\1"phx.server": [&set_build_path/1, "phx.server"],\n\\1\\2)
                )
              end
            end
          end

        content
      end)
    end)
  end
end
