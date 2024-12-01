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
  """

  @doc """
  Extracts Vue component information from a LiveView or HTML string.

  When multiple Vue components are present, you can specify which one to extract using
  the `:name` option.

  Returns a map containing the component's configuration:
    * `:component` - The Vue component name (from `v-component` attribute)
    * `:id` - The unique component identifier (auto-generated or explicitly set)
    * `:props` - The decoded props passed to the component
    * `:handlers` - Map of event handlers (`v-on:*`) and their operations
    * `:slots` - Base64 encoded slot content
    * `:ssr` - Boolean indicating if server-side rendering was performed
    * `:class` - CSS classes applied to the component root element

  ## Examples

      # From a LiveView, get first Vue component
      {:ok, view, _html} = live(conn, "/")
      vue = LiveVue.Test.get_vue(view)

      # Get specific component by name
      vue = LiveVue.Test.get_vue(view, name: "MyComponent")

      # From HTML string with specific component
      html = \"\"\"
      <div>
        <div phx-hook='VueHook' data-name='OtherComponent' ...></div>
        <div phx-hook='VueHook' data-name='MyComponent' ...></div>
      </div>
      \"\"\"
      vue = LiveVue.Test.get_vue(html, name: "MyComponent")
  """
  def get_vue(view, opts \\ [])

  def get_vue(view, opts) when is_struct(view, Phoenix.LiveViewTest.View) do
    view |> Phoenix.LiveViewTest.render() |> get_vue(opts)
  end

  def get_vue(html, opts) when is_binary(html) do
    doc =
      html
      |> Floki.parse_document!()
      |> Floki.find("[phx-hook='VueHook']")
      |> find_component(opts[:name])

    case doc do
      nil ->
        nil

      vue ->
        %{
          props: Jason.decode!(Floki.attribute(vue, "data-props") |> hd()),
          component: Floki.attribute(vue, "data-name") |> hd(),
          id: Floki.attribute(vue, "id") |> hd(),
          handlers: extract_handlers(Floki.attribute(vue, "data-handlers") |> hd()),
          slots: Floki.attribute(vue, "data-slots") |> hd() |> Jason.decode!(),
          ssr: Floki.attribute(vue, "data-ssr") |> hd() |> String.to_existing_atom(),
          class: Floki.attribute(vue, "class") |> List.first()
        }
    end
  end

  defp extract_handlers(handlers) do
    handlers
    |> Jason.decode!()
    |> Enum.map(fn {k, v} -> {k, extract_js_ops(v)} end)
    |> Enum.into(%{})
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

  defp find_component(doc, name) do
    case name do
      nil ->
        doc

      name ->
        doc
        |> Enum.find(fn vue -> Floki.attribute(vue, "data-name") |> hd() == name end)
    end
  end
end
