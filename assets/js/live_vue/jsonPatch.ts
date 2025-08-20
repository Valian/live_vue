/*!
 * Simplified JSON Patch functionality extracted from https://github.com/Starcounter-Jack/JSON-Patch/blob/master/src/core.ts
 * (c) 2013-2021 Joachim Wester
 * MIT license
 */

// Type definitions
export type Operation =
  | AddOperation
  | RemoveOperation
  | ReplaceOperation
  | MoveOperation
  | CopyOperation
  | TestOperation
  | UpsertOperation
  | LimitOperation

export interface BaseOperation {
  path: string
}

export interface AddOperation extends BaseOperation {
  op: "add"
  value: any
}

export interface RemoveOperation extends BaseOperation {
  op: "remove"
}

export interface ReplaceOperation extends BaseOperation {
  op: "replace"
  value: any
}

export interface MoveOperation extends BaseOperation {
  op: "move"
  from: string
}

export interface CopyOperation extends BaseOperation {
  op: "copy"
  from: string
}

export interface TestOperation extends BaseOperation {
  op: "test"
  value: any
}

export interface UpsertOperation extends BaseOperation {
  op: "upsert"
  value: any
}

export interface LimitOperation extends BaseOperation {
  op: "limit"
  value: number
}

// Helper functions
function deepClone<T>(obj: T): T {
  if (obj === null || typeof obj !== "object") return obj
  if (obj instanceof Date) return new Date(obj.getTime()) as any
  if (Array.isArray(obj)) return obj.map(item => deepClone(item)) as any

  const cloned = {} as T
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      cloned[key] = deepClone(obj[key])
    }
  }
  return cloned
}

function unescapePathComponent(path: string): string {
  return path.replace(/~1/g, "/").replace(/~0/g, "~")
}

function areEquals(a: any, b: any): boolean {
  if (a === b) return true
  if (a && b && typeof a == "object" && typeof b == "object") {
    const arrA = Array.isArray(a)
    const arrB = Array.isArray(b)

    if (arrA && arrB) {
      const length = a.length
      if (length != b.length) return false
      for (let i = length; i-- !== 0; ) {
        if (!areEquals(a[i], b[i])) return false
      }
      return true
    }
    if (arrA != arrB) return false

    const keys = Object.keys(a)
    const length = keys.length
    if (length !== Object.keys(b).length) return false

    for (let i = length; i-- !== 0; ) {
      if (!b.hasOwnProperty(keys[i])) return false
    }

    for (let i = length; i-- !== 0; ) {
      const key = keys[i]
      if (!areEquals(a[key], b[key])) return false
    }
    return true
  }
  return a !== a && b !== b
}

/**
 * Resolves a path component that may use special syntax for finding items by ID.
 * If the component starts with $$, it tries to find an array element with matching id.
 * Returns the resolved index or the original component if not using special syntax.
 */
function resolvePathComponent(component: string, arrayObj: any[]): string | null {
  if (!component.startsWith("$$")) {
    return component
  }

  // Extract the ID from $$<id> syntax
  const targetId = component.substring(2)

  // Find the index of the element with matching __dom_id
  const index = arrayObj.findIndex(item => item && typeof item === "object" && item.__dom_id == targetId)

  if (index === -1) {
    console.warn(`JSON Patch: Item with __dom_id "${targetId}" not found in array, skipping operation`)
    return null
  }

  return index.toString()
}

/**
 * Retrieves a value from a JSON document by a JSON pointer.
 */
export function getValueByPointer(document: any, pointer: string): any {
  if (pointer === "") return document

  const keys = pointer.split("/").slice(1) // remove empty first element
  let obj = document

  for (const key of keys) {
    let resolvedKey = key.indexOf("~") !== -1 ? unescapePathComponent(key) : key

    if (Array.isArray(obj)) {
      // Handle special $$id syntax for arrays
      if (resolvedKey.startsWith("$$")) {
        const resolved = resolvePathComponent(resolvedKey, obj)
        if (resolved === null) {
          return undefined // Item not found
        }
        resolvedKey = resolved
      }
      obj = obj[resolvedKey === "-" ? obj.length - 1 : parseInt(resolvedKey, 10)]
    } else {
      obj = obj[resolvedKey]
    }
  }

  return obj
}

/**
 * Apply a single JSON Patch Operation on a JSON document in-place.
 * Modifies the original document to maintain Vue reactivity.
 */
export function applyOperation<T>(document: T, operation: Operation): T {
  // Handle root operations
  if (operation.path === "") {
    switch (operation.op) {
      case "add":
      case "replace":
        return (operation as AddOperation | ReplaceOperation).value
      case "move":
      case "copy":
        return getValueByPointer(document, (operation as MoveOperation | CopyOperation).from)
      case "test":
        return document // Test always returns original document
      case "remove":
        return null as any
    }
  }

  const keys = operation.path.split("/").slice(1) // remove empty first element
  let obj = document as any

  // Navigate to parent object
  for (let i = 0; i < keys.length - 1; i++) {
    let key = keys[i].indexOf("~") !== -1 ? unescapePathComponent(keys[i]) : keys[i]

    if (Array.isArray(obj)) {
      // Handle special $$id syntax for arrays
      if (key.startsWith("$$")) {
        const resolved = resolvePathComponent(key, obj)
        if (resolved === null) {
          return document // Skip operation if id not found
        }
        key = resolved
      }
      obj = obj[key === "-" ? obj.length - 1 : parseInt(key, 10)]
    } else {
      obj = obj[key]
    }
  }

  // Apply operation on final key
  const finalKey = keys[keys.length - 1]
  let unescapedKey = finalKey.indexOf("~") !== -1 ? unescapePathComponent(finalKey) : finalKey

  if (Array.isArray(obj)) {
    let index: number

    // Handle special $$id syntax for arrays
    if (unescapedKey.startsWith("$$")) {
      const resolved = resolvePathComponent(unescapedKey, obj)
      if (resolved === null) {
        return document // Skip operation if id not found
      }
      index = parseInt(resolved, 10)
    } else {
      index = unescapedKey === "-" ? obj.length : parseInt(unescapedKey, 10)
    }

    switch (operation.op) {
      case "add":
        obj.splice(index, 0, (operation as AddOperation).value)
        break
      case "remove":
        obj.splice(index, 1)
        break
      case "replace":
        obj[index] = (operation as ReplaceOperation).value
        break
      case "upsert":
        const upsertValue = (operation as UpsertOperation).value
        // Check if item with same ID already exists in the array
        if (upsertValue && typeof upsertValue === "object" && "__dom_id" in upsertValue) {
          const existingIndex = obj.findIndex(
            item => item && typeof item === "object" && item.__dom_id === upsertValue.__dom_id
          )

          if (existingIndex !== -1) {
            // Update existing item
            obj[existingIndex] = upsertValue
          } else {
            // Insert new item at specified index
            obj.splice(index, 0, upsertValue)
          }
        } else {
          // No ID to match against, just insert at specified index
          obj.splice(index, 0, upsertValue)
        }
        break
      case "move":
        const moveValue = getValueByPointer(document, (operation as MoveOperation).from)
        if (moveValue === undefined) {
          return document // Skip operation if source not found
        }
        applyOperation(document, { op: "remove", path: (operation as MoveOperation).from })
        obj.splice(index, 0, moveValue)
        break
      case "copy":
        const copyValue = getValueByPointer(document, (operation as CopyOperation).from)
        obj.splice(index, 0, deepClone(copyValue))
        break
      case "test":
        // Test operation - just return document unchanged
        break
      case "limit":
        const limitValue = (operation as LimitOperation).value
        if (limitValue >= 0) {
          // Positive limit: keep first N elements, remove the rest
          if (limitValue < obj.length) {
            obj.splice(limitValue)
          }
        } else {
          // Negative limit: keep last N elements, remove from the beginning
          const keepCount = Math.abs(limitValue)
          if (keepCount < obj.length) {
            obj.splice(0, obj.length - keepCount)
          }
        }
        break
    }
  } else {
    switch (operation.op) {
      case "add":
      case "replace":
        obj[unescapedKey] = (operation as AddOperation | ReplaceOperation).value
        break
      case "remove":
        delete obj[unescapedKey]
        break
      case "move":
        const moveValue = getValueByPointer(document, (operation as MoveOperation).from)
        applyOperation(document, { op: "remove", path: (operation as MoveOperation).from })
        obj[unescapedKey] = moveValue
        break
      case "copy":
        const copyValue = getValueByPointer(document, (operation as CopyOperation).from)
        obj[unescapedKey] = deepClone(copyValue)
        break
      case "test":
        // Test operation - just return document unchanged
        break
      case "limit":
        // Check if target is an array
        const targetArray = obj[unescapedKey]
        if (Array.isArray(targetArray)) {
          const limitValue = (operation as LimitOperation).value
          if (limitValue >= 0) {
            // Positive limit: keep first N elements, remove the rest
            if (limitValue < targetArray.length) {
              targetArray.splice(limitValue)
            }
          } else {
            // Negative limit: keep last N elements, remove from the beginning
            const keepCount = Math.abs(limitValue)
            if (keepCount < targetArray.length) {
              targetArray.splice(0, targetArray.length - keepCount)
            }
          }
        }
        break
    }
  }

  return document
}

/**
 * Apply a JSON-Patch sequence to a JSON document in-place.
 * Modifies the original document to maintain Vue reactivity.
 */
export function applyPatch<T>(document: T, patch: ReadonlyArray<Operation>): T {
  let result = document

  for (const operation of patch) {
    result = applyOperation(result, operation)
  }

  return result
}
