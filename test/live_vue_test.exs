defmodule LiveVueTest do
  use ExUnit.Case

  import LiveVue
  import Phoenix.Component
  import Phoenix.LiveViewTest

  doctest LiveVue

  def test_component(assigns) do
    ~H'<.vue name="John" surname="Doe" vue-component="MyComponent" />'
  end

  @tag :skip
  test "Render the html correctly" do
    assert render_component(&test_component/1) =~ "<h1>Hello John Doe</h1>"
  end
end
