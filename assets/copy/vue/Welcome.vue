<script setup lang="ts">
import { ref, computed } from "vue"

// Props from LiveView - server state
const props = defineProps<{
  todos: Array<{ id: number; text: string; completed: boolean }>
  user_name?: string
  total_count: number
}>()

// Local client-side state
const newTodo = ref("")
const filter = ref<"all" | "active" | "completed">("all")

// Computed properties for reactive UI
const greeting = computed(() => (props.user_name ? `Welcome back, ${props.user_name}!` : "Welcome to LiveVue!"))

const filteredTodos = computed(() => {
  switch (filter.value) {
    case "active":
      return props.todos.filter(todo => !todo.completed)
    case "completed":
      return props.todos.filter(todo => todo.completed)
    default:
      return props.todos
  }
})

const activeCount = computed(() => props.todos.filter(todo => !todo.completed).length)

// Event handler for form submission
const addTodo = () => {
  if (newTodo.value.trim()) {
    newTodo.value = ""
  }
}
</script>

<template>
  <div class="hero min-h-screen">
    <div class="hero-content text-center">
      <div class="max-w-2xl">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-5xl font-bold">🎉 Welcome to LiveVue!</h1>
          <h2 class="text-2xl py-4">{{ greeting }}</h2>
          <p class="text-lg">Vue.js components seamlessly integrated with Phoenix LiveView</p>
        </div>

        <!-- Todo Demo Card -->
        <div class="card bg-base-100 shadow-xl mb-8">
          <div class="card-body">
            <div class="card-title justify-between">
              <h3>Interactive Todo Demo</h3>
              <div class="badge badge-info">{{ activeCount }} of {{ props.total_count }} active</div>
            </div>

            <!-- Add Todo Form -->
            <form @submit.prevent="addTodo" class="form-control mb-6">
              <div class="input-group">
                <input
                  v-model="newTodo"
                  type="text"
                  placeholder="What needs to be done?"
                  class="input input-bordered flex-1"
                />
                <button
                  type="submit"
                  :disabled="!newTodo.trim()"
                  class="btn btn-primary"
                  @click="$live.pushEvent('add_todo', { text: newTodo.trim() }); addTodo()"
                >
                  Add Todo
                </button>
              </div>
            </form>

            <!-- Filter Buttons -->
            <div class="btn-group mb-6">
              <button
                v-for="filterType in ['all', 'active', 'completed']"
                :key="filterType"
                @click="filter = filterType as 'all' | 'active' | 'completed'"
                :class="['btn btn-sm', filter === filterType ? 'btn-active' : '']"
              >
                {{ filterType.charAt(0).toUpperCase() + filterType.slice(1) }}
              </button>
            </div>

            <!-- Todo List -->
            <div v-if="filteredTodos.length > 0" class="space-y-2 mb-4">
              <div
                v-for="todo in filteredTodos"
                :key="todo.id"
                class="card card-compact bg-base-200"
              >
                <div class="card-body">
                  <div class="flex items-center gap-3">
                    <input
                      type="checkbox"
                      :checked="todo.completed"
                      @change="$live.pushEvent('toggle_todo', { id: todo.id })"
                      class="checkbox checkbox-primary"
                    />
                    <span :class="['flex-1 text-left', todo.completed ? 'line-through opacity-60' : '']">
                      {{ todo.text }}
                    </span>
                    <button
                      @click="$live.pushEvent('delete_todo', { id: todo.id })"
                      class="btn btn-error btn-sm"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div v-else class="alert">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-info shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <span>{{ filter === "all" ? "No todos yet!" : `No ${filter} todos!` }}</span>
            </div>

            <!-- Actions -->
            <div v-if="props.todos.some(todo => todo.completed)" class="card-actions justify-between">
              <span class="text-sm opacity-70">{{ props.todos.filter(todo => todo.completed).length }} completed</span>
              <button @click="$live.pushEvent('clear_completed', {})" class="btn btn-error btn-sm">
                Clear completed
              </button>
            </div>
          </div>
        </div>

        <!-- Features Info -->
        <div class="alert alert-info">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          <div>
            <h4 class="font-bold">LiveVue Features Demonstrated:</h4>
            <ul class="text-sm mt-2 space-y-1">
              <li>✅ <strong>Reactive Props:</strong> Todos and counts flow from server state</li>
              <li>✅ <strong>Client Events:</strong> Add, toggle, delete todos send events to LiveView</li>
              <li>✅ <strong>Local State:</strong> Filter buttons work entirely client-side</li>
              <li>✅ <strong>Server Sync:</strong> All changes persist and update across sessions</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
