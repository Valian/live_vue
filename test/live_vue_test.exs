defmodule LiveVueTest do
  use ExUnit.Case

  import LiveVue
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias LiveVue.Test

  doctest LiveVue

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
        <.vue name="John" v-component="UserProfile" />
        <.vue name="Jane" v-component="UserCard" />
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
  end
end
