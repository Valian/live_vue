defmodule LiveVue.E2E.StreamLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div id="stream-test">
      <LiveVue.vue items={@streams.items} v-component="stream_test" v-socket={@socket} />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Initialize with some sample items
    items = [
      %{id: 1, name: "Item 1", description: "First item"},
      %{id: 2, name: "Item 2", description: "Second item"},
      %{id: 3, name: "Item 3", description: "Third item"}
    ]

    socket =
      socket
      |> stream_configure(:items, dom_id: &"songs-#{&1.id}")
      |> stream(:items, items)
      |> assign(:next_id, 4)

    {:ok, socket}
  end

  def handle_event("add_item", %{"name" => name, "description" => description}, socket) do
    new_item = %{
      id: socket.assigns.next_id,
      name: name,
      description: description
    }

    socket =
      socket
      |> stream_insert(:items, new_item)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end

  def handle_event("remove_item", %{"id" => id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :items, "songs-#{id}")}
  end

  def handle_event("clear_stream", _params, socket) do
    # Reset the stream with empty list
    socket =
      socket
      |> stream(:items, [], reset: true)
      |> assign(:next_id, 1)

    {:noreply, socket}
  end

  def handle_event("reset_stream", _params, socket) do
    # Reset with initial items
    items = [
      %{id: 1, name: "Item 1", description: "First item"},
      %{id: 2, name: "Item 2", description: "Second item"},
      %{id: 3, name: "Item 3", description: "Third item"}
    ]

    socket =
      socket
      |> stream(:items, items, at: -1, reset: true)
      |> assign(:next_id, 4)

    {:noreply, socket}
  end

  def handle_event("reset_stream_at_0", _params, socket) do
    # Reset with initial items
    items = [
      %{id: 1, name: "Item 1", description: "First item"},
      %{id: 2, name: "Item 2", description: "Second item"},
      %{id: 3, name: "Item 3", description: "Third item"}
    ]

    socket =
      socket
      |> stream(:items, items, at: 0, reset: true)
      |> assign(:next_id, 4)

    {:noreply, socket}
  end

  def handle_event("add_multiple_start", _params, socket) do
    # Add multiple items at the start with positive limit (keep first 5 items)
    new_items = [
      %{id: socket.assigns.next_id, name: "Start Item A", description: "Added at start A"},
      %{id: socket.assigns.next_id + 1, name: "Start Item B", description: "Added at start B"},
      %{id: socket.assigns.next_id + 2, name: "Start Item C", description: "Added at start C"}
    ]

    socket =
      socket
      |> stream(:items, new_items, at: 0, limit: 5)
      |> assign(:next_id, socket.assigns.next_id + 3)

    {:noreply, socket}
  end

  def handle_event("add_multiple_end", _params, socket) do
    # Add multiple items at the end with negative limit (keep last 5 items)
    new_items = [
      %{id: socket.assigns.next_id, name: "End Item X", description: "Added at end X"},
      %{id: socket.assigns.next_id + 1, name: "End Item Y", description: "Added at end Y"},
      %{id: socket.assigns.next_id + 2, name: "End Item Z", description: "Added at end Z"}
    ]

    socket =
      socket
      |> stream(:items, new_items, at: -1, limit: -5)
      |> assign(:next_id, socket.assigns.next_id + 3)

    {:noreply, socket}
  end

  def handle_event("add_with_positive_limit", %{"limit" => limit_str}, socket) do
    limit = String.to_integer(limit_str)

    new_item = %{
      id: socket.assigns.next_id,
      name: "Limited Item +#{limit}",
      description: "Added with positive limit #{limit}"
    }

    socket =
      socket
      |> stream_insert(:items, new_item, at: 0, limit: limit)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end

  def handle_event("add_with_negative_limit", %{"limit" => limit_str}, socket) do
    # Make it negative
    limit = String.to_integer(limit_str) * -1

    new_item = %{
      id: socket.assigns.next_id,
      name: "Limited Item #{limit}",
      description: "Added with negative limit #{limit}"
    }

    socket =
      socket
      |> stream_insert(:items, new_item, limit: limit)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end
end
