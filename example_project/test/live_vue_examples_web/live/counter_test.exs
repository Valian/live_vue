defmodule LiveVueExamplesWeb.CounterTest do
  use LiveVueExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "displays the count", %{conn: conn} do
    {:ok, view, html} = live(conn, "/counter")

    vue = LiveVue.Test.get_vue(html)
    assert vue.component == "Counter"
    assert vue.props["count"] == 10
    assert vue.ssr == false
    assert vue.handlers["inc"] == Phoenix.LiveView.JS.push("inc")

    render_hook(view, "inc", %{"value" => 2})

    vue = LiveVue.Test.get_vue(view)
    assert vue.props["count"] == 12
  end
end
