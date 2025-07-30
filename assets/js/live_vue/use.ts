import { inject, onMounted, onUnmounted, ref, computed, watchEffect, toValue, ComputedRef, Ref } from "vue"
import { MaybeRefOrGetter } from "vue"
import type { LiveHook, UploadConfig, UploadEntry, UploadOptions } from "./types.js"

export const liveInjectKey = "_live_vue"

/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export const useLiveVue = (): LiveHook => {
  const live = inject<LiveHook>(liveInjectKey)
  if (!live) throw new Error("LiveVue not provided. Are you using this inside a LiveVue component?")
  return live
}

/**
 * Registers a callback to be called when an event is received from the server.
 * It automatically removes the callback when the component is unmounted.
 * @param event - The event name.
 * @param callback - The callback to call when the event is received.
 */
export function useLiveEvent<T>(event: string, callback: (data: T) => void) {
  let callbackRef: ReturnType<LiveHook["handleEvent"]> | null = null
  onMounted(() => {
    const live = useLiveVue()
    callbackRef = live.handleEvent(event, callback)
  })
  onUnmounted(() => {
    const live = useLiveVue()
    if (callbackRef) live.removeHandleEvent(callbackRef)
    callbackRef = null
  })
}

/**
 * A composable for navigation.
 * It uses the LiveSocket instance to navigate to a new location.
 * Works in the same way as the `live_patch` and `live_redirect` functions in LiveView.
 * @returns An object with `patch` and `navigate` functions.
 */
export const useLiveNavigation = () => {
  const live = useLiveVue()
  const liveSocket = live.liveSocket
  if (!liveSocket) throw new Error("LiveSocket not initialized")

  /**
   * Patches the current LiveView.
   * @param hrefOrQueryParams - The URL or query params to navigate to.
   * @param opts - The options for the navigation.
   */
  const patch = (hrefOrQueryParams: string | Record<string, string>, opts: { replace?: boolean } = {}) => {
    let href = typeof hrefOrQueryParams === "string" ? hrefOrQueryParams : window.location.pathname
    if (typeof hrefOrQueryParams === "object") {
      const queryParams = new URLSearchParams(hrefOrQueryParams)
      href = `${href}?${queryParams.toString()}`
    }
    liveSocket.pushHistoryPatch(new Event("click"), href, opts.replace ? "replace" : "push", null)
  }

  /**
   * Navigates to a new location.
   * @param href - The URL to navigate to.
   * @param opts - The options for the navigation.
   */
  const navigate = (href: string, opts: { replace?: boolean } = {}) => {
    liveSocket.historyRedirect(new Event("click"), href, opts.replace ? "replace" : "push", null, null)
  }

  return {
    patch,
    navigate,
  }
}

export interface UseLiveUploadReturn {
  /** Reactive list of current entries coming from the server patch */
  entries: Ref<UploadEntry[]>
  /** Opens the native file-picker dialog */
  showFilePicker: () => void
  /** Manually enqueue external files (e.g. drag-drop) */
  addFiles: (files: (File | Blob)[] | DataTransfer) => void
  /** Submit *all* currently queued files to LiveView (no args) */
  submit: () => void
  /** Cancel a single entry by ref or every entry when omitted */
  cancel: (ref?: string) => void
  /** Clear local queue and reset hidden input (post-upload cleanup) */
  clear: () => void
  /** Overall progress 0-100 derived from entries */
  progress: Ref<number>
  /** The underlying hidden <input type=file> */
  inputEl: Ref<HTMLInputElement | null>
  /** Whether the selected files are valid */
  valid: ComputedRef<boolean>
}

/**
 * A composable for Phoenix LiveView file uploads.
 * Provides a Vue-friendly API for handling file uploads with LiveView.
 * @param uploadConfig - Reactive reference to the upload configuration from LiveView
 * @param options - The options for the upload. Mostly names of events to use for phx-change and phx-submit.
 * @returns An object with upload methods and reactive state
 */
export const useLiveUpload = (
  uploadConfig: MaybeRefOrGetter<UploadConfig>,
  options: UploadOptions
): UseLiveUploadReturn => {
  const live = useLiveVue()
  const inputEl = ref<HTMLInputElement | null>(null)

  // Create and manage the hidden file input element with Phoenix upload attributes
  onMounted(() => {
    if (!inputEl.value) {
      // Create a form to wrap the input, with phx-change="validate"
      const uploadConfigValue = toValue(uploadConfig)
      const form = document.createElement("form")
      if (options.changeEvent) form.setAttribute("phx-change", options.changeEvent)
      form.setAttribute("phx-submit", options.submitEvent)
      form.style.display = "none"

      const input = document.createElement("input")
      input.type = "file"
      input.id = uploadConfigValue.ref
      input.name = uploadConfigValue.name

      // Phoenix LiveView upload attributes - these are critical for Phoenix to find and manage the input
      input.setAttribute("data-phx-hook", "Phoenix.LiveFileUpload")
      input.setAttribute("data-phx-update", "ignore")
      input.setAttribute("data-phx-upload-ref", uploadConfigValue.ref)
      form.appendChild(input)

      // Set accept attribute if specified
      if (uploadConfigValue.accept && typeof uploadConfigValue.accept === "string") {
        input.accept = uploadConfigValue.accept
      }

      // Set auto_upload attribute if specified
      if (uploadConfigValue.auto_upload) {
        input.setAttribute("data-phx-auto-upload", "true")
      }

      // Set multiple attribute based on max_entries
      if (uploadConfigValue.max_entries > 1) {
        input.multiple = true
      }

      // Update entry refs attributes based on current entries
      const updateEntryRefs = () => {
        const config = toValue(uploadConfig)
        const joinEntries = (entries: UploadEntry[]) => entries.map(e => e.ref).join(",")

        input.setAttribute("data-phx-active-refs", joinEntries(config.entries))
        input.setAttribute("data-phx-done-refs", joinEntries(config.entries.filter(e => e.done)))
        input.setAttribute("data-phx-preflighted-refs", joinEntries(config.entries.filter(e => e.preflighted)))
      }

      const unwatchConfig = watchEffect(() => updateEntryRefs())

      // Store unwatch function for cleanup
      ;(input as any).__unwatchConfig = unwatchConfig

      // Append to the LiveView element so Phoenix can find it
      // Phoenix searches for upload inputs within the LiveView element
      live.el.appendChild(form)
      inputEl.value = input
    }
  })

  // Clean up the input element when component unmounts
  onUnmounted(() => {
    if (inputEl.value) {
      // Clean up the watcher
      ;(inputEl.value as any).__unwatchConfig?.()
      inputEl.value.form?.remove()
      inputEl.value.remove()
      inputEl.value = null
    }
  })

  // Reactive entries from the upload config
  const entries = computed(() => {
    const uploadConfigValue = toValue(uploadConfig)
    return uploadConfigValue.entries || []
  })

  // Calculate overall progress
  const progress = computed(() => {
    const allEntries = entries.value
    if (allEntries.length === 0) return 0

    const totalProgress = allEntries.reduce((sum: number, entry) => sum + (entry.progress || 0), 0)
    return Math.round(totalProgress / allEntries.length)
  })

  // Open the native file picker dialog
  const showFilePicker = () => {
    if (inputEl.value) {
      inputEl.value.click()
    }
  }

  // Manually add files (e.g., from drag-and-drop or DataTransfer)
  const addFiles = (input: (File | Blob)[] | DataTransfer) => {
    if (!inputEl.value) return

    if (input instanceof DataTransfer) {
      inputEl.value.files = input.files
    } else if (Array.isArray(input)) {
      const dataTransfer = new DataTransfer()
      input.forEach(f => dataTransfer.items.add(f as File))
      inputEl.value.files = dataTransfer.files
    }

    // Dispatch change event to trigger Phoenix LiveView upload handling
    // This mimics what happens when files are selected through the native file picker
    // Use setTimeout to ensure Phoenix has had a chance to initialize the upload system
    setTimeout(() => {
      if (inputEl.value) {
        inputEl.value.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }))
      }
    }, 0)
  }

  // Submit all queued files (for non-auto uploads)
  const submit = () => {
    // For auto-upload configs, this is essentially a no-op since Phoenix handles it automatically
    // For manual uploads, we could trigger a form submission or push an event
    // But Phoenix's upload system handles this automatically when files are selected
    if (inputEl.value) {
      // Phoenix will handle the upload automatically based on the auto_upload setting
      // We could push a manual upload event here if needed
      inputEl.value.form?.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }))
    }
  }

  // Cancel upload entries
  const cancel = (ref?: string) => {
    if (ref) {
      // Cancel specific entry
      live.pushEvent("cancel-upload", { ref })
    } else {
      // Cancel all entries
      entries.value.forEach(entry => {
        live.pushEvent("cancel-upload", { ref: entry.ref })
      })
    }
  }

  // Clear the input and reset state
  const clear = () => {
    if (inputEl.value) {
      inputEl.value.value = ""
    }
  }

  const valid = computed(() => {
    const uploadConfigValue = toValue(uploadConfig)
    return Object.keys(uploadConfigValue.errors).length === 0
  })

  return {
    entries,
    showFilePicker,
    addFiles,
    submit,
    cancel,
    clear,
    progress,
    inputEl,
    valid,
  }
}
