defmodule LiveVueExamplesWeb.LiveCounter do
  use LiveVueExamplesWeb, :live_view
  @topic "shared_session"

  def render(assigns) do
    ~H"""
    <.header>LiveVue hybrid counter</.header>
    <.vue id="counter" count={@count} v-component="Counter" v-socket={@socket} v-ssr={true} v-on:inc={JS.push("inc")} />
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      LiveVueExamplesWeb.Endpoint.subscribe(@topic)
    end

    {:ok, assign(socket, :count, 0)}
  end

  def handle_event("inc", %{"value" => diff}, socket) do
    new_count = socket.assigns.count + diff
    LiveVueExamplesWeb.Endpoint.broadcast(@topic, "update_count", new_count)
    {:noreply, socket}
  end

  def handle_info(%{event: "update_count", payload: new_count}, socket) do
    # Update the count for all connected users
    {:noreply, assign(socket, :count, new_count)}
  end
end
