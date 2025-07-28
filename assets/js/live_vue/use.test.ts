import { describe, it, expect, vi, beforeEach, afterEach } from "vitest"
import type { LiveHook } from "./types"

// Mock Vue injection system
vi.mock("vue", () => ({
  inject: vi.fn(),
  onMounted: vi.fn((fn: () => void) => fn()), // Execute immediately for testing
  onUnmounted: vi.fn((fn: () => void) => fn()), // Execute immediately for testing
}))

// Import after mocking
import { useLiveVue, useLiveEvent, useLiveNavigation, liveInjectKey } from "./use"
import { inject } from "vue"

const mockInject = inject as any

// Mock LiveHook for testing
const createMockLiveHook = (): LiveHook => ({
  handleEvent: vi.fn().mockReturnValue("callback-id"),
  removeHandleEvent: vi.fn(),
  liveSocket: {
    pushHistoryPatch: vi.fn(),
    historyRedirect: vi.fn(),
    execJS: vi.fn(),
  } as any,
  pushEvent: vi.fn(),
  pushEventTo: vi.fn(),
  el: document.createElement("div"),
} as unknown as LiveHook)

describe("useLiveVue", () => {
  let mockLive: LiveHook

  beforeEach(() => {
    vi.clearAllMocks()
    mockLive = createMockLiveHook()
  })

  it("should return LiveHook when properly provided", () => {
    mockInject.mockReturnValue(mockLive)

    const result = useLiveVue()

    expect(mockInject).toHaveBeenCalledWith(liveInjectKey)
    expect(result).toBe(mockLive)
  })

  it("should throw error when LiveVue is not provided", () => {
    mockInject.mockReturnValue(undefined)

    expect(() => useLiveVue()).toThrow("LiveVue not provided. Are you using this inside a LiveVue component?")
  })

  it("should throw error when LiveVue is null", () => {
    mockInject.mockReturnValue(null)

    expect(() => useLiveVue()).toThrow("LiveVue not provided. Are you using this inside a LiveVue component?")
  })
})

describe("useLiveEvent", () => {
  let mockLive: LiveHook
  beforeEach(() => {
    vi.clearAllMocks()
    mockLive = createMockLiveHook()
    mockInject.mockReturnValue(mockLive)
  })

  it("should register event handler on mount", () => {
    const eventName = "test-event"
    const callback = vi.fn()

    useLiveEvent(eventName, callback)

    expect(mockLive.handleEvent).toHaveBeenCalledWith(eventName, callback)
  })

  it("should remove event handler on unmount", () => {
    const eventName = "test-event"
    const callback = vi.fn()
    const callbackId = "test-callback-id"
    
    mockLive.handleEvent = vi.fn().mockReturnValue(callbackId)
    mockInject.mockReturnValue(mockLive)

    useLiveEvent(eventName, callback)

    expect(mockLive.removeHandleEvent).toHaveBeenCalledWith(callbackId)
  })

  it("should handle multiple event registrations", () => {
    const callback1 = vi.fn()
    const callback2 = vi.fn()

    useLiveEvent("event1", callback1)
    useLiveEvent("event2", callback2)

    expect(mockLive.handleEvent).toHaveBeenCalledTimes(2)
    expect(mockLive.handleEvent).toHaveBeenCalledWith("event1", callback1)
    expect(mockLive.handleEvent).toHaveBeenCalledWith("event2", callback2)
    expect(mockLive.removeHandleEvent).toHaveBeenCalledTimes(2)
  })

  it("should handle callback with typed data", () => {
    interface TestEventData {
      message: string
      count: number
    }

    const callback = vi.fn<(data: TestEventData) => void>()
    
    useLiveEvent<TestEventData>("typed-event", callback)

    expect(mockLive.handleEvent).toHaveBeenCalledWith("typed-event", expect.any(Function))
  })

  it("should not remove handler if callback was null", () => {
    mockLive.handleEvent = vi.fn().mockReturnValue(null)
    mockInject.mockReturnValue(mockLive)

    useLiveEvent("test-event", vi.fn())

    expect(mockLive.removeHandleEvent).not.toHaveBeenCalled()
  })
})

describe("useLiveNavigation", () => {
  let mockLive: LiveHook
  let mockLiveSocket: any
  let originalLocation: Location

  beforeEach(() => {
    vi.clearAllMocks()
    
    // Mock window.location
    originalLocation = window.location
    delete (window as any).location
    ;(window as any).location = {
      pathname: "/current-path",
      search: "",
      href: "http://localhost/current-path"
    }

    mockLiveSocket = {
      pushHistoryPatch: vi.fn(),
      historyRedirect: vi.fn(),
    }
    
    mockLive = createMockLiveHook()
    mockLive.liveSocket = mockLiveSocket
    mockInject.mockReturnValue(mockLive)
  })

  afterEach(() => {
    ;(window as any).location = originalLocation
  })

  it("should throw error when LiveSocket is not initialized", () => {
    const mockLiveWithoutSocket = { ...mockLive, liveSocket: null }
    mockInject.mockReturnValue(mockLiveWithoutSocket)

    expect(() => useLiveNavigation()).toThrow("LiveSocket not initialized")
  })

  it("should throw error when LiveSocket is undefined", () => {
    const mockLiveWithoutSocket = { ...mockLive, liveSocket: undefined }
    mockInject.mockReturnValue(mockLiveWithoutSocket)

    expect(() => useLiveNavigation()).toThrow("LiveSocket not initialized")
  })

  describe("patch function", () => {
    it("should patch with string href", () => {
      const { patch } = useLiveNavigation()
      const href = "/new-path"

      patch(href)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        "push",
        null
      )
    })

    it("should patch with string href and replace option", () => {
      const { patch } = useLiveNavigation()
      const href = "/new-path"

      patch(href, { replace: true })

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        "replace",
        null
      )
    })

    it("should patch with query params object", () => {
      const { patch } = useLiveNavigation()
      const queryParams = { page: "2", filter: "active" }

      patch(queryParams)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/current-path?page=2&filter=active",
        "push",
        null
      )
    })

    it("should patch with query params object and replace option", () => {
      const { patch } = useLiveNavigation()
      const queryParams = { search: "test", category: "books" }

      patch(queryParams, { replace: true })

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/current-path?search=test&category=books",
        "replace",
        null
      )
    })

    it("should handle empty query params object", () => {
      const { patch } = useLiveNavigation()
      const queryParams = {}

      patch(queryParams)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/current-path?",
        "push",
        null
      )
    })

    it("should handle query params with special characters", () => {
      const { patch } = useLiveNavigation()
      const queryParams = { search: "hello world", filter: "a&b" }

      patch(queryParams)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        "/current-path?search=hello+world&filter=a%26b",
        "push",
        null
      )
    })
  })

  describe("navigate function", () => {
    it("should navigate with href", () => {
      const { navigate } = useLiveNavigation()
      const href = "/new-page"

      navigate(href)

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        "push",
        null,
        null
      )
    })

    it("should navigate with href and replace option", () => {
      const { navigate } = useLiveNavigation()
      const href = "/new-page"

      navigate(href, { replace: true })

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        "replace",
        null,
        null
      )
    })

    it("should handle external URLs", () => {
      const { navigate } = useLiveNavigation()
      const href = "https://example.com/external"

      navigate(href)

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        "push",
        null,
        null
      )
    })

    it("should handle relative paths", () => {
      const { navigate } = useLiveNavigation()
      const href = "../parent-page"

      navigate(href)

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        "push",
        null,
        null
      )
    })
  })

  it("should return object with patch and navigate functions", () => {
    const navigation = useLiveNavigation()

    expect(navigation).toHaveProperty("patch")
    expect(navigation).toHaveProperty("navigate")
    expect(typeof navigation.patch).toBe("function")
    expect(typeof navigation.navigate).toBe("function")
  })
})

describe("integration tests", () => {
  let mockLive: LiveHook

  beforeEach(() => {
    vi.clearAllMocks()
    mockLive = createMockLiveHook()
    mockInject.mockReturnValue(mockLive)
  })

  it("should work together - useLiveVue and useLiveEvent", () => {
    const callback = vi.fn()
    
    // First get the live instance
    const live = useLiveVue()
    expect(live).toBe(mockLive)
    
    // Then use it for event handling
    useLiveEvent("test-event", callback)
    
    expect(mockLive.handleEvent).toHaveBeenCalledWith("test-event", callback)
  })

  it("should work together - useLiveVue and useLiveNavigation", () => {
    // First get the live instance
    const live = useLiveVue()
    expect(live).toBe(mockLive)
    
    // Then use it for navigation
    const { patch, navigate } = useLiveNavigation()
    
    patch("/test-path")
    navigate("/another-path")
    
    expect(mockLive.liveSocket.pushHistoryPatch).toHaveBeenCalledWith(
      expect.any(Event),
      "/test-path",
      "push",
      null
    )
    expect(mockLive.liveSocket.historyRedirect).toHaveBeenCalledWith(
      expect.any(Event),
      "/another-path",
      "push",
      null,
      null
    )
  })
})