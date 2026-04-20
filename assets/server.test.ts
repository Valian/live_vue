import { describe, it, expect } from "vitest"
import { renderPreloadLink, renderPreloadLinks } from "./server"

describe("renderPreloadLink", () => {
  it("returns modulepreload for .js files", () => {
    expect(renderPreloadLink("/assets/chunk-abc123.js")).toBe(
      `<link rel="modulepreload" crossorigin href="/assets/chunk-abc123.js">`
    )
  })

  it("returns modulepreload for .mjs files", () => {
    expect(renderPreloadLink("/assets/chunk-abc123.mjs")).toBe(
      `<link rel="modulepreload" crossorigin href="/assets/chunk-abc123.mjs">`
    )
  })

  it("returns stylesheet for .css files", () => {
    expect(renderPreloadLink("/assets/style.css")).toBe(
      `<link rel="stylesheet" href="/assets/style.css">`
    )
  })

  it("returns font preload for .woff files", () => {
    expect(renderPreloadLink("/assets/font.woff")).toBe(
      ` <link rel="preload" href="/assets/font.woff" as="font" type="font/woff" crossorigin>`
    )
  })

  it("returns font preload for .woff2 files", () => {
    expect(renderPreloadLink("/assets/font.woff2")).toBe(
      ` <link rel="preload" href="/assets/font.woff2" as="font" type="font/woff2" crossorigin>`
    )
  })

  it("returns image preload for .gif files", () => {
    expect(renderPreloadLink("/assets/image.gif")).toBe(
      ` <link rel="preload" href="/assets/image.gif" as="image" type="image/gif">`
    )
  })

  it("returns image preload for .jpg files", () => {
    expect(renderPreloadLink("/assets/image.jpg")).toBe(
      ` <link rel="preload" href="/assets/image.jpg" as="image" type="image/jpeg">`
    )
  })

  it("returns image preload for .jpeg files", () => {
    expect(renderPreloadLink("/assets/image.jpeg")).toBe(
      ` <link rel="preload" href="/assets/image.jpeg" as="image" type="image/jpeg">`
    )
  })

  it("returns image preload for .png files", () => {
    expect(renderPreloadLink("/assets/image.png")).toBe(
      ` <link rel="preload" href="/assets/image.png" as="image" type="image/png">`
    )
  })

  it("returns empty string for unknown extensions", () => {
    expect(renderPreloadLink("/assets/data.json")).toBe("")
    expect(renderPreloadLink("/assets/file.txt")).toBe("")
  })
})

describe("renderPreloadLinks", () => {
  it("returns empty string when no modules provided", () => {
    expect(renderPreloadLinks([], {})).toBe("")
  })

  it("returns empty string when modules have no manifest entries", () => {
    expect(renderPreloadLinks(["SomeModule.vue"], {})).toBe("")
  })

  it("generates links for manifest entries", () => {
    const manifest = {
      "Counter.vue": ["/assets/Counter.js", "/assets/Counter.css"],
    }
    const result = renderPreloadLinks(["Counter.vue"], manifest)
    expect(result).toContain(`<link rel="modulepreload" crossorigin href="/assets/Counter.js">`)
    expect(result).toContain(`<link rel="stylesheet" href="/assets/Counter.css">`)
  })

  it("generates links for .mjs chunks", () => {
    const manifest = {
      "App.vue": ["/assets/chunk-vendor.mjs", "/assets/App.js"],
    }
    const result = renderPreloadLinks(["App.vue"], manifest)
    expect(result).toContain(`<link rel="modulepreload" crossorigin href="/assets/chunk-vendor.mjs">`)
    expect(result).toContain(`<link rel="modulepreload" crossorigin href="/assets/App.js">`)
  })

  it("deduplicates files across modules", () => {
    const manifest = {
      "A.vue": ["/assets/shared.js"],
      "B.vue": ["/assets/shared.js", "/assets/B.css"],
    }
    const result = renderPreloadLinks(["A.vue", "B.vue"], manifest)
    const sharedCount = result.split("/assets/shared.js").length - 1
    expect(sharedCount).toBe(1)
    expect(result).toContain(`<link rel="stylesheet" href="/assets/B.css">`)
  })

  it("resolves transitive dependencies from manifest", () => {
    const manifest = {
      "App.vue": ["/assets/chunk-abc.mjs"],
      "chunk-abc.mjs": ["/assets/dep.js"],
    }
    const result = renderPreloadLinks(["App.vue"], manifest)
    expect(result).toContain(`href="/assets/dep.js"`)
    expect(result).toContain(`href="/assets/chunk-abc.mjs"`)
  })
})
