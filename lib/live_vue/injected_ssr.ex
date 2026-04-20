defmodule LiveVue.InjectedSSR do
  @moduledoc false

  alias LiveVue.SSR

  require Logger

  @state_key :live_vue_injected_ssr_state

  defmodule Fragment do
    @moduledoc false

    defstruct [:token, :field, :component]
  end

  @type component :: %{
          required(:id) => String.t(),
          required(:name) => String.t(),
          required(:props) => map(),
          required(:slots) => map()
        }

  @type injection :: %{
          required(:target) => String.t(),
          required(:slot) => String.t(),
          required(:component) => component()
        }

  @doc """
  Single entry point for `LiveVue.vue/1` SSR. When `target` is nil, returns a
  deferred fragment map for the root (visible) component. When `target` is a
  string, registers this component as an injection into its target's slot and
  returns nil — the target's fragment will pull it in at render time.
  """
  def prepare(component, nil, _slot), do: fragment(component)

  def prepare(component, target, slot) do
    register_injection(%{target: target, slot: slot || "default", component: component})
    nil
  end

  defp register_injection(%{target: target, slot: slot, component: component}) do
    state = ensure_state()

    put_state(%{
      state
      | injections:
          Map.update(state.injections, target, %{slot => component}, fn slots ->
            Map.put(slots, slot, component)
          end)
    })

    :ok
  end

  defp fragment(component) do
    state = ensure_state()
    put_state(%{state | active: state.active + 1})

    %{
      preloadLinks: %Fragment{token: state.token, field: :preloadLinks, component: component},
      html: %Fragment{token: state.token, field: :html, component: component}
    }
  end

  def render_fragment(%Fragment{token: token, field: field, component: component}) do
    case Process.get(@state_key) do
      %{token: ^token} = state ->
        {result, state} = fetch_rendered_component(state, component)

        state =
          if field == :html do
            decrement_active(state)
          else
            state
          end

        put_state(state)
        Map.fetch!(result, field)

      _ ->
        ""
    end
  end

  defp fetch_rendered_component(state, component) do
    case Map.fetch(state.cache, component.id) do
      {:ok, result} ->
        {result, state}

      :error ->
        result = render_component(component, state.injections, MapSet.new())
        {result, %{state | cache: Map.put(state.cache, component.id, result)}}
    end
  end

  defp render_component(component, injections, seen) do
    if MapSet.member?(seen, component.id) do
      Logger.error("LiveVue SSR injection cycle detected for ##{component.id}")
      %{preloadLinks: "", html: ""}
    else
      seen = MapSet.put(seen, component.id)

      {slot_html, preload_links} =
        injections
        |> Map.get(component.id, %{})
        |> Enum.reduce({%{}, ""}, fn {slot, child}, {slots, links} ->
          child_render = render_component(child, injections, seen)
          {Map.put(slots, slot, child_render.html), links <> child_render.preloadLinks}
        end)

      case SSR.render(component.name, component.props, Map.merge(component.slots, slot_html)) do
        %{preloadLinks: links, html: html} ->
          %{preloadLinks: preload_links <> links, html: html}

        {:error, message} ->
          Logger.error("Vue SSR error: #{message}")
          %{preloadLinks: preload_links, html: ""}
      end
    end
  rescue
    SSR.NotConfigured ->
      %{preloadLinks: "", html: ""}
  end

  defp ensure_state do
    case Process.get(@state_key) do
      %{active: active} = state when active > 0 ->
        state

      _ ->
        state = %{token: make_ref(), active: 0, injections: %{}, cache: %{}}
        put_state(state)
        state
    end
  end

  defp decrement_active(%{active: 1}) do
    %{token: make_ref(), active: 0, injections: %{}, cache: %{}}
  end

  defp decrement_active(state) do
    %{state | active: max(state.active - 1, 0)}
  end

  defp put_state(state) do
    Process.put(@state_key, state)
    state
  end
end

defimpl Phoenix.HTML.Safe, for: LiveVue.InjectedSSR.Fragment do
  def to_iodata(fragment) do
    LiveVue.InjectedSSR.render_fragment(fragment)
  end
end
