defmodule LiveVueExamplesWeb.PageController do
  use LiveVueExamplesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
