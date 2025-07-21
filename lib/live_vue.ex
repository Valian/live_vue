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
  alias LiveVue.Encoder
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

    changed = Enum.filter(assigns, fn {k, _v} -> key_changed(assigns, k) end)
    changed_props = extract(changed, :props) |> Encoder.encode()
    changed_slots = extract(changed, :slots)
    changed_handlers = extract(changed, :handlers)
    changed_props_diff = calculate_props_diff(changed_props, assigns)
    rendered_slots = if changed_slots != %{}, do: Slots.rendered_slot_map(changed_slots), else: %{}

    assigns =
      assigns
      |> Map.put_new(:class, nil)
      |> Map.put(:__component_name, Map.get(assigns, :"v-component"))
      |> Map.put(:props, changed_props)
      |> Map.put(:props_diff, changed_props_diff)
      |> Map.put(:handlers, changed_handlers)
      |> Map.put(:slots, rendered_slots)

    assigns =
      Map.put(assigns, :ssr_render, if(render_ssr?, do: ssr_render(assigns), else: nil))

    computed_changed =
      %{
        # we send initial props only on initial render, later we send only changed props
        props: init or dead,
        ssr_render: render_ssr?,
        slots: changed_slots != %{},
        handlers: changed_handlers != %{},
        # we want to send props_diff always but not on initial render
        props_diff: not init and not dead
      }

    assigns =
      update_in(assigns.__changed__, fn
        nil -> nil
        changed -> for {k, true} <- computed_changed, into: changed, do: {k, true}
      end)

    # optimizing diffs by using string interpolation
    # https://elixirforum.com/t/heex-attribute-value-in-quotes-send-less-data-than-values-in-braces/63274
    ~H"""
    {raw(@ssr_render[:preloadLinks])}
    <div
      id={assigns[:id] || id(@__component_name)}
      data-name={@__component_name}
      data-props={"#{json(@props)}"}
      data-props-diff={"#{json(@props_diff)}"}
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

  # Calculates minimal JSON Patch operations for changed props only.
  # Uses Phoenix LiveView's __changed__ tracking to identify what props have changed.
  # For simple values, generates direct replace operations.
  # For complex values (maps, lists), uses Jsonpatch.diff to find minimal changes.
  # Uses LiveVue.Encoder to safely encode structs before diffing.
  defp calculate_props_diff(encoded_changed_props, %{__changed__: changed}) do
    # For simple types: changed[k] == true
    # For complex types: changed[k] is the old value
    Enum.flat_map(encoded_changed_props, fn {k, new_value} ->
      case changed[k] do
        nil ->
          []

        # For simple types, generate replace operation
        true ->
          [%{op: "replace", path: "/#{k}", value: new_value}]

        # For complex types, use Jsonpatch to find minimal diff
        old_value ->
          old_value
          |> LiveVue.Diff.diff(new_value,
            ancestor_path: "/#{k}",
            prepare_struct: &Encoder.encode/1,
            object_hash: &object_hash/1
          )
          # let's compress it a little bit, and decompress it on the client side
          |> Enum.map(&compress_diff/1)
      end
    end)
  end

  defp object_hash(%__struct__{id: id}), do: id
  defp object_hash(_), do: nil

  defp compress_diff(diff), do: [diff[:op], diff[:path], diff[:value]]

  defp extract(assigns, type) do
    Enum.reduce(assigns, %{}, fn {key, value}, acc ->
      case normalize_key(key, value) do
        ^type -> Map.put(acc, key, value)
        {^type, k} -> Map.put(acc, k, value)
        _ -> acc
      end
    end)
  end

  defp normalize_key(key, _val)
       when key in ~w"id class v-ssr v-component v-socket __changed__ __given__"a,
       do: :special

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
