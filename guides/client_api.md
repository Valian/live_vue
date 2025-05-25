# Client-Side API Reference

This guide documents all client-side utilities, composables, and APIs available in LiveVue for Vue components.

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
// Basic usage
live.pushEvent("save_user", { name: "John", email: "john@example.com" })

// With callback
live.pushEvent("save_user", payload, (reply, ref) => {
  console.log("Server replied:", reply)
})

// Without payload
live.pushEvent("refresh")
```

**Parameters:**
- `event` (string): Event name to push to LiveView
- `payload` (object, optional): Data to send with the event
- `callback` (function, optional): Callback for server replies

**Returns:** Event reference number

##### handleEvent(event, callback)

Listen for events pushed from the LiveView server.

```typescript
// Listen for server events
live.handleEvent("user_updated", (payload) => {
  console.log("User was updated:", payload)
})

// Multiple event handlers
live.handleEvent("notification", showNotification)
live.handleEvent("redirect", handleRedirect)
```

**Parameters:**
- `event` (string): Event name to listen for
- `callback` (function): Handler function receiving the payload

**Returns:** Function to remove the event listener

##### pushEventTo(selector, event, payload?, callback?)

Push an event to a specific LiveView component.

```typescript
// Push to specific component
live.pushEventTo("#user-form", "validate", formData)

// Push to component by data attribute
live.pushEventTo("[data-component='UserProfile']", "refresh")
```

**Parameters:**
- `selector` (string): CSS selector for target component
- `event` (string): Event name
- `payload` (object, optional): Event data
- `callback` (function, optional): Reply callback

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

Creates a LiveVue application instance. Read more in [Configuration](configuration.html).

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

## Advanced Usage

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

- [Component Reference](component_reference.html) for LiveView-side API
- [Advanced Features](advanced_features.html) for complex scenarios
- [Testing](testing.html) for testing client-side code