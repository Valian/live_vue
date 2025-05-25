# Client-Side API Reference

This guide documents all client-side utilities, composables, and APIs available in LiveVue for Vue components.

> #### Getting Started {: .tip}
>
> New to LiveVue? Check out [Basic Usage](basic_usage.html) for fundamental patterns before diving into the API details.

## Core Composables

### useLiveVue()

The primary composable for interacting with Phoenix LiveView from Vue components.

```typescript
import { useLiveVue } from 'live_vue'

const live = useLiveVue()
```

#### Methods

##### pushEvent(event, payload?, callback?)

Push an event to the LiveView server.

```typescript
// Basic usage - increment a counter
live.pushEvent("increment", { amount: 1 })

// Form submission with validation feedback
live.pushEvent("save_user", {
  name: "John",
  email: "john@example.com"
}, (reply, ref) => {
  if (reply.status === "ok") {
    console.log("User saved successfully!")
  } else {
    console.log("Validation errors:", reply.errors)
  }
})

// Simple refresh without payload
live.pushEvent("refresh")
```

**Real-world example - Auto-save draft:**
```vue
<script setup>
import { watch, debounce } from 'vue'
import { useLiveVue } from 'live_vue'

const live = useLiveVue()
const content = ref('')

// Auto-save draft every 2 seconds after user stops typing
const debouncedSave = debounce((text) => {
  live.pushEvent("save_draft", { content: text })
}, 2000)

watch(content, debouncedSave)
</script>
```

**Parameters:**
- `event` (string): Event name to push to LiveView
- `payload` (object, optional): Data to send with the event
- `callback` (function, optional): Callback for server replies

**Returns:** Event reference number

##### handleEvent(event, callback)

Listen for events pushed from the LiveView server.

```typescript
// Listen for server-sent notifications
live.handleEvent("notification", (payload) => {
  showToast(payload.message, payload.type)
})

// Handle real-time data updates
live.handleEvent("data_updated", (data) => {
  // Update local reactive state
  localData.value = data
})
```

**Real-world example - Live chat:**
```vue
<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useLiveVue } from 'live_vue'

const live = useLiveVue()
const messages = ref([])

onMounted(() => {
  // Listen for new messages
  const callbackRef = live.handleEvent("new_message", (message) => {
    messages.value.push(message)
  })

  // Clean up on unmount
  onUnmounted(() => live.removeHandleEvent(callbackRef))
})
</script>
```

**Parameters:**
- `event` (string): Event name to listen for
- `callback` (function): Handler function receiving the payload

**Returns:** Function to remove the event listener

##### pushEventTo(selector, event, payload?, callback?)

Push an event to a specific LiveView component.

```typescript
// Push to specific form component
live.pushEventTo("#user-form", "validate", formData)

// Target component by data attribute
live.pushEventTo("[data-component='UserProfile']", "refresh")
```

**Real-world example - Multi-component dashboard:**
```vue
<script setup>
const live = useLiveVue()

const refreshWidget = (widgetId) => {
  live.pushEventTo(`#widget-${widgetId}`, "refresh", {
    timestamp: Date.now()
  })
}
</script>
```

##### upload(name, entries)

Handle file uploads to LiveView.

```typescript
// Handle file upload
const fileInput = ref<HTMLInputElement>()

const handleUpload = () => {
  if (fileInput.value?.files) {
    live.upload("avatar", fileInput.value.files)
  }
}
```

**Real-world example - Drag & drop upload:**
```vue
<script setup>
import { ref } from 'vue'
import { useLiveVue } from 'live_vue'

const live = useLiveVue()
const isDragging = ref(false)

const handleDrop = (event) => {
  event.preventDefault()
  isDragging.value = false

  const files = event.dataTransfer.files
  if (files.length > 0) {
    live.upload("documents", files)
  }
}

const handleDragOver = (event) => {
  event.preventDefault()
  isDragging.value = true
}
</script>

<template>
  <div
    @drop="handleDrop"
    @dragover="handleDragOver"
    @dragleave="isDragging = false"
    :class="{ 'border-blue-500': isDragging }"
    class="border-2 border-dashed border-gray-300 p-8 text-center"
  >
    Drop files here to upload
  </div>
</template>
```

**Parameters:**
- `name` (string): Upload name (must match LiveView allow_upload)
- `entries` (FileList): Files to upload

##### uploadTo(selector, name, entries)

Upload files to a specific LiveView component.

```typescript
live.uploadTo("#profile-form", "avatar", files)
```

## Utility Functions

### createLiveVue(config)

Creates a LiveVue application instance. For complete configuration options, see [Configuration](configuration.html#vue-application-setup).

### findComponent(components, name)

Helper function to resolve components by name or path.

```typescript
import { findComponent } from 'live_vue'

// Finds component by suffix matching
const component = findComponent(components, 'UserProfile')
// Matches: './components/UserProfile.vue', './admin/UserProfile.vue', './admin/UserProfile/index.vue'
```

**Parameters:**
- `components` (object): Component map - name to Vue Component
- `name` (string): Component name to find

**Returns:** Component or undefined

### getHooks(liveVueApp)

Generates Phoenix LiveView hooks for LiveVue integration.

```typescript
import { getHooks } from 'live_vue'
import liveVueApp from '../vue'

const hooks = getHooks(liveVueApp)

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: hooks
})
```

## TypeScript Support

### Type Definitions

LiveVue provides comprehensive TypeScript support:

```typescript
// Component props typing
interface Props {
  user: {
    id: number
    name: string
    email: string
  }
  settings: Record<string, any>
}

const props = defineProps<Props>()

// Event emissions typing
const emit = defineEmits<{
  'user-updated': [{ user: Props['user'] }]
  'settings-changed': [{ key: string, value: any }]
}>()

// useLiveVue typing
const live = useLiveVue()
// live is fully typed with all available methods
```

## Common Patterns

### Real-Time Data Synchronization

```typescript
// Composable for real-time data sync with {:reply, data, socket} tuple
export const useRealtimeData = (dataType: string) => {
  const live = useLiveVue()
  const data = ref(null)
  const loading = ref(true)
  const error = ref(null)

  onMounted(() => {
    // Request initial data
    live.pushEvent("load_data", { type: dataType }, (newData) => {
      data.value = newData
      loading.value = false
    })
  })

  return { data, loading, error }
}
```

### File Upload Helper

```typescript
// Composable for file uploads
export const useFileUpload = (uploadName: string) => {
  const live = useLiveVue()
  const uploading = ref(false)
  const progress = ref(0)

  const upload = (files: FileList) => {
    uploading.value = true
    progress.value = 0

    // Listen for upload progress
    live.handleEvent("upload_progress", ({ percentage }) => {
      progress.value = percentage
    })

    // Listen for upload completion
    live.handleEvent("upload_complete", () => {
      uploading.value = false
      progress.value = 100
    })

    live.upload(uploadName, files)
  }

  return { upload, uploading, progress }
}
```

## Performance Considerations

### Debounced Events

```typescript
import { debounce } from 'lodash-es'

// Debounce search input
const debouncedSearch = debounce((query: string) => {
  live.pushEvent("search", { query })
}, 300)

watch(searchQuery, debouncedSearch)
```

### Event Cleanup

```typescript
// Always clean up event listeners
onUnmounted(() => {
  // Remove specific listeners
  const removeListener = live.handleEvent("data_update", handler)
  removeListener()
})
```

## Next Steps

- [Basic Usage](basic_usage.html) for fundamental patterns and examples
- [Component Reference](component_reference.html) for LiveView-side API
- [Configuration](configuration.html) for advanced setup options
- [Testing](testing.html) for testing client-side code