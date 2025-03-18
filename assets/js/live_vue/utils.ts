import { isProxy, isReactive, isRef, toRaw } from "vue"
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

export function deepToRaw<T>(sourceObj: T): T {
  const objectIterator = (input: any): any => {
    if (Array.isArray(input)) {
      return input.map(item => objectIterator(item))
    }
    if (isRef(input) || isReactive(input) || isProxy(input)) {
      return objectIterator(toRaw(input))
    }
    if (input && typeof input === "object") {
      return Object.keys(input).reduce((acc, key) => {
        acc[key as keyof typeof acc] = objectIterator(input[key])
        return acc
      }, {} as T)
    }
    return input
  }

  return objectIterator(sourceObj)
}

function assignArray(targetArray: any[], sourceArray: any[]) {
  // Adjust the length of the target array to match the source array
  targetArray.length = sourceArray.length

  sourceArray.forEach((item, index) => {
    if (typeof item === "object" && item !== null) {
      if (index in targetArray && targetArray[index] !== null && targetArray[index] !== undefined) {
        // Deep assign existing items
        deepAssign(targetArray[index], item)
      } else {
        // Create a new item if it doesn't exist in the target
        targetArray[index] = deepAssign(Array.isArray(item) ? [] : {}, item)
      }
    } else {
      // For primitive values, simply assign
      targetArray[index] = item
    }
  })
}

function clearObject(targetObject: any) {
  if (Array.isArray(targetObject)) {
    targetObject.length = 0
  } else {
    Object.values(targetObject).forEach(value => {
      clearObject(value)
    })
  }
}

function assignObject(targetObject: any, sourceObject: any) {
  Object.keys(sourceObject).forEach(key => {
    const sourceValue = toRaw(sourceObject[key])
    targetObject[key] =
      typeof sourceValue === "object" && sourceValue !== null && targetObject !== null
        ? deepAssign(targetObject[key] ?? (Array.isArray(sourceValue) ? [] : {}), sourceValue)
        : sourceValue
  })

  // Remove properties from target that are not in source
  Object.keys(targetObject).forEach(key => {
    if (!(key in sourceObject)) {
      clearObject(targetObject[key])
    }
  })
}

export function deepAssign(target: any, source: any) {
  if (Array.isArray(source)) {
    assignArray(target, source)
  } else if (typeof source === "object" && source !== null) {
    assignObject(target, source)
  } else {
    target = source
  }

  return target
}

export function deepCopy<T>(obj: T): T {
  if (structuredClone) {
    return structuredClone(deepToRaw(obj))
  } else {
    return JSON.parse(JSON.stringify(obj))
  }
}

export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: ReturnType<typeof setTimeout> | null = null

  return (...args: Parameters<T>) => {
    if (timeout !== null) clearTimeout(timeout)
    timeout = setTimeout(() => func(...args), wait)
  }
}

export const cacheOnAccessProxy = <T extends object>(createFunc: (key: keyof T) => any) =>
  new Proxy(
    {},
    {
      // @ts-expect-error proxy get always expect string key
      get: (fields, key: keyof T) => {
        if (typeof key === "string" && key.startsWith("__")) {
          return Reflect.get(fields, key)
        }
        if (!Reflect.has(fields, key)) {
          Reflect.set(fields, key, createFunc(key))
        }
        return Reflect.get(fields, key)
      },
    }
  )
