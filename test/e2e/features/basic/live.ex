defmodule LiveVue.E2E.TestLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :counter, 0)}
  end

  def handle_event("increment", %{"value" => value}, socket) do
    {:noreply, assign(socket, :counter, socket.assigns.counter + value)}
  end

  def render(assigns) do
    ~H"""
    <LiveVue.vue count={@counter} v-component="counter" />
    """
  end
end
