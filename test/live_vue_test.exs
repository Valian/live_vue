defmodule LiveVueTest do
  use ExUnit.Case

  import ExUnit.CaptureLog
  import LiveVue
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias LiveVue.Test
  alias Phoenix.LiveView.JS

  defmodule InjectedSSRRenderer do
    @moduledoc false
    @behaviour LiveVue.SSR

    def render(name, props, slots) do
      page = props |> Map.get("page", "") |> to_string()
      message = props |> Map.get("message", "") |> to_string()
      label = props |> Map.get("label", "") |> to_string()

      """
      <section data-ssr-name="#{name}">
        <span data-ssr-page>#{page}</span>
        <span data-ssr-message>#{message}</span>
        <span data-ssr-label>#{label}</span>
        <div data-ssr-slot="default">#{Map.get(slots, "default", "")}</div>
        <div data-ssr-slot="sidebar">#{Map.get(slots, "sidebar", "")}</div>
      </section>
      """
    end
  end

  doctest LiveVue

  defp put_live_vue_env(key, value) do
    previous = Application.fetch_env(:live_vue, key)
    Application.put_env(:live_vue, key, value)

    on_exit(fn ->
      case previous do
        {:ok, previous} -> Application.put_env(:live_vue, key, previous)
        :error -> Application.delete_env(:live_vue, key)
      end
    end)
  end

  describe "basic component rendering" do
    def simple_component(assigns) do
      ~H"""
      <.vue name="John" surname="Doe" v-component="MyComponent" />
      """
    end

    test "renders component with correct props" do
      html = render_component(&simple_component/1)
      vue = Test.get_vue(html)

      assert vue.component == "MyComponent"
      assert vue.props == %{"name" => "John", "surname" => "Doe"}
    end

    test "generates consistent ID" do
      html = render_component(&simple_component/1)
      vue = Test.get_vue(html)

      assert vue.id =~ ~r/MyComponent-\d+/
    end
  end

  describe "multiple components" do
    def multi_component(assigns) do
      ~H"""
      <div>
        <.vue id="profile-1" name="John" v-component="UserProfile" />
        <.vue id="card-1" name="Jane" v-component="UserCard" />
      </div>
      """
    end

    test "finds first component by default" do
      html = render_component(&multi_component/1)
      vue = Test.get_vue(html)

      assert vue.component == "UserProfile"
      assert vue.props == %{"name" => "John"}
    end

    test "finds specific component by name" do
      html = render_component(&multi_component/1)
      vue = Test.get_vue(html, name: "UserCard")

      assert vue.component == "UserCard"
      assert vue.props == %{"name" => "Jane"}
    end

    test "finds specific component by id" do
      html = render_component(&multi_component/1)
      vue = Test.get_vue(html, id: "card-1")

      assert vue.component == "UserCard"
      assert vue.id == "card-1"
    end

    test "raises error when component with name not found" do
      html = render_component(&multi_component/1)

      assert_raise RuntimeError,
                   ~r/No Vue component found with name="Unknown".*Available components: UserProfile#profile-1, UserCard#card-1/,
                   fn ->
                     Test.get_vue(html, name: "Unknown")
                   end
    end

    test "raises error when component with id not found" do
      html = render_component(&multi_component/1)

      assert_raise RuntimeError,
                   ~r/No Vue component found with id="unknown-id".*Available components: UserProfile#profile-1, UserCard#card-1/,
                   fn ->
                     Test.get_vue(html, id: "unknown-id")
                   end
    end
  end

  describe "event handlers" do
    def component_with_events(assigns) do
      ~H"""
      <.vue
        name="John"
        v-component="MyComponent"
        v-on:click={JS.push("click", value: %{"abc" => "def"})}
        v-on:submit={JS.push("submit")}
      />
      """
    end

    test "renders event handlers correctly" do
      html = render_component(&component_with_events/1)
      vue = Test.get_vue(html)

      assert vue.handlers == %{
               "click" => JS.push("click", value: %{"abc" => "def"}),
               "submit" => JS.push("submit")
             }
    end
  end

  describe "styling" do
    def styled_component(assigns) do
      ~H"""
      <.vue name="John" v-component="MyComponent" class="bg-blue-500 rounded" />
      """
    end

    test "applies CSS classes" do
      html = render_component(&styled_component/1)
      vue = Test.get_vue(html)

      assert vue.class == "bg-blue-500 rounded"
    end
  end

  describe "SSR behavior" do
    def ssr_component(assigns) do
      ~H"""
      <.vue name="John" v-component="MyComponent" v-ssr={false} />
      """
    end

    test "respects SSR flag" do
      html = render_component(&ssr_component/1)
      vue = Test.get_vue(html)

      assert vue.ssr == false
    end

    def injected_ssr_component(assigns) do
      ~H"""
      <div>
        <.vue v-component="Layout" id="vue-layout" v-ssr={true} />
        <.vue page="page-1" v-component="Page" id="page-component" v-inject="vue-layout" v-ssr={true} />
        <.vue message="nested" v-component="Nested" id="nested-component" v-inject="page-component" v-ssr={true} />
        <.vue label="Sidebar" v-component="Sidebar" v-inject:sidebar="vue-layout" v-ssr={true} />
      </div>
      """
    end

    def duplicate_ssr_id_component(assigns) do
      ~H"""
      <div>
        <.vue v-component="First" id="duplicate-id" v-ssr={true} />
        <.vue v-component="Second" id="duplicate-id" v-ssr={true} />
      </div>
      """
    end

    def duplicate_slot_injection_component(assigns) do
      ~H"""
      <div>
        <.vue v-component="Layout" id="vue-layout" v-ssr={true} />
        <.vue label="First" v-component="FirstSidebar" id="first-sidebar" v-inject:sidebar="vue-layout" v-ssr={true} />
        <.vue label="Second" v-component="SecondSidebar" id="second-sidebar" v-inject:sidebar="vue-layout" v-ssr={true} />
      </div>
      """
    end

    def boolean_inject_component(assigns) do
      ~H"""
      <.vue v-component="Child" v-inject={true} />
      """
    end

    test "SSR-composes injected content into the visible target tree" do
      put_live_vue_env(:ssr_module, InjectedSSRRenderer)

      html = render_component(&injected_ssr_component/1)

      layout = Test.get_vue(html, id: "vue-layout")
      page = Test.get_vue(html, id: "page-component")
      nested = Test.get_vue(html, id: "nested-component")

      assert layout.ssr == true
      assert page.ssr == false
      assert nested.ssr == false

      assert html =~ ~s(<section data-ssr-name="Layout">)
      assert html =~ ~s(<section data-ssr-name="Page">)
      assert html =~ ~s(<section data-ssr-name="Nested">)
      assert html =~ ~s(<section data-ssr-name="Sidebar">)

      assert html =~
               ~r/<section data-ssr-name="Layout">[\s\S]*<section data-ssr-name="Page">[\s\S]*<section data-ssr-name="Nested">/

      assert html =~ ~r/<section data-ssr-name="Layout">[\s\S]*<section data-ssr-name="Sidebar">/
    end

    test "raises on duplicate SSR component ids when configured" do
      put_live_vue_env(:validate_unique_component_ids, true)

      assert_raise ArgumentError, ~r/duplicate LiveVue component id "duplicate-id"/, fn ->
        render_component(&duplicate_ssr_id_component/1)
      end
    end

    test "allows duplicate SSR component ids when validation is disabled" do
      put_live_vue_env(:validate_unique_component_ids, false)

      assert render_component(&duplicate_ssr_id_component/1) =~ ~s(id="duplicate-id")
    end

    test "warns when multiple components inject into the same target slot" do
      put_live_vue_env(:ssr_module, InjectedSSRRenderer)

      log =
        capture_log(fn ->
          html = render_component(&duplicate_slot_injection_component/1)
          send(self(), {:html, html})
        end)

      assert_receive {:html, html}
      assert log =~ ~s(LiveVue SSR injection into #vue-layout slot "sidebar" was overwritten)
      refute html =~ ~s(data-ssr-name="FirstSidebar")
      assert html =~ ~s(data-ssr-name="SecondSidebar")
    end

    test "raises when v-inject is used without a target id" do
      assert_raise ArgumentError, ~r/v-inject requires a target component id/, fn ->
        render_component(&boolean_inject_component/1)
      end
    end
  end

  describe "slots" do
    def component_with_slots(assigns) do
      ~H"""
      <.vue v-component="WithSlots">
        Default content
        <:header>Header content</:header>
        <:footer>
          <div>Footer content</div>
          <button>Click me</button>
        </:footer>
      </.vue>
      """
    end

    def component_with_default_slot(assigns) do
      ~H"""
      <.vue v-component="WithSlots">
        <:default>Simple content</:default>
      </.vue>
      """
    end

    def component_with_inner_block(assigns) do
      ~H"""
      <.vue v-component="WithSlots">
        Simple content
      </.vue>
      """
    end

    test "warns about usage of <:default> slot" do
      assert_raise RuntimeError,
                   "Instead of using <:default> use <:inner_block> slot",
                   fn -> render_component(&component_with_default_slot/1) end
    end

    test "renders multiple slots" do
      html = render_component(&component_with_slots/1)
      vue = Test.get_vue(html)

      assert vue.slots == %{
               "default" => "Default content",
               "header" => "Header content",
               "footer" => "<div>Footer content</div>\n    <button>Click me</button>"
             }
    end

    test "renders default slot with inner_block" do
      html = render_component(&component_with_inner_block/1)
      vue = Test.get_vue(html)

      assert vue.slots == %{"default" => "Simple content"}
    end

    test "encodes slots as base64" do
      html = render_component(&component_with_slots/1)

      # Get raw data-slots attribute to verify base64 encoding
      doc = LazyHTML.from_fragment(html)
      slots_attr = doc |> LazyHTML.attribute("data-slots") |> hd()

      # JSON encoded map
      assert slots_attr =~ ~r/^\{.*\}$/

      slots =
        slots_attr
        |> Jason.decode!()
        |> Map.new(fn {key, value} -> {key, Base.decode64!(value)} end)

      assert slots == %{
               "default" => "Default content",
               "header" => "Header content",
               "footer" => "<div>Footer content</div>\n    <button>Click me</button>"
             }
    end

    test "handles empty slots" do
      html =
        render_component(fn assigns ->
          ~H"""
          <.vue v-component="WithSlots" />
          """
        end)

      vue = Test.get_vue(html)

      assert vue.slots == %{}
    end
  end

  describe "edge cases" do
    def edge_case_component(assigns) do
      ~H"""
      <.vue name="John" v-component="MyComponent" />
      """
    end

    test "raises ArgumentError with invalid option key" do
      html = render_component(&edge_case_component/1)

      assert_raise ArgumentError,
                   "invalid keyword option for get_vue/2: foo",
                   fn ->
                     Test.get_vue(html, foo: "bar")
                   end
    end

    test "raises error when no Vue components found" do
      html = "<div>No Vue components here</div>"

      assert_raise RuntimeError,
                   "No Vue components found in the rendered HTML",
                   fn ->
                     Test.get_vue(html)
                   end
    end

    test "handles missing attributes gracefully" do
      html = render_component(&edge_case_component/1)
      vue = Test.get_vue(html)

      # Components without class attribute should return nil or empty string
      assert vue.class in [nil, ""]
    end
  end
end
