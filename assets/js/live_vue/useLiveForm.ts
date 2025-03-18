/* eslint-disable @typescript-eslint/no-explicit-any */
import { reactive, isRef, Ref, watch, computed, ref } from "vue"
import { useLiveVue } from "./use"
import { cacheOnAccessProxy, debounce, deepAssign, deepCopy } from "./utils"

/**
 * Maps form field structure to a corresponding structure tracking touched state
 * For each field in the original form, creates a boolean flag indicating if it's been modified
 */
type TouchedValues<T extends object> = {
  [K in keyof T]: T[K] extends object ? TouchedValues<T[K]> : boolean
}

/**
 * Maps form field structure to a corresponding structure for validation errors
 * For each field in the original form, creates an array of error strings
 */
type FormErrors<T extends object> = {
  [K in keyof T]: T[K] extends object ? FormErrors<T[K]> : string[]
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
}

/**
 * Extended internal form state interface used by the form system
 * @template T - The type of form values
 */
interface FormStateInternal<T extends object> extends Form<T> {
  /** Original values when the form was initialized or last submitted */
  initialValues: T
  /** Tracks which fields have been modified by the user */
  touched: TouchedValues<T>
  /** Callback that runs when any field value changes */
  onChange: (name: string) => void
}

/**
 * Metadata about a field's state
 */
interface FieldMeta {
  /** Whether the field passes validation */
  valid: boolean
  /** Whether the field's value differs from its initial value */
  dirty: boolean
  /** The field's initial value */
  initialValue: any
}

/**
 * Represents the state of an individual form field
 * @template T - The type of the field value
 */
interface FieldState<T = any> {
  /** Full path name of the field (e.g. "user.address.street") */
  name: string
  /** Current field value */
  value: T
  /** Whether the field has been modified by the user */
  touched: boolean
  /** Validation errors for this field */
  errors: T extends object ? FormErrors<T> : string[]
  /** First error message for this field, if any */
  errorMessage: string | undefined
  /** Additional metadata about the field state */
  meta: FieldMeta
}

/**
 * Complete form state accessible to component
 * @template T - The type of form values
 */
interface FormState<T extends object> {
  /** Full path name of the form */
  name: string
  /** Current form values */
  value: T
  /** Whether any field in the form has been touched */
  touched: boolean
  /** All validation errors in the form */
  errors: FormErrors<T>
  /** First error message in the form, if any */
  errorMessage: string | undefined
  /** Metadata about the form state */
  meta: FieldMeta
  /** Access to all primitive fields (string, number, boolean, arrays) */
  fields: { [K in keyof T as T[K] extends string | boolean | number | any[] ? K : never]: FieldState<T[K]> }
  /** Access to all nested form objects */
  forms: { [K in keyof T as T[K] extends object ? K : never]: FormState<T[K] & object> }
}

/**
 * Configuration options for the form system
 */
export interface FormOptions {
  /** Event name to send to the server when form values change */
  changeEvent?: string
  /** Event name to send to the server when form is submitted */
  submitEvent?: string
  /** Delay in milliseconds before sending change events to reduce server load */
  debounceInMiliseconds?: number
  /** Function to transform form data before sending to server */
  prepareData?: (data: any) => any
}

/**
 * Recursively searches for the first error message in a nested error structure
 * @param errors - Error structure to search
 * @returns The first error message found, or undefined if no errors
 */
const findFirstError = <T extends object>(
  errors: FormErrors<T> | FormErrors<T>[] | string[] | string
): string | undefined => {
  if (typeof errors === "string") return errors
  errors = Array.isArray(errors) ? errors : Object.values(errors)
  for (const error of errors) {
    const firstError = findFirstError(error || [])
    if (firstError) return firstError
  }
}

/**
 * Creates a nested form state for handling sub-forms
 * @param form - Parent form state
 * @param name - Property name of the nested form
 * @returns Internal form state for the nested form
 */
const createNestedForm = <T extends object>(form: FormStateInternal<T>, name: keyof T) => {
  // Initialize nested state if it doesn't exist
  form.errors[name] = form.errors[name] || {}
  form.touched[name] = form.touched[name] || ({} as TouchedValues<T>[keyof T])
  form.values[name] = form.values[name] || ({} as T[typeof name])

  return {
    name: `${form.name}.${name.toString()}`,
    initialValues: form.initialValues[name],
    values: form.values[name],
    errors: form.errors[name],
    touched: form.touched[name],
    onChange: form.onChange,
  } as FormStateInternal<T[typeof name] & object>
}

/**
 * Class implementation of FormState that provides a reactive interface to the form
 * @template T - The type of form values
 */
class FormStateClass<T extends object> implements FormState<T> {
  name: string
  fields: FormState<T>["fields"]
  forms: FormState<T>["forms"]
  private form: FormStateInternal<T>

  constructor(form: FormStateInternal<T>) {
    this.form = form
    this.name = form.name

    // Create proxies that lazily instantiate field and form states when accessed
    this.fields = cacheOnAccessProxy<T>(name => new FieldStateClass(form, name)) as unknown as FormState<T>["fields"]
    this.forms = cacheOnAccessProxy<T>(
      (name: any) => new FormStateClass(createNestedForm(form, name))
    ) as FormState<T>["forms"]
  }

  /** Get or set the entire form value object */
  get value(): T {
    return this.form.values
  }
  set value(newValue: T) {
    this.form.values = newValue
    this.form.onChange(this.name)
  }

  /**
   * Whether any field in the form has been touched
   * Setting this will mark all fields as touched/untouched
   */
  get touched(): boolean {
    for (const key in this.fields) if (this.fields[key].touched) return true
    for (const key in this.forms) if (this.forms[key].touched) return true
    return false
  }
  set touched(value: boolean) {
    for (const key in this.fields) this.fields[key].touched = value
    for (const key in this.forms) this.forms[key].touched = value
  }

  /** All validation errors in the form */
  get errors(): FormErrors<T> {
    return this.form.errors
  }

  /** First error message in the form, if any */
  get errorMessage(): string | undefined {
    return findFirstError(this.errors)
  }

  /** Metadata about the form's overall state */
  get meta(): FieldMeta {
    const fields = Object.values(this.fields) as FieldState<T>[]
    const forms = Object.values(this.forms) as FormState<T>[]
    return {
      valid: fields.every(field => field.meta.valid) && forms.every(form => form.meta.valid),
      dirty: fields.some(field => field.meta.dirty) || forms.some(form => form.meta.dirty),
      initialValue: this.form.initialValues,
    }
  }
}

/**
 * Class implementation of FieldState that provides a reactive interface to a form field
 * @template T - The type of the parent form values
 */
class FieldStateClass<T extends object> implements FieldState<T[keyof T]> {
  name: string
  private form: FormStateInternal<T>
  private fieldName: keyof T

  constructor(form: FormStateInternal<T>, name: keyof T) {
    this.fieldName = name
    this.name = `${form.name}.${name.toString()}`
    this.form = form

    // Initialize field state
    this.form.touched[name] = this.form.touched[name] || (false as TouchedValues<T>[keyof T])
    this.form.errors[name] = this.form.errors[name] || []

    // Watch for changes to the field value
    watch(
      () => this.value as object,
      () => {
        this.touched = true
        this.form.onChange(this.name)
      },
      { deep: true, flush: "sync" }
    )
  }

  /** Get or set the field value */
  get value(): T[keyof T] {
    return this.form.values[this.fieldName]
  }

  set value(newValue: T[keyof T]) {
    this.form.values[this.fieldName] = newValue
    this.form.touched[this.fieldName] = true as TouchedValues<T>[keyof T]
  }

  /** Whether the field has been touched */
  get touched(): boolean {
    return this.form.touched[this.fieldName] as boolean
  }
  set touched(value: boolean) {
    this.form.touched[this.fieldName] = value as TouchedValues<T>[keyof T]
  }

  /** Validation errors for this field */
  get errors() {
    return this.form.errors[this.fieldName]
  }

  /** First error message for this field, if any */
  get errorMessage(): string | undefined {
    return findFirstError(this.errors || [])
  }

  /** Metadata about the field's state */
  get meta(): FieldMeta {
    // Compare string representations to detect changes
    const initialJson = JSON.stringify(this.form.initialValues[this.fieldName])
    const currentJson = JSON.stringify(this.form.values[this.fieldName])
    return {
      valid: !this.errorMessage,
      dirty: initialJson !== currentJson,
      initialValue: this.form.initialValues[this.fieldName],
    }
  }
}

/**
 * Vue composable that creates a reactive form interface connected to Phoenix LiveView
 *
 * @template T - The type of form values
 * @param initialForm - Ref containing form data from the server (name, values, errors)
 * @param options - Configuration options for the form
 * @returns Object with form state and utility functions for form handling
 *
 * @example
 * ```
 * // Basic usage
 * const { form, fields, submit } = useLiveForm(toRef(props, "form"), {
 *   changeEvent: "validate",
 *   submitEvent: "save"
 * })
 *
 * // Access field value and error
 * const email = fields.email.value
 * const emailError = fields.email.errorMessage
 * ```
 */
export const useLiveForm = <T extends object>(initialForm: Ref<Form<T>>, options: FormOptions) => {
  if (!isRef(initialForm))
    throw new Error('form must be a ref. Use `toRef(props, "form")` to create a ref from a prop.')

  const live = useLiveVue()

  // Create change handler with optional debounce
  const onChange = (fieldName: string) => {
    if (options.changeEvent) {
      live.pushEvent(options.changeEvent, { [form.name]: form.values, _target: fieldName.split(".") })
    }
  }

  // Initialize form state
  const form = {
    name: initialForm.value.name,
    initialValues: reactive(deepCopy(initialForm.value.values)),
    values: reactive(deepCopy(initialForm.value.values)),
    errors: reactive(deepCopy(initialForm.value.errors)),
    touched: reactive({}) as TouchedValues<T>,
    onChange: options.debounceInMiliseconds ? debounce(onChange, options.debounceInMiliseconds) : onChange,
  } as FormStateInternal<T>

  const formState = new FormStateClass<T>(form)
  const isSubmitting = ref<boolean>(false)
  const submitCount = ref<number>(0)

  /**
   * Submits the form to the server
   * @param e - Optional event object to prevent default form submission
   * @returns Promise that resolves to form validity after submission
   */
  const submit = async (e?: Event) => {
    if (!options.submitEvent) {
      throw new Error('submitEvent was not provided. Use `submitEvent: "submit"` to submit the form.')
    }
    const submitEvent = options.submitEvent
    e?.preventDefault()
    if (!isSubmitting.value) {
      isSubmitting.value = true
      formState.touched = true
      submitCount.value++
      return new Promise<boolean>(resolve => {
        let data = { [form.name]: form.values }
        if (options.prepareData) data = options.prepareData(data)
        return live.pushEvent(submitEvent, data, () => {
          isSubmitting.value = false
          deepAssign(form.initialValues, form.values)
          // a small hack, that valid value is there but I'm not including it in the main type to avoid defining it in the subforms
          resolve((initialForm as Ref<Form<T> & { valid: boolean }>).value.valid)
        })
      })
    }
  }

  // Update form errors when server validation results come back
  watch(initialForm, newForm => deepAssign(form.errors, newForm.errors), { deep: true })

  return {
    fields: formState.fields,
    forms: formState.forms,
    form: formState,
    isSubmitting: isSubmitting as Ref<boolean>,
    submitCount: submitCount as Ref<number>,
    submit,
  }
}

/**
 * Represents an item in an array field with its value, errors, and position
 */
interface ArrayItem<T> {
  /** The item's value */
  value: T
  /** Validation errors for this item */
  error?: T extends object ? FormErrors<T> : string[]
  /** First error message for this item, if any */
  errorMessage?: string
  /** Index position in the array (used as React key) */
  key: number
}

/**
 * Vue composable for managing array fields in forms
 * Provides reactive access to array items and methods to manipulate the array
 *
 * @template T - The type of items in the array
 * @param field - FieldState for the array field
 * @returns Object with items and methods to push, remove, and update items
 *
 * @example
 * ```
 * // Usage with form fields
 * const { items, push, remove } = useFieldArray(fields.items)
 *
 * // Add a new item
 * push({ name: '', quantity: 0 })
 *
 * // Remove an item
 * remove(2) // removes the item at index 2
 * ```
 */
export const useFieldArray = <T>(field: FieldState<T[]>) => {
  // Create a computed array of items with their values and errors
  const items = computed<ArrayItem<T>[]>(() => {
    const errors = Array.isArray(field.errors) ? field.errors : []
    const values = field.value || []
    return values.map((value, index) => ({
      value,
      error: (errors[index] || {}) as T extends object ? FormErrors<T> : string[],
      errorMessage: findFirstError(errors[index] || {}),
      key: index,
    }))
  })

  /**
   * Adds a new item to the end of the array
   * @param value - The item to add
   */
  const push = (value: T) => {
    field.value.push(value)
  }

  /**
   * Removes an item at the specified index
   * @param index - The index of the item to remove
   */
  const remove = (index: number) => {
    field.value = field.value.filter((_, i) => i !== index)
  }

  /**
   * Updates an item at the specified index
   * @param index - The index of the item to update
   * @param value - The new value for the item
   */
  const update = (index: number, value: T) => {
    field.value = field.value.map((item, i) => (i === index ? value : item))
  }

  return {
    items,
    push,
    remove,
    update,
  }
}
