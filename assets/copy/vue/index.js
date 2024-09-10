// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill";


// it's a way of importing multiple files in one go with Vite. 
// we get back a map of components with their relative paths as keys.
// we're importing from ../../lib to allow collocating Vue files with LiveView files
// eager controls if the import should be lazy or not 

// we're exposing each component twice:
// 1. as it's filename without extension. If you have 2 files with the same name in different directories, it will pick the last one. 
// 2. as a path relative either to `assets/vue` or `lib/my_app_web`. 
// I'd recommend using option 1 in `v-component` wherever possible, and fallback to option 2 if needed.

export default {
  // eager: true disables lazy loading - all these components will be part of the app.js bundle
  ...import.meta.glob('./**/*.vue', { eager: true }),
  ...import.meta.glob('../../lib/**/*.vue')
}

// above way imports ALL the vue files in the project, even if they're unused
// if you want to maximize benefits of lazy loading or avoid importing unneded files
// put all your top-level (used in Elixir renders) in a single directory, remove above lines and uncomment below
// export default import.meta.glob('./entrypoints/**/*.vue', { eager: false })

// you can even do fine-grained control of what exactly should be imported

// import component1 from './Component1.vue'
// import component2 from './Component2.vue'
// const entryComponents = {
//   Component1: component1,
//   Component2: component2,
//   Component3Lazy: () => import('./Component3.vue')
// }