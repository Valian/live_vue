import { vi } from "vitest"
import type { LiveVueApp } from "../types.js"

const defaultComponent = {
  template: "<div>{{ message }}</div>",
  props: ["message", "count"],
  setup(props: any) {
    return { props }
  },
}

let mockIdCounter = 0

export const createMockLiveViewHook = (elementAttributes: Record<string, string> = {}) => {
  const id = elementAttributes.id || `mock-${++mockIdCounter}`
  const mockElement = {
    id,
    getAttribute: vi.fn((name: string) => elementAttributes[name] || null),
    setAttribute: vi.fn(),
    removeAttribute: vi.fn(),
  } as any

  const mockLiveSocket = {
    execJS: vi.fn(),
  }

  return {
    el: mockElement,
    liveSocket: mockLiveSocket,
    vue: undefined as any,
  } as any
}

export const createMockLiveVueApp = (component: any = defaultComponent): LiveVueApp => ({
  resolve: vi.fn().mockResolvedValue(component),
  setup: vi.fn(({ createApp, component, plugin }) => {
    const app = createApp({
      render: () => null,
    })
    app.use(plugin)

    app.mount = vi.fn().mockReturnValue(app)

    return app
  }),
})

export const MockComponent = defaultComponent
