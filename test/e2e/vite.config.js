import path from 'node:path'
import vue from '@vitejs/plugin-vue'

import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig(() => {
  const isDev = false

  return {
    base: '/assets',
    plugins: [vue()],
    resolve: {
      alias: {
        'vue': path.resolve(__dirname, '../../node_modules/vue'),
        '@': path.resolve(__dirname, '.'),
        'live_vue': path.resolve(__dirname, '../../priv/static/index.js'),
      },
    },
    build: {
      commonjsOptions: { transformMixedEsModules: true },
      target: 'es2020',
      outDir: './test/e2e/priv/static/assets',
      emptyOutDir: true,
      sourcemap: isDev,
      manifest: false,
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
