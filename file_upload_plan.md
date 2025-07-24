# LiveVue File Upload – Implementation Plan

## 1. Goals

1. Provide first-class, Vue-idiomatic support for Phoenix LiveView file uploads without any server-side changes.
2. Replicate the **client-side API** and behaviour of Phoenix’s `<.live_file_input>` and `<.live_img_preview>` – users familiar with HEEx should feel at home.
3. Integrate with the existing LiveVue composables pattern (`useLiveVue`, `useLiveEvent`, …).
4. Rely on Phoenix LiveView JS internals (`LiveHook.upload`, `LiveUploader`, `PHX_TRACK_UPLOADS` event, etc.) instead of re-implementing the low-level transport/protocol.

## 2. What We Can Re-Use From phoenix_live_view.esm.js

✅ LiveUploader & UploadEntry classes – handle chunking, progress, adapters.
✅ `LiveHook.upload(name, files)` which kicks off the upload sequence via `dispatchUploads`.
✅ Event constants ( `PHX_TRACK_UPLOADS`, `PHX_UPLOAD_REF`, `PHX_ACTIVE_ENTRY_REFS`, … ).
✅ Utility `LiveUploader.getEntryDataURL` for local previews.
✅ Server diff/patches already update assigns (`@uploads.<name>`) – Vue props will refresh automatically so we get progress/state “for free”.

## 3. What We Need To Provide Ourselves

1. **DOM file input element** – LiveView JS locates `input[type=file][data-phx-upload-ref]` to attach uploads. HEEx normally renders it, but inside Vue we must generate it ourselves (can be hidden).
2. **Composable `useLiveUpload`** – high-level API that:
   • Creates & manages the hidden input element
   • Exposes methods: `selectFiles()`, `addFiles(files)`, `upload(files?)`, `cancel(entryRef?)`, `clear()`
   • Returns reactive state (entries, progress %, errors, uploadedFiles, etc.) sourced from Vue props (the LiveView assign) and local mirrors.
3. **Vue components**
   • `LiveFileInput.vue` – presentation component (drop zone, button) that delegates logic to `useLiveUpload` but renders the real `<input>` for accessibility when desired.
   • `LiveImgPreview.vue` / `LiveFilePreview.vue` – thin wrappers that render `<img>` or generic preview using `LiveUploader.getEntryDataURL`.
4. **TypeScript helpers & types** mirroring `Phoenix.LiveView.UploadEntry` subset for strong typing.

## 4. API Sketch

```ts
// composable
const {
  entries,          // reactive UploadEntry[]
  selectFiles,      // open native dialog
  upload,           // manually start (if autoUpload = false)
  cancel,           // cancel one/all entries
  clear,            // reset input
  progress,         // computed overall %
  inputEl           // ref to the hidden <input>
} = useLiveUpload({
  name: "avatar",        // must match allow_upload name
  config: props.upload,   // UploadConfig passed from LiveView (contains ref, accept, …)
})
```

```vue
<template>
  <LiveFileInput
     :upload="uploadConfig"          // server assign
     label="Choose files"
     @files-selected="upload"        // or rely on auto-upload
  />

  <LiveImgPreview v-for="e in entries" :key="e.ref" :entry="e" />
</template>
```

Behaviour matches HEEx semantics:
• If `upload.auto_upload?`, files are pushed immediately after selection.
• Otherwise user calls `upload()` manually (button).
• Drag-and-drop just drops on our component – we internally forward files to hidden input and dispatch `PHX_TRACK_UPLOADS`.

## 4-bis. JSON Encoding / LiveVue.Encoder Strategy

Phoenix structs (`UploadConfig`, `UploadEntry`) cannot be sent over the wire as-is – the diff engine relies on the `LiveVue.Encoder` protocol to turn them into plain maps.  We must therefore:

1. **Select a minimal, safe subset of fields** that the browser actually needs.
2. **Derive** `LiveVue.Encoder` for both structs with `only:` metadata so the chosen subset is auto-encoded.

Example (in your Phoenix app – *not* in LiveVue lib):

```elixir
# in web.ex or a dedicated file
@derive {LiveVue.Encoder, only: ~w(ref name accept max_entries auto_upload? entries)a}
alias Phoenix.LiveView.UploadConfig

@derive {LiveVue.Encoder, only: ~w(ref client_name client_size client_type progress done?)a}
alias Phoenix.LiveView.UploadEntry
```

Alternatively, if you don’t want to touch the structs, wrap them into plain maps before assigning.

Resulting JSON/props on the client will look like:

```jsonc
{
  "ref": "123ABC",
  "name": "avatar",
  "accept": ".jpg,.png",
  "max_entries": 5,
  "auto_upload?": true,
  "entries": [
    {
      "ref": "1",
      "client_name": "pic.png",
      "client_size": 14231,
      "client_type": "image/png",
      "progress": 45,
      "done?": false
    }
  ]
}
```

Our composable will consume exactly these fields – no sensitive data is exposed.

## 5. Type Definitions (client-side)

Add to `assets/js/live_vue/types.ts`:

```ts
export interface UploadEntryClient {
  ref: string
  client_name: string
  client_size: number
  client_type: string
  progress: number
  done?: boolean
}

export interface UploadConfigClient {
  ref: string
  name: string
  accept: string | false
  max_entries: number
  auto_upload?: boolean
  entries: UploadEntryClient[]
}

export interface UseLiveUploadReturn {
  /** Reactive list of current entries coming from the server patch */
  entries: Ref<UploadEntryClient[]>;
  /** Opens the native file-picker dialog */
  showFilePicker: () => void;
  /** Manually enqueue external files (e.g. drag-drop) */
  addFiles: (files: (File | Blob)[]) => void;
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
}
```

The composable signature becomes:

```ts
// API expects a **reactive** ref to the UploadConfig coming from props
export function useLiveUpload(uploadConfig: Ref<UploadConfigClient>): UseLiveUploadReturn
```

### Props / Reactivity Note

Always keep the prop reactive by passing a `toRef`:

```ts
const props = defineProps<{ upload: UploadConfigClient }>()
const uploadRef = toRef(props, 'upload')
const { entries, submit } = useLiveUpload(uploadRef)
```

Internally `useLiveUpload` can derive `const name = uploadConfig.value.name` whenever needed, so a separate `name` argument is no longer necessary.

## 6. HEEx Usage Examples

Minimal LiveView template sending the upload config to Vue:

```heex
<script setup lang="ts">
import AvatarUploader from "~/components/AvatarUploader.vue"
</script>

<template>
  <.vue
    v-component="AvatarUploader"
    v-socket={@socket}
    upload={@uploads.avatar}    <!-- only prop required -->
  />
</template>
```

Inside the Vue component you’d use:

```ts
const { entries, upload, progress } = useLiveUpload({
  name: "avatar",
  config: defineProps<{ upload: UploadConfigClient }>().upload,
})
```

That’s **all** that’s needed from the server – no extra assigns or events.

## 7. Updated Work Breakdown

1. Derive or wrap structs for JSON encoding (server side).
2. Create `types.ts` additions (client).
3. Implement `useLiveUpload` composable.
4. Components (`LiveFileInput.vue`, `LiveImgPreview.vue`).
5. Example component + HEEx demo.
6. Docs.

(Old numbering shifted by +2.)

---

This plan focuses on maximum reuse of Phoenix’s proven upload pipeline while giving Vue developers a familiar, high-level API.

### Typical Workflows

1. **Auto-upload (most common)**
```ts
const { entries, progress } = useLiveUpload({ name: "avatar", config })
// autoUpload? – files picked are submitted automatically; submit() is a noop.
```

2. **Manual picker + submit**
```ts
const { showFilePicker, submit } = useLiveUpload({ name: "docs", config })
<button @click="showFilePicker()">Choose files</button>
<button @click="submit()">Upload now</button>
```

3. **Drag-and-drop queue**
```ts
const { addFiles, submit } = useLiveUpload({ name:"video", config })
function onDrop(e:DragEvent){
  addFiles(Array.from(e.dataTransfer!.files)) // enqueue only
  submit()                                   // start upload of queue
}
```

### Notes on `cancel` vs `clear`

• `cancel(ref?)` → aborts uploads **in-flight or queued**. When `ref` omitted every active entry is cancelled; the hidden input keeps its `value` so the same files could be re-submitted.

• `clear()` → removes *all* tracked files from the hidden input and local state. Use after a successful batch when you want to allow selecting the **same** file names again (browsers block re-selecting identical files until the input value changes).

In many apps only `cancel(ref)` is required, but `clear()` is handy for post-success reset scenarios.

## 8. Code Reference Appendix (for implementers)

Key browser-side hooks we rely on (paths fixed to repo):

```1:40:deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js
// constants including PHX_TRACK_UPLOADS, PHX_UPLOAD_REF, ...
```

```3330:3360:deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js
// ViewHook.prototype.upload – public API to trigger uploads from client
```

```5205:5230:deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js
// Global listener for "track-uploads" custom event; calls LiveUploader.trackFiles
```

```959:968:deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js
// LiveUploader.trackFiles implementation (adds files to hidden input tracking)
```

```921:928:deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js
// LiveUploader.getEntryDataURL – client preview helper used by <LiveImgPreview>
```

Server-side structs & helpers:

```1:70:deps/phoenix_live_view/lib/phoenix_live_view/upload_entry.ex
// %UploadEntry{} definition – fields you may want to encode
```

```1:120:deps/phoenix_live_view/lib/phoenix_live_view/upload_config.ex
// %UploadConfig{} definition – include subset via LiveVue.Encoder derive
```

Those lines should be enough for another LLM to source exact behaviour.

---
