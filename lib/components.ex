defmodule LiveVue.Components do
  @moduledoc """
  Macros to improve the developer experience of crossing the Liveview/Vue boundary.
  """

  @doc """
  Generates functions local to your current module that can be used to render Vue components.
  TODO: This could perhaps be optimized to only read the files once per compilation.
  """
  defmacro __using__(_opts) do
    "./assets/vue/*.vue"
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".vue"))
    |> Enum.map(&name_to_function/1)
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
