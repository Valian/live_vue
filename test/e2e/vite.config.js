import path from "path"
import { defineConfig } from "vite"

import vue from "@vitejs/plugin-vue"
import stubNodeBuiltins from "../../assets/stubNodeBuiltins.js"

// https://vitejs.dev/config/
export default defineConfig(({ isSsrBuild }) => {
  const isDev = false

  return {
    base: "/assets",
    plugins: [vue(), ...(isSsrBuild ? [stubNodeBuiltins()] : [])],
    resolve: {
      alias: {
        vue: path.resolve(__dirname, "../../node_modules/vue"),
        "@": path.resolve(__dirname, "."),
        live_vue: path.resolve(__dirname, "../../assets/index.ts"),
      },
    },
    ssr: isSsrBuild
      ? {
          noExternal: true,
        }
      : undefined,
    build: {
      commonjsOptions: { transformMixedEsModules: true },
      target: "es2020",
      outDir: isSsrBuild ? "./priv/static" : "./test/e2e/priv/static/assets",
      emptyOutDir: !isSsrBuild,
      sourcemap: isDev,
      manifest: false,
      rollupOptions: {
        ...(isSsrBuild
          ? {}
          : {
              input: {
                app: path.resolve(__dirname, "./js/app.js"),
              },
            }),
        output: {
          // remove hashes to match phoenix way of handling assets
          entryFileNames: isSsrBuild ? "server.mjs" : "[name].js",
          chunkFileNames: isSsrBuild ? "[name].mjs" : "[name].js",
          assetFileNames: "[name][extname]",
        },
      },
    },
  }
})
