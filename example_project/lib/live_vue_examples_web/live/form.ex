defmodule LiveVueExamplesWeb.LiveForm do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>Form example - TODO</.header>
    <.FormExample data={@data} v-on:save={JS.push("save")} v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: %{})}
  end

  def handle_event("save", %{} = params, socket) do
    {:noreply, assign(socket, :data, params)}
  end
end
