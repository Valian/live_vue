// it's a way of importing multiple files in one go with Vite. 
// we get back a map of components with their relative paths as keys.
// we're importing from ../../lib to allow collocating Vue files with LiveView files
const assetsComponents = import.meta.glob('./**/*.vue', { eager: true, import: 'default' })
const libComponents = import.meta.glob('../../lib/**/*.vue', { eager: true, import: 'default' })

const flatMapKeys = (object, cb) => Object.entries(object).reduce((acc, [key, value]) => {
  const newKeys = cb(key, value, object);
  for (const newKey of newKeys) {
    acc[newKey] = value;
  }
  return acc;
}, {});

// we're exposing each component twice:
// 1. as it's filename without extension. If you have 2 files with the same name in different directories, it will pick the last one. 
// 2. as a path relative either to `assets/vue` or `lib/my_app_web`. 
// I'd recommend using option 1 in `v-component` wherever possible, and fallback to option 2 if needed.
export default {
  ...flatMapKeys(assetsComponents, key => {
    // it's in the current directory
    const path = key.replace("./", "").replace(".vue", "")
    return [ path, path.split("/").slice(-1)[0] ]
  }),
  ...flatMapKeys(libComponents, key => {
    // it's colocated with the LiveView, so path should be relative to lib/my_app_web
    const path = key.split("/").slice(4).join("/").replace(".vue", "")
    return [ path, path.split("/").slice(-1)[0]]
  }),
}