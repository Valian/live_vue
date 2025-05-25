# Building Your First LiveVue App

This tutorial will guide you through building a complete todo application using LiveVue, demonstrating key concepts and best practices along the way.

## What You'll Build

By the end of this tutorial, you'll have a fully functional todo app with:
- Add/remove todos
- Mark todos as complete
- Filter todos (all, active, completed)
- Real-time updates across browser tabs
- Smooth Vue transitions

## Prerequisites

- Completed [Installation](installation.html)
- Basic familiarity with Phoenix LiveView
- Basic Vue.js knowledge (helpful but not required)

## Step 1: Create the LiveView

First, let's create our todo LiveView:

```elixir
# lib/my_app_web/live/todo_live.ex
defmodule MyAppWeb.TodoLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    todos = [
      %{id: 1, text: "Learn LiveVue", completed: false},
      %{id: 2, text: "Build awesome apps", completed: false}
    ]

    socket =
      socket
      |> assign(:todos, todos)
      |> assign(:filter, :all)
      |> assign(:next_id, 3)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto mt-8">
      <h1 class="text-2xl font-bold mb-4">LiveVue Todos</h1>

      <.vue
        todos={@todos}
        filter={@filter}
        v-component="TodoApp"
        v-socket={@socket}
        v-on:add-todo={JS.push("add_todo")}
        v-on:toggle-todo={JS.push("toggle_todo")}
        v-on:remove-todo={JS.push("remove_todo")}
        v-on:set-filter={JS.push("set_filter")}
      />
    </div>
    """
  end

  # Event handlers
  def handle_event("add_todo", %{"text" => text}, socket) when text != "" do
    new_todo = %{
      id: socket.assigns.next_id,
      text: text,
      completed: false
    }

    socket =
      socket
      |> update(:todos, &[new_todo | &1])
      |> update(:next_id, &(&1 + 1))

    {:noreply, socket}
  end

  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todos = Enum.map(socket.assigns.todos, fn todo ->
      if todo.id == id do
        %{todo | completed: !todo.completed}
      else
        todo
      end
    end)

    {:noreply, assign(socket, :todos, todos)}
  end

  def handle_event("remove_todo", %{"id" => id}, socket) do
    todos = Enum.reject(socket.assigns.todos, &(&1.id == id))
    {:noreply, assign(socket, :todos, todos)}
  end

  def handle_event("set_filter", %{"filter" => filter}, socket) do
    filter_atom = String.to_existing_atom(filter)
    {:noreply, assign(socket, :filter, filter_atom)}
  end
end
```

## Step 2: Create the Vue Component

Now let's create our main Vue component:

```html
<!-- assets/vue/TodoApp.vue -->
<script setup lang="ts">
import { ref, computed } from 'vue'

interface Todo {
  id: number
  text: string
  completed: boolean
}

const props = defineProps<{
  todos: Todo[]
  filter: 'all' | 'active' | 'completed'
}>()

const emit = defineEmits<{
  'add-todo': [{ text: string }]
  'toggle-todo': [{ id: number }]
  'remove-todo': [{ id: number }]
  'set-filter': [{ filter: string }]
}>()

const newTodoText = ref('')

const filteredTodos = computed(() => {
  switch (props.filter) {
    case 'active':
      return props.todos.filter(todo => !todo.completed)
    case 'completed':
      return props.todos.filter(todo => todo.completed)
    default:
      return props.todos
  }
})

const addTodo = () => {
  if (newTodoText.value.trim()) {
    emit('add-todo', { text: newTodoText.value.trim() })
    newTodoText.value = ''
  }
}

const toggleTodo = (id: number) => {
  emit('toggle-todo', { id })
}

const removeTodo = (id: number) => {
  emit('remove-todo', { id })
}

const setFilter = (filter: string) => {
  emit('set-filter', { filter })
}
</script>

<template>
  <div class="space-y-4">
    <!-- Add Todo Form -->
    <form @submit.prevent="addTodo" class="flex gap-2">
      <input
        v-model="newTodoText"
        type="text"
        placeholder="What needs to be done?"
        class="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <button
        type="submit"
        class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        Add
      </button>
    </form>

    <!-- Filter Buttons -->
    <div class="flex gap-2">
      <button
        v-for="filterOption in ['all', 'active', 'completed']"
        :key="filterOption"
        @click="setFilter(filterOption)"
        :class="[
          'px-3 py-1 rounded-md text-sm',
          filter === filterOption
            ? 'bg-blue-500 text-white'
            : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
        ]"
      >
        {{ filterOption.charAt(0).toUpperCase() + filterOption.slice(1) }}
      </button>
    </div>

    <!-- Todo List -->
    <TransitionGroup
      name="todo"
      tag="ul"
      class="space-y-2"
    >
      <li
        v-for="todo in filteredTodos"
        :key="todo.id"
        class="flex items-center gap-3 p-3 bg-white border border-gray-200 rounded-md shadow-sm"
      >
        <input
          type="checkbox"
          :checked="todo.completed"
          @change="toggleTodo(todo.id)"
          class="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
        />
        <span
          :class="[
            'flex-1',
            todo.completed ? 'line-through text-gray-500' : 'text-gray-900'
          ]"
        >
          {{ todo.text }}
        </span>
        <button
          @click="removeTodo(todo.id)"
          class="px-2 py-1 text-red-600 hover:bg-red-50 rounded"
        >
          ✕
        </button>
      </li>
    </TransitionGroup>

    <!-- Empty State -->
    <div
      v-if="filteredTodos.length === 0"
      class="text-center py-8 text-gray-500"
    >
      <p v-if="filter === 'all'">No todos yet. Add one above!</p>
      <p v-else>No {{ filter }} todos.</p>
    </div>
  </div>
</template>

<style scoped>
.todo-enter-active,
.todo-leave-active {
  transition: all 0.3s ease;
}

.todo-enter-from {
  opacity: 0;
  transform: translateX(-30px);
}

.todo-leave-to {
  opacity: 0;
  transform: translateX(30px);
}

.todo-move {
  transition: transform 0.3s ease;
}
</style>
```

## Step 3: Add the Route

Add the route to your router:

```elixir
# lib/my_app_web/router.ex
scope "/", MyAppWeb do
  pipe_through :browser

  live "/todos", TodoLive
  # ... other routes
end
```

## Step 4: Test Your App

1. Start your server: `mix phx.server`
2. Visit `http://localhost:4000/todos`
3. Try adding, completing, and filtering todos
4. Open multiple browser tabs to see real-time updates!

## Key Concepts Demonstrated

### 1. Props Flow
LiveView manages the authoritative state (`todos`, `filter`) and passes it to Vue as props.

### 2. Event Handling
Vue emits events that are handled by LiveView using the `v-on:` syntax.

### 3. Local UI State
Vue manages local form state (`newTodoText`) that doesn't need server persistence.

### 4. Computed Properties
Vue's `computed` provides efficient filtering without server round-trips.

### 5. Transitions
Vue's transition system provides smooth animations for list changes.

## Next Steps

Now that you've built your first LiveVue app, explore:

- [Basic Usage](basic_usage.html) for more patterns
- [Advanced Features](advanced_features.html) for complex scenarios
- [Testing](testing.html) to add tests to your todo app

## Troubleshooting

**Component not rendering?**
- Check that the component name matches the file name
- Verify `v-socket={@socket}` is present
- Check browser console for errors

**Events not working?**
- Ensure event names match between Vue `emit` and LiveView `v-on:`
- Check that event handlers are defined in LiveView
- Verify payload structure matches expectations

**Styling issues?**
- Ensure Tailwind is configured to scan Vue files
- Check that CSS classes are being applied correctly
- Use browser dev tools to inspect generated HTML