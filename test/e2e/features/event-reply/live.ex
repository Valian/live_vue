defmodule LiveVue.E2E.EventReplyTestLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div>
      <h1>Event Reply Test</h1>
      <div id="server-state">
        <div id="counter">Counter: {@counter}</div>
        <div id="user-data">User: {@user_name || "none"}</div>
        <div id="last-message">Last message: {@last_message || "none"}</div>
      </div>

      <LiveVue.vue
        id="event-reply-component"
        counter={@counter}
        v-component="event_reply_test"
        v-socket={@socket}
      />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:counter, 0)
     |> assign(:user_name, nil)
     |> assign(:last_message, nil)}
  end

  # Simple increment event that returns the new value
  def handle_event("increment", %{"by" => by}, socket) do
    new_counter = socket.assigns.counter + by
    socket = assign(socket, :counter, new_counter)
    {:reply, %{counter: new_counter, timestamp: DateTime.utc_now()}, socket}
  end

  # Get user data event that simulates fetching user info
  def handle_event("get-user", %{"id" => user_id}, socket) do
    # Simulate different user responses based on ID
    user_data =
      case user_id do
        1 -> %{id: 1, name: "John Doe", email: "john@example.com"}
        2 -> %{id: 2, name: "Jane Smith", email: "jane@example.com"}
        _ -> %{id: user_id, name: "Unknown User", email: "unknown@example.com"}
      end

    socket = assign(socket, :user_name, user_data.name)
    {:reply, user_data, socket}
  end

  # Event that simulates server error
  def handle_event("error-event", _params, socket) do
    # Return an error response
    {:reply, %{error: "Something went wrong on the server"}, socket}
  end

  # Event that simulates slow response (for cancel testing)
  def handle_event("slow-event", %{"delay" => delay}, socket) do
    # Simulate processing delay
    Process.sleep(delay)
    message = "Slow response after #{delay}ms"
    socket = assign(socket, :last_message, message)
    {:reply, %{message: message, completed_at: DateTime.utc_now()}, socket}
  end

  # Event without parameters
  def handle_event("ping", _params, socket) do
    message = "pong at #{DateTime.utc_now()}"
    socket = assign(socket, :last_message, message)
    {:reply, %{response: "pong", timestamp: DateTime.utc_now()}, socket}
  end

  # Event that returns different data types (wrapped in maps since only maps can be returned)
  def handle_event("get-data-type", %{"type" => type}, socket) do
    response =
      case type do
        "string" -> %{data: "Hello World"}
        "number" -> %{data: 42}
        "boolean" -> %{data: true}
        "array" -> %{data: [1, 2, 3, "four", true]}
        "object" -> %{data: %{nested: %{value: "test"}, count: 5}}
        "null" -> %{data: nil}
        _ -> %{data: "unknown type"}
      end

    {:reply, response, socket}
  end

  # Event that validates parameters and returns errors
  def handle_event("validate-input", %{"input" => input}, socket) do
    cond do
      String.length(input) < 3 ->
        {:reply, %{valid: false, error: "Input too short"}, socket}

      String.length(input) > 20 ->
        {:reply, %{valid: false, error: "Input too long"}, socket}

      true ->
        {:reply, %{valid: true, message: "Input is valid"}, socket}
    end
  end

  # Event that doesn't return a reply (should timeout or error)
  def handle_event("no-reply", _params, socket) do
    {:noreply, socket}
  end
end
