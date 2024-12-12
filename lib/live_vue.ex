defmodule LiveVue do
  @moduledoc """
  LiveVue provides seamless integration between Phoenix LiveView and Vue.js components.

  ## Installation and Configuration

  See README.md for installation instructions and usage.

  ## Component Options

  When using the `vue/1` component or `~V` sigil, the following options are supported:

  ### Required Attributes
    * `v-component` (string) - Name of the Vue component (e.g., "YourComponent", "directory/Example")

  ### Optional Attributes
    * `id` (string) - Explicit ID of the wrapper component. If not provided, a random one will be
      generated. Useful to keep ID consistent in development (e.g., "vue-1")
    * `class` (string) - CSS class(es) to apply to the Vue component wrapper
      (e.g., "my-class" or "my-class another-class")
    * `v-ssr` (boolean) - Whether to render the component on the server. Defaults to the value set
      in config (default: true)
    * `v-socket` (LiveView.Socket) - LiveView socket, should be provided when rendering inside LiveView

  ### Event Handlers
    * `v-on:*` - Vue event handlers can be attached using the `v-on:` prefix
      (e.g., `v-on:click`, `v-on:input`)

  ### Props and Slots
    * All other attributes are passed as props to the Vue component
    * Slots can be passed as regular Phoenix slots
  """

  use Phoenix.Component
  import Phoenix.HTML

  alias Phoenix.LiveView
  alias LiveVue.Slots
  alias LiveVue.SSR

  require Logger

  @ssr_default Application.compile_env(:live_vue, :ssr, true)

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
    init = assigns.__changed__ == nil
    dead = assigns[:"v-socket"] == nil or not LiveView.connected?(assigns[:"v-socket"])
    render_ssr? = init and dead and Map.get(assigns, :"v-ssr", @ssr_default)

    # we manually compute __changed__ for the computed props and slots so it's not sent without reason
    {props, props_changed?} = extract(assigns, :props)
    {slots, slots_changed?} = extract(assigns, :slots)
    {handlers, handlers_changed?} = extract(assigns, :handlers)

    assigns =
      assigns
      |> Map.put_new(:class, nil)
      |> Map.put(:__component_name, Map.get(assigns, :"v-component"))
      |> Map.put(:props, props)
      |> Map.put(:handlers, handlers)
      |> Map.put(:slots, if(slots_changed?, do: Slots.rendered_slot_map(slots), else: %{}))

    assigns =
      Map.put(assigns, :ssr_render, if(render_ssr?, do: ssr_render(assigns), else: nil))

    computed_changed =
      %{
        props: props_changed?,
        slots: slots_changed?,
        handlers: handlers_changed?,
        ssr_render: render_ssr?
      }

    assigns =
      update_in(assigns.__changed__, fn
        nil -> nil
        changed -> for {k, true} <- computed_changed, into: changed, do: {k, true}
      end)

    # optimizing diffs by using string interpolation
    # https://elixirforum.com/t/heex-attribute-value-in-quotes-send-less-data-than-values-in-braces/63274
    ~H"""
    <%= raw(@ssr_render[:preloadLinks]) %>
    <div
      id={assigns[:id] || id(@__component_name)}
      data-name={@__component_name}
      data-props={"#{json(@props)}"}
      data-ssr={(@ssr_render != nil) |> to_string()}
      data-handlers={"#{for({k, v} <- @handlers, into: %{}, do: {k, json(v.ops)}) |> json()}"}
      data-slots={"#{@slots |> Slots.base_encode_64() |> json}"}
      phx-update="ignore"
      phx-hook="VueHook"
      phx-no-format
      class={@class}
    ><%= raw(@ssr_render[:html]) %></div>
    """
  end

  defp extract(assigns, type) do
    Enum.reduce(assigns, {%{}, false}, fn {key, value}, {acc, changed} ->
      case normalize_key(key, value) do
        ^type -> {Map.put(acc, key, value), changed || key_changed(assigns, key)}
        {^type, k} -> {Map.put(acc, k, value), changed || key_changed(assigns, key)}
        _ -> {acc, changed}
      end
    end)
  end

  defp normalize_key(key, _val) when key in ~w"id class v-ssr v-component v-socket __changed__ __given__"a, do: :special
  defp normalize_key(_key, [%{__slot__: _}]), do: :slots
  defp normalize_key(key, val) when is_atom(key), do: key |> to_string() |> normalize_key(val)
  defp normalize_key("v-on:" <> key, _val), do: {:handlers, key}
  defp normalize_key(_key, _val), do: :props

  defp key_changed(%{__changed__: nil}, _key), do: true
  defp key_changed(%{__changed__: changed}, key), do: changed[key] != nil

  defp ssr_render(assigns) do
    try do
      name = assigns[:"v-component"]

      case SSR.render(name, assigns.props, assigns.slots) do
        {:error, message} ->
          Logger.error("Vue SSR error: #{message}")
          nil

        %{preloadLinks: links, html: html} ->
          %{preloadLinks: links, html: html}
      end
    rescue
      SSR.NotConfigured ->
        nil
    end
  end

  defp json(data), do: Jason.encode!(data, escape: :html_safe)

  defp id(name) do
    # a small trick to avoid collisions of IDs but keep them consistent across dead and live render
    # id(name) is called only once during the whole LiveView lifecycle because it's not using any assigns
    number = Process.get(:live_vue_counter, 1)
    Process.put(:live_vue_counter, number + 1)
    "#{name}-#{number}"
  end

  @doc false
  def get_socket(assigns) do
    case get_in(assigns, [:vue_opts, :socket]) || assigns[:socket] do
      %LiveView.Socket{} = socket -> socket
      _ -> nil
    end
  end

  @doc false
  defmacro sigil_V({:<<>>, _meta, [string]}, []) do
    path = "./assets/vue/_build/#{__CALLER__.module}.vue"

    with :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write!(path, string)
    end

    quote do
      ~H"""
      <LiveVue.vue
        class={get_in(assigns, [:vue_opts, :class])}
        v-component={"_build/#{__MODULE__}"}
        v-socket={get_socket(assigns)}
        v-ssr={get_in(assigns, [:vue_opts, :ssr]) != false}
        {Map.drop(assigns, [:vue_opts, :socket, :flash, :live_action])}
      />
      """
    end
  end
end
