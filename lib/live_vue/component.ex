defmodule LiveVue.Component do
  @moduledoc """
  A stateful LiveComponent that renders a Vue component.

  It handles prop diffing, SSR rendering, and event handling.
  """
  use Phoenix.LiveComponent

  import Phoenix.HTML

  alias LiveVue.Encoder
  alias LiveVue.Slots
  alias LiveVue.SSR
  alias Phoenix.LiveView.LiveStream

  require Logger

  @ssr_default Application.compile_env(:live_vue, :ssr, true)
  @diff_default Application.compile_env(:live_vue, :enable_props_diff, true)

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :props, %{})}
  end

  @impl true
  def update(assigns, socket) do
    init = not Map.has_key?(socket.assigns, :component_name)
    dead = not Phoenix.LiveView.connected?(socket)

    # On initial mount or if socket is disconnected, we don't have old props to diff against
    # But for update, we do.

    use_diff = Map.get(assigns, :"v-diff", @diff_default)
    use_streams_diff = Enum.any?(assigns, fn {_k, v} -> match?(%LiveStream{}, v) end)
    render_ssr? = init and dead and Map.get(assigns, :"v-ssr", @ssr_default)

    new_props = extract(assigns, :props)
    old_props = socket.assigns.props

    props_diff =
      if not init and not dead and use_diff do
        Jsonpatch.diff(old_props, new_props,
          prepare_map: fn
            struct when is_struct(struct) -> Encoder.encode(struct)
            rest -> rest
          end,
          object_hash: &object_hash/1
        )
      else
        []
      end

    streams = extract(assigns, :streams)
    streams_diff = if use_streams_diff, do: calculate_streams_diff(streams, init or dead), else: []

    handlers = extract(assigns, :handlers)
    slots = extract(assigns, :slots)

    socket =
      socket
      |> assign(:id, assigns.id)
      |> assign(:class, Map.get(assigns, :class))
      |> assign(:component_name, Map.get(assigns, :"v-component"))
      |> assign(:props, new_props)
      |> assign(:props_diff, Enum.map(props_diff, &prepare_diff/1))
      |> assign(:streams_diff, Enum.map(streams_diff, &prepare_diff/1))
      |> assign(:handlers, handlers)
      |> assign(:slots, Slots.rendered_slot_map(slots))
      |> assign(:use_diff, use_diff)
      |> assign(:ssr_render, if(render_ssr?, do: ssr_render(assigns, new_props, slots)))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-name={@component_name}
      data-props={"#{json(Encoder.encode(@props))}"}
      data-props-diff={"#{json(@props_diff)}"}
      data-streams-diff={"#{json(@streams_diff)}"}
      data-ssr={(@ssr_render != nil) |> to_string()}
      data-use-diff={@use_diff |> to_string()}
      data-handlers={"#{for({k, v} <- @handlers, into: %{}, do: {k, json(v.ops)}) |> json()}"}
      data-slots={"#{@slots |> Slots.base_encode_64() |> json}"}
      phx-update="ignore"
      phx-hook="VueHook"
      phx-no-format
      class={@class}
    >
      {raw(@ssr_render[:preloadLinks] || "")}
      <%= raw(@ssr_render[:html] || "") %>
    </div>
    """
  end

  @doc false
  def extract(assigns, type) do
    Enum.reduce(assigns, %{}, fn {key, value}, acc ->
      case normalize_key(key, value) do
        ^type -> Map.put(acc, key, value)
        {^type, k} -> Map.put(acc, k, value)
        _ -> acc
      end
    end)
  end

  defp normalize_key(key, _val)
       when key in ~w"id class v-ssr v-diff v-component v-socket socket flash myself live_action __changed__ __given__"a,
       do: :special

  defp normalize_key(_key, [%{__slot__: _}]), do: :slots
  defp normalize_key(key, val) when is_atom(key), do: key |> to_string() |> normalize_key(val)
  defp normalize_key("v-on:" <> key, _val), do: {:handlers, key}
  # Simplify stream detection - if it looks like a stream, treat it as one
  defp normalize_key(_key, %LiveStream{}), do: :streams
  defp normalize_key(_key, _val), do: :props

  # Generates JSON patch operations for LiveStream changes
  defp calculate_streams_diff(streams, initial)

  defp calculate_streams_diff(streams, true) do
    # for initial render, we want to reset all streams, and then apply the diffs
    init = Enum.map(streams, fn {k, _} -> %{op: "replace", path: "/#{k}", value: []} end)
    diffs = Enum.flat_map(streams, fn {k, stream} -> generate_stream_patches(k, stream) end)
    init ++ diffs
  end

  defp calculate_streams_diff(streams, false) do
    Enum.flat_map(streams, fn {k, stream} -> generate_stream_patches(k, stream) end)
    # We kept the random test op for streams in the original, but for props we removed it.
    # Let's clean it up here too if we want pure diffs, OR keep it if streams are unreliable.
    # The original concern was about props. LiveStreams are tracked by Phoenix so they might be reliable.
    # But for consistency, let's stick to pure diffs unless forced.
    # Wait, the original plan said "remove the performance-killing 'force update' hack".
    # So I will NOT add the random test op here.
  end

  # this function tells which field of the struct should be used as a key for the diff
  defp object_hash(%{id: id}), do: id
  defp object_hash(_), do: nil

  defp generate_stream_patches(stream_name, %LiveStream{} = stream) do
    patches = []

    # Handle reset operation first
    patches =
      if stream.reset?,
        do: [%{op: "replace", path: "/#{stream_name}", value: []} | patches],
        else: patches

    # Handle deletions second
    patches =
      Enum.reduce(stream.deletes, patches, fn dom_id, patches ->
        [%{op: "remove", path: "/#{stream_name}/$$#{dom_id}"} | patches]
      end)

    # Handle insertions third
    stream.inserts
    |> Enum.reverse()
    |> Enum.reduce(patches, fn {dom_id, at, item, limit, update_only}, patches ->
      item = Map.put(Encoder.encode(item), :__dom_id, dom_id)

      patches =
        if update_only,
          do: [%{op: "replace", path: "/#{stream_name}/$$#{dom_id}", value: item} | patches],
          else: [%{op: "upsert", path: "/#{stream_name}/#{if at == -1, do: "-", else: at}", value: item} | patches]

      if limit,
        do: [%{op: "limit", path: "/#{stream_name}", value: limit} | patches],
        else: patches
    end)
    |> Enum.reverse()
  end

  defp prepare_diff(%{op: op, path: p, value: value}), do: [op, p, value]
  defp prepare_diff(%{op: op, path: p}), do: [op, p]

  defp ssr_render(assigns, props, slots) do
    name = Map.get(assigns, :"v-component")
    encoded_props = Encoder.encode(props)

    case SSR.render(name, encoded_props, slots) do
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

  defp json(data), do: Jason.encode!(data, escape: :html_safe)
end
