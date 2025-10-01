defmodule LiveVue.Test do
  @moduledoc """
  Helpers for testing LiveVue components and views.

  ## Overview

  LiveVue testing differs from traditional Phoenix LiveView testing in how components
  are rendered and inspected:

  * In Phoenix LiveView testing, you use `Phoenix.LiveViewTest.render_component/2`
    to get the final rendered HTML
  * In LiveVue testing, `render_component/2` returns an unrendered LiveVue root
    element containing the Vue component's configuration

  This module provides helpers to extract and inspect Vue component data from the
  LiveVue root element, including:

  * Component name and ID
  * Props passed to the component
  * Event handlers and their operations
  * Server-side rendering (SSR) status
  * Slot content
  * CSS classes

  ## Examples

      # Render a LiveVue component and inspect its properties
      {:ok, view, _html} = live(conn, "/")
      vue = LiveVue.Test.get_vue(view)

      # Basic component info
      assert vue.component == "MyComponent"
      assert vue.props["title"] == "Hello"

      # Event handlers
      assert vue.handlers["click"] == JS.push("click")

      # SSR status and styling
      assert vue.ssr == true
      assert vue.class == "my-custom-class"

  ## Configuration

  ### enable_props_diff

  When set to `false` in your config, LiveVue will always send full props and not send diffs.
  This is useful for testing scenarios where you need to inspect the complete props state
  rather than just the changes.

  ```elixir
  # config/test.exs
  config :live_vue,
    enable_props_diff: false
  ```

  When disabled, the `props` field returned by `get_vue/2` will always contain
  the complete props state, making it easier to write comprehensive tests that verify the
  full component state rather than just the incremental changes.
  """

  @compile {:no_warn_undefined, Floki}

  @doc """
  Extracts Vue component information from a LiveView or HTML string.

  When multiple Vue components are present, you can specify which one to extract using
  either the `:name` or `:id` option.

  Returns a map containing the component's configuration:
    * `:component` - The Vue component name (from `v-component` attribute)
    * `:id` - The unique component identifier (auto-generated or explicitly set)
    * `:props` - The decoded props passed to the component
    * `:handlers` - Map of event handlers (`v-on:*`) and their operations
    * `:slots` - Base64 encoded slot content
    * `:ssr` - Boolean indicating if server-side rendering was performed
    * `:class` - CSS classes applied to the component root element
    * `:props_diff` - List of prop diffs
    * `:streams_diff` - List of stream diffs
    * `:doc` - Parsed HTML element of the component (as returned by Floki)

  ## Options
    * `:name` - Find component by name (from `v-component` attribute)
    * `:id` - Find component by ID

  ## Examples

      # From a LiveView, get first Vue component
      {:ok, view, _html} = live(conn, "/")
      vue = LiveVue.Test.get_vue(view)

      # Get specific component by name
      vue = LiveVue.Test.get_vue(view, name: "MyComponent")

      # Get specific component by ID
      vue = LiveVue.Test.get_vue(view, id: "my-component-1")
  """
  def get_vue(view, opts \\ [])

  def get_vue(view, opts) when is_struct(view, Phoenix.LiveViewTest.View) do
    view |> Phoenix.LiveViewTest.render() |> get_vue(opts)
  end

  def get_vue(html, opts) when is_binary(html) do
    if Code.ensure_loaded?(Floki) do
      vue =
        html
        |> Floki.parse_document!()
        |> Floki.find("[phx-hook='VueHook']")
        |> find_component!(opts)

      %{
        props: Jason.decode!(attr(vue, "data-props")),
        component: attr(vue, "data-name"),
        id: attr(vue, "id"),
        handlers: extract_handlers(attr(vue, "data-handlers")),
        slots: extract_base64_slots(attr(vue, "data-slots")),
        ssr: vue |> attr("data-ssr") |> String.to_existing_atom(),
        use_diff: vue |> attr("data-use-diff") |> String.to_existing_atom(),
        class: attr(vue, "class"),
        props_diff: Jason.decode!(attr(vue, "data-props-diff")),
        streams_diff: Jason.decode!(attr(vue, "data-streams-diff")),
        doc: vue
      }
    else
      raise "Floki is not installed. Add {:floki, \">= 0.30.0\", only: :test} to your dependencies to use LiveVue.Test"
    end
  end

  defp extract_handlers(handlers) do
    handlers
    |> Jason.decode!()
    |> Map.new(fn {k, v} -> {k, extract_js_ops(v)} end)
  end

  defp extract_base64_slots(slots) do
    slots
    |> Jason.decode!()
    |> Map.new(fn {key, value} -> {key, Base.decode64!(value)} end)
  end

  defp extract_js_ops(ops) do
    ops
    |> Jason.decode!()
    |> Enum.map(fn
      [op, map] when is_map(map) -> [op, for({k, v} <- map, do: {String.to_existing_atom(k), v}, into: %{})]
      op -> op
    end)
    |> then(&%Phoenix.LiveView.JS{ops: &1})
  end

  defp find_component!(components, opts) do
    available = Enum.map_join(components, ", ", &"#{attr(&1, "data-name")}##{attr(&1, "id")}")

    components =
      Enum.reduce(opts, components, fn
        {:id, id}, result ->
          with [] <- Enum.filter(result, &(attr(&1, "id") == id)) do
            raise "No Vue component found with id=\"#{id}\". Available components: #{available}"
          end

        {:name, name}, result ->
          with [] <- Enum.filter(result, &(attr(&1, "data-name") == name)) do
            raise "No Vue component found with name=\"#{name}\". Available components: #{available}"
          end

        {key, _}, _result ->
          raise ArgumentError, "invalid keyword option for get_vue/2: #{key}"
      end)

    case components do
      [vue | _] ->
        vue

      [] ->
        raise "No Vue components found in the rendered HTML"
    end
  end

  defp attr(element, name) do
    case Floki.attribute(element, name) do
      [value] -> value
      [] -> nil
    end
  end
end
