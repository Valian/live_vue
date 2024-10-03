type ComponentMap = Record<string, any>;

const flatMapKeys = (object: ComponentMap, cb: (key: string, value: any, object: ComponentMap) => string[]): ComponentMap =>
  Object.entries(object).reduce((acc, [key, value]) => {
    const newKeys = cb(key, value, object);
    for (const newKey of newKeys) acc[newKey] = value;
    return acc;
  }, {} as ComponentMap);

const pathToFullPathAndFilename = (path: string): string[] => {
  path = path.replace("/index.vue", "").replace(".vue", "")
  return [ path, path.split("/").slice(-1)[0] ]
}

const getRelativePath = (path: string): string => {
  if (path.includes("../../")) {
    return path.split("/").slice(4).join("/")
  } else {
    return path.replace("./", "")
  }
}

export const normalizeComponents = (components: ComponentMap): ComponentMap => flatMapKeys(
  components,
  key => pathToFullPathAndFilename(getRelativePath(key))
)

export const getComponent = async (components: ComponentMap, componentName: string): Promise<any> => {
  if (!componentName) {
    throw new Error("Component name is required")
  }

  let component = components[componentName]

  if (!component) {
    const available = Object.keys(components).filter(key => !key.includes("Elixir.") && !key.includes("/"))
    throw new Error(`Component ${componentName} not found!\n\nAvailable components: \n${available.join("\n")}\n`)
  }

  if (typeof component === "function") {
    component = await component()
  } else {
    component = await component
  }

  if (component && component.default) {
    component = component.default
  }

  return component
}