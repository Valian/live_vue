/* eslint-disable @typescript-eslint/no-explicit-any */
import { reactive, isRef, watch, computed, ref } from "vue";
import { useLiveVue } from "./use";
import { cacheOnAccessProxy, debounce, deepAssign, deepCopy } from "./utils";
/**
 * Recursively searches for the first error message in a nested error structure
 * @param errors - Error structure to search
 * @returns The first error message found, or undefined if no errors
 */
const findFirstError = (errors) => {
    if (typeof errors === "string")
        return errors;
    errors = Array.isArray(errors) ? errors : Object.values(errors);
    for (const error of errors) {
        const firstError = findFirstError(error || []);
        if (firstError)
            return firstError;
    }
};
/**
 * Creates a nested form state for handling sub-forms
 * @param form - Parent form state
 * @param name - Property name of the nested form
 * @returns Internal form state for the nested form
 */
const createNestedForm = (form, name) => {
    // Initialize nested state if it doesn't exist
    form.errors[name] = form.errors[name] || {};
    form.touched[name] = form.touched[name] || {};
    form.values[name] = form.values[name] || {};
    return {
        name: `${form.name}.${name.toString()}`,
        initialValues: form.initialValues[name],
        values: form.values[name],
        errors: form.errors[name],
        touched: form.touched[name],
        onChange: form.onChange,
    };
};
/**
 * Class implementation of FormState that provides a reactive interface to the form
 * @template T - The type of form values
 */
class FormStateClass {
    constructor(form) {
        this.form = form;
        this.name = form.name;
        // Create proxies that lazily instantiate field and form states when accessed
        this.fields = cacheOnAccessProxy(name => new FieldStateClass(form, name));
        this.forms = cacheOnAccessProxy((name) => new FormStateClass(createNestedForm(form, name)));
    }
    /** Get or set the entire form value object */
    get value() {
        return this.form.values;
    }
    set value(newValue) {
        this.form.values = newValue;
        this.form.onChange(this.name);
    }
    /**
     * Whether any field in the form has been touched
     * Setting this will mark all fields as touched/untouched
     */
    get touched() {
        for (const key in this.fields)
            if (this.fields[key].touched)
                return true;
        for (const key in this.forms)
            if (this.forms[key].touched)
                return true;
        return false;
    }
    set touched(value) {
        for (const key in this.fields)
            this.fields[key].touched = value;
        for (const key in this.forms)
            this.forms[key].touched = value;
    }
    /** All validation errors in the form */
    get errors() {
        return this.form.errors;
    }
    /** First error message in the form, if any */
    get errorMessage() {
        return findFirstError(this.errors);
    }
    /** Metadata about the form's overall state */
    get meta() {
        const fields = Object.values(this.fields);
        const forms = Object.values(this.forms);
        return {
            valid: fields.every(field => field.meta.valid) && forms.every(form => form.meta.valid),
            dirty: fields.some(field => field.meta.dirty) || forms.some(form => form.meta.dirty),
            initialValue: this.form.initialValues,
        };
    }
}
/**
 * Class implementation of FieldState that provides a reactive interface to a form field
 * @template T - The type of the parent form values
 */
class FieldStateClass {
    constructor(form, name) {
        this.fieldName = name;
        this.name = `${form.name}.${name.toString()}`;
        this.form = form;
        // Initialize field state
        this.form.touched[name] = this.form.touched[name] || false;
        this.form.errors[name] = this.form.errors[name] || [];
        // Watch for changes to the field value
        watch(() => this.value, () => {
            this.touched = true;
            this.form.onChange(this.name);
        }, { deep: true, flush: "sync" });
    }
    /** Get or set the field value */
    get value() {
        return this.form.values[this.fieldName];
    }
    set value(newValue) {
        this.form.values[this.fieldName] = newValue;
        this.form.touched[this.fieldName] = true;
    }
    /** Whether the field has been touched */
    get touched() {
        return this.form.touched[this.fieldName];
    }
    set touched(value) {
        this.form.touched[this.fieldName] = value;
    }
    /** Validation errors for this field */
    get errors() {
        return this.form.errors[this.fieldName];
    }
    /** First error message for this field, if any */
    get errorMessage() {
        return findFirstError(this.errors || []);
    }
    /** Metadata about the field's state */
    get meta() {
        // Compare string representations to detect changes
        const initialJson = JSON.stringify(this.form.initialValues[this.fieldName]);
        const currentJson = JSON.stringify(this.form.values[this.fieldName]);
        return {
            valid: !this.errorMessage,
            dirty: initialJson !== currentJson,
            initialValue: this.form.initialValues[this.fieldName],
        };
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
export const useLiveForm = (initialForm, options) => {
    if (!isRef(initialForm))
        throw new Error('form must be a ref. Use `toRef(props, "form")` to create a ref from a prop.');
    const live = useLiveVue();
    // Create change handler with optional debounce
    const onChange = (fieldName) => {
        if (options.changeEvent) {
            live.pushEvent(options.changeEvent, { [form.name]: form.values, _target: fieldName.split(".") });
        }
    };
    // Initialize form state
    const form = {
        name: initialForm.value.name,
        initialValues: reactive(deepCopy(initialForm.value.values)),
        values: reactive(deepCopy(initialForm.value.values)),
        errors: reactive(deepCopy(initialForm.value.errors)),
        touched: reactive({}),
        onChange: options.debounceInMiliseconds ? debounce(onChange, options.debounceInMiliseconds) : onChange,
    };
    const formState = new FormStateClass(form);
    const isSubmitting = ref(false);
    const submitCount = ref(0);
    /**
     * Submits the form to the server
     * @param e - Optional event object to prevent default form submission
     * @returns Promise that resolves to form validity after submission
     */
    const submit = async (e) => {
        if (!options.submitEvent) {
            throw new Error('submitEvent was not provided. Use `submitEvent: "submit"` to submit the form.');
        }
        const submitEvent = options.submitEvent;
        e?.preventDefault();
        if (!isSubmitting.value) {
            isSubmitting.value = true;
            formState.touched = true;
            submitCount.value++;
            return new Promise(resolve => {
                let data = { [form.name]: form.values };
                if (options.prepareData)
                    data = options.prepareData(data);
                return live.pushEvent(submitEvent, data, () => {
                    isSubmitting.value = false;
                    deepAssign(form.initialValues, form.values);
                    // a small hack, that valid value is there but I'm not including it in the main type to avoid defining it in the subforms
                    resolve(initialForm.value.valid);
                });
            });
        }
    };
    // Update form errors when server validation results come back
    watch(initialForm, newForm => deepAssign(form.errors, newForm.errors), { deep: true });
    return {
        fields: formState.fields,
        forms: formState.forms,
        form: formState,
        isSubmitting: isSubmitting,
        submitCount: submitCount,
        submit,
    };
};
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
export const useFieldArray = (field) => {
    // Create a computed array of items with their values and errors
    const items = computed(() => {
        const errors = Array.isArray(field.errors) ? field.errors : [];
        const values = field.value || [];
        return values.map((value, index) => ({
            value,
            error: (errors[index] || {}),
            errorMessage: findFirstError(errors[index] || {}),
            key: index,
        }));
    });
    /**
     * Adds a new item to the end of the array
     * @param value - The item to add
     */
    const push = (value) => {
        field.value.push(value);
    };
    /**
     * Removes an item at the specified index
     * @param index - The index of the item to remove
     */
    const remove = (index) => {
        field.value = field.value.filter((_, i) => i !== index);
    };
    /**
     * Updates an item at the specified index
     * @param index - The index of the item to update
     * @param value - The new value for the item
     */
    const update = (index, value) => {
        field.value = field.value.map((item, i) => (i === index ? value : item));
    };
    return {
        items,
        push,
        remove,
        update,
    };
};
