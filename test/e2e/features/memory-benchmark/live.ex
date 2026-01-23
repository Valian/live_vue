defmodule LiveVue.E2E.MemoryBenchmarkLive do
  @moduledoc """
  LiveView for benchmarking memory usage with Vue components.
  Allows dynamically adjusting the number of items in props.

  run via:
  npm run e2e:build && npm run e2e:server && open http://localhost:4004/memory-benchmark
  """
  use Phoenix.LiveView

  @initial_count 10

  def render(assigns) do
    ~H"""
    <div class="memory-benchmark">
      <h1>Memory Benchmark</h1>
      <LiveVue.vue
        items={@items}
        memory={@memory}
        v-component="memory-benchmark/item-list"
        id="item-list"
        v-socket={@socket}
      />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, items: generate_items(@initial_count), memory: nil)

    if connected?(socket) do
      request_memory_measurement()
    end

    {:ok, socket}
  end

  def handle_event("set_count", %{"count" => count}, socket) do
    count = String.to_integer(count)
    socket = assign(socket, items: generate_items(count))
    request_memory_measurement()
    {:noreply, socket}
  end

  def handle_event("add_items", %{"count" => count}, socket) do
    count = String.to_integer(count)
    current_items = socket.assigns.items
    new_items = generate_items(count, length(current_items))
    socket = assign(socket, items: current_items ++ new_items)
    request_memory_measurement()
    {:noreply, socket}
  end

  def handle_event("clear_items", _params, socket) do
    socket = assign(socket, items: [])
    request_memory_measurement()
    {:noreply, socket}
  end

  def handle_event("refresh_memory", _params, socket) do
    request_memory_measurement()
    {:noreply, socket}
  end

  defp generate_items(count, start_id \\ 0) do
    for i <- 0..(count - 1) do
      %{
        id: start_id + i,
        name: "Item #{start_id + i}",
        description: "This is a description for item #{start_id + i} with some extra text to take up memory",
        tags: ["tag-#{rem(i, 5)}", "category-#{rem(i, 3)}", "type-#{rem(i, 7)}"],
        metadata: %{
          extra_field_1: "value-#{i}",
          extra_field_2: i * 100,
          extra_field_3: rem(i, 2) == 0
        }
      }
    end
  end

  def handle_info({:memory_measured, memory}, socket) do
    {:noreply, assign(socket, memory: memory)}
  end

  # Spawn a task to measure memory from outside the process
  defp request_memory_measurement do
    parent = self()

    Task.start_link(fn ->
      # GC the target process first
      :erlang.garbage_collect(parent)

      # Now we can safely call :sys.get_state from outside
      full_state = :sys.get_state(parent)
      memory = measure_state(full_state)
      send(parent, {:memory_measured, memory})
    end)
  end

  defp measure_state(full_state) do
    word_size = :erlang.system_info(:wordsize)

    # Full channel state
    total_words = :erts_debug.size(full_state)
    total_flat_words = :erts_debug.flat_size(full_state)

    # Components tuple: {cid_to_component, id_to_cid, uuids}
    components = Map.get(full_state, :components, {%{}, %{}, 0})
    components_words = :erts_debug.size(components)
    components_flat_words = :erts_debug.flat_size(components)

    # Socket and assigns
    socket = Map.get(full_state, :socket)
    socket_words = :erts_debug.size(socket)
    assigns = if socket, do: socket.assigns, else: %{}
    assigns_words = :erts_debug.size(assigns)

    # Items specifically
    items = if assigns, do: Map.get(assigns, :items, []), else: []
    items_words = :erts_debug.size(items)
    items_flat_words = :erts_debug.flat_size(items)

    %{
      # Total state
      total_bytes: total_words * word_size,
      total_kb: Float.round(total_words * word_size / 1024, 2),
      total_flat_bytes: total_flat_words * word_size,
      sharing_bytes: (total_flat_words - total_words) * word_size,
      # Components (LiveComponent state)
      components_bytes: components_words * word_size,
      components_flat_bytes: components_flat_words * word_size,
      components_sharing_bytes: (components_flat_words - components_words) * word_size,
      # Socket & assigns
      socket_bytes: socket_words * word_size,
      assigns_bytes: assigns_words * word_size,
      # Items
      items_bytes: items_words * word_size,
      items_flat_bytes: items_flat_words * word_size,
      items_kb: Float.round(items_words * word_size / 1024, 2)
    }
  end
end
