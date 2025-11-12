/**
 * This file is provided as an example of how to configure Vite for a
 * Phoenix LiveView project, using typescript. If you want to use this, you can
 * replace assets/vite.config.js with this file.
 *
 * Some Vite plugins don't have a very good typescript support so it's hard
 * to get rid of the the cast to PluginOption[] in the plugins array.
 */

import type { PluginOption } from 'vite'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import vue from '@vitejs/plugin-vue'
import autoprefixer from 'autoprefixer'
import liveVuePlugin from 'live_vue/vitePlugin'
import tailwindcss from 'tailwindcss'
import { defineConfig } from 'vite'
import vuetify from 'vite-plugin-vuetify'
import tailwindConfig from './tailwind.config.ts'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// https://vitejs.dev/config/
export default defineConfig(({ command }) => {
  const isDev = command !== 'build'

  return {
    base: isDev ? undefined : '/assets',
    publicDir: 'static',
    // when using typescript in your vite config, you must delete the
    // postcss.config.js file, and rely on the vite css option instead
    // to load the autoprefixer and tailwindcss plugins
    css: {
      postcss: { plugins: [tailwindcss(tailwindConfig), autoprefixer()] },
    },
    plugins: [
      vue(),
      // if you change ./js/server.js, to typescript, you need
      // to set livePlugin({ entrypoint: "./js/server.ts" })
      liveVuePlugin(),
      vuetify({ autoImport: { labs: true } }),
    ] as PluginOption[],
    ssr: {
      // we need it, because in SSR build we want no external
      // and in dev, we want external for fast updates
      noExternal: ['vuetify'],
    },
    resolve: {
      alias: {
        'vue': path.resolve(__dirname, 'node_modules/vue'),
        '@': path.resolve(__dirname, '.'),
      },
    },
    optimizeDeps: {
      // these packages are loaded as file:../deps/<name> imports
      // so they're not optimized for development by vite by default
      // we want to enable it for better DX
      // more https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
      include: ['phoenix', 'phoenix_html', 'phoenix_live_view'],
    },
    build: {
      commonjsOptions: { transformMixedEsModules: true },
      target: 'es2020',
      outDir: '../priv/static/assets', // emit assets to priv/static/assets
      emptyOutDir: true,
      sourcemap: isDev, // enable source map in dev build
      manifest: false, // do not generate manifest.json
      rollupOptions: {
        input: {
          app: path.resolve(__dirname, './js/app.js'),
        },
        output: {
          // remove hashes to match phoenix way of handling assets
          entryFileNames: '[name].js',
          chunkFileNames: '[name].js',
          assetFileNames: '[name][extname]',
        },
      },
    },
  }
})
