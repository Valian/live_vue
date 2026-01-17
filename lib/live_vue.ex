defmodule LiveVue do
  @moduledoc """
  LiveVue provides seamless integration between Phoenix LiveView and Vue.js components.

  ## Installation and Configuration

  See README.md for installation instructions and usage.

  ## Component Options

  When using the `vue/1` component or `~V` sigil, the following options are supported:

  ### Required Attributes
    * `v-component` (string) - Name of the Vue component (e.g., "YourComponent", "directory/Example")

  > #### Tip {: .tip}
  >
  > Value of `v-component` will be directly passed to `resolve` function of the `createLiveVue` instance.
  > It should return Vue component or a promise that resolves to a Vue component.
  > In a standard setup, you can find it in `assets/vue/index.js`.

  ### Optional Attributes
    * `id` (string) - Explicit ID of the wrapper component. If not provided, a random one will be
      generated. Useful to keep ID consistent in development (e.g., "vue-1")
    * `class` (string) - CSS class(es) to apply to the Vue component wrapper
      (e.g., "my-class" or "my-class another-class")
    * `v-ssr` (boolean) - Whether to render the component on the server. Defaults to the value set
      in config (default: true)

  ### Event Handlers
    * `v-on:*` - Vue event handlers can be attached using the `v-on:` prefix
      (e.g., `v-on:click`, `v-on:input`)

  ### Props and Slots
    * All other attributes are passed as props to the Vue component
    * Slots can be passed as regular Phoenix slots
  """

  use Phoenix.Component

  defmacro __using__(_opts) do
    quote do
      import LiveVue
    end
  end

  @doc """
  Renders a Vue component within Phoenix LiveView.

  ## Examples

      <.vue
        v-component="MyComponent"
        message="Hello"
        v-on:click="handleClick"
        class="my-component"
      />

      <.vue
        v-component="nested/Component"
        v-ssr={false}
        items={@items}
      >
        <:default>Default slot content</:default>
        <:named>Named slot content</:named>
      </.vue>
  """
  def vue(assigns) do
    # Assign an ID if one isn't provided, to ensure stateful component uniqueness
    assigns = Map.put_new_lazy(assigns, :id, fn -> id(assigns[:"v-component"]) end)

    ~H"""
    <.live_component module={LiveVue.Component} {assigns} />
    """
  end

  defp id(name) do
    # If multiple components of the same name are used, the user MUST provide an explicit ID.
    # See: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html#:~:text=You%20must%20always%20pass%20the%20module%20and%20id%20attributes.
    name |> String.replace(~r/[^a-z0-9\-_]+/i, "-") |> String.trim("-")
  end

  @doc false
  @deprecated "~V sigil is deprecated, please use ~VUE instead."
  defmacro sigil_V(term, modifiers) do
    do_sigil(term, modifiers, __CALLER__)
  end

  @doc """
  Inlines a Vue single-file component inside a LiveView. This is the new recommended way over the `~V` sigil.
  """
  defmacro sigil_VUE(term, modifiers) do
    do_sigil(term, modifiers, __CALLER__)
  end

  defp do_sigil({:<<>>, _meta, [string]}, [], caller) do
    path = "./assets/vue/_build/#{caller.module}.vue"

    with :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write!(path, string)
    end

    quote do
      ~H"""
      <LiveVue.vue
        class={get_in(assigns, [:vue_opts, :class])}
        v-component={"_build/#{__MODULE__}"}
        v-ssr={get_in(assigns, [:vue_opts, :ssr]) != false}
        {Map.drop(assigns, [:vue_opts, :socket, :flash, :live_action])}
      />
      """
    end
  end
end
