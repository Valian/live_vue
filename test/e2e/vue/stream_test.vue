<script setup lang="ts">
import { useLiveVue } from 'live_vue'
import { computed, ref } from 'vue'

// Props
const props = defineProps<{
  items: {
    id: number
    name: string
    description: string
  }[]
}>()

// LiveVue hook
const live = useLiveVue()

// Reactive data
const newItem = ref({
  name: '',
  description: '',
})

const positiveLimit = ref(3)
const negativeLimit = ref(3)

// Computed properties for debugging and display
const itemsLength = computed(() => props.items.length)

// Methods
function addItem() {
  if (!newItem.value.name.trim()) {
    alert('Please enter a name for the item')
    return
  }

  // Send event to LiveView using the correct API
  live.pushEvent('add_item', {
    name: newItem.value.name,
    description: newItem.value.description,
  })

  // Clear form
  newItem.value = {
    name: '',
    description: '',
  }
}

function removeItem(id: number) {
  live.pushEvent('remove_item', { id })
}

function clearStream() {
  live.pushEvent('clear_stream', {})
}

function resetStream() {
  live.pushEvent('reset_stream', {})
}

function resetStreamAt0() {
  live.pushEvent('reset_stream_at_0', {})
}

// Limit operation methods
function addMultipleStart() {
  live.pushEvent('add_multiple_start', {})
}

function addMultipleEnd() {
  live.pushEvent('add_multiple_end', {})
}

function addWithPositiveLimit() {
  if (positiveLimit.value && positiveLimit.value > 0) {
    live.pushEvent('add_with_positive_limit', {
      limit: positiveLimit.value.toString(),
    })
  }
}

function addWithNegativeLimit() {
  if (negativeLimit.value && negativeLimit.value > 0) {
    live.pushEvent('add_with_negative_limit', {
      limit: negativeLimit.value.toString(),
    })
  }
}
</script>

<template>
  <div id="stream-component">
    <h2>Stream Test</h2>

    <!-- Add new item form -->
    <div class="add-form">
      <h3>Add New Item</h3>
      <input v-model="newItem.name" placeholder="Item name" data-testid="name-input">
      <input v-model="newItem.description" placeholder="Item description" data-testid="description-input">
      <button data-testid="add-button" @click="addItem">
        Add Item
      </button>
    </div>

    <!-- Stream controls -->
    <div class="stream-controls">
      <button data-testid="clear-button" @click="clearStream">
        Clear All
      </button>
      <button data-testid="reset-button" @click="resetStream">
        Reset to Default
      </button>
      <button data-testid="reset-button-at-0" @click="resetStreamAt0">
        Reset to Default (at: 0)
      </button>
    </div>

    <!-- Limit operation controls -->
    <div class="limit-controls">
      <h3>Limit Operations</h3>
      <div class="limit-section">
        <h4>Multiple Insert Operations</h4>
        <button data-testid="add-multiple-start-button" class="limit-button" @click="addMultipleStart">
          Add 3 Items at Start (Limit: Keep First 5)
        </button>
        <button data-testid="add-multiple-end-button" class="limit-button" @click="addMultipleEnd">
          Add 3 Items at End (Limit: Keep Last 5)
        </button>
      </div>

      <div class="limit-section">
        <h4>Single Insert with Custom Limits</h4>
        <div class="limit-input-group">
          <input
            v-model.number="positiveLimit"
            type="number"
            placeholder="Positive limit"
            min="1"
            max="10"
            data-testid="positive-limit-input"
            class="limit-input"
          >
          <button
            data-testid="add-positive-limit-button"
            class="limit-button"
            :disabled="!positiveLimit || positiveLimit < 1"
            @click="addWithPositiveLimit"
          >
            Add Item (Keep First {{ positiveLimit || "?" }})
          </button>
        </div>

        <div class="limit-input-group">
          <input
            v-model.number="negativeLimit"
            type="number"
            placeholder="Negative limit"
            min="1"
            max="10"
            data-testid="negative-limit-input"
            class="limit-input"
          >
          <button
            data-testid="add-negative-limit-button"
            class="limit-button"
            :disabled="!negativeLimit || negativeLimit < 1"
            @click="addWithNegativeLimit"
          >
            Add Item (Keep Last {{ negativeLimit || "?" }})
          </button>
        </div>
      </div>
    </div>

    <!-- Items list -->
    <div class="items-list">
      <h3>Items ({{ props.items.length }})</h3>
      <div v-if="props.items.length === 0" data-testid="empty-message" class="empty-state">
        No items in the stream
      </div>
      <div v-for="item in props.items" :key="item.id" class="item" :data-testid="`item-${item.id}`">
        <div class="item-content">
          <h4 data-testid="item-name">
            {{ item.name }}
          </h4>
          <p data-testid="item-description">
            {{ item.description }}
          </p>
          <small data-testid="item-id">ID: {{ item.id }}</small>
        </div>
        <button :data-testid="`remove-${item.id}`" class="remove-button" @click="removeItem(item.id)">
          Remove
        </button>
      </div>
    </div>

    <!-- Debug info -->
    <div class="debug-info">
      <h4>Debug Info</h4>
      <p>Items type: {{ typeof props.items }}</p>
      <p>Items length: {{ itemsLength }}</p>
      <pre data-testid="raw-items">{{ JSON.stringify(items, null, 2) }}</pre>
    </div>
  </div>
</template>

<style scoped>
.add-form {
  border: 1px solid #ddd;
  padding: 1rem;
  margin-bottom: 1rem;
  border-radius: 4px;
}

.add-form input {
  margin: 0.25rem;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.add-form button {
  margin: 0.25rem;
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.add-form button:hover {
  background: #0056b3;
}

.stream-controls {
  margin-bottom: 1rem;
}

.stream-controls button {
  margin-right: 0.5rem;
  padding: 0.5rem 1rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  cursor: pointer;
}

.stream-controls button:hover {
  background: #f5f5f5;
}

.items-list {
  border: 1px solid #ddd;
  padding: 1rem;
  margin-bottom: 1rem;
  border-radius: 4px;
}

.empty-state {
  color: #666;
  font-style: italic;
  text-align: center;
  padding: 2rem;
}

.item {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border: 1px solid #eee;
  padding: 1rem;
  margin: 0.5rem 0;
  border-radius: 4px;
  background: #f9f9f9;
}

.item-content {
  flex-grow: 1;
}

.item-content h4 {
  margin: 0 0 0.5rem 0;
  color: #333;
}

.item-content p {
  margin: 0 0 0.5rem 0;
  color: #666;
}

.item-content small {
  color: #999;
}

.remove-button {
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 0.25rem 0.5rem;
  cursor: pointer;
}

.remove-button:hover {
  background: #c82333;
}

.debug-info {
  border: 1px solid #ffc107;
  background: #fff3cd;
  padding: 1rem;
  border-radius: 4px;
  font-size: 0.875rem;
}

.debug-info pre {
  background: white;
  padding: 0.5rem;
  border-radius: 4px;
  overflow: auto;
  max-height: 200px;
  font-size: 0.75rem;
}

.limit-controls {
  border: 1px solid #007bff;
  background: #f8f9fa;
  padding: 1rem;
  margin-bottom: 1rem;
  border-radius: 4px;
}

.limit-controls h3 {
  margin-top: 0;
  color: #007bff;
}

.limit-section {
  margin-bottom: 1rem;
}

.limit-section h4 {
  margin-bottom: 0.5rem;
  color: #495057;
}

.limit-button {
  margin: 0.25rem;
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.limit-button:hover:not(:disabled) {
  background: #0056b3;
}

.limit-button:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.limit-input-group {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
}

.limit-input {
  width: 100px;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}
</style>
