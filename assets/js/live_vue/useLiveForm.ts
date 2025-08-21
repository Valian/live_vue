import {
  ref,
  reactive,
  computed,
  toValue,
  watch,
  onScopeDispose,
  nextTick,
  provide,
  inject,
  type Ref,
  type MaybeRefOrGetter,
  type InjectionKey,
  readonly,
} from "vue"
import { useLiveVue } from "./use"
import {
  parsePath,
  getValueByPath,
  setValueByPath,
  deepClone,
  debounce,
  replaceReactiveObject,
  deepToRaw,
} from "./utils"

// Injection key for providing form instances to child components
export const LIVE_FORM_INJECTION_KEY = Symbol("LiveForm") as InjectionKey<{
  field: (path: string) => FormField<any>
  fieldArray: (path: string) => FormFieldArray<any>
}>

/**
 * Maps form field structure to a corresponding structure for validation errors
 * For each field in the original form, creates an array of error strings
 */
export type FormErrors<T extends object> = {
  [K in keyof T]?: T[K] extends object ? FormErrors<T[K]> : string[]
}

/**
 * Base form interface representing the data coming from the server
 * @template T - The type of form values
 */
export interface Form<T extends object> {
  /** Unique identifier for the form */
  name: string
  /** Form field values */
  values: T
  /** Validation errors for form fields */
  errors: FormErrors<T>
  /** Whether the form is valid */
  valid: boolean
}

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
        ? T[K] extends readonly (infer U)[]
          ? U extends object
            ? `${K}` | `${K}[${number}]` | `${K}[${number}].${PathsToStringProps<U>}`
            : `${K}` | `${K}[${number}]`
          : T[K] extends object
          ? `${K}` | `${K}.${PathsToStringProps<T[K]>}`
          : `${K}`
        : never
    }[keyof T]
  : never

// Get type at path
type PathValue<T, P extends string> = P extends `${infer Key}[${infer Index}].${infer Rest}`
  ? Key extends keyof T
    ? T[Key] extends readonly (infer U)[]
      ? PathValue<U, Rest>
      : never
    : never
  : P extends `${infer Key}[${infer Index}]`
  ? Key extends keyof T
    ? T[Key] extends readonly (infer U)[]
      ? U
      : never
    : never
  : P extends `${infer Key}.${infer Rest}`
  ? Key extends keyof T
    ? PathValue<T[Key], Rest>
    : never
  : P extends `[${infer Index}]`
  ? T extends readonly (infer U)[]
    ? U
    : never
  : P extends keyof T
  ? T[P]
  : never

// Helper type to resolve array field types from relative paths
type ArrayFieldPath<T, P extends string | number> = P extends number
  ? FormField<T>
  : P extends `[${number}]`
  ? FormField<T>
  : P extends `[${number}].${infer Rest}`
  ? PathValue<T, Rest> extends readonly (infer U)[]
    ? FormFieldArray<U>
    : FormField<PathValue<T, Rest>>
  : P extends keyof T
  ? T[P] extends readonly (infer U)[]
    ? FormFieldArray<U>
    : FormField<T[P]>
  : FormField<any>

// Helper type for array field array paths
type ArrayFieldArrayPath<T, P extends string | number> = P extends number
  ? never
  : P extends `[${number}]`
  ? never
  : P extends `[${number}].${infer Rest}`
  ? PathValue<T, Rest> extends readonly (infer U)[]
    ? FormFieldArray<U>
    : never
  : P extends keyof T
  ? T[P] extends readonly (infer U)[]
    ? FormFieldArray<U>
    : never
  : never

export interface FormOptions {
  /** Event name to send to the server when form values change. Set to null to disable validation events */
  changeEvent?: string | null
  /** Event name to send to the server when form is submitted */
  submitEvent?: string
  /** Delay in milliseconds before sending change events to reduce server load */
  debounceInMiliseconds?: number
  /** Function to transform form data before sending to server */
  prepareData?: (data: any) => any
}

export interface FormField<T> {
  // Reactive state (using reactive + toRefs for clean syntax)
  value: Ref<T> // field.value instead of field.value.value
  errors: Readonly<Ref<string[]>> // Read-only, from backend
  errorMessage: Readonly<Ref<string | undefined>> // First error, read-only
  isValid: Ref<boolean>
  isDirty: Ref<boolean>
  isTouched: Ref<boolean>

  // Input binding helper
  inputAttrs: Readonly<
    Ref<{
      value: T
      onInput: (event: Event) => void
      onFocus: () => void
      onBlur: () => void
      name: string
      id: string
      "aria-invalid": boolean
      "aria-describedby"?: string
    }>
  >

  // Type-safe sub-field creation (enables fluent interface)
  field<K extends keyof T>(key: K): T[K] extends readonly (infer U)[] ? FormFieldArray<U> : FormField<T[K]>
  fieldArray<K extends keyof T>(key: K): T[K] extends readonly (infer U)[] ? FormFieldArray<U> : never

  // Field actions
  focus: () => void // Sets as currently editing, auto-marks as touched
  blur: () => void // Unsets as currently editing
}

export interface FormFieldArray<T> extends Omit<FormField<T[]>, "field" | "fieldArray"> {
  // Array-specific methods
  add: (item?: Partial<T>) => void
  remove: (index: number) => void
  move: (from: number, to: number) => void

  // Reactive array of field instances for iteration
  fields: Readonly<Ref<FormField<T>[]>>

  // Get individual array item fields
  field: <P extends string | number>(path: P) => ArrayFieldPath<T, P>
  fieldArray: <P extends string | number>(path: P) => ArrayFieldArrayPath<T, P>
}

export interface UseLiveFormReturn<T extends object> {
  // Form-level state
  isValid: Ref<boolean>
  isDirty: Ref<boolean>
  isTouched: Ref<boolean>
  submitCount: Readonly<Ref<number>>
  initialValues: Readonly<Ref<T>>

  // Type-safe field factory functions
  field<P extends PathsToStringProps<T>>(path: P): FormField<PathValue<T, P>>
  fieldArray<P extends PathsToStringProps<T>>(
    path: P
  ): PathValue<T, P> extends readonly (infer U)[] ? FormFieldArray<U> : never

  // Form actions
  submit: () => Promise<void>
  reset: () => void
}

export function useLiveForm<T extends object>(
  form: MaybeRefOrGetter<Form<T>>,
  options: FormOptions = {}
): UseLiveFormReturn<T> {
  const {
    changeEvent = null,
    submitEvent = "submit",
    debounceInMiliseconds = 300,
    prepareData = (data: any) => data,
  } = options

  // Get initial form data
  const initialForm = toValue(form)
  const initialValues = ref(deepClone(initialForm.values)) as Ref<T>
  const currentValues = reactive(deepClone(initialForm.values)) as T
  const currentErrors = reactive(deepClone(initialForm.errors)) as FormErrors<T>

  // Form-level state tracking
  const touchedFields = reactive<Set<string>>(new Set())
  const editingFields = reactive<Set<string>>(new Set())
  const submitCount = ref(0)
  const isUpdatingFromServer = ref(false)

  // Memoization for field instances to prevent recreation
  const fieldCache = new Map<string, FormField<any>>()
  const fieldArrayCache = new Map<string, FormFieldArray<any>>()

  // Helper function to check if any errors exist in nested error structure
  function hasAnyErrors(errors: any): boolean {
    if (Array.isArray(errors)) {
      // Check if it's an array of strings (field errors) or array of objects (nested form errors)
      if (errors.length === 0) return false

      // If first item is string, it's a field error array
      if (typeof errors[0] === "string") {
        return errors.length > 0
      }

      // If first item is object, it's an array of nested error objects
      return errors.some(item => hasAnyErrors(item))
    }
    if (typeof errors === "object" && errors !== null) {
      return Object.values(errors).some(value => hasAnyErrors(value))
    }
    return false
  }

  // Form-level computed properties
  const isValid = computed(() => !hasAnyErrors(currentErrors))

  const isDirty = computed(() => {
    return JSON.stringify(currentValues) !== JSON.stringify(initialValues.value)
  })

  const isTouched = computed(() => {
    return submitCount.value > 0 || touchedFields.size > 0
  })

  // LiveView integration
  const live = useLiveVue()

  // Create debounced change handler
  const debouncedSendChanges = debounce(() => {
    if (live && changeEvent) {
      const data = prepareData(deepToRaw(currentValues))
      live.pushEvent(changeEvent, { [initialForm.name]: data })
    }
  }, debounceInMiliseconds)

  // Create a form field for a given path
  function createFormField<V>(path: string): FormField<V> {
    // Check cache first
    if (fieldCache.has(path)) {
      return fieldCache.get(path) as FormField<V>
    }

    const keys = parsePath(path)

    const fieldValue = computed({
      get(): V {
        return getValueByPath(currentValues, keys)
      },
      set(newValue: V) {
        setValueByPath(currentValues, keys, newValue)
      },
    })

    const fieldErrors = computed(() => {
      const errors = getValueByPath(currentErrors, keys)
      return Array.isArray(errors) ? errors : []
    })

    const fieldErrorMessage = computed(() => {
      const errors = fieldErrors.value
      return errors.length > 0 ? errors[0] : undefined
    })

    const fieldIsValid = computed(() => fieldErrors.value.length === 0)
    const fieldIsTouched = computed(() => submitCount.value > 0 || touchedFields.has(path))
    const fieldIsDirty = computed(() => {
      const currentVal = getValueByPath(currentValues, keys)
      const initialVal = getValueByPath(initialValues.value, keys)
      return JSON.stringify(currentVal) !== JSON.stringify(initialVal)
    })

    // Create sanitized ID from path (replace dots with underscores, remove brackets)
    const fieldId = path.replace(/\./g, "_").replace(/\[|\]/g, "_").replace(/_+/g, "_").replace(/^_|_$/g, "")
    const fieldInputAttrs = computed(() => ({
      value: fieldValue.value,
      onInput: (event: Event) => {
        const target = event.target as HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
        fieldValue.value = target.value as V
      },
      onFocus: () => {
        editingFields.add(path)
      },
      onBlur: () => {
        editingFields.delete(path)
        touchedFields.add(path)
      },
      name: path,
      id: fieldId,
      "aria-invalid": !fieldIsValid.value,
      ...(fieldErrors.value.length > 0 ? { "aria-describedby": `${fieldId}-error` } : {}),
    }))

    const field = {
      value: fieldValue,
      errors: fieldErrors as Readonly<Ref<string[]>>,
      errorMessage: fieldErrorMessage as Readonly<Ref<string | undefined>>,
      isValid: fieldIsValid,
      isDirty: fieldIsDirty,
      isTouched: fieldIsTouched,
      inputAttrs: fieldInputAttrs,

      field<K extends keyof V>(key: K): V[K] extends readonly (infer U)[] ? FormFieldArray<U> : FormField<V[K]> {
        const subPath = path ? `${path}.${String(key)}` : String(key)
        return createFormField(subPath) as V[K] extends readonly (infer U)[] ? FormFieldArray<U> : FormField<V[K]>
      },

      fieldArray<K extends keyof V>(key: K): V[K] extends readonly (infer U)[] ? FormFieldArray<U> : never {
        const subPath = path ? `${path}.${String(key)}` : String(key)
        return createFormFieldArray(subPath) as V[K] extends readonly (infer U)[] ? FormFieldArray<U> : never
      },

      focus() {
        editingFields.add(path)
      },

      blur() {
        editingFields.delete(path)
        touchedFields.add(path)
      },
    }

    // Cache the field instance
    fieldCache.set(path, field as any)
    return field
  }

  function createFormFieldArray<V>(path: string): FormFieldArray<V> {
    // Check cache first
    if (fieldArrayCache.has(path)) {
      return fieldArrayCache.get(path) as FormFieldArray<V>
    }

    const baseField = createFormField<V[]>(path)

    const fieldArray = {
      ...baseField,

      add(item?: Partial<V>) {
        const currentArray = baseField.value.value || []
        baseField.value.value = [...currentArray, item as V]
      },

      remove(index: number) {
        const currentArray = baseField.value.value || []
        baseField.value.value = currentArray.filter((_, i) => i !== index)
      },

      move(from: number, to: number) {
        const currentArray = [...(baseField.value.value || [])]
        if (from >= 0 && from < currentArray.length && to >= 0 && to < currentArray.length) {
          const item = currentArray.splice(from, 1)[0]
          currentArray.splice(to, 0, item)
          baseField.value.value = currentArray
        }
      },

      fields: computed(() => {
        const array = baseField.value.value || []
        return array.map((_, index) => createFormField<V>(`${path}[${index}]`))
      }) as Readonly<Ref<FormField<V>[]>>,

      field<P extends string | number>(pathOrIndex: P): ArrayFieldPath<V, P> {
        // Handle number shortcut: convert 0 to "[0]"
        if (typeof pathOrIndex === "number") {
          return createFormField(`${path}[${pathOrIndex}]`) as ArrayFieldPath<V, P>
        }
        // Handle string path: use as-is, could be "[0]", "[0].name", etc.
        return createFormField(`${path}${pathOrIndex}`) as ArrayFieldPath<V, P>
      },

      fieldArray<P extends string | number>(pathOrIndex: P): ArrayFieldArrayPath<V, P> {
        // Handle number shortcut: convert 0 to "[0]"
        if (typeof pathOrIndex === "number") {
          return createFormFieldArray(`${path}[${pathOrIndex}]`) as ArrayFieldArrayPath<V, P>
        }
        // Handle string path: use as-is, could be "[0]", "[0].tags", etc.
        return createFormFieldArray(`${path}${pathOrIndex}`) as ArrayFieldArrayPath<V, P>
      },
    }

    // Cache the field array instance
    fieldArrayCache.set(path, fieldArray)
    return fieldArray
  }

  // Method to update form state from server
  function updateFromServer(newForm: Form<T>) {
    // Set flag to prevent triggering change events during server update
    isUpdatingFromServer.value = true

    try {
      // Update values intelligently - only skip paths that are currently being edited
      const newValues = deepClone(newForm.values)

      if (editingFields.size === 0) {
        // No fields being edited, safe to update everything
        Object.assign(currentValues, newValues)
      } else {
        // Selective update - avoid overwriting fields currently being edited
        updateValuesSelectively(currentValues, newValues, editingFields)
      }

      // Always update errors since they come from server validation
      // Use deep replacement instead of Object.assign to handle error clearing
      replaceReactiveObject(currentErrors, deepClone(newForm.errors))
    } finally {
      // Clear the flag after Vue's reactive effects have been flushed
      nextTick(() => {
        isUpdatingFromServer.value = false
      })
    }
  }

  // Helper function to selectively update values, avoiding currently edited paths
  function updateValuesSelectively(current: any, newValues: any, editingPaths: Set<string>, currentPath = "") {
    for (const key in newValues) {
      const fullPath = currentPath ? `${currentPath}.${key}` : key

      // Check if this path or any parent path is being edited
      const isBeingEdited = Array.from(editingPaths).some(
        editingPath => editingPath.startsWith(fullPath) || fullPath.startsWith(editingPath)
      )

      if (!isBeingEdited) {
        if (typeof newValues[key] === "object" && newValues[key] !== null && !Array.isArray(newValues[key])) {
          // Recursively update nested objects
          if (!current[key] || typeof current[key] !== "object") {
            current[key] = {}
          }
          updateValuesSelectively(current[key], newValues[key], editingPaths, fullPath)
        } else {
          // Update primitive values and arrays
          current[key] = newValues[key]
        }
      }
    }
  }

  // Watch for changes and send to server (debounced) - but only when not updating from server
  const stopWatchingValues = watch(
    () => currentValues,
    () => {
      if (!isUpdatingFromServer.value) debouncedSendChanges()
    },
    { deep: true }
  )

  // Watch for server updates to the form
  const stopWatchingForm = watch(() => toValue(form), updateFromServer, { deep: true })

  const reset = () => {
    Object.assign(currentValues, deepClone(initialValues.value))
    touchedFields.clear()
    editingFields.clear()
    submitCount.value = 0
  }

  const submit = async () => {
    // Increment submit count to mark all fields as touched
    submitCount.value += 1

    if (live) {
      const data = prepareData(deepToRaw(currentValues))

      return new Promise<void>((resolve, reject) => {
        // Send submit event to LiveView
        const result = live.pushEvent(submitEvent, { [initialForm.name]: data })

        // If pushEvent returns a promise, wait for it
        if (result && typeof result.then === "function") {
          result
            .then(() => {
              // On successful submission:
              // 1. Update initial values to match current values (server accepted changes)
              initialValues.value = deepClone(toValue(form).values)
              reset()
              resolve()
            })
            .catch(error => {
              // On failed submission, keep the incremented submit count
              reject(error)
            })
        } else {
          // Non-promise result means immediate success
          // Update initial values to match current values
          initialValues.value = deepClone(toValue(form).values)
          // Reset touched state and submit count
          reset()
          resolve()
        }
      })
    } else {
      // Fallback when not in LiveView context
      console.warn("LiveView hook not available, form submission skipped")
      return Promise.resolve()
    }
  }

  // Clean up watchers when component unmounts
  onScopeDispose(() => {
    if (stopWatchingValues) {
      stopWatchingValues()
    }
    stopWatchingForm()
  })

  const formInstance = {
    isValid,
    isDirty,
    isTouched,
    submitCount: readonly(submitCount),
    initialValues: readonly(initialValues) as Readonly<Ref<T>>,
    submit: submit,
    reset: reset,
    field<P extends PathsToStringProps<T>>(path: P): FormField<PathValue<T, P>> {
      return createFormField<PathValue<T, P>>(path as string)
    },

    fieldArray<P extends PathsToStringProps<T>>(path: P): any {
      return createFormFieldArray(path as string)
    },
  }

  // Provide the form instance to child components
  provide(LIVE_FORM_INJECTION_KEY, formInstance as any)

  return formInstance
}

/**
 * Hook to access form fields from an injected form instance
 * @param path - The field path (e.g., "name", "user.email", "items[0].title")
 * @throws Error if no form was provided via inject
 * @returns FormField instance for the specified path
 */
export function useField<T = any>(path: string): FormField<T> {
  const form = inject(LIVE_FORM_INJECTION_KEY)

  if (!form) {
    throw new Error(
      "useField() can only be used inside components where a form has been provided. " +
        "Make sure to use useLiveForm() in a parent component."
    )
  }

  return form.field(path) as FormField<T>
}

/**
 * Hook to access form array fields from an injected form instance
 * @param path - The field path for an array field (e.g., "items", "user.tags", "posts[0].comments")
 * @throws Error if no form was provided via inject
 * @returns FormFieldArray instance for the specified path
 */
export function useArrayField<T = any>(path: string): FormFieldArray<T> {
  const form = inject(LIVE_FORM_INJECTION_KEY)

  if (!form) {
    throw new Error(
      "useArrayField() can only be used inside components where a form has been provided. " +
        "Make sure to use useLiveForm() in a parent component."
    )
  }

  return form.fieldArray(path) as FormFieldArray<T>
}
