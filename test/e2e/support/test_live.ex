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
    <LiveVue.vue count={@counter} v-component="counter" v-socket={@socket} />
    """
  end
end

defmodule LiveVue.E2E.NavigationLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(params, _session, socket) do
    {:ok, assign(socket, params: params, query_params: %{})}
  end

  def handle_params(params, uri, socket) do
    query_params = URI.parse(uri).query
    parsed_query = if query_params, do: URI.decode_query(query_params), else: %{}
    {:noreply, assign(socket, params: params, query_params: parsed_query)}
  end

  def render(assigns) do
    ~H"""
    <div id="navigation-test">
      <LiveVue.vue params={@params} query_params={@query_params} v-component="navigation" v-socket={@socket} />
    </div>
    """
  end
end

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
      <LiveVue.vue message={@message} event_count={@event_count} v-component="event_test" v-socket={@socket} />
    </div>
    """
  end
end

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
      <div id="message-display">Message: <%= @message %></div>
      <div id="event-count">Event Count: <%= @event_count %></div>
      <LiveVue.vue 
        message={@message}
        event_count={@event_count}
        v-component="event_test" 
        v-socket={@socket} />
    </div>
    """
  end
end
