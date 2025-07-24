import type { LiveSocketInstanceInterface, ViewHook } from "../../../deps/phoenix_live_view/assets/js/types"
import type { App, Component, createApp, createSSRApp, h, Plugin, Ref } from "vue"
export type { Hook } from "../../../deps/phoenix_live_view/assets/js/types"

export type ComponentOrComponentModule = Component | { default: Component }
export type ComponentOrComponentPromise = ComponentOrComponentModule | Promise<ComponentOrComponentModule>
export type ComponentMap = Record<string, ComponentOrComponentPromise>

export type VueComponent = ComponentOrComponentPromise

type VueComponentInternal = Parameters<typeof h>[0]
type VuePropsInternal = Parameters<typeof h>[1]
type VueSlotsInternal = Parameters<typeof h>[2]

export type VueArgs = {
  props: VuePropsInternal
  slots: VueSlotsInternal
  app: App<Element>
}

// all the functions and additional properties that are available on the LiveHook
export type LiveHook = ViewHook & { vue: VueArgs; liveSocket: LiveSocketInstanceInterface }

// Phoenix LiveView Upload types for client-side use
export interface UploadEntryClient {
  ref: string
  client_name: string
  client_size: number
  client_type: string
  progress: number
  done: boolean
  valid: boolean
  preflighted: boolean
}

export interface UploadConfigClient {
  ref: string
  name: string
  accept: string | false
  max_entries: number
  auto_upload: boolean
  entries: UploadEntryClient[]
  errors: Array<[string, string]>
}

export interface UseLiveUploadReturn {
  /** Reactive list of current entries coming from the server patch */
  entries: Ref<UploadEntryClient[]>
  /** Opens the native file-picker dialog */
  showFilePicker: () => void
  /** Manually enqueue external files (e.g. drag-drop) */
  addFiles: (files: (File | Blob)[]) => void
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

export type LiveVueOptions = {
  resolve: (path: string) => ComponentOrComponentPromise | undefined | null
  setup?: (context: SetupContext) => App
}

export type LiveVueApp = {
  setup: (context: SetupContext) => App
  resolve: (path: string) => ComponentOrComponentPromise
}

export interface LiveVue {
  VueHook: ViewHook
}
