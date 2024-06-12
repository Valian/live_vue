defmodule LiveVueExamplesWeb.ErrorJSONTest do
  use LiveVueExamplesWeb.ConnCase, async: true

  test "renders 404" do
    assert LiveVueExamplesWeb.ErrorJSON.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert LiveVueExamplesWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
