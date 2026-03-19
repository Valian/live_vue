defmodule LiveVue.SharedPropsImportedComponent do
  @moduledoc false
  @live_vue_shortcuts ["counter"]

  def __live_vue_shortcuts__, do: @live_vue_shortcuts
  def counter(assigns), do: assigns
end

defmodule LiveVue.SharedPropsRegularComponent do
  @moduledoc false
  def counter(assigns), do: assigns
end

defmodule LiveVue.SharedPropsImportedCaller do
  @moduledoc false
  import LiveVue.SharedPropsImportedComponent

  def env, do: __ENV__
  def sample(assigns \\ %{}), do: counter(assigns)
end

defmodule LiveVue.SharedPropsRegularCaller do
  @moduledoc false
  import LiveVue.SharedPropsRegularComponent

  def env, do: __ENV__
  def sample(assigns \\ %{}), do: counter(assigns)
end

defmodule LiveVue.SharedPropsSameModuleCaller do
  @moduledoc false
  use LiveVue.Components, vue_root: ["./test/e2e/features/basic"]

  import LiveVue.SharedPropsView, only: [sigil_H: 2]

  def env, do: __ENV__

  def render(assigns) do
    ~H"""
    <.counter />
    """
  end
end

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

    test "injects v-socket automatically" do
      input = """
      <.vue v-component="A" />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, [])

      assert output =~ "v-socket={get_in(assigns, [:socket])}"
    end

    test "does not duplicate v-socket when already present" do
      input = """
      <.vue v-component="A" v-socket={@socket} />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, [])

      refute output =~ "get_in(assigns, [:socket])"
      assert output |> String.split("v-socket") |> length() == 2
    end

    test "injects both v-socket and shared props" do
      input = """
      <.vue v-component="A" />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, [:flash])

      assert output =~ "v-socket={get_in(assigns, [:socket])}"
      assert output =~ "flash={get_in(assigns, [:flash])}"
    end

    test "preserves > inside quoted attrs" do
      input = """
      <.vue v-component="A" label="a > b" />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, [:flash])

      assert output =~ ~s(label="a > b")
      assert output =~ "v-socket={get_in(assigns, [:socket])}"
      assert output =~ "flash={get_in(assigns, [:flash])}"
    end

    test "preserves > inside expressions" do
      input = """
      <.vue v-component="A" cond={1 > 0} message={if true, do: "a > b", else: "c"} />
      """

      output = SharedPropsView.inject_shared_props_in_vue(input, [:flash])

      assert output =~ "cond={1 > 0}"
      assert output =~ ~s(message={if true, do: "a > b", else: "c"})
      assert output =~ "v-socket={get_in(assigns, [:socket])}"
      assert output =~ "flash={get_in(assigns, [:flash])}"
    end
  end

  describe "inject_shared_props_in_vue/3" do
    test "injects shared attrs into imported LiveVue shortcut components" do
      input = """
      <.counter count={@count} />
      """

      output =
        SharedPropsView.inject_shared_props_in_vue(
          input,
          [:flash],
          LiveVue.SharedPropsImportedCaller.env()
        )

      assert output =~ "v-socket={get_in(assigns, [:socket])}"
      assert output =~ "flash={get_in(assigns, [:flash])}"
    end

    test "injects shared attrs into same-module shortcut components generated by LiveVue.Components" do
      input = """
      <.counter count={@count} />
      """

      output =
        SharedPropsView.inject_shared_props_in_vue(
          input,
          [:flash],
          LiveVue.SharedPropsSameModuleCaller.env()
        )

      assert output =~ "v-socket={get_in(assigns, [:socket])}"
      assert output =~ "flash={get_in(assigns, [:flash])}"
    end

    test "does not inject into regular imported function components" do
      input = """
      <.counter count={@count} />
      """

      assert SharedPropsView.inject_shared_props_in_vue(
               input,
               [:flash],
               LiveVue.SharedPropsRegularCaller.env()
             ) == input
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
