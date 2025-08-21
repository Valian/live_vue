import { ComputedRef, Ref } from "vue";
import { MaybeRefOrGetter } from "vue";
import type { LiveHook, UploadConfig, UploadEntry, UploadOptions } from "./types.js";
export declare const liveInjectKey = "_live_vue";
/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export declare const useLiveVue: () => LiveHook;
/**
 * Registers a callback to be called when an event is received from the server.
 * It automatically removes the callback when the component is unmounted.
 * @param event - The event name.
 * @param callback - The callback to call when the event is received.
 */
export declare function useLiveEvent<T>(event: string, callback: (data: T) => void): void;
/**
 * A composable for navigation.
 * It uses the LiveSocket instance to navigate to a new location.
 * Works in the same way as the `live_patch` and `live_redirect` functions in LiveView.
 * @returns An object with `patch` and `navigate` functions.
 */
export declare const useLiveNavigation: () => {
    patch: (hrefOrQueryParams: string | Record<string, string>, opts?: {
        replace?: boolean;
    }) => void;
    navigate: (href: string, opts?: {
        replace?: boolean;
    }) => void;
};
export interface UseLiveUploadReturn {
    /** Reactive list of current entries coming from the server patch */
    entries: Ref<UploadEntry[]>;
    /** Opens the native file-picker dialog */
    showFilePicker: () => void;
    /** Manually enqueue external files (e.g. drag-drop) */
    addFiles: (files: (File | Blob)[] | DataTransfer) => void;
    /** Submit *all* currently queued files to LiveView (no args) */
    submit: () => void;
    /** Cancel a single entry by ref or every entry when omitted */
    cancel: (ref?: string) => void;
    /** Clear local queue and reset hidden input (post-upload cleanup) */
    clear: () => void;
    /** Overall progress 0-100 derived from entries */
    progress: Ref<number>;
    /** The underlying hidden <input type=file> */
    inputEl: Ref<HTMLInputElement | null>;
    /** Whether the selected files are valid */
    valid: ComputedRef<boolean>;
}
/**
 * A composable for Phoenix LiveView file uploads.
 * Provides a Vue-friendly API for handling file uploads with LiveView.
 * @param uploadConfig - Reactive reference to the upload configuration from LiveView
 * @param options - The options for the upload. Mostly names of events to use for phx-change and phx-submit.
 * @returns An object with upload methods and reactive state
 */
export declare const useLiveUpload: (uploadConfig: MaybeRefOrGetter<UploadConfig>, options: UploadOptions) => UseLiveUploadReturn;
