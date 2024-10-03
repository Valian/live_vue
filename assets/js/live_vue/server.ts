import { createSSRApp, h } from 'vue'
import { renderToString } from 'vue/server-renderer'
import { normalizeComponents, getComponent } from './components'
import fs from 'fs'

type Components = Record<string, any>

export const getRender = (components: Components) => {
  components = normalizeComponents(components)

  return async (name: string, props: Record<string, any>, slots: Record<string, string>) => {
    const component = await getComponent(components, name)

    const app = createSSRApp({
      render: () => h(component, props,
        Object.fromEntries(
          Object.entries(slots).map(([name, html]) => [name, () => h('div', { innerHTML: html })])
        )
      )
    })

    return renderToString(app)
  }
}

export const loadManifest = (path: string): Record<string, string[]> => {
  const manifest = JSON.parse(fs.readFileSync(path, 'utf8'))
  return Object.fromEntries(
    Object.entries(manifest).map(([key, value]) => [
      key,
      Array.isArray(value) ? value : [value as string]
    ])
  )
}