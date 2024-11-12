import fs from "fs"
import { basename, resolve } from "path"
import { App, Component, createSSRApp, h } from "vue"
import { renderToString, type SSRContext } from "vue/server-renderer"
import { LiveVueApp, LiveHook } from "./types.js"
import { migrateToLiveVueApp } from "./app.js"
import { mapValues } from "./utils.js"

type Components = Record<string, Component>
type Manifest = Record<string, string[]>

const mockLive: LiveHook = {
  el: {} as any,
  liveSocket: {} as any,
  pushEvent: () => 0,
  pushEventTo: () => 0,
  handleEvent: () => () => {},
  removeHandleEvent: () => {},
  upload: () => {},
  uploadTo: () => {},
  vue: {
    props: {},
    slots: {},
    app: {} as App<any>,
  },
}
export const getRender = (componentsOrApp: Components | LiveVueApp, manifest: Manifest = {}) => {
  const { resolve, setup } = migrateToLiveVueApp(componentsOrApp)

  return async (name: string, props: Record<string, any>, slots: Record<string, string>) => {
    const component = await resolve(name)
    const slotComponents = mapValues(slots, base64 => () => h("div", { innerHTML: atob(base64).trim() }))
    const app = setup({
      createApp: createSSRApp,
      component,
      props,
      slots: slotComponents,
      plugin: {
        install: (app: App) => {
          // we don't want to mount the app in SSR
          app.mount = (...args: any[]): any => undefined
          // we don't have hook instance in SSR, so we need to mock it
          app.provide("_live_vue", Object.assign({}, mockLive))
        },
      },
      el: {} as any,
      ssr: true,
    })

    if (!app) throw new Error("Setup function did not return a Vue app!")

    const ctx: SSRContext = {}
    const html = await renderToString(app, ctx)

    // the SSR manifest generated by Vite contains module -> chunk/asset mapping
    // which we can then use to determine what files need to be preloaded for this
    // request.
    const preloadLinks = renderPreloadLinks(ctx.modules, manifest)
    // easy to split structure
    return preloadLinks + "<!-- preload -->" + html
  }
}
/**
 * Loads the manifest file from the given path and returns a record of the assets.
 * Manifest file is a JSON file generated by Vite for the client build.
 * We need to load it to know which files to preload for the given page.
 * @param path - The path to the manifest file.
 * @returns A record of the assets.
 */
export const loadManifest = (path: string): Record<string, string[]> => {
  try {
    // it's generated only in prod build
    const content = fs.readFileSync(resolve(path), "utf-8")
    return JSON.parse(content)
  } catch (e) {
    // manifest is not available in dev, so let's just ignore it
    return {}
  }
}

function renderPreloadLinks(modules: SSRContext["modules"], manifest: Manifest) {
  let links = ""
  const seen = new Set()
  modules.forEach((id: string) => {
    const files = manifest[id]
    if (files) {
      files.forEach(file => {
        if (!seen.has(file)) {
          seen.add(file)
          const filename = basename(file)
          if (manifest[filename]) {
            for (const depFile of manifest[filename]) {
              links += renderPreloadLink(depFile)
              seen.add(depFile)
            }
          }
          links += renderPreloadLink(file)
        }
      })
    }
  })
  return links
}

function renderPreloadLink(file: string) {
  if (file.endsWith(".js")) {
    return `<link rel="modulepreload" crossorigin href="${file}">`
  } else if (file.endsWith(".css")) {
    return `<link rel="stylesheet" href="${file}">`
  } else if (file.endsWith(".woff")) {
    return ` <link rel="preload" href="${file}" as="font" type="font/woff" crossorigin>`
  } else if (file.endsWith(".woff2")) {
    return ` <link rel="preload" href="${file}" as="font" type="font/woff2" crossorigin>`
  } else if (file.endsWith(".gif")) {
    return ` <link rel="preload" href="${file}" as="image" type="image/gif">`
  } else if (file.endsWith(".jpg") || file.endsWith(".jpeg")) {
    return ` <link rel="preload" href="${file}" as="image" type="image/jpeg">`
  } else if (file.endsWith(".png")) {
    return ` <link rel="preload" href="${file}" as="image" type="image/png">`
  } else {
    // TODO
    return ""
  }
}
