defmodule LiveVueTest do
  use ExUnit.Case

  import LiveVue
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias LiveVue.Test
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket
  alias Phoenix.LiveView.Socket.AssignsNotInSocket

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
      doc = Floki.parse_fragment!(html)
      slots_attr = doc |> Floki.attribute("data-slots") |> hd()

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

  describe "merge_socket_props" do
    test "merges simple atom props from socket" do
      # Create socket with no changes (same current and previous assigns)
      socket = create_socket(%{current_user: "john", theme: "dark"})
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}
      config = [:current_user, :theme]

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:current_user] == "john"
      assert result[:theme] == "dark"
      assert result[:existing_prop] == "value"
      assert result[:"v-socket"] == socket
      # we shouldn't add any changed props, since original socket changed didn't have it
      assert result.__changed__ == %{}
    end

    test "returns assigns unchanged when socket is missing" do
      assigns = %{existing_prop: "value", __changed__: %{}}
      config = [:current_user]
      result = LiveVue.merge_socket_props(config, assigns)

      assert result == assigns
    end

    test "returns assigns unchanged when socket is nil" do
      assigns = %{"v-socket": nil, existing_prop: "value", __changed__: %{}}
      config = [:current_user]

      result = LiveVue.merge_socket_props(config, assigns)

      assert result == assigns
    end

    test "returns assigns unchanged when props config is empty" do
      socket = create_socket(%{current_user: "john"})
      assigns = %{"v-socket": socket, existing_prop: "value"}
      config = []

      result = LiveVue.merge_socket_props(config, assigns)

      assert result == assigns
    end

    test "merges props with tuple configuration {socket_key, prop_name}" do
      socket = create_socket(%{current_scope: "admin", user_id: 123})
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}
      config = [{:current_scope, :scope}, {:user_id, :id}]

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:scope] == "admin"
      assert result[:id] == 123
      assert result[:existing_prop] == "value"
      assert result[:"v-socket"] == socket
      assert result.__changed__ == %{}
    end

    test "preserves __changed__ tracking when socket has changes" do
      socket =
        create_socket(
          # we changed jane to john
          %{current_user: "john", theme: "dark"},
          %{current_user: "jane", theme: "dark"}
        )

      config = [:current_user, :theme]
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:current_user] == "john"
      assert result[:theme] == "dark"
      # __changed__ should track that current_user changed from "jane"
      assert result.__changed__[:current_user] == true
      # theme should not be in __changed__ since socket didn't track it as changed
      refute Map.has_key?(result.__changed__, :theme)
    end

    test "handles complex __changed__ tracking with tuple config" do
      socket =
        create_socket(
          # current assigns
          %{current_scope: "admin", user_data: %{name: "john"}},
          # previous assigns (what changed)
          %{current_scope: "user", user_data: %{name: "jane"}}
        )

      config = [{:current_scope, :scope}, {:user_data, :user}]
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:scope] == "admin"
      assert result[:user] == %{name: "john"}
      # __changed__ should contain the previous values from socket.__changed__
      # simple values get true
      assert result.__changed__[:scope] == true
      # complex values get the previous value
      assert result.__changed__[:user] == %{name: "jane"}
    end

    test "ignores __changed__ tracking when assigns has no __changed__" do
      socket = create_socket(%{current_user: "john"}, %{current_user: "jane"})

      config = [:current_user]
      assigns = %{"v-socket": socket, existing_prop: "value"}
      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:current_user] == "john"
      assert result[:existing_prop] == "value"
      # No __changed__ key should be present
      refute Map.has_key?(result, :__changed__)
    end

    test "ignores __changed__ tracking when socket has no __changed__" do
      socket = create_socket(%{current_user: "john"})
      {_, socket} = pop_in(socket, [Access.key!(:assigns), Access.key!(:__assigns__), Access.key!(:__changed__)])
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}
      config = [:current_user]

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:current_user] == "john"
      assert result[:existing_prop] == "value"
      # __changed__ should remain unchanged since socket has no changes
      assert result.__changed__ == %{}
    end

    test "raises error with invalid configuration" do
      socket = create_socket(%{current_user: "john"})
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}

      assert_raise RuntimeError, ~r/Invalid shared prop config: "invalid"/, fn ->
        LiveVue.merge_socket_props(["invalid"], assigns)
      end

      assert_raise RuntimeError, ~r/Invalid shared prop config: \{:a, :b, :c\}/, fn ->
        LiveVue.merge_socket_props([{:a, :b, :c}], assigns)
      end
    end

    test "handles non-existent socket keys gracefully" do
      socket = create_socket(%{current_user: "john"})
      config = [:current_user, :non_existent_key, {:missing_key, :mapped_name}]
      assigns = %{"v-socket": socket, existing_prop: "value", __changed__: %{}}

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:current_user] == "john"
      assert result[:non_existent_key] == nil
      assert result[:mapped_name] == nil
      assert result[:existing_prop] == "value"
      assert result.__changed__ == %{}
    end

    test "keeps existing props when socket has given prop" do
      socket = create_socket(%{current_user: "socket_user", theme: "dark"})
      config = [:current_user, :theme]
      assigns = %{"v-socket": socket, current_user: "assigns_user", theme: "light", __changed__: %{}}

      result = LiveVue.merge_socket_props(config, assigns)

      assert result[:current_user] == "assigns_user"
      assert result[:theme] == "light"
      assert result.__changed__ == %{}
    end

    test "works with non-LiveView.Socket structs" do
      fake_socket = %{some: "data"}
      assigns = %{"v-socket": fake_socket, existing_prop: "value"}

      result = LiveVue.merge_socket_props([:current_user], assigns)

      # Should return unchanged since socket is not a Phoenix.LiveView.Socket
      assert result == assigns
    end
  end

  defp create_socket(assigns, previous_assigns \\ nil) do
    previous_assigns = if previous_assigns == nil, do: assigns, else: previous_assigns
    previous_assigns = Map.put(previous_assigns, :__changed__, %{})
    socket = %Socket{assigns: previous_assigns}

    socket =
      Enum.reduce(assigns, socket, fn {key, value}, acc ->
        # we're doing assigns using LiveView to make sure we're not breaking
        Phoenix.Component.assign(acc, key, value)
      end)

    %{socket | assigns: %AssignsNotInSocket{__assigns__: socket.assigns}}
  end
end
