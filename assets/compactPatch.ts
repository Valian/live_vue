import type { Operation } from "./jsonPatch.js"

const opByCode: Record<string, Operation["op"]> = {
  a: "add",
  d: "remove",
  r: "replace",
  u: "upsert",
  l: "limit",
}

const textEncoder = new TextEncoder()

export const decodeCompactPatch = (payload: string | null): Operation[] => {
  if (!payload) return []

  const operations: Operation[] = []
  let offset = 0

  while (offset < payload.length) {
    const code = payload[offset++]

    if (code === "n") {
      const result = readDigits(payload, offset)
      offset = result.offset
      continue
    }

    const op = opByCode[code]
    if (!op) throw new Error(`Unknown LiveVue patch operation code: ${code}`)

    const pathLength = readLength(payload, offset)
    offset = pathLength.offset

    const pathResult = readUtf8Bytes(payload, offset, pathLength.value)
    offset = pathResult.offset
    const path = pathResult.value

    if (op === "remove") {
      operations.push({ op, path })
      continue
    }

    const valueResult = readValue(payload, offset)
    offset = valueResult.offset
    operations.push({ op, path, value: valueResult.value } as Operation)
  }

  return operations
}

const readValue = (payload: string, offset: number): { value: any; offset: number } => {
  const tag = payload[offset++]

  switch (tag) {
    case "z":
      return { value: null, offset }
    case "b":
      return { value: payload[offset++] === "1", offset }
    case "n": {
      const result = readLengthPrefixed(payload, offset)
      return { value: Number(result.value), offset: result.offset }
    }
    case "s":
      return readLengthPrefixed(payload, offset)
    case "J": {
      const result = readLengthPrefixed(payload, offset)
      return { value: decodeCompactJson(result.value), offset: result.offset }
    }
    default:
      throw new Error(`Unknown LiveVue patch value tag: ${tag}`)
  }
}

const readLengthPrefixed = (payload: string, offset: number): { value: string; offset: number } => {
  const length = readLength(payload, offset)
  const value = readUtf8Bytes(payload, length.offset, length.value)
  return { value: value.value, offset: value.offset }
}

const readLength = (payload: string, offset: number): { value: number; offset: number } => {
  const result = readDigits(payload, offset)
  if (payload[result.offset] !== ":") throw new Error("Invalid LiveVue patch length prefix")
  return { value: Number(result.value), offset: result.offset + 1 }
}

const readDigits = (payload: string, offset: number): { value: string; offset: number } => {
  const start = offset
  while (offset < payload.length && payload.charCodeAt(offset) >= 48 && payload.charCodeAt(offset) <= 57) offset++
  return { value: payload.slice(start, offset), offset }
}

const readUtf8Bytes = (payload: string, offset: number, byteLength: number): { value: string; offset: number } => {
  let end = offset
  let bytes = 0

  while (end < payload.length && bytes < byteLength) {
    const codePoint = payload.codePointAt(end)
    if (codePoint === undefined) break

    const char = String.fromCodePoint(codePoint)
    bytes += textEncoder.encode(char).length
    end += char.length
  }

  if (bytes !== byteLength) throw new Error("Invalid LiveVue patch UTF-8 byte length")

  return { value: payload.slice(offset, end), offset: end }
}

export const decodeCompactJson = (value: string): any => {
  return JSON.parse(value.replace(/~~|~\^|\^/g, match => {
    if (match === "~~") return "~"
    if (match === "~^") return "^"
    return "\""
  }))
}
