import path from 'path'
import { defineConfig } from 'vite'

import vue from '@vitejs/plugin-vue'
import liveVuePlugin from "live_vue/vitePlugin"

// https://vitejs.dev/config/
export default defineConfig(({command}) => {
  const isDev = command !== "build";

  return {
    base: isDev ? undefined : "/assets",
    publicDir: "static",
    plugins: [vue(), liveVuePlugin()],
    ssr: {
      // we need it, because in SSR build we want no external
      // and in dev, we want external for fast updates
      noExternal: isDev ? undefined : true,
    },
    resolve: {
      alias: {
        vue: path.resolve(__dirname, 'node_modules/vue'),
        "@": path.resolve(__dirname, "."),
      }
    },
    optimizeDeps: {
      // these packages are loaded as file:../deps/<name> imports
      // so they're not optimized for development by vite by default
      // we want to enable it for better DX
      // more https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
      include: ['live_vue', 'phoenix', 'phoenix_html', 'phoenix_live_view'],
    },
    build: {
      commonjsOptions: { transformMixedEsModules: true },
      target: "es2020",
      outDir: "../priv/static/assets", // emit assets to priv/static/assets
      emptyOutDir: true,
      sourcemap: isDev, // enable source map in dev build
      manifest: false, // do not generate manifest.json
      rollupOptions: {
        input: {
          app: path.resolve(__dirname, './js/app.js'),
        },
        output: {
          // remove hashes to match phoenix way of handling asssets
          entryFileNames: "[name].js", 
          chunkFileNames: "[name].js",
          assetFileNames: "[name][extname]"
        }
      }
    },
  }
})