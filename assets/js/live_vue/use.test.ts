import type { LiveHook } from './types'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { inject } from 'vue'
// Import after mocking
import { liveInjectKey, useEventReply, useLiveEvent, useLiveNavigation, useLiveVue } from './use'

// Mock Vue injection system
vi.mock('vue', () => ({
  inject: vi.fn(),
  onMounted: vi.fn((fn: () => void) => fn()), // Execute immediately for testing
  onUnmounted: vi.fn((fn: () => void) => fn()), // Execute immediately for testing
  ref: vi.fn((initialValue: any) => ({ value: initialValue })),
}))

const mockInject = inject as any

// Mock LiveHook for testing
function createMockLiveHook(): LiveHook {
  return {
    handleEvent: vi.fn().mockReturnValue('callback-id'),
    removeHandleEvent: vi.fn(),
    liveSocket: {
      pushHistoryPatch: vi.fn(),
      historyRedirect: vi.fn(),
      execJS: vi.fn(),
    } as any,
    pushEvent: vi.fn(),
    pushEventTo: vi.fn(),
    el: document.createElement('div'),
  } as unknown as LiveHook
}

describe('useLiveVue', () => {
  let mockLive: LiveHook

  beforeEach(() => {
    vi.clearAllMocks()
    mockLive = createMockLiveHook()
  })

  it('should return LiveHook when properly provided', () => {
    mockInject.mockReturnValue(mockLive)

    const result = useLiveVue()

    expect(mockInject).toHaveBeenCalledWith(liveInjectKey)
    expect(result).toBe(mockLive)
  })

  it('should throw error when LiveVue is not provided', () => {
    mockInject.mockReturnValue(undefined)

    expect(() => useLiveVue()).toThrow('LiveVue not provided. Are you using this inside a LiveVue component?')
  })

  it('should throw error when LiveVue is null', () => {
    mockInject.mockReturnValue(null)

    expect(() => useLiveVue()).toThrow('LiveVue not provided. Are you using this inside a LiveVue component?')
  })
})

describe('useLiveEvent', () => {
  let mockLive: LiveHook
  beforeEach(() => {
    vi.clearAllMocks()
    mockLive = createMockLiveHook()
    mockInject.mockReturnValue(mockLive)
  })

  it('should register event handler on mount', () => {
    const eventName = 'test-event'
    const callback = vi.fn()

    useLiveEvent(eventName, callback)

    expect(mockLive.handleEvent).toHaveBeenCalledWith(eventName, callback)
  })

  it('should remove event handler on unmount', () => {
    const eventName = 'test-event'
    const callback = vi.fn()
    const callbackId = 'test-callback-id'

    mockLive.handleEvent = vi.fn().mockReturnValue(callbackId)
    mockInject.mockReturnValue(mockLive)

    useLiveEvent(eventName, callback)

    expect(mockLive.removeHandleEvent).toHaveBeenCalledWith(callbackId)
  })

  it('should handle multiple event registrations', () => {
    const callback1 = vi.fn()
    const callback2 = vi.fn()

    useLiveEvent('event1', callback1)
    useLiveEvent('event2', callback2)

    expect(mockLive.handleEvent).toHaveBeenCalledTimes(2)
    expect(mockLive.handleEvent).toHaveBeenCalledWith('event1', callback1)
    expect(mockLive.handleEvent).toHaveBeenCalledWith('event2', callback2)
    expect(mockLive.removeHandleEvent).toHaveBeenCalledTimes(2)
  })

  it('should handle callback with typed data', () => {
    interface TestEventData {
      message: string
      count: number
    }

    const callback = vi.fn<(data: TestEventData) => void>()

    useLiveEvent<TestEventData>('typed-event', callback)

    expect(mockLive.handleEvent).toHaveBeenCalledWith('typed-event', expect.any(Function))
  })

  it('should not remove handler if callback was null', () => {
    mockLive.handleEvent = vi.fn().mockReturnValue(null)
    mockInject.mockReturnValue(mockLive)

    useLiveEvent('test-event', vi.fn())

    expect(mockLive.removeHandleEvent).not.toHaveBeenCalled()
  })
})

describe('useLiveNavigation', () => {
  let mockLive: LiveHook
  let mockLiveSocket: any
  let originalLocation: Location

  beforeEach(() => {
    vi.clearAllMocks()

    // Mock window.location
    originalLocation = window.location
    delete (window as any).location
    ;(window as any).location = {
      pathname: '/current-path',
      search: '',
      href: 'http://localhost/current-path',
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

  it('should throw error when LiveSocket is not initialized', () => {
    const mockLiveWithoutSocket = { ...mockLive, liveSocket: null }
    mockInject.mockReturnValue(mockLiveWithoutSocket)

    expect(() => useLiveNavigation()).toThrow('LiveSocket not initialized')
  })

  it('should throw error when LiveSocket is undefined', () => {
    const mockLiveWithoutSocket = { ...mockLive, liveSocket: undefined }
    mockInject.mockReturnValue(mockLiveWithoutSocket)

    expect(() => useLiveNavigation()).toThrow('LiveSocket not initialized')
  })

  describe('patch function', () => {
    it('should patch with string href', () => {
      const { patch } = useLiveNavigation()
      const href = '/new-path'

      patch(href)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        'push',
        null,
      )
    })

    it('should patch with string href and replace option', () => {
      const { patch } = useLiveNavigation()
      const href = '/new-path'

      patch(href, { replace: true })

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        'replace',
        null,
      )
    })

    it('should patch with query params object', () => {
      const { patch } = useLiveNavigation()
      const queryParams = { page: '2', filter: 'active' }

      patch(queryParams)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        '/current-path?page=2&filter=active',
        'push',
        null,
      )
    })

    it('should patch with query params object and replace option', () => {
      const { patch } = useLiveNavigation()
      const queryParams = { search: 'test', category: 'books' }

      patch(queryParams, { replace: true })

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        '/current-path?search=test&category=books',
        'replace',
        null,
      )
    })

    it('should handle empty query params object', () => {
      const { patch } = useLiveNavigation()
      const queryParams = {}

      patch(queryParams)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        '/current-path?',
        'push',
        null,
      )
    })

    it('should handle query params with special characters', () => {
      const { patch } = useLiveNavigation()
      const queryParams = { search: 'hello world', filter: 'a&b' }

      patch(queryParams)

      expect(mockLiveSocket.pushHistoryPatch).toHaveBeenCalledWith(
        expect.any(Event),
        '/current-path?search=hello+world&filter=a%26b',
        'push',
        null,
      )
    })
  })

  describe('navigate function', () => {
    it('should navigate with href', () => {
      const { navigate } = useLiveNavigation()
      const href = '/new-page'

      navigate(href)

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        'push',
        null,
        null,
      )
    })

    it('should navigate with href and replace option', () => {
      const { navigate } = useLiveNavigation()
      const href = '/new-page'

      navigate(href, { replace: true })

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        'replace',
        null,
        null,
      )
    })

    it('should handle external URLs', () => {
      const { navigate } = useLiveNavigation()
      const href = 'https://example.com/external'

      navigate(href)

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        'push',
        null,
        null,
      )
    })

    it('should handle relative paths', () => {
      const { navigate } = useLiveNavigation()
      const href = '../parent-page'

      navigate(href)

      expect(mockLiveSocket.historyRedirect).toHaveBeenCalledWith(
        expect.any(Event),
        href,
        'push',
        null,
        null,
      )
    })
  })

  it('should return object with patch and navigate functions', () => {
    const navigation = useLiveNavigation()

    expect(navigation).toHaveProperty('patch')
    expect(navigation).toHaveProperty('navigate')
    expect(typeof navigation.patch).toBe('function')
    expect(typeof navigation.navigate).toBe('function')
  })
})

describe('integration tests', () => {
  let mockLive: LiveHook

  beforeEach(() => {
    vi.clearAllMocks()
    mockLive = createMockLiveHook()
    mockInject.mockReturnValue(mockLive)
  })

  it('should work together - useLiveVue and useLiveEvent', () => {
    const callback = vi.fn()

    // First get the live instance
    const live = useLiveVue()
    expect(live).toBe(mockLive)

    // Then use it for event handling
    useLiveEvent('test-event', callback)

    expect(mockLive.handleEvent).toHaveBeenCalledWith('test-event', callback)
  })

  it('should work together - useLiveVue and useLiveNavigation', () => {
    // First get the live instance
    const live = useLiveVue()
    expect(live).toBe(mockLive)

    // Then use it for navigation
    const { patch, navigate } = useLiveNavigation()

    patch('/test-path')
    navigate('/another-path')

    expect(mockLive.liveSocket.pushHistoryPatch).toHaveBeenCalledWith(
      expect.any(Event),
      '/test-path',
      'push',
      null,
    )
    expect(mockLive.liveSocket.historyRedirect).toHaveBeenCalledWith(
      expect.any(Event),
      '/another-path',
      'push',
      null,
      null,
    )
  })
})

describe('useEventReply', () => {
  let mockLive: LiveHook
  let mockPushEvent: any

  beforeEach(() => {
    vi.clearAllMocks()
    mockPushEvent = vi.fn()
    mockLive = {
      ...createMockLiveHook(),
      pushEvent: mockPushEvent,
    } as LiveHook
    mockInject.mockReturnValue(mockLive)
  })

  it('should initialize with default values', () => {
    const { data, isLoading } = useEventReply('test-event')

    expect(data.value).toBe(null)
    expect(isLoading.value).toBe(false)
  })

  it('should initialize with custom default value', () => {
    const defaultValue = { message: 'hello' }
    const { data } = useEventReply('test-event', { defaultValue })

    expect(data.value).toEqual(defaultValue)
  })

  it('should execute event successfully', async () => {
    const { data, isLoading, execute } = useEventReply<string>('test-event')
    const testParams = { id: 123 }
    const expectedReply = 'success'

    // Mock pushEvent to call the callback immediately
    mockPushEvent.mockImplementation((eventName: string, params: any, callback: (reply: any) => void) => {
      callback(expectedReply)
    })

    const result = await execute(testParams)

    expect(mockPushEvent).toHaveBeenCalledWith('test-event', testParams, expect.any(Function))
    expect(result).toBe(expectedReply)
    expect(data.value).toBe(expectedReply)
    expect(isLoading.value).toBe(false)
  })

  it('should execute event without parameters', async () => {
    const { execute } = useEventReply('test-event')
    const expectedReply = { status: 'ok' }

    mockPushEvent.mockImplementation((eventName: string, params: any, callback: (reply: any) => void) => {
      callback(expectedReply)
    })

    const result = await execute()

    expect(mockPushEvent).toHaveBeenCalledWith('test-event', undefined, expect.any(Function))
    expect(result).toEqual(expectedReply)
  })

  it('should reject concurrent executions', async () => {
    const { execute } = useEventReply('test-event')
    const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})

    // Mock pushEvent to never call callback (simulating slow response)
    mockPushEvent.mockImplementation(() => {})

    execute({ id: 1 })

    // Second execution should be rejected immediately
    await expect(execute({ id: 2 })).rejects.toThrow('Event "test-event" is already executing')

    expect(consoleSpy).toHaveBeenCalledWith(
      'Event "test-event" is already executing. Call cancel() first if you want to start a new execution.',
    )

    consoleSpy.mockRestore()
  })

  it('should cancel execution and ignore pending responses', async () => {
    const { data, isLoading, execute, cancel } = useEventReply<string>('test-event')
    let pendingCallback: ((reply: string) => void) | null = null

    // Mock pushEvent to store callback without calling it
    mockPushEvent.mockImplementation((_eventName: string, _params: any, callback: (reply: string) => void) => {
      pendingCallback = callback
    })

    const promise = execute({ id: 123 })
    // Cancel the execution
    cancel()
    expect(isLoading.value).toBe(false)

    // The promise should be rejected
    await expect(promise).rejects.toThrow('Event "test-event" was cancelled')

    // Now call the pending callback - it should be ignored
    if (pendingCallback) {
      (pendingCallback as (reply: string) => void)('delayed response')
    }

    expect(data.value).toBe(null) // Should remain unchanged
  })

  it('should reject pending promise when cancelled', async () => {
    const { execute, cancel } = useEventReply<string>('test-event')
    let pendingCallback: ((reply: string) => void) | null = null

    // Mock pushEvent to store callback without calling it
    mockPushEvent.mockImplementation((_eventName: string, _params: any, callback: (reply: string) => void) => {
      pendingCallback = callback
    })

    // Start execution and get the promise
    const promise = execute({ id: 123 })

    // Cancel the execution - this should reject the promise
    cancel()

    // The promise should be rejected with a cancellation error
    await expect(promise).rejects.toThrow('Event "test-event" was cancelled')

    // Calling the pending callback should not affect anything
    if (pendingCallback) {
      (pendingCallback as (reply: string) => void)('delayed response')
    }
  })

  it('should handle multiple cancel calls safely', () => {
    const { cancel, isLoading } = useEventReply('test-event')

    // Multiple cancels when there's no pending execution should be safe
    cancel()
    cancel()
    cancel()

    expect(isLoading.value).toBe(false)
  })

  it('should handle cancel after execution completes', async () => {
    const { execute, cancel } = useEventReply<string>('test-event')

    mockPushEvent.mockImplementation((_eventName: string, _params: any, callback: (reply: string) => void) => {
      callback('response')
    })

    // Execute and complete
    await execute()

    // Cancel after completion should be safe (no pending promise to reject)
    cancel()
    cancel() // Multiple calls should also be safe
  })

  it('should allow new execution after cancel', async () => {
    const { execute, cancel, data } = useEventReply<string>('test-event')
    let pendingCallback: ((reply: string) => void) | null = null

    // First execution
    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: string) => void) => {
      pendingCallback = callback
    })

    const firstPromise = execute({ id: 1 })
    cancel()

    // First promise should be rejected
    await expect(firstPromise).rejects.toThrow('Event "test-event" was cancelled')

    // Second execution should work
    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: string) => void) => {
      callback('second response')
    })

    await execute({ id: 2 })
    expect(data.value).toBe('second response')

    // Original callback should still be ignored
    if (pendingCallback) {
      (pendingCallback as (reply: string) => void)('first response')
    }
    expect(data.value).toBe('second response')
  })

  it('should work with typed parameters', async () => {
    interface UserParams {
      id: number
      name: string
    }

    interface UserResponse {
      user: {
        id: number
        name: string
        email: string
      }
    }

    const { execute } = useEventReply<UserResponse, UserParams>('get-user')
    const params: UserParams = { id: 123, name: 'John' }
    const expectedResponse: UserResponse = {
      user: { id: 123, name: 'John', email: 'john@example.com' },
    }

    mockPushEvent.mockImplementation((eventName: string, params: any, callback: (reply: any) => void) => {
      callback(expectedResponse)
    })

    const result = await execute(params)

    expect(mockPushEvent).toHaveBeenCalledWith('get-user', params, expect.any(Function))
    expect(result).toEqual(expectedResponse)
  })

  it('should return correct interface', () => {
    const result = useEventReply('test-event')

    expect(result).toHaveProperty('data')
    expect(result).toHaveProperty('isLoading')
    expect(result).toHaveProperty('execute')
    expect(result).toHaveProperty('cancel')
    expect(typeof result.execute).toBe('function')
    expect(typeof result.cancel).toBe('function')
  })

  it('should use updateData function when provided', async () => {
    const updateData = vi.fn((reply: string, currentData: string | null) => {
      return currentData ? `${currentData},${reply}` : reply
    })

    const { data, execute } = useEventReply<string>('test-event', { updateData })

    // First execution
    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: any) => void) => {
      callback('first')
    })

    await execute({ id: 1 })
    expect(updateData).toHaveBeenCalledWith('first', null)
    expect(data.value).toBe('first')

    // Second execution should accumulate
    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: any) => void) => {
      callback('second')
    })

    await execute({ id: 2 })
    expect(updateData).toHaveBeenCalledWith('second', 'first')
    expect(data.value).toBe('first,second')
  })

  it('should use updateData with default value', async () => {
    const updateData = vi.fn((reply: number, currentData: number | null) => {
      return (currentData || 0) + reply
    })

    const { data, execute } = useEventReply<number>('test-event', {
      defaultValue: 10,
      updateData,
    })

    expect(data.value).toBe(10)

    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: any) => void) => {
      callback(5)
    })

    await execute()
    expect(updateData).toHaveBeenCalledWith(5, 10)
    expect(data.value).toBe(15)
  })

  it('should use updateData for array accumulation', async () => {
    interface Item {
      id: number
      name: string
    }

    const updateData = vi.fn((reply: Item[], currentData: Item[] | null) => {
      return currentData ? [...currentData, ...reply] : reply
    })

    const { data, execute } = useEventReply<Item[]>('test-event', { updateData })

    // First item
    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: any) => void) => {
      callback([{ id: 1, name: 'first' }])
    })

    await execute()
    expect(data.value).toEqual([{ id: 1, name: 'first' }])

    // Second item
    mockPushEvent.mockImplementationOnce((_eventName: string, _params: any, callback: (reply: any) => void) => {
      callback([{ id: 2, name: 'second' }])
    })

    await execute()
    expect(data.value).toEqual([
      { id: 1, name: 'first' },
      { id: 2, name: 'second' },
    ])
  })

  it('should not call updateData when execution is cancelled', async () => {
    const updateData = vi.fn((reply: string, _currentData: string | null) => reply)

    const { execute, cancel } = useEventReply<string>('test-event', { updateData })
    let pendingCallback: ((reply: string) => void) | null = null

    mockPushEvent.mockImplementation((_eventName: string, _params: any, callback: (reply: string) => void) => {
      pendingCallback = callback
    })

    const promise = execute()
    cancel()

    // The promise should be rejected due to cancellation
    await expect(promise).rejects.toThrow('Event "test-event" was cancelled')

    // Call the pending callback - updateData should not be called
    if (pendingCallback) {
      (pendingCallback as (reply: string) => void)('delayed response')
    }

    expect(updateData).not.toHaveBeenCalled()
  })

  it('should work without updateData function (default behavior)', async () => {
    const { data, execute } = useEventReply<string>('test-event')

    mockPushEvent.mockImplementation((_eventName: string, _params: any, callback: (reply: any) => void) => {
      callback('response')
    })

    await execute()
    expect(data.value).toBe('response')
  })
})
