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

  # Read template files at compile time
  @vue_index_content File.read!(Path.join([__DIR__, "..", "..", "..", "assets", "copy", "vue", "index.ts"]))
  @counter_vue_content File.read!(Path.join([__DIR__, "..", "..", "..", "assets", "copy", "vue", "Counter.vue"]))
  @server_js_content File.read!(Path.join([__DIR__, "..", "..", "..", "assets", "copy", "js", "server.js"]))

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
  end

  # Configure environments (config/dev.exs and config/prod.exs)
  defp configure_environments(igniter, _app_name) do
    igniter
    |> Igniter.Project.Config.configure(
      "config.exs",
      :live_vue,
      [:shared_props],
      []
    )
    |> Igniter.Project.Config.configure(
      "config.exs",
      :live_vue,
      [:ssr],
      true
    )
    |> Igniter.Project.Config.configure(
      "dev.exs",
      :live_vue,
      [:vite_host],
      "http://localhost:5173"
    )
    |> Igniter.Project.Config.configure(
      "dev.exs",
      :live_vue,
      [:ssr_module],
      {:code, Sourceror.parse_string!("LiveVue.SSR.ViteJS")}
    )
    |> Igniter.Project.Config.configure(
      "prod.exs",
      :live_vue,
      [:ssr_module],
      {:code, Sourceror.parse_string!("LiveVue.SSR.NodeJS")}
    )
    |> Igniter.Project.Config.configure(
      "prod.exs",
      :live_vue,
      [:ssr],
      true
    )
  end

  # Add LiveVue to html_helpers in lib/app_web.ex
  defp add_live_vue_to_html_helpers(igniter, _app_name) do
    web_module = Igniter.Libs.Phoenix.web_module(igniter)
    web_folder = Macro.underscore(web_module)
    web_file = Path.join(["lib", web_folder <> ".ex"])

    Igniter.update_elixir_file(igniter, web_file, fn zipper ->
      with {:ok, zipper} <- Igniter.Code.Module.move_to_defmodule(zipper, web_module),
           {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
        case Igniter.Code.Function.move_to_function_call_in_current_scope(
               zipper,
               :def,
               [1],
               fn call ->
                 Igniter.Code.Function.argument_equals?(call, 0, :html_helpers)
               end
             ) do
          {:ok, zipper} ->
            case Igniter.Code.Common.move_to_do_block(zipper) do
              {:ok, zipper} ->
                new_code = """
                # Add support for Vue components
                use LiveVue

                # Generate component for each vue file, so you can use <.ComponentName> syntax
                # instead of <.vue v-component="ComponentName">
                use LiveVue.Components, vue_root: ["./assets/vue", "./lib/#{web_folder}"]
                """

                {:ok, Igniter.Code.Common.add_code(zipper, new_code, :after)}

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
        "import topbar from \"topbar\"\nimport {getHooks} from \"live_vue\"\nimport liveVueApp from \"../vue\""
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
        "import tailwindcss from \"@tailwindcss/vite\";",
        "import tailwindcss from \"@tailwindcss/vite\";\nimport vue from \"@vitejs/plugin-vue\";\nimport liveVuePlugin from \"live_vue/vitePlugin\";"
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
      "include: [\"phoenix\", \"phoenix_html\", \"phoenix_live_view\"],",
      "include: [\"live_vue\", \"phoenix\", \"phoenix_html\", \"phoenix_live_view\"],"
    )
  end

  defp update_vite_plugins(content) do
    String.replace(
      content,
      "plugins: [tailwindcss()]",
      "plugins: [tailwindcss(), vue(), liveVuePlugin()]"
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
            "@source \"../js\";\n@source \"../vue\";"
          )
        end
      end)
    end)
  end

  # Update package.json for Vue dependencies
  defp update_package_json_for_vue(igniter) do
    case Igniter.exists?(igniter, "assets/package.json") do
      true ->
        Igniter.update_file(igniter, "assets/package.json", fn source ->
          Rewrite.Source.update(source, :content, fn content ->
            case Jason.decode(content) do
              {:ok, decoded} ->
                # Add Vue dependencies
                dependencies =
                  Map.get(decoded, "dependencies", %{})
                  |> Map.put("live_vue", "file:../deps/live_vue")
                  |> Map.put("vue", "^3.4.21")

                # Add Vue dev dependencies
                dev_dependencies =
                  Map.get(decoded, "devDependencies", %{})
                  |> Map.put("@vitejs/plugin-vue", "^5.0.4")
                  |> Map.put("typescript", "^5.4.5")
                  |> Map.put("vue-tsc", "^2.0.13")

                updated =
                  decoded
                  |> Map.put("dependencies", dependencies)
                  |> Map.put("devDependencies", dev_dependencies)

                Jason.encode!(updated, pretty: true)

              {:error, _} ->
                # If JSON parsing fails, return content as is
                content
            end
          end)
        end)

      false ->
        igniter
    end
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
    case Igniter.exists?(igniter, "assets/tsconfig.json") do
      true ->
        Igniter.update_file(igniter, "assets/tsconfig.json", fn source ->
          Rewrite.Source.update(source, :content, fn content ->
            case Jason.decode(content) do
              {:ok, decoded} ->
                # Update compiler options
                compiler_options =
                  Map.get(decoded, "compilerOptions", %{})
                  |> Map.put("module", "ESNext")
                  |> Map.put("types", ["vite/client"])
                  |> Map.put("moduleResolution", "bundler")
                  |> Map.put("strict", true)

                # Update include array
                include =
                  Map.get(decoded, "include", [])
                  |> Enum.concat(["vue/**/*"])
                  |> Enum.uniq()

                updated =
                  decoded
                  |> Map.put("compilerOptions", compiler_options)
                  |> Map.put("include", include)

                Jason.encode!(updated, pretty: true)

              {:error, _} ->
                # If JSON parsing fails, return content as is
                content
            end
          end)
        end)

      false ->
        igniter
    end
  end

  # Setup SSR for production in application.ex
  defp setup_ssr_for_production(igniter, _app_name) do
    app_module = Igniter.Project.Application.app_module(igniter)
    app_file = "lib/#{Macro.underscore(app_module)}/application.ex"

    case Igniter.exists?(igniter, app_file) do
      true ->
        Igniter.update_elixir_file(igniter, app_file, fn zipper ->
          with {:ok, zipper} <- Igniter.Code.Module.move_to_defmodule(zipper, app_module),
               {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
            case Igniter.Code.Function.move_to_function_call_in_current_scope(
                   zipper,
                   :def,
                   [2],
                   fn call ->
                     Igniter.Code.Function.argument_equals?(call, 0, :start)
                   end
                 ) do
              {:ok, zipper} ->
                case Igniter.Code.Common.move_to_do_block(zipper) do
                  {:ok, zipper} ->
                    case Igniter.Code.Common.move_to_cursor_match_in_scope(zipper, "children = [") do
                      {:ok, zipper} ->
                        {:ok,
                         Igniter.Code.Common.add_code(
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

      false ->
        igniter
    end
  end
end
