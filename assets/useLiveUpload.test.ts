import { describe, it, expect, beforeEach, vi } from "vitest"
import { ref, nextTick } from "vue"

// We need real Vue reactivity (ref, watch, watchEffect, computed, nextTick) but must
// mock inject (to provide a fake LiveHook), onMounted (to fire immediately), and
// onUnmounted (to capture the cleanup callback so we can invoke it manually).
const mockLiveRef = { value: null as any }
let unmountCallbacks: Array<() => void> = []

vi.mock("vue", async () => {
  const actual = await vi.importActual("vue")
  return {
    ...actual,
    inject: vi.fn(() => mockLiveRef.value),
    provide: vi.fn(),
    onMounted: vi.fn((fn: () => void) => fn()), // execute immediately
    onUnmounted: vi.fn((fn: () => void) => {
      unmountCallbacks.push(fn)
    }),
  }
})

import { useLiveUpload } from "./use"
import type { UploadConfig, UploadOptions } from "./types"

function createUploadConfig(overrides: Partial<UploadConfig> = {}): UploadConfig {
  return {
    ref: "phx-old",
    name: "avatar",
    accept: ".png,.jpg",
    max_entries: 1,
    auto_upload: false,
    entries: [],
    errors: [],
    ...overrides,
  }
}

const defaultOptions: UploadOptions = {
  changeEvent: "validate",
  submitEvent: "save",
}

describe("useLiveUpload", () => {
  let mockEl: HTMLElement

  beforeEach(() => {
    unmountCallbacks = []
    mockEl = document.createElement("div")
    document.body.appendChild(mockEl)

    mockLiveRef.value = {
      handleEvent: vi.fn().mockReturnValue("cb-id"),
      removeHandleEvent: vi.fn(),
      pushEvent: vi.fn(),
      pushEventTo: vi.fn(),
      el: mockEl,
      liveSocket: {
        pushHistoryPatch: vi.fn(),
        historyRedirect: vi.fn(),
        execJS: vi.fn(),
      },
    }
  })

  function triggerUnmount() {
    unmountCallbacks.forEach(fn => fn())
    unmountCallbacks = []
  }

  it("should create hidden input on mount with correct attributes", () => {
    const configRef = ref(createUploadConfig({ ref: "phx-abc" }))
    const result = useLiveUpload(configRef, defaultOptions)

    expect(result.inputEl.value).not.toBeNull()
    const input = result.inputEl.value as HTMLInputElement
    expect(input.getAttribute("data-phx-upload-ref")).toBe("phx-abc")
    expect(input.id).toBe("phx-abc")
    expect(input.name).toBe("avatar")
    expect(input.accept).toBe(".png,.jpg")
    expect(input.multiple).toBe(false)

    const form = input.form!
    expect(form.getAttribute("phx-change")).toBe("validate")
    expect(form.getAttribute("phx-submit")).toBe("save")
    expect(form.style.display).toBe("none")

    triggerUnmount()
  })

  it("should set multiple when max_entries > 1", () => {
    const configRef = ref(createUploadConfig({ max_entries: 5 }))
    const result = useLiveUpload(configRef, defaultOptions)

    expect(result.inputEl.value!.multiple).toBe(true)

    triggerUnmount()
  })

  it("should set data-phx-auto-upload when auto_upload is true", () => {
    const configRef = ref(createUploadConfig({ auto_upload: true }))
    const result = useLiveUpload(configRef, defaultOptions)

    expect(result.inputEl.value!.getAttribute("data-phx-auto-upload")).toBe("true")

    triggerUnmount()
  })

  it("should retain the hidden input when uploadConfig.ref changes", async () => {
    const configRef = ref(createUploadConfig({ ref: "phx-old" }))
    const result = useLiveUpload(configRef, defaultOptions)

    const originalInput = result.inputEl.value as HTMLInputElement
    let currentValue = "C:\\fakepath\\photo.png"
    Object.defineProperty(originalInput, "value", {
      configurable: true,
      get: () => currentValue,
      set: value => {
        currentValue = value
      },
    })

    expect(originalInput.getAttribute("data-phx-upload-ref")).toBe("phx-old")

    // Update the ref — simulates server sending a new upload config
    configRef.value = createUploadConfig({ ref: "phx-new" })
    await nextTick()

    const updatedInput = result.inputEl.value as HTMLInputElement
    expect(updatedInput).toBe(originalInput)
    expect(updatedInput.getAttribute("data-phx-upload-ref")).toBe("phx-new")
    expect(updatedInput.id).toBe("phx-new")
    expect(currentValue).toBe("")
    expect(mockEl.querySelectorAll("form")).toHaveLength(1)

    triggerUnmount()
  })

  it("should update accept in place when it changes", async () => {
    const configRef = ref(createUploadConfig({ ref: "phx-1", accept: ".png" }))
    const result = useLiveUpload(configRef, defaultOptions)
    const originalInput = result.inputEl.value

    expect(result.inputEl.value!.accept).toBe(".png")

    configRef.value = createUploadConfig({ ref: "phx-1", accept: ".gif,.webp" })
    await nextTick()

    expect(result.inputEl.value).toBe(originalInput)
    expect(result.inputEl.value!.accept).toBe(".gif,.webp")

    triggerUnmount()
  })

  it("should update multiple in place when max_entries changes", async () => {
    const configRef = ref(createUploadConfig({ ref: "phx-1", max_entries: 1 }))
    const result = useLiveUpload(configRef, defaultOptions)
    const originalInput = result.inputEl.value

    expect(result.inputEl.value!.multiple).toBe(false)

    configRef.value = createUploadConfig({ ref: "phx-1", max_entries: 3 })
    await nextTick()

    expect(result.inputEl.value).toBe(originalInput)
    expect(result.inputEl.value!.multiple).toBe(true)

    triggerUnmount()
  })

  it("should not rebuild when only entries change", async () => {
    const configRef = ref(createUploadConfig({ ref: "phx-1" }))
    const result = useLiveUpload(configRef, defaultOptions)

    const originalInput = result.inputEl.value

    configRef.value = {
      ...createUploadConfig({ ref: "phx-1" }),
      entries: [{ ref: "0", client_name: "photo.png", client_size: 1024, client_type: "image/png", progress: 0, done: false, preflighted: false, errors: [] }],
    }
    await nextTick()

    // Same input element should be reused (not rebuilt)
    expect(result.inputEl.value).toBe(originalInput)

    triggerUnmount()
  })

  it("should keep a single hidden form when config changes", async () => {
    const configRef = ref(createUploadConfig({ ref: "phx-old" }))
    const result = useLiveUpload(configRef, defaultOptions)
    const originalInput = result.inputEl.value

    expect(mockEl.querySelectorAll("form").length).toBe(1)

    configRef.value = createUploadConfig({ ref: "phx-new" })
    await nextTick()

    expect(result.inputEl.value).toBe(originalInput)
    expect(mockEl.querySelectorAll("form")).toHaveLength(1)
    expect(mockEl.querySelector('[data-phx-upload-ref="phx-new"]')).toBe(result.inputEl.value)

    triggerUnmount()
  })

  it("should clean up input on unmount", () => {
    const configRef = ref(createUploadConfig())
    const result = useLiveUpload(configRef, defaultOptions)

    expect(result.inputEl.value).not.toBeNull()
    expect(mockEl.querySelectorAll("form").length).toBe(1)

    triggerUnmount()

    expect(result.inputEl.value).toBeNull()
    expect(mockEl.querySelectorAll("form").length).toBe(0)
  })
})
