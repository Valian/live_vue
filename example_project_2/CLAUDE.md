This is a web application written using the Phoenix web framework.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps
### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

<!-- usage-rules-start -->
<!-- phoenix:elixir-start -->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason
<!-- phoenix:elixir-end -->
<!-- phoenix:phoenix-start -->
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it
<!-- phoenix:phoenix-end -->
<!-- phoenix:html-start -->
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>
<!-- phoenix:html-end -->
<!-- phoenix:liveview-start -->
## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and  `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`
- Remember anytime you use `phx-hook="MyHook"` and that js hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Never** write embedded `<script>` tags in HEEx. Instead always write your scripts and hooks in the `assets/js` directory and integrate them with the `assets/js/app.js` file

### LiveView streams

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams are *not* enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
        socket
        |> assign(:messages_empty?, messages == [])
        # reset the stream with the new messages
        |> stream(:messages, messages, reset: true)}
      end

- LiveView streams *do not support counting or empty states*. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Instead of relying on testing text content, which can change, favor testing for the presence of key elements
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors
- **Never** use `<.form let={f} ...>` in the template, instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset
<!-- phoenix:liveview-end -->
<!-- usage-rules-end -->

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