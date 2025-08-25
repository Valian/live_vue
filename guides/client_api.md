# Client-Side API Reference

This guide documents all client-side utilities, composables, and APIs available in LiveVue for Vue components.

> #### Getting Started {: .tip}
>
> New to LiveVue? Check out [Basic Usage](basic_usage.md) for fundamental patterns before diving into the API details.

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

### `useLiveUpload(uploadConfig, options)`

The `useLiveUpload()` composable provides a Vue-friendly API for handling Phoenix LiveView file uploads. It manages the required DOM elements, upload state, and integrates seamlessly with LiveView's upload system.

**Parameters:**

- `uploadConfig` - Reactive reference to the upload configuration from LiveView (typically `() => props.upload`)
- `options.changeEvent` - Optional event name for file validation (sent when files are selected)
- `options.submitEvent` - Required event name for upload submission

**Returns:**

- `entries` - Reactive array of current upload entries with progress and metadata
- `showFilePicker()` - Opens the native file picker dialog
- `addFiles(files)` - Manually add files (useful for drag-and-drop)
- `submit()` - Submit all queued files (for non-auto uploads)
- `cancel(ref?)` - Cancel specific entry by ref, or all entries if ref omitted
- `clear()` - Clear the input and reset state
- `progress` - Overall progress percentage (0-100)
- `inputEl` - Reference to the underlying hidden file input element
- `valid` - Whether the current file selection is valid

**Basic Example:**

```html
<script setup>
import { useLiveUpload } from 'live_vue'

interface Props {
  upload: UploadConfig
}

const props = defineProps<Props>()

const { entries, showFilePicker, submit, cancel, progress, valid } = useLiveUpload(
  () => props.upload,
  {
    changeEvent: "validate", // Optional: event name for file validation
    submitEvent: "save"      // Required: event name for upload submission
  }
)
</script>

<template>
  <div>
    <!-- File picker button -->
    <button @click="showFilePicker">Select Files</button>

    <!-- Manual upload button (for non-auto uploads) -->
    <button v-if="!upload.auto_upload && entries.length > 0" @click="submit">
      Upload Files
    </button>

    <!-- Progress display -->
    <div v-if="entries.length > 0">Progress: {{ progress }}%</div>

    <!-- File list -->
    <div v-for="entry in entries" :key="entry.ref">
      <span>{{ entry.client_name }} ({{ entry.progress }}%)</span>
      <button @click="cancel(entry.ref)">Cancel</button>
    </div>
  </div>
</template>
```

**Drag and Drop Example:**

```html
<script setup>
import { useLiveUpload } from 'live_vue'

const props = defineProps<{ upload: UploadConfig }>()
const { addFiles, entries, showFilePicker } = useLiveUpload(() => props.upload, { submitEvent: "save" })

const handleDrop = (event) => {
  event.preventDefault()
  const files = Array.from(event.dataTransfer.files)
  addFiles(files)
}
</script>

<template>
  <div
    @drop="handleDrop"
    @dragover.prevent
    class="border-dashed border-2 p-4"
  >
    Drop files here or <button @click="showFilePicker">browse</button>
    <div v-for="entry in entries" :key="entry.ref">
      {{ entry.client_name }} - {{ entry.progress }}%
    </div>
  </div>
</template>
```

For a complete working example, see [Basic Usage - File Uploads](basic_usage.md#file-uploads).

### `useLiveForm(form, options)`

The `useLiveForm()` composable provides comprehensive form handling with server-side validation, nested objects, and dynamic arrays. It creates a reactive form instance that synchronizes with LiveView's form state and provides type-safe field access.

**Parameters:**

- `form` - Reactive reference to the form data from LiveView (typically `() => props.form`)
- `options.changeEvent` - Optional event name for sending field changes to server for validation
- `options.submitEvent` - Event name for form submission (default: "submit")
- `options.debounceInMiliseconds` - Delay before sending change events (default: 300)
- `options.prepareData` - Function to transform data before sending to server

**Returns:**

- `field(path)` - Get a typed field instance for the given path (e.g., "name", "user.email")
- `fieldArray(path)` - Get an array field instance for managing dynamic lists
- `submit()` - Submit the form to the server
- `reset()` - Reset form to initial state
- `isValid`, `isDirty`, `isTouched` - Reactive form state

**Basic Example:**

```html
<script setup>
import { useLiveForm } from 'live_vue'

type UserForm = {
  name: string
  email: string
  skills: string[]
}

const props = defineProps<{ form: Form<UserForm> }>()

const form = useLiveForm(() => props.form, {
  changeEvent: 'validate',
  submitEvent: 'submit'
})

// Type-safe field access
const nameField = form.field('name')
const skillsArray = form.fieldArray('skills')
</script>

<template>
  <div>
    <!-- Field with automatic validation -->
    <input v-bind="nameField.inputAttrs.value" />
    <div v-if="nameField.errorMessage.value">
      {{ nameField.errorMessage.value }}
    </div>

    <!-- Dynamic array -->
    <div v-for="(skillField, index) in skillsArray.fields.value" :key="index">
      <input v-bind="skillField.inputAttrs.value" />
      <button @click="skillsArray.remove(index)">Remove</button>
    </div>
    <button @click="skillsArray.add('')">Add Skill</button>

    <!-- Form actions -->
    <button @click="form.submit()" :disabled="!form.isValid.value">Submit</button>
  </div>
</template>
```

For comprehensive examples including nested objects, complex arrays, and advanced patterns, see [Forms and Validation](forms.md).

### `useLiveConnection()`

The `useLiveConnection` composable provides reactive monitoring of the LiveView WebSocket connectivity status. This is useful for showing connection indicators, handling offline scenarios, or implementing retry logic based on connection state.

**Returns:**

- `connectionState` - Reactive connection state: "connecting", "open", "closing", or "closed"
- `isConnected` - Computed boolean indicating if the socket is currently connected

**Basic Example:**

```html
<script setup>
import { useLiveConnection } from 'live_vue'
import { watch } from 'vue'

const { connectionState, isConnected } = useLiveConnection()

// React to connection changes
watch(connectionState, (state) => {
  console.log(`Connection state changed to: ${state}`)

  if (state === 'closed') {
    // Handle disconnection - maybe show a reconnecting message
    console.log('Lost connection to server')
  } else if (state === 'open') {
    // Handle reconnection - maybe hide offline indicators
    console.log('Connected to server')
  }
})
</script>

<template>
  <div>
    <!-- Connection indicator -->
    <div class="connection-status" :class="{ 'connected': isConnected, 'disconnected': !isConnected }">
      {{ isConnected ? 'Connected' : 'Disconnected' }}
    </div>

    <!-- Show detailed state for debugging -->
    <div v-if="!isConnected" class="text-sm text-gray-500">
      Status: {{ connectionState }}
    </div>
  </div>
</template>

<style scoped>
.connection-status.connected {
  color: green;
}
.connection-status.disconnected {
  color: red;
}
</style>
```

**Advanced Example - Offline Indicator with Retry:**

```html
<script setup>
import { useLiveConnection, useLiveVue } from 'live_vue'
import { ref, computed, watch } from 'vue'

const { connectionState, isConnected } = useLiveConnection()
const live = useLiveVue()

const showOfflineBanner = ref(false)

// Show offline banner after being disconnected for 3 seconds
let offlineTimeout: NodeJS.Timeout | null = null

watch(isConnected, (connected) => {
  if (!connected) {
    // Start offline timer
    offlineTimeout = setTimeout(() => {
      showOfflineBanner.value = true
    }, 3000)
  } else {
    // Clear offline timer and hide banner
    if (offlineTimeout) {
      clearTimeout(offlineTimeout)
      offlineTimeout = null
    }
    showOfflineBanner.value = false
  }
})

const connectionLabel = computed(() => {
  switch (connectionState.value) {
    case 'connecting':
      return 'Connecting...'
    case 'open':
      return 'Connected'
    case 'closing':
      return 'Disconnecting...'
    case 'closed':
      return 'Offline'
    default:
      return 'Unknown'
  }
})
</script>

<template>
  <div>
    <!-- Persistent connection indicator -->
    <div class="fixed top-4 right-4 px-3 py-1 rounded text-sm font-medium z-50"
         :class="{
           'bg-green-100 text-green-800': isConnected,
           'bg-red-100 text-red-800': !isConnected,
           'bg-yellow-100 text-yellow-800': connectionState === 'connecting'
         }">
      {{ connectionLabel }}
    </div>

    <!-- Offline banner -->
    <div v-if="showOfflineBanner"
         class="fixed top-0 left-0 right-0 bg-red-600 text-white text-center py-2 z-40">
      <p>
        You're offline. Check your internet connection.
      </p>
    </div>

    <!-- Your app content -->
    <main :class="{ 'mt-12': showOfflineBanner }">
      <!-- App content here -->
    </main>
  </div>
</template>
```

**Key Features:**

- **Real-time updates**: Connection state updates automatically when WebSocket events occur
- **Automatic cleanup**: Event listeners are properly cleaned up when component unmounts
- **Typed states**: Connection state is typed with exact string values for better TypeScript support
- **Convenience computed**: `isConnected` provides a simple boolean check for most use cases

**Use Cases:**

- Connection status indicators in the UI
- Disabling forms or features when offline
- Implementing custom retry logic
- Showing appropriate messaging during connection issues
- Analytics tracking of connection stability

### `useEventReply(eventName, options)`

The `useEventReply` composable provides a reactive way to handle LiveView events that return server responses. Unlike `useLiveEvent` which only listens for server-sent events, `useEventReply` is for bi-directional communication where you send an event to the server and handle the reply.

This is perfect for scenarios like data fetching, API calls, form submissions, or any operation where you need to wait for and handle a server response.

**Parameters:**

- `eventName` (string) - The name of the event to send to LiveView
- `options` - Configuration object (optional)

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `defaultValue` | `T` | Default value to initialize data with |
| `updateData` | `(reply: T, currentData: T \| null) => T` | Function to transform reply data before storing it (useful for data accumulation) |

**Returns:** [`UseEventReplyReturn<T, P>`](#useeventreplyreturn-interface)

**Basic Example:**

```html
<script setup lang="ts">
import { useEventReply } from 'live_vue'

// Simple data fetching
const { data, isLoading, execute } = useEventReply<User>('fetch_user')

// Fetch user data
const fetchUser = async (userId: number) => {
  try {
    const user = await execute({ id: userId })
    console.log('User fetched:', user)
  } catch (error) {
    console.error('Failed to fetch user:', error)
  }
}
</script>

<template>
  <div>
    <button @click="fetchUser(123)" :disabled="isLoading">
      {{ isLoading ? 'Loading...' : 'Fetch User' }}
    </button>

    <div v-if="data">
      <h3>{{ data.name }}</h3>
      <p>{{ data.email }}</p>
    </div>
  </div>
</template>
```

**Advanced Example with Data Accumulation:**

```html
<script setup lang="ts">
import { useEventReply } from 'live_vue'

interface ChatMessage {
  id: number
  text: string
  user: string
  timestamp: string
}

// Accumulate messages from multiple requests
const { data: messages, isLoading, execute } = useEventReply<ChatMessage[]>('load_messages', {
  defaultValue: [],
  updateData: (newMessages, currentMessages) => {
    // Append new messages to existing ones
    return currentMessages ? [...currentMessages, ...newMessages] : newMessages
  }
})

const loadMoreMessages = async () => {
  const lastMessageId = messages.value[messages.value.length - 1]?.id || 0
  await execute({ after: lastMessageId, limit: 10 })
}
</script>

<template>
  <div>
    <div v-for="message in messages" :key="message.id" class="message">
      <strong>{{ message.user }}:</strong> {{ message.text }}
    </div>

    <button @click="loadMoreMessages" :disabled="isLoading">
      {{ isLoading ? 'Loading...' : 'Load More' }}
    </button>
  </div>
</template>
```

### UseEventReplyReturn Interface

The object returned by `useEventReply()`:

**Reactive state:**

| Property | Type | Description |
|----------|------|-------------|
| `data` | `Ref<T \| null>` | The latest data returned from the server |
| `isLoading` | `Ref<boolean>` | Whether an event execution is currently in progress |

**Actions:**

| Method | Description |
|--------|-------------|
| `execute(params?)` | Execute the event with optional parameters. Returns a Promise that resolves with the server response |
| `cancel()` | Cancel the current execution if one is in progress |

### Key Features

**Execution Control:**
- Only one execution can be active at a time
- Concurrent executions are automatically rejected with a warning
- Use `cancel()` to stop current execution before starting a new one

**Error Handling:**
- Executions return promises that can be caught with try/catch
- Cancelled executions reject with a cancellation error
- Server errors are propagated through the promise rejection

**Data Management:**
- Automatic data updates with optional transformation via `updateData`
- Reactive loading states for UI feedback
- Default values for initial state

**Server-Side Integration:**

In your LiveView, handle the event and return data using the callback:

```elixir
def handle_event("fetch_user", %{"id" => user_id}, socket) do
  case Users.get_user(user_id) do
    {:ok, user} ->
      # Reply with success data
      {:reply, user, socket}

    {:error, :not_found} ->
      # Reply with error data
      {:reply, %{error: "User not found"}, socket}
  end
end
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

Low-level method for handling file uploads to LiveView. This is part of the Phoenix LiveView hook interface and is always available.

> #### Recommendation {: .tip}
>
> For Vue components, prefer the [`useLiveUpload()`](#useliveuploaduploadconfig-options) composable which provides better integration with Vue's reactivity system and handles the required DOM elements automatically.

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

Upload files to a specific LiveView component. This is part of the Phoenix LiveView hook interface.

> #### Recommendation {: .tip}
>
> For Vue components, prefer the [`useLiveUpload()`](#useliveuploaduploadconfig-options) composable for better Vue integration.

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

Creates a LiveVue application instance. For complete configuration options, see [Configuration](configuration.md#vue-application-setup).

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

## AsyncResult Type

LiveVue provides full TypeScript support for Phoenix LiveView's `AsyncResult` struct, allowing type-safe handling of async operations in your Vue components.

### Overview

`AsyncResult<T>` represents the state of an asynchronous operation (like `assign_async`, `stream_async`, or `start_async`) with the following fields:

- `ok`: Boolean indicating if the operation has completed successfully at least once
- `loading`: Loading state - can be `null`, `string[]` (list of keys from `assign_async`), or custom loading data
- `failed`: Error state - unwrapped from Elixir error tuples for JSON compatibility
- `result`: The successful result data of type `T`

### Usage Examples

```typescript
import type { AsyncResult } from 'live_vue'

// Basic async result for a single value
interface Props {
  userResult: AsyncResult<User>
}

// Multi-key async result (from assign_async with multiple keys)
interface MultiProps {
  dataResult: AsyncResult<{ users: User[], posts: Post[] }>
}

const props = defineProps<Props>()

// Check if data is available
if (props.userResult.ok && props.userResult.result) {
  console.log('User:', props.userResult.result.name)
}

// Handle different loading states
if (props.userResult.loading === true) {
  console.log('Loading...')
} else if (Array.isArray(props.userResult.loading)) {
  console.log('Loading keys:', props.userResult.loading) // ['users', 'posts']
} else if (props.userResult.loading) {
  console.log('Custom loading state:', props.userResult.loading)
}

// Handle errors (automatically unwrapped from {:error, reason} tuples)
if (props.userResult.failed) {
  console.error('Failed:', props.userResult.failed) // Direct access to error reason
}
```

### LiveView Integration

In your LiveView, use async operations that create `AsyncResult` structs:

```elixir
def mount(_params, _session, socket) do
  socket =
    socket
    |> assign_async(:user, fn ->
      case Users.get_current_user() do
        {:ok, user} -> {:ok, %{user: user}}
        {:error, reason} -> {:error, reason}
      end
    end)

  {:ok, socket}
end

def handle_event("refresh_data", _params, socket) do
  socket =
    socket
    |> assign_async([:users, :posts], fn ->
      # This creates loading: ["users", "posts"] in the AsyncResult
      {:ok, %{
        users: Users.list_users(),
        posts: Posts.list_posts()
      }}
    end)

  {:noreply, socket}
end
```

The `AsyncResult` will automatically be encoded and passed to your Vue components with proper TypeScript types.

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

// Upload and AsyncResult types (imported from 'live_vue')
import type { UploadConfig, UploadEntry, AsyncResult } from 'live_vue'

interface UploadProps {
  upload: UploadConfig
  uploadedFiles: Array<{ name: string; size: number }>
}

// Upload composable is fully typed
const { entries, showFilePicker, submit } = useLiveUpload(() => props.upload, {
  submitEvent: "save"
})
// entries: Ref<UploadEntry[]>
// showFilePicker: () => void
// submit: () => void

// AsyncResult for handling async operations
interface AsyncProps {
  userAsyncResult: AsyncResult<User>
  dataLoadingResult: AsyncResult<any[], string[]>
}

const props = defineProps<AsyncProps>()

// Type-safe access to async state
if (props.userAsyncResult.ok && props.userAsyncResult.result) {
  console.log('User loaded:', props.userAsyncResult.result.name)
}

// Handle loading states (can be boolean, string array, or custom data)
if (props.dataLoadingResult.loading) {
  if (Array.isArray(props.dataLoadingResult.loading)) {
    console.log('Loading keys:', props.dataLoadingResult.loading) // e.g., ['users', 'posts']
  } else {
    console.log('Loading state:', props.dataLoadingResult.loading)
  }
}

// Handle error states (automatically unwrapped from Elixir tuples)
if (props.userAsyncResult.failed) {
  console.error('Load failed:', props.userAsyncResult.failed) // Direct access to error reason
}
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

### File Upload Pattern

For file uploads, use the built-in [`useLiveUpload()`](#useliveuploaduploadconfig-options) composable instead of creating custom helpers. It provides comprehensive upload management with progress tracking, error handling, and automatic DOM element management.

```html
<script setup>
import { useLiveUpload } from 'live_vue'

const props = defineProps<{ upload: UploadConfig }>()

const {
  entries,
  showFilePicker,
  submit,
  cancel,
  progress,
  valid
} = useLiveUpload(() => props.upload, {
  changeEvent: "validate",
  submitEvent: "save"
})

// All upload state is handled automatically:
// - entries: reactive list of files with progress
// - progress: overall upload progress (0-100)
// - valid: whether current selection is valid
</script>

<template>
  <div>
    <button @click="showFilePicker">Choose Files</button>
    <div v-if="entries.length">Progress: {{ progress }}%</div>

    <div v-for="entry in entries" :key="entry.ref">
      {{ entry.client_name }} - {{ entry.progress }}%
      <button @click="cancel(entry.ref)">×</button>
    </div>
  </div>
</template>
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

- [Basic Usage](basic_usage.md) for fundamental patterns and examples
- [Forms and Validation](forms.md) for comprehensive form handling with useLiveForm
- [Component Reference](component_reference.md) for LiveView-side API
- [Configuration](configuration.md) for advanced setup options
- [Testing](testing.md) for testing client-side code