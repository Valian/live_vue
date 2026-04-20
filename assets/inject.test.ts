import { describe, it, expect, vi, beforeEach } from "vitest"
import { getVueHook } from "./hooks"
import type { LiveVueApp, Hook } from "./types"
import { createMockLiveViewHook, createMockLiveVueApp } from "./tests/helpers"

describe("v-inject integration", () => {
  let mockLiveVueApp: LiveVueApp
  let vueHook: Hook

  beforeEach(() => {
    vi.clearAllMocks()
    mockLiveVueApp = createMockLiveVueApp()
    vueHook = getVueHook(mockLiveVueApp)
  })

  it("should register injected content when the target mounts first", async () => {
    const targetContext = createMockLiveViewHook({
      id: "layout-root",
      "data-name": "LayoutComponent",
      "data-ssr": "true",
    })

    const injectorContext = createMockLiveViewHook({
      id: "page-component",
      "data-name": "PageComponent",
      "data-inject": "layout-root",
    })

    await vueHook.mounted!.call(targetContext)
    await vueHook.mounted!.call(injectorContext)

    expect(targetContext.vue.slots.default).toBeDefined()
    expect(mockLiveVueApp.setup).toHaveBeenCalledTimes(1)

    vueHook.destroyed!.call(injectorContext)
    vueHook.destroyed!.call(targetContext)
  })

  it("should apply pending injections when the target mounts after", async () => {
    const injectorContext = createMockLiveViewHook({
      id: "page-component-late",
      "data-name": "PageComponent",
      "data-inject": "layout-root-late",
    })

    const targetContext = createMockLiveViewHook({
      id: "layout-root-late",
      "data-name": "LayoutComponent",
    })

    await vueHook.mounted!.call(injectorContext)

    expect(mockLiveVueApp.setup).not.toHaveBeenCalled()

    await vueHook.mounted!.call(targetContext)

    expect(targetContext.vue.slots.default).toBeDefined()
    expect(mockLiveVueApp.setup).toHaveBeenCalledTimes(1)

    vueHook.destroyed!.call(injectorContext)
    vueHook.destroyed!.call(targetContext)
  })

  it("should remove injected slots when an injector is destroyed", async () => {
    const targetContext = createMockLiveViewHook({
      id: "layout-root-cleanup",
      "data-name": "LayoutComponent",
    })

    const injectorContext = createMockLiveViewHook({
      id: "page-component-cleanup",
      "data-name": "PageComponent",
      "data-inject": "layout-root-cleanup",
    })

    await vueHook.mounted!.call(targetContext)
    await vueHook.mounted!.call(injectorContext)

    expect(targetContext.vue.slots.default).toBeDefined()

    vueHook.destroyed!.call(injectorContext)

    expect(targetContext.vue.slots.default).toBeUndefined()

    vueHook.destroyed!.call(targetContext)
  })
})
