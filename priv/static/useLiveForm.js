import { ref, reactive, computed, toValue, watch, onScopeDispose, nextTick, provide, inject, readonly, } from "vue";
import { useLiveVue } from "./use";
import { parsePath, getValueByPath, setValueByPath, deepClone, debounce, replaceReactiveObject, deepToRaw, } from "./utils";
// Injection key for providing form instances to child components
export const LIVE_FORM_INJECTION_KEY = Symbol("LiveForm");
export function useLiveForm(form, options = {}) {
    const { changeEvent = null, submitEvent = "submit", debounceInMiliseconds = 300, prepareData = (data) => data, } = options;
    // Get initial form data
    const initialForm = toValue(form);
    const initialValues = ref(deepClone(initialForm.values));
    const currentValues = reactive(deepClone(initialForm.values));
    const currentErrors = reactive(deepClone(initialForm.errors));
    // Form-level state tracking
    const touchedFields = reactive(new Set());
    const editingFields = reactive(new Set());
    const submitCount = ref(0);
    const isUpdatingFromServer = ref(false);
    // Memoization for field instances to prevent recreation
    const fieldCache = new Map();
    const fieldArrayCache = new Map();
    // Helper function to check if any errors exist in nested error structure
    function hasAnyErrors(errors) {
        if (Array.isArray(errors)) {
            // Check if it's an array of strings (field errors) or array of objects (nested form errors)
            if (errors.length === 0)
                return false;
            // If first item is string, it's a field error array
            if (typeof errors[0] === "string") {
                return errors.length > 0;
            }
            // If first item is object, it's an array of nested error objects
            return errors.some(item => hasAnyErrors(item));
        }
        if (typeof errors === "object" && errors !== null) {
            return Object.values(errors).some(value => hasAnyErrors(value));
        }
        return false;
    }
    // Form-level computed properties
    const isValid = computed(() => !hasAnyErrors(currentErrors));
    const isDirty = computed(() => {
        return JSON.stringify(currentValues) !== JSON.stringify(initialValues.value);
    });
    const isTouched = computed(() => {
        return submitCount.value > 0 || touchedFields.size > 0;
    });
    // LiveView integration
    const live = useLiveVue();
    // Create debounced change handler
    const debouncedSendChanges = debounce(() => {
        if (live && isDirty.value && changeEvent) {
            const data = prepareData(deepToRaw(currentValues));
            live.pushEvent(changeEvent, { [initialForm.name]: data });
        }
    }, debounceInMiliseconds);
    // Create a form field for a given path
    function createFormField(path) {
        // Check cache first
        if (fieldCache.has(path)) {
            return fieldCache.get(path);
        }
        const keys = parsePath(path);
        const fieldValue = computed({
            get() {
                return getValueByPath(currentValues, keys);
            },
            set(newValue) {
                setValueByPath(currentValues, keys, newValue);
            },
        });
        const fieldErrors = computed(() => {
            const errors = getValueByPath(currentErrors, keys);
            return Array.isArray(errors) ? errors : [];
        });
        const fieldErrorMessage = computed(() => {
            const errors = fieldErrors.value;
            return errors.length > 0 ? errors[0] : undefined;
        });
        const fieldIsValid = computed(() => fieldErrors.value.length === 0);
        const fieldIsTouched = computed(() => submitCount.value > 0 || touchedFields.has(path));
        const fieldIsDirty = computed(() => {
            const currentVal = getValueByPath(currentValues, keys);
            const initialVal = getValueByPath(initialValues.value, keys);
            return JSON.stringify(currentVal) !== JSON.stringify(initialVal);
        });
        // Create sanitized ID from path (replace dots with underscores, remove brackets)
        const fieldId = path.replace(/\./g, "_").replace(/\[|\]/g, "_").replace(/_+/g, "_").replace(/^_|_$/g, "");
        const fieldInputAttrs = computed(() => ({
            value: fieldValue.value,
            onInput: (event) => {
                const target = event.target;
                fieldValue.value = target.value;
            },
            onFocus: () => {
                editingFields.add(path);
            },
            onBlur: () => {
                editingFields.delete(path);
                touchedFields.add(path);
            },
            name: path,
            id: fieldId,
            "aria-invalid": !fieldIsValid.value,
            ...(fieldErrors.value.length > 0 ? { "aria-describedby": `${fieldId}-error` } : {}),
        }));
        const field = {
            value: fieldValue,
            errors: fieldErrors,
            errorMessage: fieldErrorMessage,
            isValid: fieldIsValid,
            isDirty: fieldIsDirty,
            isTouched: fieldIsTouched,
            inputAttrs: fieldInputAttrs,
            field(key) {
                const subPath = path ? `${path}.${String(key)}` : String(key);
                return createFormField(subPath);
            },
            fieldArray(key) {
                const subPath = path ? `${path}.${String(key)}` : String(key);
                return createFormFieldArray(subPath);
            },
            focus() {
                editingFields.add(path);
            },
            blur() {
                editingFields.delete(path);
                touchedFields.add(path);
            },
        };
        // Cache the field instance
        fieldCache.set(path, field);
        return field;
    }
    function createFormFieldArray(path) {
        // Check cache first
        if (fieldArrayCache.has(path)) {
            return fieldArrayCache.get(path);
        }
        const baseField = createFormField(path);
        const fieldArray = {
            ...baseField,
            add(item) {
                const currentArray = baseField.value.value || [];
                baseField.value.value = [...currentArray, item];
            },
            remove(index) {
                const currentArray = baseField.value.value || [];
                baseField.value.value = currentArray.filter((_, i) => i !== index);
            },
            move(from, to) {
                const currentArray = [...(baseField.value.value || [])];
                if (from >= 0 && from < currentArray.length && to >= 0 && to < currentArray.length) {
                    const item = currentArray.splice(from, 1)[0];
                    currentArray.splice(to, 0, item);
                    baseField.value.value = currentArray;
                }
            },
            fields: computed(() => {
                const array = baseField.value.value || [];
                return array.map((_, index) => createFormField(`${path}[${index}]`));
            }),
            field(pathOrIndex) {
                // Handle number shortcut: convert 0 to "[0]"
                if (typeof pathOrIndex === "number") {
                    return createFormField(`${path}[${pathOrIndex}]`);
                }
                // Handle string path: use as-is, could be "[0]", "[0].name", etc.
                return createFormField(`${path}${pathOrIndex}`);
            },
            fieldArray(pathOrIndex) {
                // Handle number shortcut: convert 0 to "[0]"
                if (typeof pathOrIndex === "number") {
                    return createFormFieldArray(`${path}[${pathOrIndex}]`);
                }
                // Handle string path: use as-is, could be "[0]", "[0].tags", etc.
                return createFormFieldArray(`${path}${pathOrIndex}`);
            },
        };
        // Cache the field array instance
        fieldArrayCache.set(path, fieldArray);
        return fieldArray;
    }
    // Method to update form state from server
    function updateFromServer(newForm) {
        // Set flag to prevent triggering change events during server update
        isUpdatingFromServer.value = true;
        try {
            // Update values intelligently - only skip paths that are currently being edited
            const newValues = deepClone(newForm.values);
            if (editingFields.size === 0) {
                // No fields being edited, safe to update everything
                Object.assign(currentValues, newValues);
            }
            else {
                // Selective update - avoid overwriting fields currently being edited
                updateValuesSelectively(currentValues, newValues, editingFields);
            }
            // Always update errors since they come from server validation
            // Use deep replacement instead of Object.assign to handle error clearing
            replaceReactiveObject(currentErrors, deepClone(newForm.errors));
        }
        finally {
            // Clear the flag after Vue's reactive effects have been flushed
            nextTick(() => {
                isUpdatingFromServer.value = false;
            });
        }
    }
    // Helper function to selectively update values, avoiding currently edited paths
    function updateValuesSelectively(current, newValues, editingPaths, currentPath = "") {
        for (const key in newValues) {
            const fullPath = currentPath ? `${currentPath}.${key}` : key;
            // Check if this path or any parent path is being edited
            const isBeingEdited = Array.from(editingPaths).some(editingPath => editingPath.startsWith(fullPath) || fullPath.startsWith(editingPath));
            if (!isBeingEdited) {
                if (typeof newValues[key] === "object" && newValues[key] !== null && !Array.isArray(newValues[key])) {
                    // Recursively update nested objects
                    if (!current[key] || typeof current[key] !== "object") {
                        current[key] = {};
                    }
                    updateValuesSelectively(current[key], newValues[key], editingPaths, fullPath);
                }
                else {
                    // Update primitive values and arrays
                    current[key] = newValues[key];
                }
            }
        }
    }
    // Watch for changes and send to server (debounced) - but only when not updating from server
    const stopWatchingValues = watch(() => currentValues, () => {
        if (!isUpdatingFromServer.value)
            debouncedSendChanges();
    }, { deep: true });
    // Watch for server updates to the form
    const stopWatchingForm = watch(() => toValue(form), updateFromServer, { deep: true });
    const reset = () => {
        Object.assign(currentValues, deepClone(initialValues.value));
        touchedFields.clear();
        editingFields.clear();
        submitCount.value = 0;
    };
    const submit = async () => {
        // Increment submit count to mark all fields as touched
        submitCount.value += 1;
        if (live) {
            const data = prepareData(deepToRaw(currentValues));
            return new Promise((resolve, reject) => {
                // Send submit event to LiveView
                const result = live.pushEvent(submitEvent, { [initialForm.name]: data });
                // If pushEvent returns a promise, wait for it
                if (result && typeof result.then === "function") {
                    result
                        .then(() => {
                        // On successful submission:
                        // 1. Update initial values to match current values (server accepted changes)
                        initialValues.value = deepClone(toValue(form).values);
                        reset();
                        resolve();
                    })
                        .catch(error => {
                        // On failed submission, keep the incremented submit count
                        reject(error);
                    });
                }
                else {
                    // Non-promise result means immediate success
                    // Update initial values to match current values
                    initialValues.value = deepClone(toValue(form).values);
                    // Reset touched state and submit count
                    reset();
                    resolve();
                }
            });
        }
        else {
            // Fallback when not in LiveView context
            console.warn("LiveView hook not available, form submission skipped");
            return Promise.resolve();
        }
    };
    // Clean up watchers when component unmounts
    onScopeDispose(() => {
        if (stopWatchingValues) {
            stopWatchingValues();
        }
        stopWatchingForm();
    });
    const formInstance = {
        isValid,
        isDirty,
        isTouched,
        submitCount: readonly(submitCount),
        initialValues: readonly(initialValues),
        submit: submit,
        reset: reset,
        field(path) {
            return createFormField(path);
        },
        fieldArray(path) {
            return createFormFieldArray(path);
        },
    };
    // Provide the form instance to child components
    provide(LIVE_FORM_INJECTION_KEY, formInstance);
    return formInstance;
}
/**
 * Hook to access form fields from an injected form instance
 * @param path - The field path (e.g., "name", "user.email", "items[0].title")
 * @throws Error if no form was provided via inject
 * @returns FormField instance for the specified path
 */
export function useField(path) {
    const form = inject(LIVE_FORM_INJECTION_KEY);
    if (!form) {
        throw new Error("useField() can only be used inside components where a form has been provided. " +
            "Make sure to use useLiveForm() in a parent component.");
    }
    return form.field(path);
}
/**
 * Hook to access form array fields from an injected form instance
 * @param path - The field path for an array field (e.g., "items", "user.tags", "posts[0].comments")
 * @throws Error if no form was provided via inject
 * @returns FormFieldArray instance for the specified path
 */
export function useArrayField(path) {
    const form = inject(LIVE_FORM_INJECTION_KEY);
    if (!form) {
        throw new Error("useArrayField() can only be used inside components where a form has been provided. " +
            "Make sure to use useLiveForm() in a parent component.");
    }
    return form.fieldArray(path);
}
