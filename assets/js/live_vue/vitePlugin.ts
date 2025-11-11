/// <reference types="@types/node" />

import type { IncomingMessage, ServerResponse } from 'node:http'
import type { Connect, ModuleNode, Plugin } from 'vite'

interface PluginOptions {
  path?: string
  entrypoint?: string
}

interface ExtendedIncomingMessage extends Connect.IncomingMessage {
  body?: Record<string, unknown> // or more specific type if known
}

function hotUpdateType(path: string): 'css-update' | 'js-update' | null {
  if (path.endsWith('css'))
    return 'css-update'
  if (path.endsWith('js'))
    return 'js-update'
  return null
}

function jsonResponse(res: ServerResponse<IncomingMessage>, statusCode: number, data: unknown) {
  res.statusCode = statusCode
  res.setHeader('Content-Type', 'application/json')
  res.end(JSON.stringify(data))
}

// Custom JSON parsing middleware
function jsonMiddleware(req: ExtendedIncomingMessage, res: ServerResponse<IncomingMessage>, next: () => Promise<void>) {
  let data = ''

  // Listen for data event to collect the chunks of data
  req.on('data', (chunk) => {
    data += chunk
  })

  // Listen for end event to finish data collection
  req.on('end', () => {
    try {
      // Parse the collected data as JSON
      req.body = JSON.parse(data)
      next() // Proceed to the next middleware
    }
    catch (error) {
      // Handle JSON parse error
      jsonResponse(res, 400, { error: 'Invalid JSON' })
    }
  })

  // Handle error event
  req.on('error', (err: Error) => {
    console.error(err)
    jsonResponse(res, 500, { error: 'Internal Server Error' })
  })
}

function liveVuePlugin(opts: PluginOptions = {}): Plugin {
  return {
    name: 'live-vue',
    handleHotUpdate({ file, modules, server, timestamp }) {
      if (file.match(/\.(heex|ex)$/)) {
        // if it's and .ex or .heex file, invalidate all related files so they'll be updated correctly
        const invalidatedModules = new Set<ModuleNode>()
        for (const mod of modules) {
          server.moduleGraph.invalidateModule(mod, invalidatedModules, timestamp, true)
        }

        const updates = Array.from(invalidatedModules).flatMap((m) => {
          const { file } = m

          if (!file)
            return []

          const updateType = hotUpdateType(file)

          if (!updateType)
            return []

          return {
            type: updateType,
            path: m.url,
            acceptedPath: m.url,
            timestamp,
          }
        })

        // ask client to hot-reload updated modules
        server.ws.send({
          type: 'update',
          updates,
        })

        // we handle the hot update ourselves
        return []
      }
    },
    configureServer(server) {
      // Terminate the watcher when Phoenix quits
      // configureServer is only called in dev, so it's safe to use here
      process.stdin.on('close', () => process.exit(0))
      process.stdin.resume()

      // setup SSR endpoint /ssr_render
      const path = opts.path || '/ssr_render'
      const entrypoint = opts.entrypoint || './js/server.js'
      server.middlewares.use((req: ExtendedIncomingMessage, res, next) => {
        if (req.method == 'POST' && req.url?.split('?', 1)[0] === path) {
          jsonMiddleware(req, res, async () => {
            try {
              const render = (await server.ssrLoadModule(entrypoint)).render
              const html = await render(req.body?.name, req.body?.props, req.body?.slots)
              res.end(html)
            }
            catch (e) {
              e instanceof Error && server.ssrFixStacktrace(e)
              jsonResponse(res, 500, { error: e })
            }
          })
        }
        else {
          next()
        }
      })
    },
  }
}

export default liveVuePlugin
