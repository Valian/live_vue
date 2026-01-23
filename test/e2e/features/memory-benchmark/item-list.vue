<script setup lang="ts">
import { ref, computed } from 'vue'
import { useLiveVue } from 'live_vue'

interface ItemMetadata {
  extra_field_1: string
  extra_field_2: number
  extra_field_3: boolean
}

interface Item {
  id: number
  name: string
  description: string
  tags: string[]
  metadata: ItemMetadata
}

interface Memory {
  total_bytes: number
  total_kb: number
  total_flat_bytes: number
  sharing_bytes: number
  components_bytes: number
  components_flat_bytes: number
  components_sharing_bytes: number
  socket_bytes: number
  assigns_bytes: number
  items_bytes: number
  items_flat_bytes: number
  items_kb: number
}

const props = defineProps<{
  items: Item[]
  memory: Memory | null
}>()

const live = useLiveVue()

const itemCount = computed(() => props.items.length)
const tagCount = computed(() => props.items.reduce((acc, item) => acc + item.tags.length, 0))

// Timing state
const lastResponseTime = ref<number | null>(null)
const isLoading = ref(false)

// Helper to push event with timing
const timedPushEvent = (event: string, payload: Record<string, unknown> = {}) => {
  isLoading.value = true
  const start = performance.now()

  live.pushEvent(event, payload, () => {
    const end = performance.now()
    lastResponseTime.value = Math.round(end - start)
    isLoading.value = false
  })
}

const setCount = (count: number) => timedPushEvent('set_count', { count: count.toString() })
const addItems = (count: number) => timedPushEvent('add_items', { count: count.toString() })
const clearItems = () => timedPushEvent('clear_items', {})
const refreshMemory = () => timedPushEvent('refresh_memory', {})
</script>

<template>
  <div class="memory-benchmark-vue">
    <!-- Controls -->
    <div class="controls" style="margin-bottom: 20px; padding: 10px; background: #f0f0f0;">
      <h2>Controls</h2>
      <div style="margin-bottom: 10px;">
        <label>Set item count:</label>
        <button @click="setCount(10)" data-pw-set-10 :disabled="isLoading">10 items</button>
        <button @click="setCount(100)" data-pw-set-100 :disabled="isLoading">100 items</button>
        <button @click="setCount(1000)" data-pw-set-1000 :disabled="isLoading">1,000 items</button>
        <button @click="setCount(5000)" data-pw-set-5000 :disabled="isLoading">5,000 items</button>
      </div>
      <div style="margin-bottom: 10px;">
        <label>Add items:</label>
        <button @click="addItems(100)" data-pw-add-100 :disabled="isLoading">+100</button>
        <button @click="addItems(500)" data-pw-add-500 :disabled="isLoading">+500</button>
        <button @click="addItems(1000)" data-pw-add-1000 :disabled="isLoading">+1,000</button>
      </div>
      <div>
        <button @click="clearItems()" data-pw-clear :disabled="isLoading">Clear All</button>
        <button @click="refreshMemory()" data-pw-refresh :disabled="isLoading">Refresh Memory</button>
      </div>
    </div>

    <!-- Timing Stats -->
    <div class="timing-stats" style="padding: 10px; background: #f0e0f0; margin-bottom: 20px;">
      <h2>Response Time</h2>
      <p>
        <strong>Last Action:</strong>
        <span data-pw-response-time>
          <template v-if="isLoading">Loading...</template>
          <template v-else-if="lastResponseTime !== null">{{ lastResponseTime }}ms</template>
          <template v-else>N/A</template>
        </span>
      </p>
    </div>

    <!-- Memory Stats -->
    <div class="memory-stats" style="padding: 10px; background: #e0f0e0; margin-bottom: 20px;">
      <h2>Memory Statistics</h2>
      <p>
        <strong>Item Count:</strong> <span data-pw-item-count>{{ itemCount }}</span>
      </p>
      <p v-if="!memory" style="color: #666;">Measuring...</p>
      <table v-else style="width: 100%; border-collapse: collapse; font-size: 14px;">
        <tr style="border-bottom: 2px solid #888; background: #c0d8c0;">
          <td style="padding: 4px;"><strong>Total Channel State</strong></td>
          <td style="padding: 4px; text-align: right;" data-pw-total-bytes>{{ memory.total_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;" data-pw-total-kb>{{ memory.total_kb }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc;">
          <td style="padding: 4px;">Total (flat/no sharing)</td>
          <td style="padding: 4px; text-align: right;" data-pw-total-flat-bytes>{{ memory.total_flat_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.total_flat_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc; background: #e8e0d0;">
          <td style="padding: 4px;"><strong>Total sharing saves</strong></td>
          <td style="padding: 4px; text-align: right;" data-pw-sharing-bytes>{{ memory.sharing_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.sharing_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc; background: #f8f8e0;">
          <td style="padding: 4px;"><strong>LiveComponents</strong></td>
          <td style="padding: 4px; text-align: right;" data-pw-components-bytes>{{ memory.components_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.components_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc;">
          <td style="padding: 4px;">Components (flat)</td>
          <td style="padding: 4px; text-align: right;" data-pw-components-flat-bytes>{{ memory.components_flat_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.components_flat_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc;">
          <td style="padding: 4px;">Components sharing saves</td>
          <td style="padding: 4px; text-align: right;" data-pw-components-sharing>{{ memory.components_sharing_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.components_sharing_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc;">
          <td style="padding: 4px;">Socket</td>
          <td style="padding: 4px; text-align: right;" data-pw-socket-bytes>{{ memory.socket_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.socket_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc;">
          <td style="padding: 4px;">Assigns</td>
          <td style="padding: 4px; text-align: right;" data-pw-assigns-bytes>{{ memory.assigns_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.assigns_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc; background: #d0e8d0;">
          <td style="padding: 4px;"><strong>Items (your data)</strong></td>
          <td style="padding: 4px; text-align: right;" data-pw-items-bytes>{{ memory.items_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;" data-pw-items-kb>{{ memory.items_kb }} KB</td>
        </tr>
        <tr style="border-bottom: 1px solid #ccc;">
          <td style="padding: 4px;">Items (flat)</td>
          <td style="padding: 4px; text-align: right;" data-pw-items-flat-bytes>{{ memory.items_flat_bytes.toLocaleString() }} bytes</td>
          <td style="padding: 4px; text-align: right;">{{ (memory.items_flat_bytes / 1024).toFixed(2) }} KB</td>
        </tr>
      </table>
    </div>

    <!-- Vue Component Stats -->
    <div class="vue-stats" style="padding: 10px; background: #e0e0f0; margin-bottom: 20px;">
      <h2>Vue Component Stats</h2>
      <p>
        <span data-pw-vue-count>{{ itemCount }} items</span>,
        <span data-pw-vue-tags>{{ tagCount }} tags</span>
      </p>
    </div>

    <!-- Item List -->
    <div class="item-list" style="max-height: 400px; overflow-y: auto; border: 1px solid #ccc;">
      <div
        v-for="item in items"
        :key="item.id"
        style="padding: 8px; border-bottom: 1px solid #eee;"
      >
        <div><strong>{{ item.name }}</strong></div>
        <div style="font-size: 12px; color: #666;">{{ item.description }}</div>
        <div style="font-size: 11px;">
          <span
            v-for="tag in item.tags"
            :key="tag"
            style="background: #e0e0e0; padding: 2px 4px; margin-right: 4px; border-radius: 3px;"
          >
            {{ tag }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
