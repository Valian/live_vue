defmodule LiveVueExamplesWeb.PageController do
  use LiveVueExamplesWeb, :controller

  def home(conn, _params), do: render(conn, :home)
  def dead(conn, _params), do: render(conn, :dead)
end
