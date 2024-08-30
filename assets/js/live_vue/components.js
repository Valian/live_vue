const flatMapKeys = (object, cb) => Object.entries(object).reduce((acc, [key, value]) => {
  const newKeys = cb(key, value, object);
  for (const newKey of newKeys) acc[newKey] = value;
  return acc;
}, {});

const pathToFullPathAndFilename = (path) => {
  path = path.replace("/index.vue", "").replace(".vue", "")
  // both full path and only filename
  return [ path, path.split("/").slice(-1)[0] ]
}

const getRelativePath = (path) => {
  if (path.includes("../../")) {
    // it's colocated with the LiveView, so path should be relative to lib/my_app_web
    return path.split("/").slice(4).join("/")
  } else {
    // it's in the current directory
    return path.replace("./", "")
  }
}

export const normalizeComponents = (components) => flatMapKeys(
  components,
  key => pathToFullPathAndFilename(getRelativePath(key))
)

export const getComponent = async (components, componentName) => {
  if (!componentName) {
    throw new Error("Component name is required")
  }

  let component = components[componentName]

  if (!component) {
    const available = Object.keys(components).filter(key => !key.includes("Elixir.") && !key.includes("/"))
    throw new Error(`Component ${componentName} not found!\n\nAvailable components: \n${available.join("\n")}\n`)
  }

  if (typeof component === "function") {
    // it's an async component, let's try to load it
    component = await component()
  } else {
    component = await component
  }

  if (component && component.default) {
    // if there's a default export, use it
    component = component.default
  }

  return component
}