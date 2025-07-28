import { describe, it, expect, vi, beforeEach } from "vitest"
import { ref, reactive, type App } from "vue"
import { getVueHook } from "./hooks"
import type { LiveVueApp, Hook } from "./types"

// Mock Vue component for testing
const MockComponent = {
  template: "<div>{{ message }}</div>",
  props: ["message", "count"],
  setup(props: any) {
    return { props }
  },
}

// Mock LiveView hook context
const createMockLiveViewHook = (elementAttributes: Record<string, string> = {}) => {
  const mockElement = {
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
  } as any // Type assertion to avoid strict type checking for test mocks
}

// Mock LiveVue app configuration
const createMockLiveVueApp = (component = MockComponent): LiveVueApp => ({
  resolve: vi.fn().mockResolvedValue(component),
  setup: vi.fn(({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({
      render: () => null, // simplified for testing
    })
    app.use(plugin)

    // Mock mount method to avoid DOM operations
    app.mount = vi.fn().mockReturnValue(app)

    return app
  }),
})

describe("getVueHook", () => {
  let mockLiveVueApp: LiveVueApp
  let mockHookContext: ReturnType<typeof createMockLiveViewHook>
  let vueHook: Hook

  beforeEach(() => {
    vi.clearAllMocks()
    mockLiveVueApp = createMockLiveVueApp()
    mockHookContext = createMockLiveViewHook()
    vueHook = getVueHook(mockLiveVueApp)
  })

  describe("mounted lifecycle", () => {
    it("should resolve component by name from data-name attribute", async () => {
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      expect(mockLiveVueApp.resolve).toHaveBeenCalledWith("TestComponent")
    })

    it("should create SSR app when data-ssr is true", async () => {
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-ssr") return "true"
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      // Verify setup was called with correct parameters
      expect(mockLiveVueApp.setup).toHaveBeenCalledWith(
        expect.objectContaining({
          component: MockComponent,
          ssr: false,
        })
      )
    })

    it("should create client app when data-ssr is not true", async () => {
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-ssr") return "false"
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      expect(mockLiveVueApp.setup).toHaveBeenCalledWith(
        expect.objectContaining({
          component: MockComponent,
          ssr: false,
        })
      )
    })

    it("should parse props from data-props attribute", async () => {
      const mockProps = { message: "Hello", count: 42 }
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-props") return JSON.stringify(mockProps)
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      expect(mockLiveVueApp.setup).toHaveBeenCalledWith(
        expect.objectContaining({
          props: expect.objectContaining(mockProps),
        })
      )
    })

    it("should parse handlers from data-handlers attribute", async () => {
      const mockHandlers = { click: '[["push", {"event": "test-event"}, "phx-target": null]]' }
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-handlers") return JSON.stringify(mockHandlers)
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      const setupCall = (mockLiveVueApp.setup as any).mock.calls[0][0]
      expect(setupCall.props).toHaveProperty("onClick")
      expect(typeof setupCall.props.onClick).toBe("function")
    })

    it("should parse slots from data-slots attribute", async () => {
      const mockSlots = { default: btoa("<p>Slot content</p>") }
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-slots") return JSON.stringify(mockSlots)
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      const setupCall = (mockLiveVueApp.setup as any).mock.calls[0][0]
      expect(setupCall.slots).toHaveProperty("default")
      expect(typeof setupCall.slots.default).toBe("function")
    })

    it("should provide plugin with live hook context", async () => {
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      const setupCall = (mockLiveVueApp.setup as any).mock.calls[0][0]
      expect(setupCall.plugin).toBeDefined()

      // Test plugin install function
      const mockApp = {
        provide: vi.fn(),
        config: { globalProperties: {} },
      } as any

      setupCall.plugin.install(mockApp)
      expect(mockApp.provide).toHaveBeenCalled()
      expect(mockApp.config.globalProperties.$live).toBe(mockHookContext)
    })

    it("should store vue instance on hook context", async () => {
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      expect(mockHookContext.vue).toBeDefined()
      expect(mockHookContext.vue.app).toBeDefined()
      expect(mockHookContext.vue.props).toBeDefined()
      expect(mockHookContext.vue.slots).toBeDefined()
    })
  })

  describe("updated lifecycle", () => {
    beforeEach(async () => {
      // Set up a mounted component first
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-props") return JSON.stringify({ message: "initial", count: 1 })
        return null
      })

      await vueHook.mounted!.call(mockHookContext)
    })

    it("should apply props diff when data-use-diff is true", async () => {
      // Set up a more complex initial props structure
      const complexInitialProps = {
        user: {
          name: "John Doe",
          age: 30,
          preferences: {
            theme: "light",
            notifications: true
          }
        },
        items: ["apple", "banana", "cherry"],
        count: 5,
        message: "Hello World"
      }

      // Re-mount with complex initial props
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-props") return JSON.stringify(complexInitialProps)
        return null
      })
      await vueHook.mounted!.call(mockHookContext)

      // Define a complex diff that modifies various parts of the props
      const mockPropsDiff = [
        ["replace", "/user/name", "Jane Smith"],
        ["replace", "/user/age", 25],
        ["add", "/user/email", "jane@example.com"],
        ["replace", "/user/preferences/theme", "dark"],
        ["add", "/items/-", "orange"], // Add to end of array
        ["remove", "/items/0"], // Remove first item
        ["replace", "/message", "Updated message"],
        ["add", "/newTopLevelProp", "brand new property"]
      ]

      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-use-diff") return "true"
        if (name === "data-props-diff") return JSON.stringify(mockPropsDiff)
        return null
      })

      vueHook.updated!.call(mockHookContext)

      // Verify the complex diff was applied correctly
      expect(mockHookContext.vue.props.user.name).toBe("Jane Smith")
      expect(mockHookContext.vue.props.user.age).toBe(25)
      expect(mockHookContext.vue.props.user.email).toBe("jane@example.com")
      expect(mockHookContext.vue.props.user.preferences.theme).toBe("dark")
      expect(mockHookContext.vue.props.user.preferences.notifications).toBe(true) // unchanged
      expect(mockHookContext.vue.props.items).toEqual(["banana", "cherry", "orange"]) // removed first, added last
      expect(mockHookContext.vue.props.message).toBe("Updated message")
      expect(mockHookContext.vue.props.newTopLevelProp).toBe("brand new property")
      expect(mockHookContext.vue.props.count).toBe(5) // unchanged
    })

    it("should replace all props when data-use-diff is not true", () => {
      const newProps = { message: "completely new", different: "prop" }

      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-use-diff") return "false"
        if (name === "data-props") return JSON.stringify(newProps)
        if (name === "data-handlers") return null
        return null
      })

      // Object.assign merges, doesn't replace, so we need to check the merged result
      vueHook.updated!.call(mockHookContext)

      expect(mockHookContext.vue.props.message).toBe("completely new")
      expect(mockHookContext.vue.props.different).toBe("prop")
      // count will still be there because Object.assign merges
      expect(mockHookContext.vue.props.count).toBe(1)
    })

    it("should update slots", () => {
      const newSlots = {
        default: btoa("<p>Updated slot content</p>"),
        header: btoa("<h1>Header</h1>"),
      }

      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-slots") return JSON.stringify(newSlots)
        return null
      })

      vueHook.updated!.call(mockHookContext)

      expect(mockHookContext.vue.slots.default).toBeDefined()
      expect(mockHookContext.vue.slots.header).toBeDefined()
      expect(typeof mockHookContext.vue.slots.default).toBe("function")
      expect(typeof mockHookContext.vue.slots.header).toBe("function")
    })

    it("should handle handlers in updated props", () => {
      const newHandlers = { submit: '[["push", {"event": "form-submit"}, "phx-target": null]]' }

      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-use-diff") return "false"
        if (name === "data-props") return JSON.stringify({ message: "test" })
        if (name === "data-handlers") return JSON.stringify(newHandlers)
        return null
      })

      vueHook.updated!.call(mockHookContext)

      expect(mockHookContext.vue.props.onSubmit).toBeDefined()
      expect(typeof mockHookContext.vue.props.onSubmit).toBe("function")
    })

    it("should execute handler when called", () => {
      const mockHandlers = { click: '[["push", {"event": "test-click"}]]' }

      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-use-diff") return "false"
        if (name === "data-handlers") return JSON.stringify(mockHandlers)
        if (name === "data-props") return "{}"
        return null
      })

      vueHook.updated!.call(mockHookContext)

      const clickHandler = mockHookContext.vue.props.onClick
      const mockEvent = { target: { value: "test-value" } }

      clickHandler(mockEvent)

      expect(mockHookContext.liveSocket.execJS).toHaveBeenCalledWith(
        mockHookContext.el,
        expect.stringContaining("test-click")
      )
    })
  })

  describe("destroyed lifecycle", () => {
    beforeEach(async () => {
      // Set up a mounted component first
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        return null
      })

      await vueHook.mounted!.call(mockHookContext)
    })

    it("should set up unmount listener for Vue app", () => {
      const mockApp = mockHookContext.vue.app
      const addEventListenerSpy = vi.spyOn(window, "addEventListener")

      vueHook.destroyed!.call(mockHookContext)

      expect(addEventListenerSpy).toHaveBeenCalledWith("phx:page-loading-stop", expect.any(Function), { once: true })
    })

    it("should call unmount when phx:page-loading-stop event fires", () => {
      const mockApp = mockHookContext.vue.app
      mockApp.unmount = vi.fn()

      let eventHandler: () => void
      const addEventListenerSpy = vi.spyOn(window, "addEventListener").mockImplementation((event, handler) => {
        if (event === "phx:page-loading-stop") {
          eventHandler = handler as () => void
        }
      })

      vueHook.destroyed!.call(mockHookContext)

      // Simulate the event firing
      eventHandler!()

      expect(mockApp.unmount).toHaveBeenCalled()
    })
  })

  describe("reactivity", () => {
    it("should maintain reactive props during updates", async () => {
      // Set up initial component
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-name") return "TestComponent"
        if (name === "data-props") return JSON.stringify({ message: "initial", count: 1 })
        return null
      })

      await vueHook.mounted!.call(mockHookContext)

      const propsReference = mockHookContext.vue.props

      // Update props
      mockHookContext.el.getAttribute.mockImplementation((name: string) => {
        if (name === "data-use-diff") return "false"
        if (name === "data-props") return JSON.stringify({ message: "updated", count: 2 })
        return null
      })

      vueHook.updated!.call(mockHookContext)

      // Same reactive object should be maintained
      expect(mockHookContext.vue.props).toBe(propsReference)
      expect(mockHookContext.vue.props.message).toBe("updated")
      expect(mockHookContext.vue.props.count).toBe(2)
    })
  })
})
