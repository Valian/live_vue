defmodule LiveVue do
  @moduledoc """
  See README.md for installation instructions and usage.
  """

  use Phoenix.Component
  import Phoenix.HTML

  alias Phoenix.LiveView
  alias LiveVue.Slots
  alias LiveVue.SSR

  require Logger

  defmacro __using__(_opts) do
    quote do
      import LiveVue

      def __global__?(_name) do
        # To hide warnings regarding props and handlers
        # not defined in @rest attribute
        true
      end
    end
  end

  attr(
    :"v-component",
    :string,
    required: true,
    doc: "Name of the Vue component",
    examples: ["YourComponent", "directory/Example"]
  )

  attr(
    :class,
    :string,
    default: nil,
    doc: "Class to apply to the Vue component",
    examples: ["my-class", "my-class another-class"]
  )

  attr(
    :"v-ssr",
    :boolean,
    default: Application.compile_env(:live_vue, :ssr, true),
    doc: "Whether to render the component on the server",
    examples: [true, false]
  )

  attr(
    :"v-socket",
    :map,
    default: nil,
    doc: "LiveView socket, should be provided when rendering inside LiveView"
  )

  attr :rest, :global

  def vue(assigns) do
    init = assigns.__changed__ == nil
    dead = assigns[:"v-socket"] == nil or not LiveView.connected?(assigns[:"v-socket"])
    render_ssr? = init and dead and assigns[:"v-ssr"]

    # we manually compute __changed__ for the computed props and slots so it's not sent without reason
    {props, props_changed?} = extract(assigns, :props)
    {slots, slots_changed?} = extract(assigns, :slots)
    {handlers, handlers_changed?} = extract(assigns, :handlers)

    assigns =
      assigns
      |> Map.put(:__component_name, Map.get(assigns, :"v-component"))
      |> Map.put(:props, props)
      |> Map.put(:handlers, handlers)
      |> Map.put(:slots, if(slots_changed?, do: Slots.rendered_slot_map(slots), else: %{}))

    assigns = Map.put(assigns, :ssr_render, if(render_ssr?, do: ssr_render(assigns), else: ""))

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
    <div
      id={id(@__component_name)}
      data-name={@__component_name}
      data-props={"#{json(@props)}"}
      data-ssr={@ssr_render != nil}
      data-handlers={"#{for({k, v} <- @handlers, into: %{}, do: {k, json(v.ops)}) |> json()}"}
      data-slots={"#{@slots |> Slots.base_encode_64() |> json}"}
      phx-update="ignore"
      phx-hook="VueHook"
      class={@class}
    >
      <%= raw(@ssr_render) %>
    </div>
    """
  end

  defp extract(assigns, type) do
    properties =
      case assigns do
        %{inner_block: block} -> Map.put(assigns.rest, :inner_block, block)
        assigns -> assigns.rest
      end

    Enum.reduce(properties, {%{}, false}, fn {key, value}, {acc, changed} ->
      case normalize_key(key, value) do
        {^type, k} -> {Map.put(acc, k, value), changed || key_changed(assigns, key)}
        _ -> {acc, changed}
      end
    end)
  end

  defp normalize_key(key, [%{__slot__: _}]), do: {:slots, key}
  defp normalize_key(key, val) when is_atom(key), do: key |> to_string() |> normalize_key(val)
  defp normalize_key("v-on:" <> key, _val), do: {:handlers, key}
  defp normalize_key(key, _val), do: {:props, key}

  defp key_changed(%{__changed__: nil}, _key), do: true
  defp key_changed(%{__changed__: changed}, key), do: changed[key]

  defp ssr_render(assigns) do
    try do
      name = assigns[:"v-component"]

      case SSR.render(name, assigns.props, assigns.slots) do
        {:error, message} ->
          Logger.error("Vue SSR error: #{message}")
          ""

        body ->
          body
      end
    rescue
      SSR.NotConfigured ->
        nil
    end
  end

  defp json(data), do: Jason.encode!(data, escape: :html_safe)

  defp id(name), do: "#{name}-#{System.unique_integer([:positive])}"

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
