# useLiveForm Implementation Plan

## Overview
Implement a Vue composable for consuming server-side validated forms from Phoenix/Ecto, providing reactive form state, field-level validation, and seamless integration with LiveView.

## API Design

### Core Interfaces

```typescript
// TypeScript utility types for path safety
type PathsToStringProps<T> = T extends string | number | boolean | Date 
  ? never 
  : T extends readonly (infer U)[]
    ? U extends object
      ? `[${number}]` | `[${number}].${PathsToStringProps<U>}`
      : `[${number}]`
    : T extends object
      ? {
          [K in keyof T]: K extends string | number
            ? T[K] extends object
              ? `${K}` | `${K}.${PathsToStringProps<T[K]>}`
              : `${K}`
            : never
        }[keyof T]
      : never

// Get type at path
type PathValue<T, P extends string> = P extends `${infer Key}.${infer Rest}`
  ? Key extends keyof T
    ? PathValue<T[Key], Rest>
    : never
  : P extends `[${infer Index}]`
    ? T extends readonly (infer U)[]
      ? U
      : never
  : P extends `${infer Key}[${infer Index}]`
    ? Key extends keyof T
      ? T[Key] extends readonly (infer U)[]
        ? U
        : never
      : never
  : P extends keyof T
    ? T[P]
    : never

interface UseLiveFormReturn<T extends object> {
  // Form-level state
  isValid: Ref<boolean>
  isDirty: Ref<boolean>
  isTouched: Ref<boolean>
  initialValues: Readonly<Ref<T>>
  
  // Type-safe field factory functions
  field<P extends PathsToStringProps<T>>(path: P): FormField<PathValue<T, P>>
  fieldArray<P extends PathsToStringProps<T>>(path: P): PathValue<T, P> extends readonly (infer U)[] ? FormFieldArray<U> : never
  
  // Form actions
  submit: () => Promise<void>
  reset: () => void
}

interface FormField<T> {
  // Reactive state (using reactive + toRefs for clean syntax)
  value: Ref<T>                              // field.value instead of field.value.value
  errors: Readonly<Ref<string[]>>            // Read-only, from backend
  errorMessage: Readonly<Ref<string | undefined>>  // First error, read-only
  isValid: Ref<boolean>
  isDirty: Ref<boolean>
  isTouched: Ref<boolean>
  
  // Type-safe sub-field creation (enables fluent interface)
  field<K extends keyof T>(key: K): T[K] extends readonly (infer U)[] ? FormFieldArray<U> : FormField<T[K]>
  fieldArray<K extends keyof T>(key: K): T[K] extends readonly (infer U)[] ? FormFieldArray<U> : never
  
  // Field actions
  focus: () => void   // Sets as currently editing, auto-marks as touched
  blur: () => void    // Unsets as currently editing
}

interface FormFieldArray<T> extends FormField<T[]> {
  // Array-specific methods
  add: (item?: Partial<T>) => void
  remove: (index: number) => void
  move: (from: number, to: number) => void
  
  // Reactive array of field instances for iteration
  fields: Readonly<Ref<FormField<T>[]>>
  
  // Get individual array item fields - unified API with path syntax
  at: (index: number) => FormField<T>
  field: (path: string | number) => FormField<any>        // "[0].name" or 0
  fieldArray: (path: string | number) => FormFieldArray<any>  // "[0].tags" or 0
}

interface FormOptions {
  changeEvent?: string      // Default: 'validate'
  submitEvent?: string      // Default: 'submit'
  debounceInMiliseconds?: number  // Default: 300
  prepareData?: (data: any) => any
}
```

### Path Syntax
- Object navigation: `user.profile.bio`
- Array access: `items[0].name`
- Nested arrays: `users[0].skills[1].name`
- Mixed: `departments[0].employees[2].profile.skills[0]`

## Implementation Plan

### Phase 1: Core Infrastructure
1. **Basic form state management**
   - Create reactive form state from server form data
   - Track initial values, current values, touched/dirty state
   - Implement path resolution for nested access

2. **Field factory functions**
   - Implement `field(path)` with dot notation and bracket syntax
   - Implement `fieldArray(path)` for array fields
   - Use `reactive()` + `toRefs()` for clean property access

3. **Path parsing and resolution**
   - Parse paths like `user.items[0].name`
   - Safely navigate nested objects and arrays
   - Handle dynamic indices

### Phase 2: Reactivity and State Tracking
1. **Touched/dirty tracking**
   - Auto-track touched on focus/blur
   - Track dirty by comparing with initial values
   - Track currently editing field to prevent server overwrites

2. **Validation state**
   - Reactive validation from server errors
   - Field-level and form-level validity
   - Error message extraction (first error)

3. **Change detection and debouncing**
   - Watch for value changes
   - Debounce validation requests
   - Send minimal diffs to server

### Phase 3: Array Operations
1. **Array manipulation**
   - Implement add/remove/move operations
   - Update form state and indices
   - Maintain field reactivity during operations

2. **Array field iteration**
   - Provide `fields` array for iteration
   - Create field instances for each array item
   - Handle dynamic field creation/destruction

### Phase 4: Server Integration
1. **LiveView integration**
   - Send validation events via `$live.pushEvent()`
   - Handle server responses and state updates
   - Prevent overwrites of currently editing fields

2. **Form submission**
   - Implement submit functionality
   - Handle server validation responses
   - Reset form state on successful submission

### Phase 5: Advanced Features
1. **Sub-field creation**
   - Enable `field.field('subkey')` syntax
   - Enable `field.fieldArray('subarray')` syntax
   - Maintain proper path composition

2. **Performance optimizations**
   - Memoize field instances
   - Optimize reactivity updates
   - Minimize re-renders during typing

## Usage Examples

### Basic Form (with Type Safety)
```vue
<script setup>
interface UserForm {
  name: string
  email: string
  profile: {
    bio: string
    skills: string[]
  }
  items: Array<{
    name: string
    tags: string[]
  }>
}

const form = useLiveForm<UserForm>(serverForm, { 
  changeEvent: 'validate',
  debounceInMiliseconds: 300 
})

// Type-safe field access - full autocomplete and type checking
const nameField = form.field('name')              // FormField<string>
const emailField = form.field('email')            // FormField<string>
const bioField = form.field('profile.bio')        // FormField<string>
const skillsArray = form.fieldArray('profile.skills') // FormFieldArray<string>
</script>

<template>
  <input 
    v-model="nameField.value"
    @focus="nameField.focus()"
    @blur="nameField.blur()"
  />
  <span v-if="nameField.errorMessage">{{ nameField.errorMessage }}</span>
  
  <button @click="form.submit()" :disabled="!form.isValid">Submit</button>
</template>
```

### Fluent Interface (Natural Sub-Field Creation)
```vue
<script setup>
// Both approaches work and are type-safe:

// 1. Direct path access
const bioField = form.field('profile.bio')        // FormField<string>

// 2. Fluent interface through sub-field creation
const profileField = form.field('profile')        // FormField<Profile>
const bioField2 = profileField.field('bio')       // FormField<string>

// 3. Mixed usage
const userField = form.field('user')              // FormField<User>
const itemName = userField.field('items[0].name') // FormField<string>
</script>

<template>
  <!-- Both bioField and bioField2 work identically -->
  <textarea v-model="bioField.value" />
  <textarea v-model="bioField2.value" />
</template>
```

### Array Fields
```vue
<script setup>
const itemsArray = form.fieldArray('items')
</script>

<template>
  <div v-for="(itemField, index) in itemsArray.fields" :key="index">
    <input v-model="itemField.field('name').value" />
    <span v-if="itemField.field('name').errorMessage">
      {{ itemField.field('name').errorMessage }}
    </span>
    <button @click="itemsArray.remove(index)">Remove</button>
  </div>
  
  <button @click="itemsArray.add({ name: '', age: null })">Add Item</button>
</template>
```

### Unified Array Field API
```vue
<script setup>
const itemsArray = form.fieldArray('items')

// Two equivalent ways to access array item fields:

// 1. String path syntax (explicit)
const firstItemName = itemsArray.field('[0].name')       // direct path
const firstItemTags = itemsArray.fieldArray('[0].tags')  // nested array

// 2. Number shortcut + fluent interface (more readable)
const firstItemName2 = itemsArray.field(0).field('name')        // number shortcut
const firstItemTags2 = itemsArray.field(0).fieldArray('tags')   // fluent chaining
</script>

<template>
  <!-- Both approaches work identically -->
  <input v-model="firstItemName.value" />
  <input v-model="firstItemName2.value" />
</template>
```

### Nested Complex Forms
```vue
<script setup>
const userField = form.field('user')
const profileField = userField.field('profile')
const skillsArray = profileField.fieldArray('skills')
</script>

<template>
  <input v-model="userField.field('name').value" />
  <textarea v-model="profileField.field('bio').value" />
  
  <div v-for="(skillField, index) in skillsArray.fields" :key="index">
    <input v-model="skillField.value" />
    <button @click="skillsArray.remove(index)">Remove</button>
  </div>
</template>
```

## Technical Considerations

### Reactivity Strategy
- Use `reactive()` for internal state management
- Use `toRefs()` to expose clean property access
- Use `readonly()` for server-controlled properties (errors)
- Use `computed()` for derived state (isValid, isDirty)

### Path Resolution
- Implement robust path parser for bracket/dot notation
- Handle edge cases (missing properties, invalid indices)
- Optimize path lookups with caching

### Performance
- Memoize field instances to prevent recreation
- Use shallow watching where possible
- Debounce server communication
- Batch validation requests

### Server Communication
- Integrate with existing LiveView event system
- Handle server state updates gracefully
- Prevent race conditions with editing state
- Support partial form updates via JSON patches

## Testing Strategy
- Unit tests for path parsing and resolution
- Integration tests with mock LiveView server
- E2E tests with real Phoenix application
- Performance tests for large forms
- Test complex nested structures and array operations