defmodule LiveVue.E2E.ReconnectLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    items = [
      %{id: 1, name: "Alpha"},
      %{id: 2, name: "Beta"},
      %{id: 3, name: "Gamma"}
    ]

    socket =
      socket
      |> assign(count: 0, label: "initial")
      |> stream(:items, items)

    {:ok, socket}
  end

  def handle_event("update", _, socket) do
    socket =
      socket
      |> assign(count: socket.assigns.count + 1, label: "updated")
      |> stream_insert(:items, %{id: 4, name: "Delta"})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <LiveVue.vue
      count={@count}
      label={@label}
      items={@streams.items}
      v-component="reconnect/display"
      v-socket={@socket}
    />
    """
  end
end
