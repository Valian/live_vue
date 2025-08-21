import { type Ref, type MaybeRefOrGetter, type InjectionKey } from "vue";
export declare const LIVE_FORM_INJECTION_KEY: InjectionKey<{
    field: (path: string) => FormField<any>;
    fieldArray: (path: string) => FormFieldArray<any>;
}>;
/**
 * Maps form field structure to a corresponding structure for validation errors
 * For each field in the original form, creates an array of error strings
 */
export type FormErrors<T extends object> = {
    [K in keyof T]?: T[K] extends object ? FormErrors<T[K]> : string[];
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
    /** Whether the form is valid */
    valid: boolean;
}
type PathsToStringProps<T> = T extends string | number | boolean | Date ? never : T extends readonly (infer U)[] ? U extends object ? `[${number}]` | `[${number}].${PathsToStringProps<U>}` : `[${number}]` : T extends object ? {
    [K in keyof T]: K extends string | number ? T[K] extends readonly (infer U)[] ? U extends object ? `${K}` | `${K}[${number}]` | `${K}[${number}].${PathsToStringProps<U>}` : `${K}` | `${K}[${number}]` : T[K] extends object ? `${K}` | `${K}.${PathsToStringProps<T[K]>}` : `${K}` : never;
}[keyof T] : never;
type PathValue<T, P extends string> = P extends `${infer Key}[${infer Index}].${infer Rest}` ? Key extends keyof T ? T[Key] extends readonly (infer U)[] ? PathValue<U, Rest> : never : never : P extends `${infer Key}[${infer Index}]` ? Key extends keyof T ? T[Key] extends readonly (infer U)[] ? U : never : never : P extends `${infer Key}.${infer Rest}` ? Key extends keyof T ? PathValue<T[Key], Rest> : never : P extends `[${infer Index}]` ? T extends readonly (infer U)[] ? U : never : P extends keyof T ? T[P] : never;
type ArrayFieldPath<T, P extends string | number> = P extends number ? FormField<T> : P extends `[${number}]` ? FormField<T> : P extends `[${number}].${infer Rest}` ? PathValue<T, Rest> extends readonly (infer U)[] ? FormFieldArray<U> : FormField<PathValue<T, Rest>> : P extends keyof T ? T[P] extends readonly (infer U)[] ? FormFieldArray<U> : FormField<T[P]> : FormField<any>;
type ArrayFieldArrayPath<T, P extends string | number> = P extends number ? never : P extends `[${number}]` ? never : P extends `[${number}].${infer Rest}` ? PathValue<T, Rest> extends readonly (infer U)[] ? FormFieldArray<U> : never : P extends keyof T ? T[P] extends readonly (infer U)[] ? FormFieldArray<U> : never : never;
export interface FormOptions {
    /** Event name to send to the server when form values change. Set to null to disable validation events */
    changeEvent?: string | null;
    /** Event name to send to the server when form is submitted */
    submitEvent?: string;
    /** Delay in milliseconds before sending change events to reduce server load */
    debounceInMiliseconds?: number;
    /** Function to transform form data before sending to server */
    prepareData?: (data: any) => any;
}
export interface FormField<T> {
    value: Ref<T>;
    errors: Readonly<Ref<string[]>>;
    errorMessage: Readonly<Ref<string | undefined>>;
    isValid: Ref<boolean>;
    isDirty: Ref<boolean>;
    isTouched: Ref<boolean>;
    inputAttrs: Readonly<Ref<{
        value: T;
        onInput: (event: Event) => void;
        onBlur: () => void;
        name: string;
        id: string;
        "aria-invalid": boolean;
        "aria-describedby"?: string;
    }>>;
    field<K extends keyof T>(key: K): T[K] extends readonly (infer U)[] ? FormFieldArray<U> : FormField<T[K]>;
    fieldArray<K extends keyof T>(key: K): T[K] extends readonly (infer U)[] ? FormFieldArray<U> : never;
    blur: () => void;
}
export interface FormFieldArray<T> extends Omit<FormField<T[]>, "field" | "fieldArray"> {
    add: (item?: Partial<T>) => Promise<any>;
    remove: (index: number) => Promise<any>;
    move: (from: number, to: number) => Promise<any>;
    fields: Readonly<Ref<FormField<T>[]>>;
    field: <P extends string | number>(path: P) => ArrayFieldPath<T, P>;
    fieldArray: <P extends string | number>(path: P) => ArrayFieldArrayPath<T, P>;
}
export interface UseLiveFormReturn<T extends object> {
    isValid: Ref<boolean>;
    isDirty: Ref<boolean>;
    isTouched: Ref<boolean>;
    isValidating: Readonly<Ref<boolean>>;
    submitCount: Readonly<Ref<number>>;
    initialValues: Readonly<Ref<T>>;
    field<P extends PathsToStringProps<T>>(path: P): FormField<PathValue<T, P>>;
    fieldArray<P extends PathsToStringProps<T>>(path: P): PathValue<T, P> extends readonly (infer U)[] ? FormFieldArray<U> : never;
    submit: () => Promise<void>;
    reset: () => void;
}
export declare function useLiveForm<T extends object>(form: MaybeRefOrGetter<Form<T>>, options?: FormOptions): UseLiveFormReturn<T>;
/**
 * Hook to access form fields from an injected form instance
 * @param path - The field path (e.g., "name", "user.email", "items[0].title")
 * @throws Error if no form was provided via inject
 * @returns FormField instance for the specified path
 */
export declare function useField<T = any>(path: string): FormField<T>;
/**
 * Hook to access form array fields from an injected form instance
 * @param path - The field path for an array field (e.g., "items", "user.tags", "posts[0].comments")
 * @throws Error if no form was provided via inject
 * @returns FormFieldArray instance for the specified path
 */
export declare function useArrayField<T = any>(path: string): FormFieldArray<T>;
export {};
