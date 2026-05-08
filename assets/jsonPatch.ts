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

/**
 * Resolves a path component that may use special syntax for finding items by ID.
 * If the component starts with $$, it tries to find an array element with matching id.
 * Returns the resolved index or the original component if not using special syntax.
 */
function resolvePathComponent(component: string, arrayObj: any[]): string | null {
  if (!component.startsWith("$$")) {
    return component
  }

  const targetId = component.substring(2)
  const index = arrayObj.findIndex(item => item && typeof item === "object" && item.__dom_id == targetId)

  if (index === -1) {
    console.warn(`JSON Patch: Item with __dom_id "${targetId}" not found in array, skipping operation`)
    return null
  }

  return index.toString()
}

function readPathSegment(path: string, start: number, end: number): string {
  const segment = path.slice(start, end)
  return segment.indexOf("~") === -1 ? segment : unescapePathComponent(segment)
}

function resolveArrayIndex(key: string, arrayObj: any[], allowAppend: boolean): number | null {
  if (key.startsWith("$$")) {
    const resolved = resolvePathComponent(key, arrayObj)
    return resolved === null ? null : parseInt(resolved, 10)
  }

  if (key === "-") return allowAppend ? arrayObj.length : arrayObj.length - 1
  return parseInt(key, 10)
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
  return applyPatchOperation(
    document,
    operation.op,
    operation.path,
    "value" in operation ? operation.value : undefined,
    "from" in operation ? operation.from : undefined
  )
}

export function applyPatchOperation<T>(
  document: T,
  op: Operation["op"],
  path: string,
  value?: AddOperation["value"],
  from?: string
): T {
  if (path === "") {
    switch (op) {
      case "add":
      case "replace":
        return value
      case "move":
      case "copy":
        return getValueByPointer(document, from || "")
      case "test":
        return document
      case "remove":
        return null as any
    }
  }

  let obj = document as any
  let segmentStart = 1

  while (true) {
    const segmentEnd = path.indexOf("/", segmentStart)
    if (segmentEnd === -1) break

    const key = readPathSegment(path, segmentStart, segmentEnd)

    if (Array.isArray(obj)) {
      const index = resolveArrayIndex(key, obj, false)
      if (index === null) return document
      obj = obj[index]
    } else {
      obj = obj[key]
    }

    segmentStart = segmentEnd + 1
  }

  const unescapedKey = readPathSegment(path, segmentStart, path.length)

  if (Array.isArray(obj)) {
    let index: number

    const resolvedIndex = resolveArrayIndex(unescapedKey, obj, true)
    if (resolvedIndex === null) return document
    index = resolvedIndex

    switch (op) {
      case "add":
        obj.splice(index, 0, value)
        break
      case "remove":
        obj.splice(index, 1)
        break
      case "replace":
        obj[index] = value
        break
      case "upsert":
        if (value && typeof value === "object" && "__dom_id" in value) {
          const existingIndex = obj.findIndex(
            item => item && typeof item === "object" && item.__dom_id === value.__dom_id
          )

          if (existingIndex !== -1) {
            obj[existingIndex] = value
          } else {
            obj.splice(index, 0, value)
          }
        } else {
          obj.splice(index, 0, value)
        }
        break
      case "move":
        const moveValue = getValueByPointer(document, from || "")
        if (moveValue === undefined) return document
        applyPatchOperation(document, "remove", from || "")
        obj.splice(index, 0, moveValue)
        break
      case "copy":
        obj.splice(index, 0, deepClone(getValueByPointer(document, from || "")))
        break
      case "test":
        break
      case "limit":
        if (value >= 0) {
          if (value < obj.length) obj.splice(value)
        } else {
          const keepCount = Math.abs(value)
          if (keepCount < obj.length) obj.splice(0, obj.length - keepCount)
        }
        break
    }
  } else {
    switch (op) {
      case "add":
      case "replace":
        obj[unescapedKey] = value
        break
      case "remove":
        delete obj[unescapedKey]
        break
      case "move":
        const moveValue = getValueByPointer(document, from || "")
        applyPatchOperation(document, "remove", from || "")
        obj[unescapedKey] = moveValue
        break
      case "copy":
        obj[unescapedKey] = deepClone(getValueByPointer(document, from || ""))
        break
      case "test":
        break
      case "limit":
        const targetArray = obj[unescapedKey]
        if (Array.isArray(targetArray)) {
          if (value >= 0) {
            if (value < targetArray.length) targetArray.splice(value)
          } else {
            const keepCount = Math.abs(value)
            if (keepCount < targetArray.length) targetArray.splice(0, targetArray.length - keepCount)
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
