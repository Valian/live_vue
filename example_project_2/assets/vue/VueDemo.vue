<script setup lang="ts">
import { ref, computed } from "vue"
import { useLiveVue, Form, useLiveForm } from "live_vue"

type FilterType = "all" | "active" | "completed"

// Props from LiveView - server state
const props = defineProps<{
  todos: Array<{ id: number; text: string; completed: boolean }>
  form: Form<{ text: string }>
}>()

// Phoenix hook instance responsible for syncing this Vue component
const live = useLiveVue()

// Server-side validation using changesets
const { field, submit, isValid } = useLiveForm<{ text: string }>(() => props.form, {
  submitEvent: "add_todo",
  changeEvent: "validate_todo",
  debounceInMiliseconds: 50,
})

const textField = field("text")

// Local client-side state
const filter = ref<FilterType>("all")

const filterByType = (type: FilterType) => {
  switch (type) {
    case "active":
      return props.todos.filter((todo) => !todo.completed)
    case "completed":
      return props.todos.filter((todo) => todo.completed)
    default:
      return props.todos
  }
}
// Computed properties for reactive UI
const filteredTodos = computed(() => filterByType(filter.value))
const completedCount = computed(() => filterByType("completed").length)
</script>

<template>
  <div class="text-center">
    <div class="max-w-2xl space-y-8">
      <!-- Header -->
      <div>
        <h1 class="text-5xl font-bold">🎉 Welcome to LiveVue!</h1>
        <p class="text-lg text-base-content/70">Vue.js components seamlessly integrated with Phoenix LiveView</p>
      </div>

      <!-- Todo Demo Card -->
      <div>
        <!-- Add Todo Form -->
        <form @submit.prevent="submit" class="form-control mb-6">
          <div class="join mb-2">
            <input
              v-bind="textField.inputAttrs.value"
              type="text"
              placeholder="What needs to be done?"
              class="input input-bordered join-item flex-1"
            />
            <button type="submit" :disabled="!isValid" class="btn btn-primary join-item">Add Todo</button>
          </div>
          <div
            v-if="(textField.isTouched.value || textField.isDirty.value) && textField.errorMessage.value"
            class="text-error text-xs"
          >
            {{ textField.errorMessage }}
          </div>
        </form>

        <!-- Filter Buttons -->
        <div class="join mb-6 mx-auto">
          <button
            v-for="filterType in ['all', 'active', 'completed'] as FilterType[]"
            :key="filterType"
            @click="filter = filterType"
            :class="['btn btn-sm join-item', filter === filterType ? 'btn-active' : '']"
          >
            {{ filterType.charAt(0).toUpperCase() + filterType.slice(1) }}
            ({{ filterByType(filterType).length }})
          </button>
        </div>

        <!-- Todo List -->
        <div v-if="filteredTodos.length > 0" class="space-y-2 mb-4">
          <div v-for="todo in filteredTodos" :key="todo.id" class="card card-compact bg-base-200">
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
                <button @click="$live.pushEvent('delete_todo', { id: todo.id })" class="btn btn-error btn-sm">
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="alert">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-info shrink-0 w-6 h-6">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            ></path>
          </svg>
          <span>{{ filter === "all" ? "No todos yet!" : `No ${filter} todos!` }}</span>
        </div>

        <!-- Actions -->
        <div v-if="props.todos.some((todo) => todo.completed)" class="card-actions justify-between">
          <span class="text-sm opacity-70">{{ completedCount }} completed</span>
          <button @click="$live.pushEvent('clear_completed', {})" class="btn btn-error btn-sm">Clear completed</button>
        </div>
      </div>

      <!-- Features Info -->
      <div class="alert alert-info">
        <div>
          <h4 class="font-bold">LiveVue Features Demonstrated:</h4>
          <ul class="text-sm mt-2 space-y-1">
            <li>✅ <strong>Reactive Props:</strong> Todos flow from server state</li>
            <li>✅ <strong>Server Events:</strong> Add, toggle, delete todos send events to LiveView</li>
            <li>✅ <strong>Local State:</strong> Filter buttons work entirely client-side</li>
            <li>✅ <strong>Server-side Validation:</strong> Uses Ecto.Changeset</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
