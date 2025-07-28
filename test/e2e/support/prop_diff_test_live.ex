defmodule LiveVue.E2E.PropDiffTestLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    initial_data = %{
      simple_string: "hello",
      simple_number: 42,
      simple_boolean: true,
      simple_list: ["a", "b", "c"],
      simple_map: %{key1: "value1", key2: "value2"},
      nested_data: %{
        user: %{name: "John", age: 30},
        settings: %{theme: "dark", notifications: true}
      },
      list_of_maps: [
        %{id: 1, name: "Alice", role: "admin"},
        %{id: 2, name: "Bob", role: "user"}
      ]
    }

    {:ok, assign(socket, :data, initial_data)}
  end

  def handle_event("set_simple_string", %{"new" => value}, socket) do
    {:noreply, update(socket, :data, &Map.put(&1, :simple_string, value))}
  end

  def handle_event("set_simple_number", %{"new" => value}, socket) do
    {:noreply, update(socket, :data, &Map.put(&1, :simple_number, String.to_integer(value)))}
  end

  def handle_event("set_simple_boolean", %{"new" => value}, socket) do
    {:noreply, update(socket, :data, &Map.put(&1, :simple_boolean, String.to_existing_atom(value)))}
  end

  def handle_event("add_to_list", %{"new" => value}, socket) do
    {:noreply, update(socket, :data, &Map.put(&1, :simple_list, &1.simple_list ++ [value]))}
  end

  def handle_event("remove_from_list", %{"index" => index}, socket) do
    {:noreply,
     update(socket, :data, &Map.put(&1, :simple_list, List.delete_at(&1.simple_list, String.to_integer(index))))}
  end

  def handle_event("replace_in_list", %{"index" => index, "new" => value}, socket) do
    {:noreply,
     update(socket, :data, &Map.put(&1, :simple_list, List.replace_at(&1.simple_list, String.to_integer(index), value)))}
  end

  def handle_event("add_to_map", %{"key" => key, "new" => value}, socket) do
    {:noreply, update(socket, :data, &Map.put(&1, :simple_map, Map.put(&1.simple_map, String.to_atom(key), value)))}
  end

  def handle_event("remove_from_map", %{"key" => key}, socket) do
    {:noreply,
     update(socket, :data, &Map.put(&1, :simple_map, Map.delete(&1.simple_map, String.to_existing_atom(key))))}
  end

  def handle_event("change_nested_user_name", %{"new" => value}, socket) do
    {:noreply, update(socket, :data, &put_in(&1, [:nested_data, :user, :name], value))}
  end

  def handle_event("change_nested_user_age", %{"new" => value}, socket) do
    {:noreply, update(socket, :data, &put_in(&1, [:nested_data, :user, :age], String.to_integer(value)))}
  end

  def handle_event("add_nested_setting", %{"key" => key, "new" => value}, socket) do
    {:noreply, update(socket, :data, &put_in(&1, [:nested_data, :settings, String.to_atom(key)], value))}
  end

  def handle_event("set_to_nil", %{"key" => key}, socket) do
    {:noreply, update(socket, :data, &Map.put(&1, String.to_existing_atom(key), nil))}
  end

  def handle_event("add_list_item", %{"name" => name, "role" => role}, socket) do
    {:noreply,
     update(socket, :data, fn data ->
       new_id = Enum.max_by(data.list_of_maps, & &1.id).id + 1
       new_item = %{id: new_id, name: name, role: role}
       Map.put(data, :list_of_maps, data.list_of_maps ++ [new_item])
     end)}
  end

  def handle_event("update_list_item", %{"id" => id, "name" => name}, socket) do
    {:noreply,
     update(socket, :data, fn data ->
       new_list =
         Enum.map(data.list_of_maps, fn item ->
           if item.id == String.to_integer(id) do
             %{item | name: name}
           else
             item
           end
         end)

       Map.put(data, :list_of_maps, new_list)
     end)}
  end

  def handle_event("remove_list_item", %{"id" => id}, socket) do
    {:noreply,
     update(
       socket,
       :data,
       &Map.put(&1, :list_of_maps, Enum.reject(&1.list_of_maps, fn item -> item.id == String.to_integer(id) end))
     )}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Prop Diff Test LiveView</h1>
      <LiveVue.vue data={@data} v-component="prop-display" v-socket={@socket} />
      
    <!-- Test Controls -->
      <div class="mt-8 space-y-4">
        <h2>Test Controls</h2>

        <div>
          <button phx-click="set_simple_string" phx-value-new="changed" data-testid="btn-change-string">
            Change String
          </button>
        </div>

        <div>
          <button phx-click="set_simple_number" phx-value-new="99" data-testid="btn-change-number">
            Change Number
          </button>
        </div>

        <div>
          <button
            phx-click="set_simple_boolean"
            phx-value-new={to_string(!@data.simple_boolean)}
            data-testid="btn-toggle-boolean"
          >
            Toggle Boolean
          </button>
        </div>

        <div>
          <button phx-click="add_to_list" phx-value-new="d" data-testid="btn-add-to-list">
            Add to List
          </button>
        </div>

        <div>
          <button phx-click="remove_from_list" phx-value-index="0" data-testid="btn-remove-from-list">
            Remove First from List
          </button>
        </div>

        <div>
          <button phx-click="replace_in_list" phx-value-index="1" phx-value-new="REPLACED" data-testid="btn-replace-in-list">
            Replace Second in List
          </button>
        </div>

        <div>
          <button phx-click="add_to_map" phx-value-key="key3" phx-value-new="value3" data-testid="btn-add-to-map">
            Add to Map
          </button>
        </div>

        <div>
          <button phx-click="remove_from_map" phx-value-key="key1" data-testid="btn-remove-from-map">
            Remove from Map
          </button>
        </div>

        <div>
          <button phx-click="change_nested_user_name" phx-value-new="Jane" data-testid="btn-change-nested-name">
            Change Nested User Name
          </button>
        </div>

        <div>
          <button phx-click="change_nested_user_age" phx-value-new="25" data-testid="btn-change-nested-age">
            Change Nested User Age
          </button>
        </div>

        <div>
          <button
            phx-click="add_nested_setting"
            phx-value-key="language"
            phx-value-new="en"
            data-testid="btn-add-nested-setting"
          >
            Add Nested Setting
          </button>
        </div>

        <div>
          <button phx-click="set_to_nil" phx-value-key="simple_string" data-testid="btn-set-nil">
            Set String to Nil
          </button>
        </div>

        <div>
          <button phx-click="add_list_item" phx-value-name="Charlie" phx-value-role="guest" data-testid="btn-add-list-item">
            Add List Item
          </button>
        </div>

        <div>
          <button
            phx-click="update_list_item"
            phx-value-id="1"
            phx-value-name="Alice Updated"
            data-testid="btn-update-list-item"
          >
            Update List Item
          </button>
        </div>

        <div>
          <button phx-click="remove_list_item" phx-value-id="2" data-testid="btn-remove-list-item">
            Remove List Item
          </button>
        </div>
      </div>
    </div>
    """
  end
end
