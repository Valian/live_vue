# Forms and Validation

This guide covers the `useLiveForm` composable for building complex forms with server-side validation, nested objects, and dynamic arrays in LiveVue.

> #### Getting Started {: .tip}
>
> New to LiveVue? Check out [Basic Usage](basic_usage.md) for fundamental patterns before diving into forms.

## Quick Example

Here's how a typical form setup looks with `useLiveForm`:

**Vue Component:**
```html
<script setup lang="ts">
import { useLiveForm, type Form } from 'live_vue'

type UserForm = {
  name: string
  email: string
  profile: {
    bio: string
    skills: string[]
  }
}

const props = defineProps<{ form: Form<UserForm> }>()

const form = useLiveForm(() => props.form, {
  changeEvent: 'validate',     // Send validation requests on changes
  submitEvent: 'submit',       // Event sent on form submission
  debounceInMiliseconds: 300   // Debounce validation requests
})

// Access fields with full type safety
const nameField = form.field('name')
const emailField = form.field('email')
const bioField = form.field('profile.bio')
const skillsArray = form.fieldArray('profile.skills')
</script>

<template>
  <div>
    <!-- Basic field with validation -->
    <input
      v-bind="nameField.inputAttrs.value"
      :class="{ error: nameField.isTouched.value && nameField.errorMessage.value }"
    />
    <div v-if="nameField.errorMessage.value">
      {{ nameField.errorMessage.value }}
    </div>

    <!-- Array field with add/remove -->
    <div v-for="(skillField, index) in skillsArray.fields.value" :key="index">
      <input v-bind="skillField.inputAttrs.value" placeholder="Enter skill" />
      <button @click="skillsArray.remove(index)">Remove</button>
    </div>
    <button @click="skillsArray.add('')">Add Skill</button>

    <!-- Form actions -->
    <button @click="form.submit()" :disabled="!form.isValid.value || form.isValidating.value">
      {{ form.isValidating.value ? 'Validating...' : 'Submit' }}
    </button>
    <button @click="form.reset()">Reset</button>
  </div>
</template>
```

**LiveView Setup:**
```elixir
defmodule MyAppWeb.UserFormLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.vue form={@form} v-component="UserForm" v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    changeset = User.changeset(%User{}, %{})
    {:ok, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset = User.changeset(%User{}, params)
    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    changeset = User.changeset(%User{}, params)
    case Repo.insert(changeset) do
      {:ok, _user} -> {:noreply, redirect(socket, to: "/")}
      {:error, changeset} -> {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end
end
```

## Why useLiveForm?

Traditional client-side forms present several challenges:
- **Validation synchronization** between client and server
- **Complex state management** for nested objects and arrays
- **Type safety** for deeply nested form structures
- **Accessibility** and proper ARIA attributes
- **User experience** patterns like field states and error handling

The `useLiveForm` composable solves these problems by:
- Providing seamless server-side validation with debouncing
- Offering type-safe field access for complex structures
- Managing all form state reactively (dirty, touched, valid)
- Automatically generating proper input attributes and accessibility features
- Handling nested objects and dynamic arrays with ease

## Basic Usage

### Setting Up a Form

First, set up your LiveView with form handling:

```elixir
defmodule MyAppWeb.ContactFormLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.vue form={@form} v-component="ContactForm" v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    changeset = Contact.changeset(%Contact{}, %{})
    {:ok, assign(socket, form: to_form(changeset, as: :contact))}
  end

  def handle_event("validate", %{"contact" => params}, socket) do
    changeset = Contact.changeset(%Contact{}, params)
    {:noreply, assign(socket, form: to_form(changeset, as: :contact))}
  end

  def handle_event("submit", %{"contact" => params}, socket) do
    changeset = Contact.changeset(%Contact{}, params)

    case Repo.insert(changeset) do
      {:ok, contact} ->
        {:noreply, put_flash(socket, :info, "Contact created successfully!")}
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :contact))}
    end
  end
end
```

### Creating the Vue Component

Create a Vue component that uses `useLiveForm`:

```html
<script setup lang="ts">
import { useLiveForm, type Form } from 'live_vue'

type ContactForm = {
  name: string
  email: string
  subject: string
  message: string
}

const props = defineProps<{ form: Form<ContactForm> }>()

const form = useLiveForm(() => props.form, {
  changeEvent: 'validate',
  submitEvent: 'submit'
})

// Create typed field references
const nameField = form.field('name')
const emailField = form.field('email')
const subjectField = form.field('subject')
const messageField = form.field('message')
</script>

<template>
  <div class="contact-form">
    <div class="field">
      <label :for="nameField.inputAttrs.value.id">Name</label>
      <input
        v-bind="nameField.inputAttrs.value"
        :class="{ error: nameField.isTouched.value && nameField.errorMessage.value }"
      />
      <div v-if="nameField.errorMessage.value" class="error-message">
        {{ nameField.errorMessage.value }}
      </div>
    </div>

    <div class="field">
      <label :for="emailField.inputAttrs.value.id">Email</label>
      <input
        v-bind="emailField.inputAttrs.value"
        type="email"
        :class="{ error: emailField.isTouched.value && emailField.errorMessage.value }"
      />
      <div v-if="emailField.errorMessage.value" class="error-message">
        {{ emailField.errorMessage.value }}
      </div>
    </div>

    <div class="field">
      <label :for="subjectField.inputAttrs.value.id">Subject</label>
      <input v-bind="subjectField.inputAttrs.value" />
      <div v-if="subjectField.errorMessage.value" class="error-message">
        {{ subjectField.errorMessage.value }}
      </div>
    </div>

    <div class="field">
      <label :for="messageField.inputAttrs.value.id">Message</label>
      <textarea
        v-bind="messageField.inputAttrs.value"
        rows="5"
        :class="{ error: messageField.isTouched.value && messageField.errorMessage.value }"
      />
      <div v-if="messageField.errorMessage.value" class="error-message">
        {{ messageField.errorMessage.value }}
      </div>
    </div>

    <div class="form-actions">
      <button @click="form.reset()" type="button">Reset</button>
      <button
        @click="form.submit()"
        :disabled="!form.isValid.value"
        type="submit"
      >
        Submit
      </button>
    </div>

    <!-- Optional: Form state display -->
    <div class="form-status">
      <p>Valid: {{ form.isValid.value }}</p>
      <p>Dirty: {{ form.isDirty.value }}</p>
      <p>Touched: {{ form.isTouched.value }}</p>
      <p>Validating: {{ form.isValidating.value }}</p>
    </div>
  </div>
</template>
```

## API Reference

### useLiveForm(form, options)

Creates a reactive form instance with validation and state management.

**Parameters:**
- `form` - Reactive reference to the form data from LiveView (typically `() => props.form`)
- `options` - Configuration object for form behavior

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `changeEvent` | `string \| null` | `null` | Event sent on field changes (set to `null` to disable validation events) |
| `submitEvent` | `string` | `"submit"` | Event sent on form submission |
| `debounceInMiliseconds` | `number` | `300` | Debounce delay for change events to reduce server load |
| `prepareData` | `function` | `(data) => data` | Transform data before sending to server |

**Returns:** [`UseLiveFormReturn<T>`](#useliveformreturn-interface)

### Form Interface

The form data structure passed from LiveView:

| Property | Type | Description |
|----------|------|-------------|
| `name` | `string` | Form identifier (e.g., "user", "contact") |
| `values` | `T` | Current form values |
| `errors` | `object` | Validation errors from server (nested structure matching form shape) |
| `valid` | `boolean` | Whether the form is valid |

### UseLiveFormReturn Interface

The object returned by `useLiveForm()`:

**Form-level state:**

| Property | Type | Description |
|----------|------|-------------|
| `isValid` | `Ref<boolean>` | No validation errors exist |
| `isDirty` | `Ref<boolean>` | Form values differ from initial |
| `isTouched` | `Ref<boolean>` | At least one field has been interacted with |
| `isValidating` | `Readonly<Ref<boolean>>` | Whether validation requests are in progress (debounced or executing) |
| `submitCount` | `Readonly<Ref<number>>` | Number of submission attempts. Resets to 0 after successful submission |
| `initialValues` | `Readonly<Ref<T>>` | Original form values for reset |

**Field factory functions:**

| Method | Description |
|--------|-------------|
| `field(path)` | Get a typed field instance for the given path (e.g., "name", "user.email", "users[0].name") |
| `fieldArray(path)` | Get an array field instance for managing dynamic lists |

**Form actions:**

| Method | Description |
|--------|-------------|
| `submit()` | Submit form to server (returns Promise) |
| `reset()` | Reset to initial values and clear state |

### FormField Interface

Individual form field with reactive state and helpers:

**Reactive state:**

| Property | Type | Description |
|----------|------|-------------|
| `value` | `Ref<T>` | Current field value |
| `errors` | `Readonly<Ref<string[]>>` | Validation errors from server |
| `errorMessage` | `Readonly<Ref<string \| undefined>>` | First error message |
| `isValid` | `Ref<boolean>` | No validation errors |
| `isDirty` | `Ref<boolean>` | Value differs from initial |
| `isTouched` | `Ref<boolean>` | Field has been blurred |

**Input binding:**

| Property | Description |
|----------|-------------|
| `inputAttrs` | Object containing `value`, event handlers (`onInput`, `onBlur`), `name`, `id`, and accessibility attributes (`aria-invalid`, `aria-describedby`). Designed to be used with `v-bind` |

**Navigation methods:**

| Method | Description |
|--------|-------------|
| `field(key)` | Access nested object field |
| `fieldArray(key)` | Access nested array field |

**Field actions:**

| Method | Description |
|--------|-------------|
| `blur()` | Mark field as touched |

### FormFieldArray Interface

Array field with additional methods for array manipulation. If `changeEvent` is set, they will return a promise resolving when the item is validated through the server and added. Otherwise, promise resolves immediately.

**Array operations:**

| Method | Description |
|--------|-------------|
| `add(item?)` | Add new item to array (optionally with partial data). Returns a promise. |
| `remove(index)` | Remove item by index. Returns a promise. |
| `move(from, to)` | Move item to different position. Returns a promise. |


> #### Ecto by default removes empty values {: .tip}
>
> If calling `add()` on an array field does not add a new item, it often means that your Ecto changeset is filtering out empty or invalid values (e.g., empty strings in an array). Make sure your changeset doesn't consider value [you're trying to add as empty](https://hexdocs.pm/ecto/Ecto.Changeset.html#cast/4-options), or provide a valid initial value when adding.


**Reactive array:**

| Property | Description |
|----------|-------------|
| `fields` | Array of field instances for iteration (`FormField<T>[]`) |

**Individual array item access:**

| Method | Description |
|--------|-------------|
| `field(path)` | Get individual array item fields (e.g., `field(0)`, `field('[0].name')`) |
| `fieldArray(path)` | Get nested array fields within array items |

> **Note:** Array fields inherit all properties and methods from `FormField` except `field()` and `fieldArray()` navigation methods, which are replaced with array-specific versions.

## Working with Fields

### Field State

Each field provides reactive state that updates automatically:

```html
<script setup>
const nameField = form.field('name')

// Reactive field state
console.log(nameField.value.value)        // Current value
console.log(nameField.errors.value)       // Array of error strings
console.log(nameField.errorMessage.value) // First error or undefined
console.log(nameField.isValid.value)      // true if no errors
console.log(nameField.isDirty.value)      // true if changed from initial
console.log(nameField.isTouched.value)    // true if user interacted
</script>

<template>
  <!-- Display field state -->
  <div class="field-debug">
    <p>Value: {{ nameField.value.value }}</p>
    <p>Valid: {{ nameField.isValid.value }}</p>
    <p>Dirty: {{ nameField.isDirty.value }}</p>
    <p>Touched: {{ nameField.isTouched.value }}</p>
    <p>Errors: {{ nameField.errors.value }}</p>
  </div>
</template>
```

### Input Binding

The `inputAttrs` property provides all necessary attributes for form inputs:

```html
<template>
  <!-- Automatic binding with all attributes -->
  <input v-bind="nameField.inputAttrs.value" />

  <!-- Manual binding (equivalent to above) -->
  <input
    :value="nameField.inputAttrs.value.value"
    @input="nameField.inputAttrs.value.onInput"
    @blur="nameField.inputAttrs.value.onBlur"
    :name="nameField.inputAttrs.value.name"
    :id="nameField.inputAttrs.value.id"
    :aria-invalid="nameField.inputAttrs.value['aria-invalid']"
    :aria-describedby="nameField.inputAttrs.value['aria-describedby']"
  />

  <!-- Error message with proper ID linking -->
  <div
    v-if="nameField.errorMessage.value"
    :id="nameField.inputAttrs.value.id + '-error'"
    class="error"
  >
    {{ nameField.errorMessage.value }}
  </div>
</template>
```

### Custom Field Components

Create reusable field components by extracting the binding logic:

```html
<!-- TextInput.vue -->
<script setup lang="ts">
interface Props {
  field: FormField<string>
  label: string
  type?: string
  placeholder?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text'
})
</script>

<template>
  <div class="field">
    <label :for="field.inputAttrs.value.id">{{ label }}</label>
    <input
      v-bind="field.inputAttrs.value"
      :type="type"
      :placeholder="placeholder"
      :class="{ error: field.isTouched.value && field.errorMessage.value }"
    />
    <div v-if="field.errorMessage.value" class="error-message">
      {{ field.errorMessage.value }}
    </div>
  </div>
</template>
```

Usage:
```html
<TextInput :field="form.field('name')" label="Full Name" placeholder="Enter your name" />
<TextInput :field="form.field('email')" label="Email" type="email" />
```

## Nested Fields

### Object Navigation

Access nested object fields using dot notation:

```typescript
type UserProfile = {
  name: string
  email: string
  address: {
    street: string
    city: string
    country: string
  }
  preferences: {
    newsletter: boolean
    theme: 'light' | 'dark'
    notifications: {
      email: boolean
      push: boolean
    }
  }
}

const form = useLiveForm<UserProfile>(/* ... */)

// Access nested fields with full type safety
const nameField = form.field('name')                           // FormField<string>
const streetField = form.field('address.street')               // FormField<string>
const themeField = form.field('preferences.theme')             // FormField<'light' | 'dark'>
const emailNotifField = form.field('preferences.notifications.email') // FormField<boolean>
```

### Fluent Field Navigation

You can also navigate through object structures using the field methods:

```typescript
// Equivalent ways to access nested fields
const emailNotifField1 = form.field('preferences.notifications.email')

const preferencesField = form.field('preferences')
const notificationsField = preferencesField.field('notifications')
const emailNotifField2 = notificationsField.field('email')

// Both approaches are type-safe and equivalent
```

### Complex Nested Structures

```html
<script setup lang="ts">
type CompanyForm = {
  name: string
  headquarters: {
    address: {
      street: string
      city: string
      postal_code: string
    }
    contact: {
      phone: string
      email: string
    }
  }
  departments: Array<{
    name: string
    manager: {
      name: string
      email: string
    }
  }>
}

const form = useLiveForm<CompanyForm>(/* ... */)

// Access deeply nested fields
const companyNameField = form.field('name')
const hqStreetField = form.field('headquarters.address.street')
const hqPhoneField = form.field('headquarters.contact.phone')
const departmentsArray = form.fieldArray('departments')
</script>

<template>
  <div>
    <!-- Company basic info -->
    <TextInput :field="companyNameField" label="Company Name" />

    <!-- Headquarters address -->
    <fieldset>
      <legend>Headquarters</legend>
      <TextInput :field="hqStreetField" label="Street" />
      <TextInput :field="form.field('headquarters.address.city')" label="City" />
      <TextInput :field="form.field('headquarters.address.postal_code')" label="Postal Code" />
      <TextInput :field="hqPhoneField" label="Phone" />
      <TextInput :field="form.field('headquarters.contact.email')" label="Email" type="email" />
    </fieldset>

    <!-- Departments array -->
    <fieldset>
      <legend>Departments</legend>
      <div v-for="(deptField, index) in departmentsArray.fields.value" :key="index">
        <h4>Department {{ index + 1 }}</h4>
        <TextInput :field="deptField.field('name')" label="Department Name" />
        <TextInput :field="deptField.field('manager.name')" label="Manager Name" />
        <TextInput :field="deptField.field('manager.email')" label="Manager Email" type="email" />
        <button @click="departmentsArray.remove(index)">Remove Department</button>
      </div>
      <button @click="departmentsArray.add({ name: '', manager: { name: '', email: '' } })">
        Add Department
      </button>
    </fieldset>
  </div>
</template>
```

## Array Fields

### Basic Array Operations

Array fields provide methods for adding, removing, and reordering items:

```html
<script setup lang="ts">
type TagsForm = {
  title: string
  tags: string[]
}

const form = useLiveForm<TagsForm>(/* ... */)
const titleField = form.field('title')
const tagsArray = form.fieldArray('tags')

// Array operations
const addTag = () => tagsArray.add('')
const removeTag = (index: number) => tagsArray.remove(index)
const moveTag = (from: number, to: number) => tagsArray.move(from, to)
</script>

<template>
  <div>
    <TextInput :field="titleField" label="Title" />

    <!-- Tags array -->
    <fieldset>
      <legend>Tags</legend>
      <div v-for="(tagField, index) in tagsArray.fields.value" :key="index" class="tag-item">
        <input v-bind="tagField.inputAttrs.value" placeholder="Enter tag" />
        <button @click="removeTag(index)">Remove</button>
        <button v-if="index > 0" @click="moveTag(index, index - 1)">↑</button>
        <button v-if="index < tagsArray.fields.value.length - 1" @click="moveTag(index, index + 1)">↓</button>
      </div>
      <button @click="addTag()">Add Tag</button>
    </fieldset>
  </div>
</template>
```

### Array Field Indexing

Access individual array items using multiple syntaxes:

```typescript
const skillsArray = form.fieldArray('profile.skills')

// Method 1: Using numeric index
const firstSkill = skillsArray.field(0)                    // FormField<string>

// Method 2: Using bracket notation
const secondSkill = skillsArray.field('[1]')               // FormField<string>

// Method 3: Using the fields array (for iteration)
const allSkillFields = skillsArray.fields.value            // FormField<string>[]
```

### Complex Array Structures

Handle arrays of objects with nested properties:

```html
<script setup lang="ts">
type ProjectForm = {
  name: string
  team_members: Array<{
    name: string
    email: string
    role: string
    skills: string[]
    contact: {
      phone: string
      address: string
    }
  }>
}

const form = useLiveForm<ProjectForm>(/* ... */)
const membersArray = form.fieldArray('team_members')

const addMember = () => {
  membersArray.add({
    name: '',
    email: '',
    role: 'developer',
    skills: [],
    contact: { phone: '', address: '' }
  })
}

const addSkillToMember = (memberIndex: number) => {
  const memberField = membersArray.field(memberIndex)
  const skillsArray = memberField.fieldArray('skills')
  skillsArray.add('')
}
</script>

<template>
  <div>
    <TextInput :field="form.field('name')" label="Project Name" />

    <fieldset>
      <legend>Team Members</legend>
      <div v-for="(memberField, memberIndex) in membersArray.fields.value" :key="memberIndex" class="member-card">
        <h4>Member {{ memberIndex + 1 }}</h4>

        <!-- Basic member info -->
        <TextInput :field="memberField.field('name')" label="Name" />
        <TextInput :field="memberField.field('email')" label="Email" type="email" />
        <select v-bind="memberField.field('role').inputAttrs.value">
          <option value="developer">Developer</option>
          <option value="designer">Designer</option>
          <option value="manager">Manager</option>
        </select>

        <!-- Contact info (nested object) -->
        <fieldset>
          <legend>Contact Information</legend>
          <TextInput :field="memberField.field('contact.phone')" label="Phone" />
          <TextInput :field="memberField.field('contact.address')" label="Address" />
        </fieldset>

        <!-- Skills array (nested array) -->
        <fieldset>
          <legend>Skills</legend>
          <div
            v-for="(skillField, skillIndex) in memberField.fieldArray('skills').fields.value"
            :key="skillIndex"
            class="skill-item"
          >
            <input v-bind="skillField.inputAttrs.value" placeholder="Enter skill" />
            <button @click="memberField.fieldArray('skills').remove(skillIndex)">Remove</button>
          </div>
          <button @click="addSkillToMember(memberIndex)">Add Skill</button>
        </fieldset>

        <button @click="membersArray.remove(memberIndex)">Remove Member</button>
      </div>

      <button @click="addMember()">Add Team Member</button>
    </fieldset>
  </div>
</template>
```

### Deeply Nested Arrays

Handle arrays within arrays within objects:

```typescript
type BlogPost = {
  title: string
  sections: Array<{
    heading: string
    paragraphs: string[]
    comments: Array<{
      author: string
      text: string
      replies: Array<{
        author: string
        text: string
      }>
    }>
  }>
}

const form = useLiveForm<BlogPost>(/* ... */)

// Access deeply nested arrays
const sectionsArray = form.fieldArray('sections')
const firstSectionParagraphs = sectionsArray.field('[0].paragraphs')  // FormFieldArray<string>
const firstSectionComments = sectionsArray.field('[0].comments')      // FormFieldArray<Comment>

// Using fluent interface
const firstSection = sectionsArray.field(0)                           // FormField<Section>
const firstSectionParagraphsAlt = firstSection.fieldArray('paragraphs') // FormFieldArray<string>

// Access replies of first comment in first section
const firstCommentReplies = sectionsArray.fieldArray('[0].comments').field('[0].replies') // FormFieldArray<Reply>
```

## Form State Management

### Form-Level State

The form instance provides reactive state about the entire form:

```html
<script setup>
const form = useLiveForm(/* ... */)

// Form state is reactive
watch(() => form.isValid.value, (valid) => {
  console.log('Form validity changed:', valid)
})

watch(() => form.isDirty.value, (dirty) => {
  if (dirty) {
    console.log('Form has unsaved changes')
  }
})

watch(() => form.isValidating.value, (validating) => {
  console.log('Validation status:', validating ? 'in progress' : 'complete')
})
</script>

<template>
  <div class="form-status">
    <!-- Visual indicators -->
    <div :class="{ 'status-valid': form.isValid.value, 'status-invalid': !form.isValid.value }">
      {{ form.isValid.value ? '✓ Valid' : '✗ Has Errors' }}
    </div>

    <div :class="{ 'status-dirty': form.isDirty.value }">
      {{ form.isDirty.value ? '● Unsaved Changes' : '✓ Saved' }}
    </div>

    <div v-if="form.isTouched.value">
      User has interacted with the form
    </div>

    <div v-if="form.isValidating.value" class="validating">
      🔄 Validating changes...
    </div>

    <div>
      Submit attempts: {{ form.submitCount.value }}
    </div>
  </div>

  <!-- Conditional submit button -->
  <button
    @click="form.submit()"
    :disabled="!form.isValid.value || !form.isDirty.value || form.isValidating.value"
    class="submit-btn"
  >
    {{ form.isValidating.value ? 'Validating...' : form.isDirty.value ? 'Save Changes' : 'No Changes' }}
  </button>
</template>
```

### Reset and Submit Actions

```html
<script setup>
const form = useLiveForm(/* ... */)

const handleSubmit = async () => {
  try {
    await form.submit()
    console.log('Form submitted successfully!')
    // Form will automatically reset on successful submission
  } catch (error) {
    console.error('Submission failed:', error)
    // Form state remains intact for user to fix errors
  }
}

const handleReset = () => {
  if (form.isDirty.value) {
    if (confirm('You have unsaved changes. Are you sure you want to reset?')) {
      form.reset()
    }
  } else {
    form.reset()
  }
}

const handleCancel = () => {
  // Navigate away or close modal
  if (form.isDirty.value) {
    if (confirm('You have unsaved changes. Are you sure you want to cancel?')) {
      // Navigate away
      $live.pushEvent('cancel')
    }
  }
}
</script>

<template>
  <div class="form-actions">
    <button @click="handleReset" type="button" :disabled="!form.isDirty.value">
      Reset
    </button>
    <button @click="handleCancel" type="button">
      Cancel
    </button>
    <button @click="handleSubmit" :disabled="!form.isValid.value">
      {{ form.submitCount.value > 0 ? 'Resubmit' : 'Submit' }}
    </button>
  </div>
</template>
```

## Advanced Patterns

### Custom Validation Logic

While server-side validation is primary, you can add client-side validation for better UX:

```html
<script setup>
const form = useLiveForm(/* ... */)
const emailField = form.field('email')
const passwordField = form.field('password')
const confirmPasswordField = form.field('confirm_password')

// Client-side validation helpers
const emailIsValid = computed(() => {
  const value = emailField.value.value
  return !value || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
})

const passwordsMatch = computed(() => {
  return passwordField.value.value === confirmPasswordField.value.value
})

// Combine client and server validation
const emailHasError = computed(() => {
  return (emailField.isTouched.value && !emailIsValid.value) ||
         (emailField.errorMessage.value !== undefined)
})
</script>

<template>
  <div class="field">
    <input
      v-bind="emailField.inputAttrs.value"
      type="email"
      :class="{ error: emailHasError.value }"
    />
    <!-- Show client-side error first, then server error -->
    <div v-if="emailField.isTouched.value && !emailIsValid.value" class="error">
      Please enter a valid email address
    </div>
    <div v-else-if="emailField.errorMessage.value" class="error">
      {{ emailField.errorMessage.value }}
    </div>
  </div>

  <div class="field">
    <input v-bind="confirmPasswordField.inputAttrs.value" type="password" />
    <div v-if="confirmPasswordField.isTouched.value && !passwordsMatch.value" class="error">
      Passwords do not match
    </div>
  </div>
</template>
```

### Data Transformation

Transform form data before sending to the server:

```html
<script setup>
type RawForm = {
  name: string
  tags: string
  price: string
  is_active: string
}

type ProcessedForm = {
  name: string
  tags: string[]
  price: number
  is_active: boolean
}

const form = useLiveForm<RawForm>(() => props.form, {
  changeEvent: 'validate',
  submitEvent: 'submit',
  prepareData: (data: RawForm): ProcessedForm => {
    return {
      name: data.name.trim(),
      tags: data.tags.split(',').map(tag => tag.trim()).filter(Boolean),
      price: parseFloat(data.price) || 0,
      is_active: data.is_active === 'true'
    }
  }
})

// Form fields work with the raw format
const tagsField = form.field('tags')  // string field for comma-separated input
const priceField = form.field('price')  // string field for user input
</script>

<template>
  <!-- User enters comma-separated tags -->
  <input v-bind="tagsField.inputAttrs.value" placeholder="javascript, vue, forms" />

  <!-- User enters price as string -->
  <input v-bind="priceField.inputAttrs.value" type="number" step="0.01" />
</template>
```

### Conditional Field Logic

Show/hide fields based on form state:

```html
<script setup>
type UserForm = {
  account_type: 'personal' | 'business'
  name: string
  company_name?: string
  tax_id?: string
  billing_address: string
  shipping_address?: string
  same_as_billing: boolean
}

const form = useLiveForm<UserForm>(/* ... */)

const accountTypeField = form.field('account_type')
const sameAsBillingField = form.field('same_as_billing')

const isBusinessAccount = computed(() =>
  accountTypeField.value.value === 'business'
)

const needsShippingAddress = computed(() =>
  !sameAsBillingField.value.value
)

// Clear conditional fields when they become hidden
watch(isBusinessAccount, (isBusiness) => {
  if (!isBusiness) {
    form.field('company_name').value.value = ''
    form.field('tax_id').value.value = ''
  }
})

watch(needsShippingAddress, (needsShipping) => {
  if (!needsShipping) {
    form.field('shipping_address').value.value = ''
  }
})
</script>

<template>
  <div>
    <select v-bind="accountTypeField.inputAttrs.value">
      <option value="personal">Personal</option>
      <option value="business">Business</option>
    </select>

    <!-- Business-only fields -->
    <div v-if="isBusinessAccount">
      <TextInput :field="form.field('company_name')" label="Company Name" />
      <TextInput :field="form.field('tax_id')" label="Tax ID" />
    </div>

    <TextInput :field="form.field('billing_address')" label="Billing Address" />

    <label>
      <input type="checkbox" v-bind="sameAsBillingField.inputAttrs.value" />
      Shipping address same as billing
    </label>

    <div v-if="needsShippingAddress">
      <TextInput :field="form.field('shipping_address')" label="Shipping Address" />
    </div>
  </div>
</template>
```

## Provide/Inject API (Advanced)

For building reusable form components, LiveVue provides `useField()` and `useArrayField()` hooks that work with Vue's provide/inject system.

> #### Advanced API {: .warning}
>
> This is an advanced pattern for creating reusable form components. Most applications should use the direct field access patterns shown above.

### Component Injection

When you call `useLiveForm()`, it automatically provides the form instance to child components:

```html
<!-- ParentForm.vue -->
<script setup>
const form = useLiveForm(/* ... */)
// Form instance is automatically provided to children
</script>

<template>
  <div>
    <!-- These child components can access form fields -->
    <UserNameInput />
    <UserEmailInput />
    <SkillsManager />
  </div>
</template>
```

### useField Hook

Create reusable field components that access the parent form:

```html
<!-- UserNameInput.vue -->
<script setup lang="ts">
import { useField } from 'live_vue'

interface Props {
  path?: string
}

const props = withDefaults(defineProps<Props>(), {
  path: 'name'
})

// Access field from parent form context
const field = useField<string>(props.path)
</script>

<template>
  <div class="field">
    <label :for="field.inputAttrs.value.id">Full Name</label>
    <input
      v-bind="field.inputAttrs.value"
      :class="{ error: field.isTouched.value && field.errorMessage.value }"
      placeholder="Enter your full name"
    />
    <div v-if="field.errorMessage.value" class="error-message">
      {{ field.errorMessage.value }}
    </div>
  </div>
</template>
```

### useArrayField Hook

Create reusable array field managers:

```html
<!-- SkillsManager.vue -->
<script setup lang="ts">
import { useArrayField } from 'live_vue'

interface Props {
  path?: string
}

const props = withDefaults(defineProps<Props>(), {
  path: 'skills'
})

const skillsArray = useArrayField<string>(props.path)

const addSkill = () => skillsArray.add('')
const removeSkill = (index: number) => skillsArray.remove(index)
</script>

<template>
  <fieldset>
    <legend>Skills</legend>

    <div v-for="(skillField, index) in skillsArray.fields.value" :key="index" class="skill-item">
      <input v-bind="skillField.inputAttrs.value" placeholder="Enter skill" />
      <button @click="removeSkill(index)" type="button">Remove</button>
    </div>

    <button @click="addSkill" type="button">Add Skill</button>

    <div v-if="skillsArray.errorMessage.value" class="error-message">
      {{ skillsArray.errorMessage.value }}
    </div>
  </fieldset>
</template>
```

### Complex Reusable Components

Build sophisticated reusable form sections:

```html
<!-- AddressInput.vue -->
<script setup lang="ts">
import { useField } from 'live_vue'

interface Props {
  basePath: string      // e.g., 'billing_address' or 'shipping_address'
  label: string
}

const props = defineProps<Props>()

// Access nested address fields
const streetField = useField<string>(`${props.basePath}.street`)
const cityField = useField<string>(`${props.basePath}.city`)
const stateField = useField<string>(`${props.basePath}.state`)
const zipField = useField<string>(`${props.basePath}.zip`)
const countryField = useField<string>(`${props.basePath}.country`)
</script>

<template>
  <fieldset>
    <legend>{{ label }}</legend>

    <div class="address-grid">
      <TextInput :field="streetField" label="Street Address" />
      <TextInput :field="cityField" label="City" />
      <TextInput :field="stateField" label="State" />
      <TextInput :field="zipField" label="ZIP Code" />

      <div class="field">
        <label :for="countryField.inputAttrs.value.id">Country</label>
        <select v-bind="countryField.inputAttrs.value">
          <option value="US">United States</option>
          <option value="CA">Canada</option>
          <option value="UK">United Kingdom</option>
        </select>
      </div>
    </div>
  </fieldset>
</template>
```

Usage:
```html
<template>
  <div>
    <AddressInput base-path="billing_address" label="Billing Address" />
    <AddressInput base-path="shipping_address" label="Shipping Address" />
  </div>
</template>
```

### Error Handling with Inject

```html
<!-- Component using injection -->
<script setup>
import { useField, useArrayField } from 'live_vue'

const nameField = useField('name')
const skillsArray = useArrayField('skills')

// Error handling for missing form context
try {
  const field = useField('some_field')
} catch (error) {
  console.error('Component must be used within a form context:', error.message)
  // Handle gracefully or show error message
}
</script>
```

## Server-Side Integration

### Ecto Changeset Integration

LiveVue forms work seamlessly with Ecto changesets:

```elixir
defmodule MyApp.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer

    embeds_one :profile, Profile do
      field :bio, :string
      field :skills, {:array, :string}, default: []
    end

    has_many :posts, Post
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than: 0)
    |> cast_embed(:profile, with: &profile_changeset/2)
  end

  defp profile_changeset(profile, attrs) do
    profile
    |> cast(attrs, [:bio, :skills])
    |> validate_length(:bio, max: 500)
  end
end
```

### LiveView Form Handling

```elixir
defmodule MyAppWeb.UserFormLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="user-form">
      <h1>User Profile</h1>
      <.vue form={@form} v-component="UserForm" v-socket={@socket} />
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    user = Users.get_user!(id)
    changeset = User.changeset(user, %{})

    socket =
      socket
      |> assign(:user, user)
      |> assign(:form, to_form(changeset, as: :user))

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    # New user
    changeset = User.changeset(%User{}, %{})

    socket =
      socket
      |> assign(:user, nil)
      |> assign(:form, to_form(changeset, as: :user))

    {:ok, socket}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    user = socket.assigns.user || %User{}

    changeset =
      user
      |> User.changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :user))}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    case save_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        socket =
          socket
          |> put_flash(:info, "User saved successfully!")
          |> redirect(to: ~p"/users/#{user}")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :user))}
    end
  end

  defp save_user(nil, user_params) do
    %User{}
    |> User.changeset(user_params)
    |> Repo.insert()
  end

  defp save_user(user, user_params) do
    user
    |> User.changeset(user_params)
    |> Repo.update()
  end
end
```

### Validation Best Practices

```elixir
# In your context module
defmodule MyApp.Users do
  def change_user(user \\ %User{}, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def validate_user_step(user, attrs, step) do
    case step do
      :basic_info ->
        user
        |> cast(attrs, [:name, :email])
        |> validate_required([:name, :email])

      :profile ->
        user
        |> cast_embed(:profile)

      :complete ->
        User.changeset(user, attrs)
    end
  end
end
```

## Complete Examples

### Simple Contact Form

A basic form demonstrating core concepts:

```html
<!-- ContactForm.vue -->
<script setup lang="ts">
import { useLiveForm, type Form } from 'live_vue'

type ContactForm = {
  name: string
  email: string
  subject: string
  message: string
  contact_method: 'email' | 'phone'
  phone?: string
}

const props = defineProps<{ form: Form<ContactForm> }>()

const form = useLiveForm(() => props.form, {
  changeEvent: 'validate',
  submitEvent: 'submit',
  debounceInMiliseconds: 200
})

const nameField = form.field('name')
const emailField = form.field('email')
const subjectField = form.field('subject')
const messageField = form.field('message')
const contactMethodField = form.field('contact_method')
const phoneField = form.field('phone')

const needsPhone = computed(() =>
  contactMethodField.value.value === 'phone'
)

const submitForm = async () => {
  try {
    await form.submit()
    // Success feedback will be handled by LiveView
  } catch (error) {
    console.error('Submission failed:', error)
  }
}
</script>

<template>
  <div class="contact-form">
    <h2>Contact Us</h2>

    <div class="form-grid">
      <div class="field">
        <label :for="nameField.inputAttrs.value.id">Name *</label>
        <input
          v-bind="nameField.inputAttrs.value"
          :class="{ error: nameField.isTouched.value && nameField.errorMessage.value }"
        />
        <div v-if="nameField.errorMessage.value" class="error-message">
          {{ nameField.errorMessage.value }}
        </div>
      </div>

      <div class="field">
        <label :for="emailField.inputAttrs.value.id">Email *</label>
        <input
          v-bind="emailField.inputAttrs.value"
          type="email"
          :class="{ error: emailField.isTouched.value && emailField.errorMessage.value }"
        />
        <div v-if="emailField.errorMessage.value" class="error-message">
          {{ emailField.errorMessage.value }}
        </div>
      </div>
    </div>

    <div class="field">
      <label :for="subjectField.inputAttrs.value.id">Subject *</label>
      <input v-bind="subjectField.inputAttrs.value" />
      <div v-if="subjectField.errorMessage.value" class="error-message">
        {{ subjectField.errorMessage.value }}
      </div>
    </div>

    <div class="field">
      <label>Preferred Contact Method</label>
      <div class="radio-group">
        <label>
          <input type="radio" v-bind="contactMethodField.inputAttrs.value" value="email" />
          Email
        </label>
        <label>
          <input type="radio" v-bind="contactMethodField.inputAttrs.value" value="phone" />
          Phone
        </label>
      </div>
    </div>

    <div v-if="needsPhone" class="field">
      <label :for="phoneField.inputAttrs.value.id">Phone Number</label>
      <input v-bind="phoneField.inputAttrs.value" type="tel" />
      <div v-if="phoneField.errorMessage.value" class="error-message">
        {{ phoneField.errorMessage.value }}
      </div>
    </div>

    <div class="field">
      <label :for="messageField.inputAttrs.value.id">Message *</label>
      <textarea
        v-bind="messageField.inputAttrs.value"
        rows="5"
        :class="{ error: messageField.isTouched.value && messageField.errorMessage.value }"
      />
      <div v-if="messageField.errorMessage.value" class="error-message">
        {{ messageField.errorMessage.value }}
      </div>
    </div>

    <div class="form-actions">
      <button @click="form.reset()" type="button" :disabled="!form.isDirty.value">
        Reset
      </button>
      <button @click="submitForm" :disabled="!form.isValid.value || form.isValidating.value" class="primary">
        {{ form.isValidating.value ? 'Validating...' : 'Send Message' }}
      </button>
    </div>

    <div class="form-status">
      <small>
        <span :class="{ valid: form.isValid.value, invalid: !form.isValid.value }">
          {{ form.isValid.value ? '✓' : '✗' }}
        </span>
        {{ form.isValidating.value ? 'Validating...' : form.isDirty.value ? 'Unsaved changes' : 'Form ready' }}
      </small>
    </div>
  </div>
</template>

<style scoped>
.contact-form {
  max-width: 600px;
  margin: 0 auto;
  padding: 2rem;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.field {
  margin-bottom: 1rem;
}

.field label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.field input, .field textarea, .field select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.field input.error, .field textarea.error {
  border-color: #e74c3c;
}

.radio-group {
  display: flex;
  gap: 1rem;
}

.radio-group label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: normal;
}

.error-message {
  color: #e74c3c;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

.form-actions button {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.form-actions button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-actions button.primary {
  background: #3498db;
  color: white;
}

.form-status {
  margin-top: 1rem;
  text-align: center;
}

.valid { color: #27ae60; }
.invalid { color: #e74c3c; }
</style>
```

### Complex Nested Form

An advanced form with nested objects, arrays, and dynamic fields:

For a complete example of a complex nested form, see the [FormExample.vue](https://github.com/Valian/live_vue/blob/main/example_project/assets/vue/FormExample.vue) in the LiveVue repository, which demonstrates:

- Nested object fields (`owner.name`, `owner.email`)
- Array fields with objects (`team_members[]`)
- Deeply nested arrays (`tasks[].assignees[]`)
- Dynamic field operations (add/remove/reorder)
- Complex validation scenarios
- Form state management

## Next Steps

Now that you understand LiveVue forms, you might want to explore:

- [Client-Side API](client_api.md) for detailed API reference and advanced patterns
- [Testing](testing.md) for testing form components and validation logic
- [Component Reference](component_reference.md) for LiveView-side form integration
- [Basic Usage](basic_usage.md) for other LiveVue patterns and features