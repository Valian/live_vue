import type { Operation } from "./jsonPatch.js"

export const decodeCompactPatch = (payload: string | null): Operation[] => {
  if (!payload) return []

  const operations: Operation[] = []
  let offset = 0

  while (offset < payload.length) {
    const code = payload[offset++]

    if (code === "n") {
      offset = skipDigits(payload, offset)
      continue
    }

    const op = opFromCode(code)
    const pathLength = readLength(payload, offset)
    offset = pathLength.offset

    const pathEnd = findUtf8End(payload, offset, pathLength.value)
    const path = payload.slice(offset, pathEnd)
    offset = pathEnd

    if (op === "remove") {
      operations.push({ op, path })
      continue
    }

    const tag = payload[offset++]

    if (tag === "z") {
      operations.push({ op, path, value: null } as Operation)
      continue
    }

    if (tag === "b") {
      operations.push({ op, path, value: payload[offset++] === "1" } as Operation)
      continue
    }

    const valueLength = readLength(payload, offset)
    offset = valueLength.offset

    const valueEnd = findUtf8End(payload, offset, valueLength.value)
    const rawValue = payload.slice(offset, valueEnd)
    offset = valueEnd

    if (tag === "n") {
      operations.push({ op, path, value: Number(rawValue) } as Operation)
    } else if (tag === "s") {
      operations.push({ op, path, value: rawValue } as Operation)
    } else if (tag === "J") {
      operations.push({ op, path, value: decodeCompactJson(rawValue) } as Operation)
    } else {
      throw new Error(`Unknown LiveVue patch value tag: ${tag}`)
    }
  }

  return operations
}

const opFromCode = (code: string): Operation["op"] => {
  switch (code) {
    case "a":
      return "add"
    case "d":
      return "remove"
    case "r":
      return "replace"
    case "u":
      return "upsert"
    case "l":
      return "limit"
    default:
      throw new Error(`Unknown LiveVue patch operation code: ${code}`)
  }
}

const readLength = (payload: string, offset: number): { value: number; offset: number } => {
  let value = 0
  let hasDigits = false

  while (offset < payload.length) {
    const code = payload.charCodeAt(offset)
    if (code < 48 || code > 57) break
    value = value * 10 + code - 48
    offset++
    hasDigits = true
  }

  if (!hasDigits || payload[offset] !== ":") throw new Error("Invalid LiveVue patch length prefix")
  return { value, offset: offset + 1 }
}

const skipDigits = (payload: string, offset: number): number => {
  while (offset < payload.length) {
    const code = payload.charCodeAt(offset)
    if (code < 48 || code > 57) break
    offset++
  }

  return offset
}

const findUtf8End = (payload: string, offset: number, byteLength: number): number => {
  let end = offset
  let bytes = 0

  while (end < payload.length && bytes < byteLength) {
    const code = payload.charCodeAt(end)

    if (code <= 0x7f) {
      bytes++
      end++
    } else if (code <= 0x7ff) {
      bytes += 2
      end++
    } else if (code >= 0xd800 && code <= 0xdbff && end + 1 < payload.length) {
      const next = payload.charCodeAt(end + 1)
      if (next >= 0xdc00 && next <= 0xdfff) {
        bytes += 4
        end += 2
      } else {
        bytes += 3
        end++
      }
    } else {
      bytes += 3
      end++
    }
  }

  if (bytes !== byteLength) throw new Error("Invalid LiveVue patch UTF-8 byte length")

  return end
}

export const decodeCompactJson = (value: string): any => {
  return JSON.parse(
    value.replace(/~~|~\^|\^/g, match => {
      if (match === "~~") return "~"
      if (match === "~^") return "^"
      return '"'
    })
  )
}
