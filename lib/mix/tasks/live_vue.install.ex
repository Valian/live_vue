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
  import Mix.Tasks.PhoenixVite.Install.Helper

  with_igniter do
    use Igniter.Mix.Task

    alias Igniter.Libs.Phoenix
    alias Igniter.Project.Config

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
      |> update_phoenix_vite_config()
      |> configure_tailwind_for_vue()
      |> update_package_json_for_vue()
      |> create_vue_files()
      |> setup_ssr_for_production(app_name)
      |> update_mix_aliases()
      |> add_vue_demo_route()
      |> update_home_template()
      |> update_gitignore()
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
      web_module = Phoenix.web_module(igniter)
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

    defp update_phoenix_vite_config(igniter) do
      Config.configure(
        igniter,
        "config.exs",
        :phoenix_vite,
        [PhoenixVite.Npm, :assets],
        {:code, Sourceror.parse_string!(~s|[args: [], cd: __DIR__]|)}
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
          |> update_vite_manifest()
          |> add_ssr_vite_entry()
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

    defp update_vite_manifest(content) do
      if String.contains?(content, "manifest: false") do
        content
      else
        String.replace(
          content,
          ~r/manifest: true,/s,
          "manifest: false,\n    ssrManifest: false,"
        )
      end
    end

    defp add_ssr_vite_entry(content) do
      if String.contains?(content, "noExternal") do
        content
      else
        String.replace(
          content,
          ~r/build: {/s,
          "ssr: { noExternal: process.env.NODE_ENV === \"production\" ? true : undefined },\n    build: {"
        )
      end
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
      igniter
      |> Igniter.move_file("assets/package.json", "package.json")
      |> Igniter.update_file("package.json", fn source ->
        Rewrite.Source.update(source, :content, fn _ ->
          """
          {
            "dependencies": {
              "@vueuse/core": "^13.7.0",
              "live_vue": "file:./deps/live_vue",
              "phoenix": "file:./deps/phoenix",
              "phoenix_html": "file:./deps/phoenix_html",
              "phoenix_live_view": "file:./deps/phoenix_live_view",
              "topbar": "^3.0.0",
              "vue": "^3.4.21"
            },
            "devDependencies": {
              "@tailwindcss/vite": "^4.1.0",
              "@vitejs/plugin-vue": "^5.0.4",
              "daisyui": "^5.0.0",
              "phoenix_vite": "file:./deps/phoenix_vite",
              "tailwindcss": "^4.1.0",
              "typescript": "^5.4.5",
              "vite": "^6.3.0",
              "vue-tsc": "^2.0.13"
            }
          }
          """
        end)
      end)
    end

    # Create Vue files from templates
    defp create_vue_files(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)

      igniter
      |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
      |> Igniter.mkdir("assets/vue")
      |> Igniter.mkdir("lib/#{web_folder}/live")
      |> Igniter.create_new_file("assets/vue/index.ts", vue_index_content())
      |> Igniter.create_new_file("assets/vue/VueDemo.vue", demo_vue_content())
      |> Igniter.create_new_file("assets/js/server.js", server_js_content())
      |> Igniter.create_new_file(
        "assets/vue/.gitignore",
        "# Ignore automatically generated Vue files by the ~V sigil\n_build/"
      )
      |> Igniter.create_new_file("lib/#{web_folder}/live/vue_demo_live.ex", demo_live_view_content(igniter))
      |> update_tsconfig_for_vue()
    end

    defp update_tsconfig_for_vue(igniter) do
      igniter
      |> Igniter.rm("assets/tsconfig.json")
      |> Igniter.create_new_file("tsconfig.json", """
      {
        "compilerOptions": {
          "allowJs": true,
          "baseUrl": ".",
          "lib": ["ES2015", "DOM"],
          "module": "ESNext",
          "moduleResolution": "bundler",
          "noEmit": true,
          "skipLibCheck": true,
          "paths": {
            "*": [ "./deps/*", "node_modules/*" ]
          },
          "strict": true,
          "types": [ "vite/client" ]
        },
        "include": [
          "./assets/js/**/*",
          "./assets/vue/**/*",
          "./lib/my_app_web/**/*"
        ],
        "exclude": [
          "node_modules"
        ]
      }
      """)
    end

    # Setup SSR for production in application.ex
    defp setup_ssr_for_production(igniter, _app_name) do
      app_module = igniter |> Igniter.Project.Application.app_name() |> to_string()
      app_file = "lib/#{Macro.underscore(app_module)}/application.ex"

      # Use simple file update instead of complex AST manipulation
      Igniter.update_file(igniter, app_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          # Look for the children list and add NodeJS.Supervisor right after the opening bracket
          if String.contains?(content, "children = [") and not String.contains?(content, "NodeJS.Supervisor") do
            String.replace(
              content,
              ~r/(children = \[\s*\n)/,
              "\\1      {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},\n"
            )
          else
            content
          end
        end)
      end)
    end

    defp vue_index_content do
      """
      import { h, type Component } from "vue"
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
    end

    defp demo_live_view_content(igniter) do
      web_module_name = Phoenix.web_module(igniter)

      """
      defmodule #{inspect(web_module_name)}.VueDemoLive do
        use #{inspect(web_module_name)}, :live_view

        @impl true
        def render(assigns) do
          ~H\"\"\"
          <Layouts.app flash={@flash}>
            <.vue
              todos={@todos}
              form={@form}
              v-component="VueDemo"
              v-socket={@socket}
            />
          </Layouts.app>
          \"\"\"
        end

        @impl true
        def mount(_params, _session, socket) do
          socket =
            socket
            |> assign(:todos, [
              %{id: 1, text: "Learn LiveVue basics", completed: true},
              %{id: 2, text: "Build an interactive component", completed: false},
              %{id: 3, text: "Deploy to production", completed: false}
            ])
            |> assign(:next_id, 4)
            |> assign(:form, add_todo_form(%{text: ""}))

          {:ok, socket}
        end

        @impl true
        def handle_event("validate_todo", %{"todo" => params}, socket) do
          {:noreply, assign(socket, :form, add_todo_form(params))}
        end

        @impl true
        def handle_event("add_todo", %{"todo" => params}, socket) do
          changeset = add_todo_changeset(params, socket.assigns.next_id)

          case Ecto.Changeset.apply_action(changeset, :insert) do
            {:ok, new_todo} ->
              socket =
                socket
                |> assign(:todos, socket.assigns.todos ++ [new_todo])
                |> assign(:next_id, socket.assigns.next_id + 1)
                |> assign(:form, add_todo_form(%{text: ""}))

              {:noreply, socket}

            {:error, changeset} ->
              {:noreply, assign(socket, :form, to_form(changeset, as: :todo))}
          end
        end

        @impl true
        def handle_event("toggle_todo", %{"id" => id}, socket) do
          todos =
            Enum.map(socket.assigns.todos, fn todo ->
              if todo.id == id, do: %{todo | completed: !todo.completed}, else: todo
            end)

          {:noreply, assign(socket, :todos, todos)}
        end

        @impl true
        def handle_event("delete_todo", %{"id" => id}, socket) do
          todos = Enum.reject(socket.assigns.todos, fn todo -> todo.id == id end)
          {:noreply, assign(socket, :todos, todos)}
        end

        @impl true
        def handle_event("clear_completed", _params, socket) do
          todos = Enum.reject(socket.assigns.todos, fn todo -> todo.completed end)
          {:noreply, assign(socket, :todos, todos)}
        end

        defp add_todo_changeset(params, id \\\\ nil) do
          data = %{text: "", id: id, completed: false}
          types = %{text: :string}

          {data, types}
          |> Ecto.Changeset.cast(params, Map.keys(types))
          |> Ecto.Changeset.validate_required([:text])
          |> Ecto.Changeset.validate_length(:text, min: 8, max: 50)
        end

        defp add_todo_form(params) do
          params
          |> add_todo_changeset()
          |> Map.put(:action, :validate)
          |> to_form(as: :todo)
        end
      end
      """
    end

    defp demo_vue_content do
      """
      <script setup lang="ts">
      import { ref, computed } from "vue"
      import { useLiveVue, Form, useLiveForm } from "live_vue"

      type FilterType = "all" | "active" | "completed"

      // Props from LiveView - server state
      const props = defineProps<{
        todos: Array<{ id: number; text: string; completed: boolean }>
        form: Form<{ text: string }>
      }>()

      // Phoenix hook instance responsible for syncing this Vue component
      const live = useLiveVue()

      // Server-side validation using changesets
      const { field, submit, isValid } = useLiveForm<{ text: string }>(() => props.form, {
        submitEvent: "add_todo",
        changeEvent: "validate_todo",
        debounceInMiliseconds: 50,
      })

      const textField = field("text")

      // Local client-side state
      const filter = ref<FilterType>("all")

      const filterByType = (type: FilterType) => {
        switch (type) {
          case "active":
            return props.todos.filter((todo) => !todo.completed)
          case "completed":
            return props.todos.filter((todo) => todo.completed)
          default:
            return props.todos
        }
      }
      // Computed properties for reactive UI
      const filteredTodos = computed(() => filterByType(filter.value))
      const completedCount = computed(() => filterByType("completed").length)
      </script>

      <template>
        <div class="text-center">
          <div class="max-w-2xl space-y-8">
            <!-- Header -->
            <div>
              <h1 class="text-5xl font-bold">🎉 Welcome to LiveVue!</h1>
              <p class="text-lg text-base-content/70">Vue.js components seamlessly integrated with Phoenix LiveView</p>
            </div>

            <!-- Todo Demo Card -->
            <div>
              <!-- Add Todo Form -->
              <form @submit.prevent="submit" class="form-control mb-6">
                <div class="join mb-2">
                  <input
                    v-bind="textField.inputAttrs.value"
                    type="text"
                    placeholder="What needs to be done?"
                    class="input input-bordered join-item flex-1"
                  />
                  <button type="submit" :disabled="!isValid" class="btn btn-primary join-item">Add Todo</button>
                </div>
                <div
                  v-if="(textField.isTouched.value || textField.isDirty.value) && textField.errorMessage.value"
                  class="text-error text-xs"
                >
                  {{ textField.errorMessage }}
                </div>
              </form>

              <!-- Filter Buttons -->
              <div class="join mb-6 mx-auto">
                <button
                  v-for="filterType in ['all', 'active', 'completed'] as FilterType[]"
                  :key="filterType"
                  @click="filter = filterType"
                  :class="['btn btn-sm join-item', filter === filterType ? 'btn-active' : '']"
                >
                  {{ filterType.charAt(0).toUpperCase() + filterType.slice(1) }}
                  ({{ filterByType(filterType).length }})
                </button>
              </div>

              <!-- Todo List -->
              <div v-if="filteredTodos.length > 0" class="space-y-2 mb-4">
                <div v-for="todo in filteredTodos" :key="todo.id" class="card card-compact bg-base-200">
                  <div class="card-body">
                    <div class="flex items-center gap-3">
                      <input
                        type="checkbox"
                        :checked="todo.completed"
                        @change="$live.pushEvent('toggle_todo', { id: todo.id })"
                        class="checkbox checkbox-primary"
                      />
                      <span :class="['flex-1 text-left', todo.completed ? 'line-through opacity-60' : '']">
                        {{ todo.text }}
                      </span>
                      <button @click="$live.pushEvent('delete_todo', { id: todo.id })" class="btn btn-error btn-sm">
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <div v-else class="alert">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-info shrink-0 w-6 h-6">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  ></path>
                </svg>
                <span>{{ filter === "all" ? "No todos yet!" : `No ${filter} todos!` }}</span>
              </div>

              <!-- Actions -->
              <div v-if="props.todos.some((todo) => todo.completed)" class="card-actions justify-between">
                <span class="text-sm opacity-70">{{ completedCount }} completed</span>
                <button @click="$live.pushEvent('clear_completed', {})" class="btn btn-error btn-sm">Clear completed</button>
              </div>
            </div>

            <!-- Features Info -->
            <div class="alert alert-info">
              <div>
                <h4 class="font-bold">LiveVue Features Demonstrated:</h4>
                <ul class="text-sm mt-2 space-y-1">
                  <li>✅ <strong>Reactive Props:</strong> Todos flow from server state</li>
                  <li>✅ <strong>Server Events:</strong> Add, toggle, delete todos send events to LiveView</li>
                  <li>✅ <strong>Local State:</strong> Filter buttons work entirely client-side</li>
                  <li>✅ <strong>Server-side Validation:</strong> Uses Ecto.Changeset</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </template>
      """
    end

    defp server_js_content do
      """
      import components from "../vue"
      import { getRender, loadManifest } from "live_vue/server"

      // present only in prod build. Returns empty obj if doesn't exist
      // used to render preload links
      const manifest = loadManifest("../priv/static/.vite/ssr-manifest.json")
      export const render = getRender(components, manifest)
      """
    end

    # Add vue_demo route to dev section of router.ex
    defp add_vue_demo_route(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      web_module_name = web_module |> Module.split() |> Enum.join(".")
      router_file = Path.join(["lib", web_folder, "router.ex"])

      Igniter.update_file(igniter, router_file, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          # Add the vue_demo route to the dev section after live_dashboard
          if String.contains?(content, "live \"/vue_demo\"") do
            content
          else
            if String.contains?(content, "live_dashboard") do
              String.replace(
                content,
                ~r/(live_dashboard.*)/,
                "\\1\n      live \"/vue_demo\", #{web_module_name}.VueDemoLive"
              )
            else
              # there is no live_dashboard, so we need to add the route to the browser pipeline
              String.replace(
                content,
                ~r/(pipe_through :browser.*)/,
                "\\1\n      live \"/dev/vue_demo\", #{web_module_name}.VueDemoLive"
              )
            end
          end
        end)
      end)
    end

    # Update home.html.heex template with LiveVue content
    defp update_home_template(igniter) do
      web_module = Phoenix.web_module(igniter)
      web_folder = Macro.underscore(web_module)
      home_template = Path.join(["lib", web_folder, "controllers", "page_html", "home.html.heex"])

      Igniter.update_file(igniter, home_template, fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          content
          |> String.replace(
            "Peace of mind from prototype to production.",
            "End-to-end reactivity for your Live Vue apps."
          )
          |> String.replace(
            ~r/Build rich, interactive web applications quickly.*at scale\./s,
            """
            Congratulations, you've successfully created a LiveVue app with Phoenix!
                  We've automatically created two files for you: <br />
                  <code class="text-sm text-primary">assets/vue/VueDemo.vue</code>
                  <br />
                  <code class="text-sm text-primary">lib/#{web_folder}/live/vue_demo.ex</code>
                  <br /> Click the button below to see it in action.\
            """
          )
          |> String.replace(
            ~s(<div class="flex">),
            ~s(<a href={~p"/dev/vue_demo"} class="btn btn-primary mt-4">Vue Demo</a>\n    <div class="flex">)
          )
        end)
      end)
    end

    # Update mix.exs aliases to include set_build_path function
    defp update_mix_aliases(igniter) do
      Igniter.update_file(igniter, "mix.exs", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          # Check if set_build_path function already exists
          if String.contains?(content, "js/server.js") do
            content
          else
            # Add the set_build_path function at the end of the module (before final end)
            String.replace(
              content,
              ~s("phoenix_vite.npm vite build"),
              ~s("phoenix_vite.npm vite build --manifest", "phoenix_vite.npm vite build --ssr js/server.js --outDir ../priv/static --ssrManifest")
            )
          end
        end)
      end)
    end

    defp update_gitignore(igniter) do
      Igniter.update_file(igniter, ".gitignore", fn source ->
        Rewrite.Source.update(source, :content, fn content ->
          String.replace(content, "/assets/node_modules", "node_modules")
        end)
      end)
    end
  else
    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'live_vue.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
