import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue()
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './vue')
    }
  },
  build: {
    manifest: true,
    rollupOptions: {
      input: {
        app: path.resolve(__dirname, 'js/app.js'),
      },
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name].[ext]'
      }
    }
  },
  server: {
    hmr: true,
    port: 5173,
    strictPort: true
  }
}); 