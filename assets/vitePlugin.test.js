// @vitest-environment node

import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import path from "node:path"
import { describe, expect, it } from "vitest"
import liveVuePlugin from "./vitePlugin"

const loadSsrManifestModule = (root, opts = {}) => {
  const plugin = liveVuePlugin(opts)
  plugin.configResolved?.({ root })
  const id = plugin.resolveId?.("live_vue/ssrManifest")
  return plugin.load?.(id)
}

describe("liveVuePlugin ssr manifest module", () => {
  it("embeds the SSR manifest as a virtual module", () => {
    const projectRoot = mkdtempSync(path.join(tmpdir(), "live-vue-"))
    const root = path.join(projectRoot, "assets")
    mkdirSync(root)
    try {
      const manifestPath = path.join(root, "../priv/static/.vite/ssr-manifest.json")
      mkdirSync(path.dirname(manifestPath), { recursive: true })
      writeFileSync(manifestPath, JSON.stringify({ "App.vue": ["/assets/app.js"] }))

      expect(loadSsrManifestModule(root)).toBe(`export default {"App.vue":["/assets/app.js"]}`)
    } finally {
      rmSync(projectRoot, { recursive: true, force: true })
    }
  })

  it("returns an empty manifest when the file is missing", () => {
    const projectRoot = mkdtempSync(path.join(tmpdir(), "live-vue-"))
    const root = path.join(projectRoot, "assets")
    mkdirSync(root)
    try {
      expect(loadSsrManifestModule(root)).toBe("export default {}")
    } finally {
      rmSync(projectRoot, { recursive: true, force: true })
    }
  })
})
