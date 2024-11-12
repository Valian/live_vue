import { ComponentMap, ComponentOrComponentPromise } from "./types.js"

/**
 * Maps the values of an object using a callback function and returns a new object with the mapped values.
 * @returns A new object with the mapped values.
 */
export const mapValues = <T, U>(
  object: Record<string, T>,
  cb: (value: T, key: string, object: Record<string, T>) => U
): Record<string, U> =>
  Object.entries(object).reduce((acc, [key, value]) => {
    acc[key] = cb(value, key, object)
    return acc
  }, {} as Record<string, U>)

/**
 * Flattens the keys of an object using a callback function and returns a new object with the flattened keys.
 * @returns A new object with the flattened keys.
 */
export const flatMapKeys = <T>(
  object: Record<string, T>,
  cb: (key: string, value: any, object: Record<string, T>) => string[]
): Record<string, T> =>
  Object.entries(object).reduce((acc, [key, value]) => {
    const newKeys = cb(key, value, object)
    for (const newKey of newKeys) acc[newKey] = value
    return acc
  }, {} as Record<string, T>)

/**
 * Finds a component by name or path suffix.
 * @returns The component if found, otherwise throws an error with a list of available components.
 */
export const findComponent = (components: ComponentMap, name: string): ComponentOrComponentPromise => {
  // we're looking for a component by name or path suffix.
  for (const [key, value] of Object.entries(components)) {
    if (key.endsWith(`${name}.vue`) || key.endsWith(`${name}/index.vue`)) {
      return value
    }
  }

  // a helpful message for the user
  const availableComponents = Object.keys(components)
    .map(key => key.replace("../../lib/", "").replace("/index.vue", "").replace(".vue", "").replace("./", ""))
    .filter(key => !key.startsWith("_build"))
    .join("\n")

  throw new Error(`Component '${name}' not found! Available components:\n\n${availableComponents}\n\n`)
}
