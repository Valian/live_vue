# Client-Side API Reference

This guide documents all client-side utilities, composables, and APIs available in LiveVue for Vue components.

> #### Getting Started {: .tip}
>
> New to LiveVue? Check out [Basic Usage](basic_usage.html) for fundamental patterns before diving into the API details.

## Core Composables

### useLiveVue()

The primary composable for interacting with Phoenix LiveView from Vue components.

```html
<script setup>
import { useLiveVue } from 'live_vue'

// under the hood it's using Provide / Inject feature from Vue, so has to be used in setup function
// more: https://vuejs.org/guide/components/provide-inject
const live = useLiveVue()
</script>
```

#### Methods

##### pushEvent(event, payload?, callback?)

Push an event to the LiveView server.

```html
<script setup>
import { useLiveVue } from 'live_vue'
const live = useLiveVue()

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
</script>
```

**Real-world example - Auto-save draft:**
```html
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

```html
<script setup>
import { useLiveVue } from 'live_vue'
const live = useLiveVue()

// Listen for server-sent notifications
live.handleEvent("notification", (payload) => {
  showToast(payload.message, payload.type)
})

// Handle real-time data updates
live.handleEvent("data_updated", (data) => {
  // Update local reactive state
  localData.value = data
})
</script>
```

**Real-world example - Live chat:**
```html
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

```html
<script setup>
import { useLiveVue } from 'live_vue'
const live = useLiveVue()

// Push to specific form component
live.pushEventTo("#user-form", "validate", formData)

// Target component by data attribute
live.pushEventTo("[data-component='UserProfile']", "refresh")

</script>
```

**Real-world example - Multi-component dashboard:**
```html
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

```html
<script setup>
import { useLiveVue } from 'live_vue'
const live = useLiveVue()

// Handle file upload
const fileInput = ref<HTMLInputElement>()

const handleUpload = () => {
  if (fileInput.value?.files) {
    live.upload("avatar", fileInput.value.files)
  }
}
</script>
```

**Real-world example - Drag & drop upload:**
```html
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

```html
<script setup>
import { useLiveVue } from 'live_vue'
const live = useLiveVue()

live.uploadTo("#profile-form", "avatar", files)
</script>
```

## Built-in Components

### Link

The `Link` component provides a convenient wrapper around Phoenix LiveView's navigation capabilities, making it easy to perform `patch` and `navigate` actions from within your Vue components.

```html
<script setup>
import { Link } from 'live_vue'
</script>

<template>
  <!-- Basic link -->
  <Link href="/regular-link">Regular Link</Link>

  <!-- `live_patch` to the same LiveView -->
  <Link patch="/posts/1/edit">Edit Post</Link>

  <!-- `live_redirect` to a different LiveView -->
  <Link navigate="/posts">Back to Posts</Link>

  <!-- Replace the current history entry -->
  <Link patch="/posts/1/edit" replace>Edit (replace history)</Link>
</template>
```

#### Props

| Prop | Type | Description |
|---|---|---|
| `href` | `string` | A standard link that causes a full page reload. |
| `patch` | `string` | Navigates to a new URL within the same LiveView by calling `handle_params`. |
| `navigate` | `string` | Navigates to a different LiveView, replacing the current one without a full page reload. |
| `replace` | `boolean` | If `true`, the browser's history entry is replaced instead of a new one being pushed. |

## Utility Functions

### createLiveVue(config)

Creates a LiveVue application instance. For complete configuration options, see [Configuration](configuration.html#vue-application-setup).

### findComponent(components, name)

A flexible helper function to resolve a component from a map of available components. It finds a component by checking if the key ends with either `name.vue` or `name/index.vue`.

This is particularly useful when using Vite's `import.meta.glob` to import all components, as it allows for a simple and conventional way to organize and resolve them.

```typescript
import { findComponent } from 'live_vue'

// Given a components map from Vite:
const components = import.meta.glob(["./**/*.vue", "../../lib/**/*.vue"]);

// It can resolve the following:
// 1. By component name: `findComponent(components, 'UserProfile')`
//    -> Matches: `./components/UserProfile.vue`
// 2. By path: `findComponent(components, 'admin/Dashboard')`
//    -> Matches: `./components/admin/Dashboard.vue`
// 3. By directory with an index file: `findComponent(components, 'forms/Button')`
//    -> Matches: `./components/forms/Button/index.vue`
```

If the component is not found, it will throw a helpful error listing all available components.

**Parameters:**
- `components` (object): A map of component paths to component modules, typically from `import.meta.glob`.
- `name` (string): The name or path of the component to find.

**Returns:** The resolved Vue component, or throws an error if not found.

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

```html
<script setup>
import { useLiveVue } from 'live_vue'
import { debounce } from 'lodash-es'

const live = useLiveVue()

// Debounce search input
const debouncedSearch = debounce((query: string) => {
  live.pushEvent("search", { query })
}, 300)

watch(searchQuery, debouncedSearch)
</script>
```

### Event Cleanup

```html
<script setup lang="ts">
import { useLiveVue } from 'live_vue'
import { onMounted, onUnmounted } from 'vue'

const live = useLiveVue()

// Helper function to clean up event listeners
// will likely be added to LiveVue in the future
export function useLiveEvent(event, callback) {
  let callbackRef = null
  onMounted(() => {
    callbackRef = live.handleEvent(event, callback)
  })
  onUnmounted(() => {
    if (callbackRef) live.removeHandleEvent(callbackRef)
    callbackRef = null
  })
}


useLiveEvent("data_update", (data) => console.log("Data updated:", data))
</script>
```

## Next Steps

- [Basic Usage](basic_usage.html) for fundamental patterns and examples
- [Component Reference](component_reference.html) for LiveView-side API
- [Configuration](configuration.html) for advanced setup options
- [Testing](testing.html) for testing client-side code