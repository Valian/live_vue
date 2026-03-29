/**
 * Vite plugin that replaces Node.js built-in imports with stubs.
 *
 * Use in vite.config when building SSR bundles for non-Node runtimes (e.g. QuickBEAM).
 * This makes the output self-contained with no `import` statements for `fs`, `path`, etc.
 *
 * @example
 * import stubNodeBuiltins from "live_vue/stubNodeBuiltins"
 *
 * // in vite.config
 * export default defineConfig({
 *   plugins: [vue(), liveVuePlugin(), stubNodeBuiltins()],
 * })
 *
 * @returns {import("vite").Plugin}
 */
export default function stubNodeBuiltins() {
  const stubs = {
    fs: "export default { readFileSync() { return '{}' } }",
    path: `
      export function resolve() { return Array.from(arguments).join('/') }
      export function basename(p) { return p.split('/').pop() }
      export default { resolve, basename }
    `,
    "node:stream": `
      function Readable() {}
      export { Readable }
      export default { Readable }
    `,
  }

  return {
    name: "stub-node-builtins",
    enforce: "pre",
    resolveId(id) {
      if (id in stubs) return `\0stub:${id}`
    },
    load(id) {
      if (id.startsWith("\0stub:")) {
        return stubs[id.slice(6)]
      }
    },
  }
}
