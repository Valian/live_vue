defmodule LiveVue.E2E.ReconnectLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, label: "initial")}
  end

  def handle_event("update", _, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1, label: "updated")}
  end

  def render(assigns) do
    ~H"""
    <LiveVue.vue count={@count} label={@label} v-component="reconnect/display" v-socket={@socket} />
    """
  end
end
