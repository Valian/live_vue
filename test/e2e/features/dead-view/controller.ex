defmodule LiveVue.E2E.DeadViewHTML do
  @moduledoc """
  HTML view module for dead view tests.
  """
  use Phoenix.Component
  use LiveVue

  def show(assigns) do
    ~H"""
    <h1>Dead View Test</h1>
    <p data-pw-server-message>{@message}</p>

    <.vue message={@message} v-component="dead-view/dead-view-test" id="dead-view-component" />
    """
  end
end

defmodule LiveVue.E2E.DeadViewController do
  @moduledoc """
  A regular Phoenix controller (not LiveView) to test Vue components in dead views.
  """
  use Phoenix.Controller, formats: [:html]

  def show(conn, _params) do
    conn
    |> put_layout(html: {LiveVue.E2E.Layout, :live})
    |> Plug.Conn.assign(:message, "Hello from dead view!")
    |> render(:show)
  end
end
