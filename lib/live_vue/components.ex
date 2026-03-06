defmodule LiveVue.Components do
  @moduledoc """
  Macros to improve the developer experience of crossing the Liveview/Vue boundary.
  """

  @doc """
  Generates functions local to your current module that can be used to render Vue components.
  TODO: This could perhaps be optimized to only read the files once per compilation.

  These shortcut names are also registered so `LiveVue.SharedPropsView` can inject shared
  props and `v-socket` into `<.ComponentName>` tags during `~H` compilation.

  ## Examples

  ```elixir
  use LiveVue.Components, vue_root: ["./assets/vue", "./lib/my_app_web"]
  ```
  """
  defmacro __using__(opts) do
    names =
      opts
      |> Keyword.get(:vue_root, ["./assets/vue"])
      |> List.wrap()
      |> Enum.flat_map(fn vue_root ->
        if String.contains?(vue_root, "*"),
          do:
            raise("""
            Glob pattern is not supported in :vue_root, please specify a list of directories.

            Example:

            use LiveVue.Components, vue_root: ["./assets/vue", "./lib/my_app_web"]
            """)

        vue_root
        |> Path.join("**/*.vue")
        |> Path.wildcard()
        |> Enum.map(&Path.basename(&1, ".vue"))
      end)
      |> Enum.uniq()

    Module.put_attribute(__CALLER__.module, :live_vue_shortcuts, names)

    functions = Enum.map(names, &name_to_function/1)

    quote do
      def __live_vue_shortcuts__, do: unquote(names)

      unquote_splicing(functions)
    end
  end

  defp name_to_function(name) do
    quote do
      def unquote(:"#{name}")(assigns) do
        assigns
        |> Map.put(:"v-component", unquote(name))
        |> LiveVue.vue()
      end
    end
  end
end
