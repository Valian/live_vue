defmodule LiveVue.E2E.EventLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, message: "", event_count: 0)}
  end

  def handle_event("send_notification", %{"message" => message}, socket) do
    # Send a server event to the Vue component
    send(self(), {:broadcast_event, "notification", %{message: message, timestamp: :os.system_time(:millisecond)}})
    {:noreply, assign(socket, message: message, event_count: socket.assigns.event_count + 1)}
  end

  def handle_event("send_custom_event", %{"data" => data}, socket) do
    # Send a custom event with structured data
    send(self(), {:broadcast_event, "custom_event", %{data: data, count: socket.assigns.event_count + 1}})
    {:noreply, assign(socket, event_count: socket.assigns.event_count + 1)}
  end

  def handle_info({:broadcast_event, event_name, payload}, socket) do
    # Push the event to the client
    {:noreply, push_event(socket, event_name, payload)}
  end

  def render(assigns) do
    ~H"""
    <div id="event-test">
      <div id="message-display">Message: {@message}</div>
      <div id="event-count">Event Count: {@event_count}</div>
      <LiveVue.vue message={@message} event_count={@event_count} v-component="event_test" />
    </div>
    """
  end
end
