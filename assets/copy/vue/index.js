// it's a way of importing multiple files in one go with Vite. 
// we get back a map of components with their relative paths as keys.
// we're importing from ../../lib to allow collocating Vue files with LiveView files
const assetsComponents = import.meta.glob('./**/*.vue', { eager: true, import: 'default' })

// these imports are lazy, meaning they won't be loaded unless requested. You can change it.
const libComponents = import.meta.glob('../../lib/**/*.vue', { eager: false, import: 'default' })

/* 
!!! Possibly important optimization !!!
above way imports ALL the vue files in the project, even if they're unused
if you want to maximize benefits of lazy loading or avoid importing unneded files
try to put all your top-level (used in Elixir renders) in a single directory, remove above lines and uncomment below
*/

// const entryComponents = import.meta.glob('./entrypoints/**/*.vue', { eager: false, import: 'default' })

/* you can even do fine-grained control of what exactly should be imported */

// import component1 from './Component1.vue'
// import component2 from './Component2.vue'
// const entryComponents = {
//   Component1: component1,
//   Component2: component2,
//   Component3Lazy: () => import('./Component3.vue').then(m => m.default)
// }

const flatMapKeys = (object, cb) => Object.entries(object).reduce((acc, [key, value]) => {
  const newKeys = cb(key, value, object);
  for (const newKey of newKeys) acc[newKey] = value;
  return acc;
}, {});

function pathToKeys(path) {
  path = path.replace(".vue", "")
  // both full path and only filename
  return [ path, path.split("/").slice(-1)[0] ]
}

// we're exposing each component twice:
// 1. as it's filename without extension. If you have 2 files with the same name in different directories, it will pick the last one. 
// 2. as a path relative either to `assets/vue` or `lib/my_app_web`. 
// I'd recommend using option 1 in `v-component` wherever possible, and fallback to option 2 if needed.
export default {
  // it's in the current directory
  ...flatMapKeys(assetsComponents, key => pathToKeys(key.replace("./", ""))),
  // it's colocated with the LiveView, so path should be relative to lib/my_app_web
  ...flatMapKeys(libComponents, key => pathToKeys(key.split("/").slice(4).join("/"))) 
}