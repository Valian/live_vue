# Basic Usage

This guide covers the fundamental patterns for using Vue components within LiveView.

## Component Organization

By default, Vue components should be placed in either:
- `assets/vue` directory
- Colocated with your LiveView files in `lib/my_app_web`

For advanced component organization and custom resolution patterns, see [Configuration](configuration.md#component-organization).

## Rendering Components

### Basic Syntax

To render a Vue component from HEEX, use the `<.vue>` function:

```elixir
<.vue
  count={@count}
  v-component="Counter"
  v-socket={@socket}
  v-on:inc={JS.push("inc")}
/>
```

### Required Attributes

| Attribute    | Example                | Required        | Description                                    |
|--------------|------------------------|-----------------|------------------------------------------------|
| v-component  | `v-component="Counter"`| Yes            | Component name or path relative to vue_root    |
| v-socket     | `v-socket={@socket}`   | Yes in LiveView| Required for SSR and reactivity               |

### Optional Attributes

| Attribute    | Example              | Description                                    |
|--------------|----------------------|------------------------------------------------|
| v-ssr        | `v-ssr={true}`      | Override default SSR setting                   |
| v-on:event   | `v-on:inc={JS.push("inc")}` | Handle Vue component events           |
| prop={@value}| `count={@count}`     | Pass props to the component                   |

### Component Shortcut

Instead of writing `<.vue v-component="Counter">`, you can use the shortcut syntax:

```elixir
<.Counter count={@count} v-socket={@socket} />
```

Function names are generated based on `.vue` file names. For files with identical names, use the full path:

```elixir
<.vue v-component="helpers/nested/Modal" />
```

## Passing Props

Props can be passed in three equivalent ways:

```elixir
# Individual props
<.vue count={@count} max={123} v-component="Counter" v-socket={@socket} />

# Map spread
<.vue v-component="Counter" v-socket={@socket} {@props} />

# Using shortcut - you don't have to specify v-component
<.Counter count={@count} max={123} v-socket={@socket} />
```

### Custom Structs as Props

When passing custom structs as props, you must implement the `LiveVue.Encoder` protocol:

```elixir
defmodule User do
  @derive LiveVue.Encoder
  defstruct [:name, :email, :age]
end

# Use in your LiveView
def render(assigns) do
  ~H"""
  <.vue
    user={@current_user}
    v-component="UserProfile"
    v-socket={@socket}
  />
  """
end
```

The encoder protocol ensures that only specified fields are sent to the client, sensitive data is protected, and props can be efficiently diffed for updates.

For complete implementation details including field selection and custom implementations, see [Component Reference](component_reference.md#custom-structs-with-livevue-encoder).

> #### Protocol.UndefinedError {: .warning}
>
> If you get a `Protocol.UndefinedError` when passing structs as props, it means you need to implement the `LiveVue.Encoder` protocol for that struct. This is a safety feature to prevent accidental exposure of sensitive data.

## Handling Events

### Phoenix Events

All standard Phoenix event handlers work inside Vue components:
- `phx-click`
- `phx-change`
- `phx-submit`
- etc.

They will be pushed directly to LiveView, exactly as happens with `HEEX` components.

### Programmatic access to hook instance

There are two ways to access the Phoenix LiveView hook instance from your Vue components:

1.  **`useLiveVue()` Composable (in `<script setup>`):**

    Use the `useLiveVue()` composable when you need to access the hook instance for logic within your `<script setup>` block. It's ideal for pushing events programmatically.

    ```html
    <script setup>
    import { useLiveVue } from "live_vue"
    import { ref } from "vue"

    const live = useLiveVue()
    const name = ref("")

    function save() {
      live.pushEvent("save", { name: name.value })
    }
    </script>
    ```

    To listen for events from the server, the easiest way is to use the `useLiveEvent` composable, which will automatically handle cleanup for you.

    ```html
    <script setup>
    import { useLiveEvent } from "live_vue"

    // Example: listening for a server event
    useLiveEvent("response", (payload) => { console.log(payload) })
    </script>
    ```

2.  **`$live` Property (in `<template>`):**

    For convenience, the hook instance is also available directly in your template as the `$live` property. This is the preferred method for simple, one-off event pushes directly from the template, as it avoids the need to import and call `useLiveVue()`.

    ```html
    <template>
      <button @click="$live.pushEvent('hello', { value: 'world' })">
        Click me
      </button>
    </template>
    ```

The `live` object provides all methods from [Phoenix.LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook). For a complete API reference, see [Client-Side API](client_api.md).

### LiveView Navigation

For navigation, LiveVue provides a built-in `Link` component that makes using `live_patch` and `live_redirect` as easy as using a standard `<a>` tag.

```html
<script setup>
import { Link } from "live_vue"
</script>

<template>
  <nav>
    <!-- Behaves like a normal link -->
    <Link href="/about">About</Link>

    <!-- Performs a `live_patch` -->
    <Link patch="/users?sort=name">Sort by Name</Link>

    <!-- Performs a `live_redirect` -->
    <Link navigate="/dashboard">Dashboard</Link>
  </nav>
</template>
```

For a complete API reference, see [Client-Side API](client_api.md#link).

### Vue Events

If you want to create reusable Vue components where you'd like to define what happens when Vue emits an event, you can use the `v-on:` syntax with `JS` [module helpers](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#module-client-utility-commands).

```elixir
<.vue
  v-on:submit={JS.push("submit")}
  v-on:close={JS.hide()}
  v-component="Form"
  v-socket={@socket}
/>
```

Special case: When using `JS.push()` without a value, it automatically uses the emit payload:
```elixir
# In Vue
emit('inc', {value: 5})

# In LiveView
<.vue v-on:inc={JS.push("inc")} />
# Equivalent to: JS.push("inc", value: 5)
```

## Slots Support

Vue components can receive slots from LiveView templates:

```elixir
<.Card title="Example Card" v-socket={@socket}>
  <p>This is the default slot content!</p>
  <p>Phoenix components work too: <.icon name="hero-info" /></p>

  <:footer>
    This is a named slot
  </:footer>
</.Card>
```

```html
<template>
  <div>
    <!-- Default slot -->
    <slot></slot>

    <!-- Named slot -->
    <slot name="footer"></slot>
  </div>
</template>
```

Important notes about slots:
- Each slot is wrapped in a div (technical limitation)
- You can use HEEX components inside slots 🥳
- Slots stay reactive and update when their content changes


> #### Hooks inside slots are not supported {: .warning}
>
> Slots are rendered server-side and then sent to the client as a raw HTML.
> It happens outside of the LiveView lifecycle, so hooks inside slots are not supported.
>
> As a consequence, since `.vue` components rely on hooks, it's not possible to nest `.vue` components inside other `.vue` components.

## File Uploads

LiveVue provides seamless integration with Phoenix LiveView's file upload system through the `useLiveUpload()` composable. This handles all the complexity of managing upload state, progress tracking, and DOM elements automatically.

### Server Setup

First, configure your LiveView with `allow_upload`:

```elixir
defmodule MyAppWeb.UploadLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:documents,
       accept: ~w(.pdf .txt .jpg .png),
       max_entries: 3,
       max_file_size: 5_000_000,  # 5MB
       auto_upload: true          # Files upload immediately when selected
     )}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :documents, fn %{path: path}, entry ->
        # Process your file here
        dest = Path.join("uploads", entry.client_name)
        File.cp!(path, dest)
        {:ok, %{name: entry.client_name, size: entry.client_size}}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.vue
        upload={@uploads.documents}
        uploaded_files={@uploaded_files}
        v-component="FileUploader"
        v-socket={@socket}
      />
    </div>
    """
  end
end
```

### Vue Component

Create a Vue component that uses `useLiveUpload()`:

```html
<!-- assets/vue/FileUploader.vue -->
<script setup lang="ts">
import { useLiveUpload, UploadConfig } from 'live_vue'

interface Props {
  upload: UploadConfig
  uploadedFiles: { name: string; size: number }[]
}

const props = defineProps<Props>()

const {
  entries,
  showFilePicker,
  submit,
  cancel,
  progress,
  valid
} = useLiveUpload(() => props.upload, {
  changeEvent: "validate",  // Optional: for file validation
  submitEvent: "save"       // Required: for processing uploads
})
</script>

<template>
  <div class="upload-container">
    <!-- Upload controls -->
    <div class="controls">
      <button @click="showFilePicker" class="btn-primary">
        Choose Files
      </button>

      <!-- Manual upload for non-auto uploads -->
      <button
        v-if="!upload.auto_upload && entries.length > 0"
        @click="submit"
        class="btn-success"
      >
        Upload Files
      </button>

      <!-- Cancel all -->
      <button
        v-if="entries.length > 0"
        @click="cancel()"
        class="btn-danger"
      >
        Cancel All
      </button>
    </div>

    <!-- Progress indicator -->
    <div v-if="entries.length > 0" class="progress">
      Overall Progress: {{ progress }}%
    </div>

    <!-- File list -->
    <div class="file-list">
      <div v-for="entry in entries" :key="entry.ref" class="file-entry">
        <div class="file-info">
          <span class="name">{{ entry.client_name }}</span>
          <span class="size">{{ entry.client_size }} bytes</span>
          <span class="progress">{{ entry.progress }}%</span>
          <span :class="entry.done ? 'done' : 'pending'">
            {{ entry.done ? 'Complete' : 'Uploading...' }}
          </span>
        </div>

        <!-- Individual file errors -->
        <div v-if="entry.errors?.length" class="errors">
          <div v-for="error in entry.errors" :key="error">{{ error }}</div>
        </div>

        <button @click="cancel(entry.ref)" class="cancel-btn">×</button>
      </div>
    </div>

    <!-- Uploaded files -->
    <div v-if="uploadedFiles.length" class="uploaded-files">
      <h3>Uploaded Files</h3>
      <div v-for="file in uploadedFiles" :key="file.name">
        {{ file.name }} ({{ file.size }} bytes)
      </div>
    </div>
  </div>
</template>
```

### Key Features

- **Automatic DOM management**: The composable creates and manages the required file input elements
- **Progress tracking**: Real-time progress updates for individual files and overall progress
- **Error handling**: Validation errors are automatically displayed
- **Auto-upload support**: Files can upload immediately when selected, or manually triggered
- **Drag & drop**: Use `addFiles()` method to support drag-and-drop functionality
- **Cancellation**: Cancel individual files or all uploads

For the complete API reference, see [`useLiveUpload()` in the Client API guide](client_api.md#useliveuploadevent-callback).

## Phoenix Streams

LiveVue provides full support for Phoenix LiveView's `stream()` operations. Since LiveVue already sends minimal JSON patches for all props updates, streams primarily help reduce server memory consumption by not keeping large collections in the socket assigns.

### Why Use Streams?

Streams are ideal for:
- Lists with many items where you want to avoid keeping all data in memory
- Real-time data like chat messages, notifications, or live feeds

Note: LiveVue's automatic JSON patch diffing already ensures efficient client updates for regular props, so the main benefit of streams is server-side memory efficiency.

### Server Setup

Configure your LiveView to use streams:

```elixir
defmodule MyAppWeb.ItemsLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.vue items={@streams.items} v-component="ItemList" v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    # Initialize with sample items
    items = [
      %{id: 1, name: "Item 1"},
      %{id: 2, name: "Item 2"},
      %{id: 3, name: "Item 3"}
    ]

    {:ok, stream(socket, :items, items)}
  end

  def handle_event("add_item", %{"name" => name}, socket) do
    new_item = %{ id: Enum.random(1..1000), name: name }
    {:noreply, stream_insert(socket, :items, new_item)}
  end

  def handle_event("remove_item", %{"id" => id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :items, "item-#{id}")}
  end

end
```

### Vue Component

Create a Vue component that receives and renders the stream:

```html
<!-- assets/vue/ItemList.vue -->
<script setup lang="ts">
import { useLiveVue } from 'live_vue'
import { ref } from 'vue'

const props = defineProps<{
  items: {
    id: number
    name: string
  }[]
}>()

const live = useLiveVue()
const newName = ref('')

function addItem() {
  if (newName.value) {
    // Use $live to push events to LiveView
    live.pushEvent('add_item', { name: newName.value })
    newName.value = ''
  }
}
</script>

<template>
  <div>
    <!-- Add new item form -->
    <div>
      <input v-model="newName" placeholder="Item name" />
      <button @click="addItem">Add Item</button>
    </div>

    <!-- Items list -->
    <div>
      <div v-for="item in items" :key="item.id" >
        <h3>{{ item.name }}</h3>
        <button @click="$live.pushEvent('remove_item', { id: item.id })">
          Remove
        </button>
      </div>
    </div>
    <div v-if="items.length === 0" >No items yet.</div>
  </div>
</template>
```

### Key Features

- **Memory Efficient**: Reduces server memory usage by not storing large collections in socket assigns
- **Transparent Updates**: When you use `stream_insert()`, `stream_delete()`, or other stream operations, LiveVue automatically patches only the affected items
- **State Preservation**: Vue component state (like form inputs, local variables) is preserved during stream updates
- **Same API as HEEX**: Use `@streams.items` exactly as you would in a HEEX template
- **Automatic Patches**: LiveVue's existing JSON patch system handles efficient client updates

### Advanced Stream Operations

All Phoenix stream operations work seamlessly:

```elixir
# Add item at specific position
stream_insert(socket, :items, new_item, at: 0)

# Add multiple items with limits
stream(socket, :items, new_items, at: -1, limit: -5)

# Reset entire stream
stream(socket, :items, new_items, reset: true)

# Delete by DOM ID
stream_delete_by_dom_id(socket, :items, "item-123")
```

The Vue component will automatically receive these updates and maintain its local state throughout all operations.

## Dead Views vs Live Views

Components can be used in both contexts:
- Live Views: Full reactivity with WebSocket updates
- Dead Views: Static rendering, no reactivity
  - `v-socket={@socket}` not required
  - SSR still works for initial render

## Using ~VUE Sigil

The `~VUE` sigil provides an alternative to the standard LiveView DSL, allowing you to write Vue components directly in your LiveView:

> #### Deprecation Notice {: .warning}
>
> The `~V` sigil is deprecated in favor of `~VUE`. It will be removed in future versions.

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~VUE"""
    <script setup lang="ts">
    import {ref} from "vue"
    const props = defineProps<{count: number}>()
    const diff = ref(1)
    </script>

    <template>
      Current count: {{ props.count }}
      <label>Diff: </label>
      <input v-model.number="diff" type="range" min="1" max="10" />

      <button phx-click="inc" :phx-value-diff="diff">
        Increase counter by {{ diff }}
      </button>
    </template>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("inc", %{"diff" => diff}, socket) do
    {:noreply, update(socket, :count, &(&1 + String.to_integer(diff)))}
  end
end
```

The `~VUE` sigil is a powerful macro that compiles the string content into a full-fledged Vue component at compile time. It automatically passes all of the LiveView's `assigns` as props to the component, making it easy to create reactive components.

**When to use the `~VUE` sigil:**

*   **Prototyping:** Quickly build and iterate on new components without creating new files.
*   **Single-use components:** Ideal for components that are tightly coupled to a specific LiveView and won't be reused.
*   **Co-location:** Keep server-side and client-side logic for a piece of functionality within a single file.

**When to use `.vue` files instead:**

*   **Reusability:** When you need to use the same component in multiple LiveViews.
*   **Large components:** For complex components, a dedicated file improves organization and editor support.
*   **Collaboration:** Separate files are often easier for teams to work on simultaneously.

## Next Steps

Now that you understand the basics, you might want to explore:

- [Forms and Validation](forms.md) for complex forms with server-side validation
- [Component Reference](component_reference.md) for complete syntax documentation
- [Configuration](configuration.md) for advanced setup and customization options
- [Client-Side API](client_api.md) for detailed API reference and advanced patterns
- [FAQ](faq.md) for common questions and troubleshooting