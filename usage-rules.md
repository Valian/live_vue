# LiveVue Usage Rules

This document outlines best practices, conventions, and usage patterns for the LiveVue library. Following these guidelines will help you build maintainable, performant applications that leverage Vue.js components within Phoenix LiveView.

**Key Principle**: The LiveView holds the source of truth. Vue components are reactive views of server state with their own client-side state.

## Component Organization

### File Structure

**DO** keep Vue components in the `assets/vue` directory. Organize them in a sensible way:

```
assets/
  vue/
    index.ts # this is the entry point for the Vue app
    components/
      ui/
        Button.vue
        Modal.vue
      forms/
        ContactForm.vue
    pages/
      Dashboard.vue
    shared/
      Layout.vue
```

### Component Naming

**DO** use PascalCase for component file names, longer than a single word:

```
✅ UserProfile.vue
✅ ShoppingCart.vue
✅ ContactForm.vue
```

**DO NOT** use kebab-case or snake_case for file names:

```
❌ user-profile.vue
❌ shopping_cart.vue
```

**Use** the same name in the `v-component` attribute (match case exactly, without the extension). **Always** pass the socket to the component:

```elixir
<.vue v-component="UserProfile" user={@user} v-socket={@socket} />
```

## Props and Data Flow

### Props Passing

**DO** pass all necessary data as props from LiveView. Always pass the socket to the component:

```elixir
<.vue
  v-component="ShoppingCart"
  v-socket={@socket}
  cartItems={@cart_items}
  cartTotal={@cart_total}
  currency={@currency}
/>
```

**DO NOT** rely on Vue components to fetch their own data:

```vue
❌ <!-- WRONG: Fetching data in Vue component -->
<script setup>
import { onMounted, ref } from 'vue'

const items = ref([])

onMounted(async () => {
  const response = await fetch('/api/cart')
  items.value = await response.json()
})
</script>
```

### Custom Struct Encoding

**DO** implement the `LiveVue.Encoder` protocol for custom structs:

```elixir
defmodule MyApp.User do
  # You can derive the protocol if it doesn't need any customization
  @derive {LiveVue.Encoder, only: [:id, :name, :email]}
  defstruct [:id, :name, :email, :private_field]
end

defimpl LiveVue.Encoder, for: MyApp.User do
  def encode(user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email
      # private_field intentionally omitted
    }
  end
end
```

**DO NOT** pass structs without implementing the encoder protocol:

```elixir
❌ # This will raise Protocol.UndefinedError
<.vue v-component="UserCard" user={%MyApp.User{}} />
```

## Event Handling

### Phoenix handle_event

**Use** Phoenix event handlers for most interactions:

```elixir
defmodule MyApp.Live.ContactForm do
  use LiveVue, :live_view

  def handle_event("like_post", %{"post_id" => post_id}, socket) do
    # handle the event here
    {:noreply, socket}
  end
end
```

### Client-side events

**Use** `useLiveVue().pushEvent()` or in the template `$live.pushEvent()` API for dynamic events. `useLiveVue()` and `$live` are the same thing - Vue phoenix hook instance.

```vue
<script setup>
import { useLiveVue } from 'live_vue'

const live = useLiveVue()

const handleCustomAction = (data) => {
  live.pushEvent('custom_action', data)
}
</script>

<template>
  <!-- You can also use $live directly in templates -->
  <button @click="$live.pushEvent('simple_action', { value: 'hello' })">
    Click me
  </button>
</template>
```

**DO** use `useLiveEvent()` for server-to-client communication. It handles component lifecycle correctly.

```vue
<script setup>
import { useLiveEvent } from 'live_vue'

useLiveEvent('notification', (data) => {
  // Handle server-sent notification
  console.log('Received:', data)
})
</script>
```

## Server-Side Rendering (SSR)

By default, live_vue uses SSR.**DO** disable SSR for components with client-only dependencies:

```elixir
<.vue
  v-component="ClientOnlyMap"
  v-socket={@socket}
  v-ssr={false}
/>
```

## Navigation and Routing

### Template links supporting LiveView navigation

```vue
<script setup>
import { Link } from 'live_vue'
</script>

<template>
  <!-- Normal link -->
  <Link href="/">Home</Link>
  <!-- Navigate to a different route -->
  <Link navigate="/users">Users</Link>
  <!-- Patch the current route with different params -->
  <Link patch="/users/3">User 3</Link>
  <!-- Patch the current route with query params and replace the history -->
  <Link patch="/users/3?details=true" replace>User 3 with details</Link>
</template>
```

### Navigation Hook

**Use** `useLiveNavigation()` for programmatic navigation:

```vue
<script setup>
import { useLiveNavigation } from 'live_vue'

const { patch, navigate } = useLiveNavigation()

// Same route, different params
const updateUser = (user) => patch(`/users/${user.id}`)

// Same route, different query params with replace history
const goToTab = (tab) => patch({ tab: tab }, { replace: true })

// Different route
const goToPage = (path) => navigate(path)
</script>
```

**Prefer** `<Link>` components in templates, unless not possible.

## File Uploads

### Upload Hook

**Use** `useLiveUpload()` for file upload functionality. Server-side upload is supported by LiveView in the exact same way as when using HEEX templates.

```vue
<script setup>
import { useLiveUpload } from 'live_vue'

const {
  entries,
  progress,
  showFilePicker,
  addFiles,
  submit,
  cancel,
  clear,
  valid
} = useLiveUpload(
  () => props.uploadConfig,
  {
    changeEvent: 'validate_upload',
    submitEvent: 'save_upload'
  }
)
</script>
```

**Use** `addFiles()` for drag-and-drop:

```vue
<template>
  <div
    @drop.prevent="addFiles($event.dataTransfer)"
    @dragover.prevent
    class="upload-zone"
  >
    <p v-if="entries.length === 0">Drop files here or</p>
    <button @click="showFilePicker">Choose Files</button>

    <!-- Show upload progress -->
    <div v-if="entries.length > 0" class="upload-progress">
      <div v-for="entry in entries" :key="entry.ref">
        {{ entry.client_name }} - {{ entry.progress }}%
        <button @click="cancel(entry.ref)">Cancel</button>
      </div>
      <p>Overall progress: {{ progress }}%</p>
      <p v-if="!valid" class="error">Upload has errors</p>
    </div>
  </div>
</template>
```

## Testing

### Component Testing

**Test** Vue components through LiveView integration:

```elixir
test "renders user profile component", %{conn: conn} do
  {:ok, view, _html} = live(conn, "/users/1")

  # Get Vue component by name or id. Optional if there is only one component on the page.
  vue_config = LiveVue.Test.get_vue(view, name: "UserProfile")
  # or by ID: vue_config = LiveVue.Test.get_vue(view, id: "user-profile-1")
  # or without any arguments: vue_config = LiveVue.Test.get_vue(view)

  assert vue_config.props["name"] == "John Doe"
  assert vue_config.props["email"] == "john@example.com"
  assert vue_config.component == "UserProfile"

  render_hook(view, "toggle_details", %{"details" => true})

  # Details should now be true.
  %{props: props} = LiveVue.Test.get_vue(view)
  assert props["details"] == true
end
```


## Troubleshooting

Problem: Component is not found on the client side
Solution:
1. Make sure you use the correct name in the `v-component` attribute (should match file name exactly, without the extension).
2. Restart the server to pick up newly created components.
3. Ensure resolve function can find that component in `assets/vue/index.ts`.


## Forms and Validation

### Using useLiveForm Hook

**Use** `useLiveForm()` for complex forms with validation, arrays, and nested objects:

```vue
<script setup>
import { Form, useLiveForm } from 'live_vue'

type UserForm = {
  name: string
  email: string
  tags: string[]
  profile: {
    bio: string
    skills: Array<{ name: string; level: string }>
  }
}

const props = defineProps<{ form: Form<UserForm> }>()

const form = useLiveForm(() => props.form, {
  changeEvent: 'validate',     // Event sent on field changes (null to disable)
  submitEvent: 'submit',       // Event sent on form submission
  debounceInMiliseconds: 300,  // Debounce validation requests
  prepareData: (data) => data  // Transform data before sending
})

// Basic field access
const nameField = form.field('name')
const emailField = form.field('email')

// Nested object fields
const bioField = form.field('profile.bio')

// Array fields
const tagsArray = form.fieldArray('tags')
const skillsArray = form.fieldArray('profile.skills')

// Nested array fields are also supported
const firstSkillNameField = form.field('profile.skills[0].name')

// Field operations
const addTag = () => tagsArray.add('')
const removeTag = (index) => tagsArray.remove(index)
</script>

<template>
  <!-- Basic field with validation -->
  <input
    v-bind="nameField.inputAttrs.value"
    :class="{ 'error': nameField.isTouched.value && nameField.errorMessage.value }"
  />
  <div v-if="nameField.errorMessage.value">
    {{ nameField.errorMessage.value }}
  </div>

  <!-- Array iteration -->
  <div v-for="(tagField, index) in tagsArray.fields.value" :key="index">
    <input v-bind="tagField.inputAttrs.value" />
    <button @click="removeTag(index)">Remove</button>
  </div>

  <!-- Form actions -->
  <button @click="form.submit()" :disabled="!form.isValid.value">
    Submit
  </button>
  <button @click="form.reset()">Reset</button>
</template>
```

### Form Field Properties

Each field provides reactive state and helpers:

```typescript
interface FormField<T> {
  // Reactive state
  value: Ref<T>                    // Current field value
  errors: Ref<string[]>            // Validation errors from server
  errorMessage: Ref<string>        // First error message
  isValid: Ref<boolean>            // No validation errors
  isDirty: Ref<boolean>            // Value changed from initial
  isTouched: Ref<boolean>          // Field has been interacted with

  // Input binding helper (includes value, events, accessibility)
  inputAttrs: Ref<{
    value: T
    onInput: (event: Event) => void
    onFocus: () => void
    onBlur: () => void
    name: string
    id: string
    'aria-invalid': boolean
    'aria-describedby'?: string
  }>

  // Navigation methods for nested structures
  field(key): FormField           // Access nested object field
  fieldArray(key): FormFieldArray // Access nested array field
}

interface FormFieldArray<T> extends FormField<T[]> {
  // Array-specific methods
  add: (item?: Partial<T>) => void
  remove: (index: number) => void
  move: (from: number, to: number) => void

  // Reactive array of field instances for iteration
  fields: Readonly<Ref<FormField<T>[]>>
}

interface UseLiveFormReturn<T extends object> {
  // Form-level state
  isValid: Ref<boolean>
  isDirty: Ref<boolean>
  isTouched: Ref<boolean>
  submitCount: Readonly<Ref<number>>
  initialValues: Readonly<Ref<T>>

  // Type-safe field factory functions
  field(key): FormField
  fieldArray(key): FormFieldArray

  // Form actions
  submit: () => Promise<void>
  reset: () => void
}
```

### Server-Side Form Setup

**Set up** server-side forms in the standard way:

```elixir
defmodule MyApp.Live.FormTest do
  use LiveVue, :live_view

  def render(assigns) do
    ~H"""
    <.vue form={@form} v-component="UserForm" v-socket={@socket} />
    """
  end

  def mount(params, socket) do
    changeset = MyApp.User.changeset(%MyApp.User{}, %{})
    socket = assign(socket, form: to_form(changeset, as: :user))
    {:ok, socket}
  end

  def handle_event("validate", params, socket) do
    changeset = MyApp.User.changeset(%MyApp.User{}, params)
    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("submit", params, socket) do
    changeset = MyApp.User.changeset(%MyApp.User{}, params)
    case Repo.insert(changeset) do
      {:ok, _user} ->
        {:noreply, socket}
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end
end
```

## Common Anti-Patterns

### State Management

**DO NOT** use Vue state stores (Pinia, Vuex) for application state:

```vue
❌ <!-- WRONG: Using Pinia for app state -->
<script setup>
import { useUserStore } from '@/stores/user'
const userStore = useUserStore()
</script>
```

**DO** use LiveView state with reactive props:

```elixir
✅ <!-- CORRECT: Server-side state -->
def handle_event("update_user", params, socket) do
  # Update state on server
  {:noreply, assign(socket, user: updated_user)}
end
```