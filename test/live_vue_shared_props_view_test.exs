defmodule LiveVue.SharedPropsViewTest do
  use ExUnit.Case, async: true

  alias LiveVue.SharedPropsView

  @shared_props [
    :flash,
    :workspaces,
    {[:streams, :workspace_notifications], :workspace_notifications},
    {[:current_scope, :user], :user},
    {[:current_scope, :user, :is_admin], :is_admin},
    {:current_user, :current_user}
  ]

  describe "inject_shared_props_in_vue/2" do
    test "injects shared attrs into .vue component" do
      input = """
      <.vue
        posts={@posts}
        v-component="posts"
        v-socket={@socket}
      />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, @shared_props)

      assert output =~ "flash={get_in(assigns, [:flash])}"
      assert output =~ "workspaces={get_in(assigns, [:workspaces])}"
      assert output =~ "workspace_notifications={get_in(assigns, [:streams, :workspace_notifications])}"
      assert output =~ "user={get_in(assigns, [:current_scope, :user])}"
      assert output =~ "is_admin={get_in(assigns, [:current_scope, :user, :is_admin])}"
      assert output =~ "current_user={get_in(assigns, [:current_user])}"
    end

    test "does not duplicate attrs that already exist" do
      input = """
      <.vue
        flash={@flash}
        workspaces={@workspaces}
        v-component="posts"
        v-socket={@socket}
      />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, @shared_props)

      # flash and workspaces should appear exactly once (the original)
      assert output |> String.split("flash={@flash}") |> length() == 2
      assert output |> String.split("workspaces={@workspaces}") |> length() == 2
      # but other shared props should still be injected
      assert output =~ "user={get_in(assigns, [:current_scope, :user])}"
    end

    test "leaves non-vue tags unchanged" do
      input = """
      <div>
        hello
      </div>
      """

      assert SharedPropsView.inject_shared_props_in_vue(input, @shared_props) == input
    end

    test "handles multiple .vue tags" do
      input = """
      <.vue v-component="A" v-socket={@socket} />
      <.vue v-component="B" v-socket={@socket} />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, @shared_props)

      # Each tag should get shared props
      assert output |> String.split("flash={get_in(assigns, [:flash])}") |> length() == 3
    end

    test "handles non-self-closing .vue tags" do
      input = """
      <.vue v-component="Slotted" v-socket={@socket}>
        <:default>content</:default>
      </.vue>
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, @shared_props)

      assert output =~ "flash={get_in(assigns, [:flash])}"
    end

    test "returns template unchanged when shared_props is empty" do
      input = """
      <.vue v-component="A" v-socket={@socket} />
      """

      assert SharedPropsView.inject_shared_props_in_vue(input, []) == input
    end
  end

  describe "shared_prop_to_attr!/1" do
    test "simple atom prop" do
      assert SharedPropsView.shared_prop_to_attr!(:flash) ==
               {"flash", "get_in(assigns, [:flash])"}
    end

    test "source/target tuple" do
      assert SharedPropsView.shared_prop_to_attr!({:current_user, :user}) ==
               {"user", "get_in(assigns, [:current_user])"}
    end

    test "nested path tuple" do
      assert SharedPropsView.shared_prop_to_attr!({[:scope, :user], :user}) ==
               {"user", "get_in(assigns, [:scope, :user])"}
    end

    test "raises on invalid entry" do
      assert_raise ArgumentError, ~r/invalid entry/, fn ->
        SharedPropsView.shared_prop_to_attr!("invalid")
      end
    end

    test "raises on non-atom path elements" do
      assert_raise ArgumentError, ~r/expected list of atoms/, fn ->
        SharedPropsView.shared_prop_to_attr!({["string", :atom], :target})
      end
    end
  end
end
