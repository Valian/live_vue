import { bench, describe } from "vitest"
import { decodeCompactJson, decodeCompactPatch } from "./compactPatch"
import { applyPatch } from "./jsonPatch"

const textEncoder = new TextEncoder()

const fieldLength = (value: string) => value.length

const encodeJson = (value: unknown) => JSON.stringify(value).replace(/~/g, "~~").replace(/\^/g, "~^").replace(/"/g, "^")

const field = (value: string) => `${fieldLength(value)}:${value}`

const valueField = (value: unknown) => {
  if (value === null) return "z"
  if (typeof value === "boolean") return value ? "b1" : "b0"
  if (typeof value === "number") return `n${field(String(value))}`
  if (typeof value === "string") return `s${field(value)}`
  return `J${field(encodeJson(value))}`
}

const operation = (op: "a" | "d" | "r" | "u" | "l", path: string, value?: unknown) =>
  op === "d" ? `${op}${field(path)}` : `${op}${field(path)}${valueField(value)}`

const makeSyntheticPayload = (targetBytes: number) => {
  let payload = "n12345"
  let index = 0

  while (payload.length < targetBytes) {
    payload += operation("r", `/rows/${index}/name`, `row ${index} zażółć`)
    payload += operation("r", `/rows/${index}/enabled`, index % 2 === 0)
    payload += operation("u", `/rows/${index}`, {
      id: index,
      name: `Row ${index}`,
      tags: [`tag-${index % 5}`, "vue", "liveview"],
      nested: { count: index, active: index % 3 === 0 },
    })
    index++
  }

  return payload
}

const makeArticle = (index: number) => ({
  __dom_id: `article-${index}`,
  id: index,
  slug: `article-${index}`,
  title: `LiveVue update ${index} 🚀 zażółć`,
  summary:
    `Moderate length text with UTF-8 characters: café, 東京, emoji ✨🔥, and caret ^ / tilde ~ markers. `.repeat(3) +
    index,
  author: {
    id: `user-${index % 12}`,
    name: `Author ${index % 12} Łukasz 😊`,
    profile: {
      timezone: "Europe/Warsaw",
      bio: "Builds interfaces with Phoenix LiveView and Vue. Uses nested data often.",
    },
  },
  stats: {
    views: index * 137,
    likes: index % 17,
    featured: index % 11 === 0,
    scores: [index, index + 1, index + 2, index + 3],
  },
  metadata: {
    labels: [`team-${index % 4}`, "vue", "phoenix", "ssr"],
    flags: { archived: false, reviewed: index % 3 === 0, pinned: index % 8 === 0 },
    seo: {
      title: `SEO title ${index}`,
      description: "A longer nested string that resembles user-generated content and includes emoji 🧪.",
    },
  },
})

const makeScalarDocument = (rows = 300) => ({
  dashboard: {
    rows: Array.from({ length: rows }, (_, index) => ({
      id: index,
      title: `Title ${index}`,
      count: index,
      enabled: index % 2 === 0,
      nested: { label: `Label ${index}`, score: index * 2 },
    })),
  },
})

const makeScalarPayload = (targetBytes: number) => {
  let payload = "n246810"
  let index = 0

  while (payload.length < targetBytes) {
    const row = index % 300
    payload += operation("r", `/dashboard/rows/${row}/title`, `Updated ${index} ✨`)
    payload += operation("r", `/dashboard/rows/${row}/count`, index)
    payload += operation("r", `/dashboard/rows/${row}/enabled`, index % 2 === 0)
    payload += operation("r", `/dashboard/rows/${row}/nested/label`, `Nested ${index} zażółć`)
    index++
  }

  return payload
}

const makeRealisticPayload = (targetBytes: number) => {
  let payload = "n987654"
  let index = 0

  while (payload.length < targetBytes) {
    payload += operation("r", `/dashboard/articles/${index}/title`, `Updated title ${index} ✨`)
    payload += operation(
      "r",
      `/dashboard/articles/${index}/metadata/seo/description`,
      `Changed copy ${index} with emoji 😄`
    )
    payload += operation("u", `/dashboard/articles/${index}`, makeArticle(index))
    payload += operation("l", "/dashboard/articles", -50)
    index++
  }

  return payload
}

const synthetic5kb = makeSyntheticPayload(5_000)
const synthetic25kb = makeSyntheticPayload(25_000)
const synthetic50kb = makeSyntheticPayload(50_000)
const realistic25kb = makeRealisticPayload(25_000)
const realistic50kb = makeRealisticPayload(50_000)
const scalar50kb = makeScalarPayload(50_000)
const realisticJsonValue = encodeJson({ articles: Array.from({ length: 30 }, (_, index) => makeArticle(index)) })
const decodeThenApplyDocument = {
  dashboard: { articles: Array.from({ length: 80 }, (_, index) => makeArticle(index)) },
}
const scalarDecodeThenApplyDocument = makeScalarDocument()
const utf8Sample = Array.from({ length: 150 }, (_, index) => makeArticle(index).summary).join(" | ")
const utf8SampleBytes = textEncoder.encode(utf8Sample).length

const findUtf8EndManually = (value: string, offset: number, bytesToRead: number) => {
  let end = offset
  let bytes = 0

  while (end < value.length && bytes < bytesToRead) {
    const code = value.charCodeAt(end)

    if (code <= 0x7f) {
      bytes++
      end++
    } else if (code <= 0x7ff) {
      bytes += 2
      end++
    } else if (code >= 0xd800 && code <= 0xdbff && end + 1 < value.length) {
      const next = value.charCodeAt(end + 1)
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

  if (bytes !== bytesToRead) throw new Error("Invalid UTF-8 byte length")
  return end
}

describe("decodeCompactPatch", () => {
  bench("synthetic 5kb payload", () => {
    decodeCompactPatch(synthetic5kb)
  })

  bench("synthetic 25kb payload", () => {
    decodeCompactPatch(synthetic25kb)
  })

  bench("synthetic 50kb payload", () => {
    decodeCompactPatch(synthetic50kb)
  })

  bench("realistic 25kb payload", () => {
    decodeCompactPatch(realistic25kb)
  })

  bench("realistic 50kb payload", () => {
    decodeCompactPatch(realistic50kb)
  })
})

describe("decode and apply compact patch", () => {
  // Direct compact-patch application was benchmarked here and removed because it was not faster.
  bench("object-heavy: decode to operations, then apply", () => {
    applyPatch(decodeThenApplyDocument, decodeCompactPatch(realistic50kb))
  })

  bench("scalar-heavy: decode to operations, then apply", () => {
    applyPatch(scalarDecodeThenApplyDocument, decodeCompactPatch(scalar50kb))
  })
})

describe("decodeCompactJson", () => {
  bench("realistic nested JSON value", () => {
    decodeCompactJson(realisticJsonValue)
  })
})

describe("field boundary detection", () => {
  bench("UTF-8 byte scan", () => {
    findUtf8EndManually(utf8Sample, 0, utf8SampleBytes)
  })

  bench("JS string length", () => {
    utf8Sample.slice(0, utf8Sample.length)
  })
})
