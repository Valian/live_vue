defmodule LiveVue.InjectedSSR do
  @moduledoc false

  alias LiveVue.SSR

  require Logger

  @state_key :live_vue_injected_ssr_state
  @validate_unique_component_ids_default Mix.env() == :dev

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
    state =
      ensure_state()
      |> register_component!(component)
      |> register_injection(%{target: target, slot: slot || "default", component: component})

    put_state(state)
    nil
  end

  defp register_injection(state, %{target: target, slot: slot, component: component}) do
    if existing = get_in(state.injections, [target, slot]) do
      Logger.warning(
        "LiveVue SSR injection into ##{target} slot #{inspect(slot)} was overwritten. " <>
          "Existing component: #{existing.name}##{existing.id}, new component: #{component.name}##{component.id}"
      )
    end

    %{
      state
      | injections:
          Map.update(state.injections, target, %{slot => component}, fn slots ->
            Map.put(slots, slot, component)
          end)
    }
  end

  defp fragment(component) do
    state = register_component!(ensure_state(), component)

    put_state(%{state | pending_roots: state.pending_roots + 1})

    # HEEx builds the full rendered tree before these fragments are converted to
    # iodata, giving later injected children a chance to register before root SSR runs.
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
            decrement_pending_roots(state)
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

  defp register_component!(state, component) do
    if validate_unique_component_ids?() && Map.has_key?(state.component_ids, component.id) do
      raise ArgumentError,
            "duplicate LiveVue component id #{inspect(component.id)} detected during SSR. " <>
              "Component ids must be unique within a single render. " <>
              "Set config :live_vue, validate_unique_component_ids: false to disable this check."
    end

    %{state | component_ids: Map.put(state.component_ids, component.id, component)}
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
      %{pending_roots: pending_roots} = state when pending_roots > 0 ->
        state

      _ ->
        state = %{token: make_ref(), pending_roots: 0, injections: %{}, cache: %{}, component_ids: %{}}
        put_state(state)
        state
    end
  end

  defp decrement_pending_roots(%{pending_roots: 1}) do
    %{token: make_ref(), pending_roots: 0, injections: %{}, cache: %{}, component_ids: %{}}
  end

  defp decrement_pending_roots(state) do
    %{state | pending_roots: max(state.pending_roots - 1, 0)}
  end

  defp validate_unique_component_ids? do
    Application.get_env(:live_vue, :validate_unique_component_ids, @validate_unique_component_ids_default)
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
