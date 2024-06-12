defmodule LiveVueExamplesWeb.LiveCounter do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>LiveVue hybrid counter</.header>
    <.vue id="counter" count={@count} v-component="Counter" v-socket={@socket} v-ssr={true} v-on:inc={JS.push("inc")} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 10)}
  end

  def handle_event("inc", %{"value" => diff}, socket) do
    socket = update(socket, :count, &(&1 + diff * 2))

    {:noreply, socket}
  end
end
