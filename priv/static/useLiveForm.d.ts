import { Ref } from "vue";
/**
 * Maps form field structure to a corresponding structure tracking touched state
 * For each field in the original form, creates a boolean flag indicating if it's been modified
 */
type TouchedValues<T extends object> = {
    [K in keyof T]: T[K] extends object ? TouchedValues<T[K]> : boolean;
};
/**
 * Maps form field structure to a corresponding structure for validation errors
 * For each field in the original form, creates an array of error strings
 */
type FormErrors<T extends object> = {
    [K in keyof T]: T[K] extends object ? FormErrors<T[K]> : string[];
};
/**
 * Base form interface representing the data coming from the server
 * @template T - The type of form values
 */
export interface Form<T extends object> {
    /** Unique identifier for the form */
    name: string;
    /** Form field values */
    values: T;
    /** Validation errors for form fields */
    errors: FormErrors<T>;
}
/**
 * Extended internal form state interface used by the form system
 * @template T - The type of form values
 */
interface FormStateInternal<T extends object> extends Form<T> {
    /** Original values when the form was initialized or last submitted */
    initialValues: T;
    /** Tracks which fields have been modified by the user */
    touched: TouchedValues<T>;
    /** Callback that runs when any field value changes */
    onChange: (name: string) => void;
}
/**
 * Metadata about a field's state
 */
interface FieldMeta {
    /** Whether the field passes validation */
    valid: boolean;
    /** Whether the field's value differs from its initial value */
    dirty: boolean;
    /** The field's initial value */
    initialValue: any;
}
/**
 * Represents the state of an individual form field
 * @template T - The type of the field value
 */
interface FieldState<T = any> {
    /** Full path name of the field (e.g. "user.address.street") */
    name: string;
    /** Current field value */
    value: T;
    /** Whether the field has been modified by the user */
    touched: boolean;
    /** Validation errors for this field */
    errors: T extends object ? FormErrors<T> : string[];
    /** First error message for this field, if any */
    errorMessage: string | undefined;
    /** Additional metadata about the field state */
    meta: FieldMeta;
}
/**
 * Complete form state accessible to component
 * @template T - The type of form values
 */
interface FormState<T extends object> {
    /** Full path name of the form */
    name: string;
    /** Current form values */
    value: T;
    /** Whether any field in the form has been touched */
    touched: boolean;
    /** All validation errors in the form */
    errors: FormErrors<T>;
    /** First error message in the form, if any */
    errorMessage: string | undefined;
    /** Metadata about the form state */
    meta: FieldMeta;
    /** Access to all primitive fields (string, number, boolean, arrays) */
    fields: {
        [K in keyof T as T[K] extends string | boolean | number | any[] ? K : never]: FieldState<T[K]>;
    };
    /** Access to all nested form objects */
    forms: {
        [K in keyof T as T[K] extends object ? K : never]: FormState<T[K] & object>;
    };
}
/**
 * Configuration options for the form system
 */
export interface FormOptions {
    /** Event name to send to the server when form values change */
    changeEvent?: string;
    /** Event name to send to the server when form is submitted */
    submitEvent?: string;
    /** Delay in milliseconds before sending change events to reduce server load */
    debounceInMiliseconds?: number;
    /** Function to transform form data before sending to server */
    prepareData?: (data: any) => any;
}
/**
 * Class implementation of FormState that provides a reactive interface to the form
 * @template T - The type of form values
 */
declare class FormStateClass<T extends object> implements FormState<T> {
    name: string;
    fields: FormState<T>["fields"];
    forms: FormState<T>["forms"];
    private form;
    constructor(form: FormStateInternal<T>);
    /** Get or set the entire form value object */
    get value(): T;
    set value(newValue: T);
    /**
     * Whether any field in the form has been touched
     * Setting this will mark all fields as touched/untouched
     */
    get touched(): boolean;
    set touched(value: boolean);
    /** All validation errors in the form */
    get errors(): FormErrors<T>;
    /** First error message in the form, if any */
    get errorMessage(): string | undefined;
    /** Metadata about the form's overall state */
    get meta(): FieldMeta;
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
export declare const useLiveForm: <T extends object>(initialForm: Ref<Form<T>>, options: FormOptions) => {
    fields: { [K in keyof T as T[K] extends string | number | boolean | any[] ? K : never]: FieldState<T[K]>; };
    forms: { [K_1 in keyof T as T[K_1] extends object ? K_1 : never]: FormState<T[K_1] & object>; };
    form: FormStateClass<T>;
    isSubmitting: Ref<boolean>;
    submitCount: Ref<number>;
    submit: (e?: Event) => Promise<boolean | undefined>;
};
/**
 * Represents an item in an array field with its value, errors, and position
 */
interface ArrayItem<T> {
    /** The item's value */
    value: T;
    /** Validation errors for this item */
    error?: T extends object ? FormErrors<T> : string[];
    /** First error message for this item, if any */
    errorMessage?: string;
    /** Index position in the array (used as React key) */
    key: number;
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
export declare const useFieldArray: <T>(field: FieldState<T[]>) => {
    items: import("vue").ComputedRef<ArrayItem<T>[]>;
    push: (value: T) => void;
    remove: (index: number) => void;
    update: (index: number, value: T) => void;
};
export {};
