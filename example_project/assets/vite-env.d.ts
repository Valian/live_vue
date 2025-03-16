/// <reference types="vite/client" />

// Declare the module for Vue single file components
declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
} 