# Client-Side API Reference

This guide documents all client-side utilities, composables, and APIs available in LiveVue for Vue components.

> #### Getting Started {: .tip}
>
> New to LiveVue? Check out [Basic Usage](basic_usage.html) for fundamental patterns before diving into the API details.

## Composables

LiveVue provides several Vue Composables to make interacting with the LiveView instance from your components easier and more declarative. These should be your first choice when working inside `.vue` files.

### `useLiveVue()`

The `useLiveVue()` composable is the standard way to get access to the LiveView hook instance within your component's `<script setup>` block. This is the method you should use when you need to call hook methods from your script logic (e.g., in watchers, lifecycle hooks, or other functions).

```html
<script setup>
import { useLiveVue } from 'live_vue'

// Must be called inside setup
const live = useLiveVue()

// Now you can use `live` anywhere in your script
live.pushEvent("some_event")
</script>
```

### `useLiveEvent(event, callback)`

The `useLiveEvent` composable is the recommended way to listen for server-pushed events within a component. It automatically registers an event handler when the component is mounted and cleans it up when the component is unmounted.

It is a wrapper around `useLiveVue().handleEvent()` that saves you the boilerplate of using `onMounted` and `onUnmounted`.

**Parameters:**
- `event` (string): Event name to listen for
- `callback` (function): Handler function that receives the payload from the server.

**Example: Showing Notifications**

```html
<script setup>
import { useLiveEvent } from 'live_vue'
import { useToast } from 'primevue/usetoast'; // example toast library

const toast = useToast();

useLiveEvent("notification", (payload) => {
  toast.add({ severity: payload.type, summary: payload.message, life: 3000 });
})
</script>
```

### `useLiveNavigation()`

A composable for programmatic navigation that mirrors the functionality of `live_patch` and `live_redirect` in Phoenix LiveView. It returns an object with `patch` and `navigate` functions.

This is useful for scenarios where you need to trigger navigation from your script logic, such as after a form submission or a modal action.

**Returns:**
- `patch(hrefOrQueryParams, { replace: boolean })`: Patches the current LiveView, similar to `live_patch`.
- `navigate(href, { replace: boolean })`: Navigates to a new LiveView, similar to `live_redirect`.

**Example: Navigating after a successful action**

```html
<template>
  <div>
    <button @click="goToSettings">Go to Settings</button>
  </div>
</template>

<script setup>
import { useLiveNavigation } from 'live_vue';
import { useLiveEvent } from 'live_vue';

const { patch, navigate } = useLiveNavigation();

useLiveEvent("user_created", (payload) => {
  // Redirect to the new user's page
  navigate(`/users/${payload.id}`);
})

function goToSettings() {
  // Update the URL with new query params
  patch({ tab: 'settings', page: 1 });
}
</script>
```

## Low-Level API

While composables are recommended for most component-based use cases, you can also access the underlying hook instance for more control or for use outside of components.

### Accessing the Hook Instance

There are two primary ways to interact with the LiveView instance from your Vue component:

#### 1. `useLiveVue()` Composable

As seen above, `useLiveVue()` returns the raw hook instance.

#### 2. `$live` Global Property

For convenience, the LiveView hook instance is also exposed directly to your Vue templates as a global property named `$live`. This is ideal for simple, one-off calls directly from an element's event handler, as it saves you from importing and calling `useLiveVue()` when you don't need the instance in your script.

```html
<template>
  <!-- No script setup needed for this simple case -->
  <button @click="$live.pushEvent('button_clicked')">
    Click Me
  </button>
</template>
```

Both `useLiveVue()` and `$live` return the same hook instance, which is fully typed and provides access to the methods below.

## Hook Methods

The hook instance (returned by `useLiveVue()` or accessed via `$live`) provides the following methods:

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

> **Note:** When using this inside a Vue component, prefer the [`useLiveEvent`](#useliveevent) composable for automatic cleanup. Use `handleEvent` when you need to manually manage the listener's lifecycle.

```html
<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useLiveVue } from 'live_vue'

const live = useLiveVue()

// Listen for server-sent notifications
const callbackRef = live.handleEvent("notification", (payload) => {
  showToast(payload.message, payload.type)
})

// Clean up on unmount to prevent memory leaks
onUnmounted(() => {
  live.removeHandleEvent(callbackRef)
})
</script>
```

**Parameters:**
- `event` (string): Event name to listen for
- `callback` (function): Handler function receiving the payload

**Returns:** A reference to the callback that can be used with `removeHandleEvent`.

##### removeHandleEvent(callbackRef)

Removes an event listener that was previously registered with `handleEvent`.

```js
// callbackRef is the value returned from a `handleEvent` call
live.removeHandleEvent(callbackRef)
```

**Parameters:**
- `callbackRef`: The reference returned by `handleEvent`.

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