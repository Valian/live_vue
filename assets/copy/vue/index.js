// it's a way of importing multiple files in one go with Vite. 
// we get back a map of components with their paths as keys.
// https://vitejs.dev/guide/features#glob-import
const components = import.meta.glob('./**/*.vue', { eager: true, import: 'default' })

const mapKeys = (object, cb) => Object.entries(object).reduce((acc, [key, value]) => {
  const newKey = cb(key, value, object);
  acc[newKey] = value;
  return acc;
}, {});

// we just need to replace the "./" with "" and ".vue" with ""
export default mapKeys(components, key => key.replace("./", "").replace(".vue", ""))