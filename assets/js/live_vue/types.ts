// Try to import from phoenix_live_view first, fallback to our definitions if not available
import type {
  Hook as PhoenixHook,
  LiveSocketInstanceInterface as PhoenixLiveSocketInstanceInterface,
  ViewHook as PhoenixViewHook,
} from 'phoenix_live_view'

// Conditional imports with fallback types for phoenix_live_view < 1.1
import type { App, Component, createApp, createSSRApp, h, Plugin } from 'vue'

// If using phoenix_live_view < 1.1, use our fallback types
import type {
  Hook as FallbackHook,
  LiveSocketInstanceInterface as FallbackLiveSocketInstanceInterface,
  ViewHook as FallbackViewHook,
} from './phoenixFallbackTypes'

// Re-export with our preferred names, using phoenix_live_view types if available
export type LiveSocketInstanceInterface = PhoenixLiveSocketInstanceInterface extends undefined
  ? FallbackLiveSocketInstanceInterface
  : PhoenixLiveSocketInstanceInterface

export type ViewHook = PhoenixViewHook extends undefined ? FallbackViewHook : PhoenixViewHook
export type Hook = PhoenixHook extends undefined ? FallbackHook : PhoenixHook

export type ComponentOrComponentModule = Component | { default: Component }
export type ComponentOrComponentPromise = ComponentOrComponentModule | Promise<ComponentOrComponentModule>
export type ComponentMap = Record<string, ComponentOrComponentPromise>

export type VueComponent = ComponentOrComponentPromise

type VueComponentInternal = Parameters<typeof h>[0]
type VuePropsInternal = Parameters<typeof h>[1]
type VueSlotsInternal = Parameters<typeof h>[2]

export interface VueArgs {
  props: VuePropsInternal
  slots: VueSlotsInternal
  app: App<Element>
}

// all the functions and additional properties that are available on the LiveHook
export type LiveHook = ViewHook & { vue: VueArgs, liveSocket: LiveSocketInstanceInterface }

// Phoenix LiveView Upload types for client-side use
export interface UploadEntry {
  ref: string
  client_name: string
  client_size: number
  client_type: string
  progress: number
  done: boolean
  valid: boolean
  preflighted: boolean
  errors: string[]
}

export interface UploadConfig {
  ref: string
  name: string
  accept: string | false
  max_entries: number
  auto_upload: boolean
  entries: UploadEntry[]
  errors: { ref: string, error: string }[]
}

export interface UploadOptions {
  changeEvent?: string
  submitEvent: string
}

// Phoenix LiveView AsyncResult type for client-side use
export interface AsyncResult<T = unknown> {
  ok: boolean
  loading: string[] | null
  failed: any | null
  result: T | null
}

export interface SetupContext {
  createApp: typeof createSSRApp | typeof createApp
  component: VueComponentInternal
  props: Record<string, unknown>
  slots: Record<string, () => unknown>
  plugin: Plugin<[]>
  el: Element
  ssr: boolean
}

export interface LiveVueOptions {
  resolve: (path: string) => ComponentOrComponentPromise | undefined | null
  setup?: (context: SetupContext) => App
}

export interface LiveVueApp {
  setup: (context: SetupContext) => App
  resolve: (path: string) => ComponentOrComponentPromise
}

export interface LiveVue {
  VueHook: ViewHook
}
