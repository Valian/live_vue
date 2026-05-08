import { bench, describe } from "vitest"
import { decodeCompactJson, decodeCompactPatch } from "./compactPatch"

const textEncoder = new TextEncoder()

const byteLength = (value: string) => textEncoder.encode(value).length

const encodeJson = (value: unknown) => JSON.stringify(value).replace(/~/g, "~~").replace(/\^/g, "~^").replace(/"/g, "^")

const field = (value: string) => `${byteLength(value)}:${value}`

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
const realisticJsonValue = encodeJson({ articles: Array.from({ length: 30 }, (_, index) => makeArticle(index)) })
const utf8Sample = Array.from({ length: 150 }, (_, index) => makeArticle(index).summary).join(" | ")
const utf8SampleBytes = byteLength(utf8Sample)

const findUtf8EndWithTextEncoder = (value: string, offset: number, bytesToRead: number) => {
  let end = offset
  let bytes = 0

  while (end < value.length && bytes < bytesToRead) {
    const codePoint = value.codePointAt(end)
    if (codePoint === undefined) break

    const char = String.fromCodePoint(codePoint)
    bytes += textEncoder.encode(char).length
    end += char.length
  }

  if (bytes !== bytesToRead) throw new Error("Invalid UTF-8 byte length")
  return end
}

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

describe("decodeCompactJson", () => {
  bench("realistic nested JSON value", () => {
    decodeCompactJson(realisticJsonValue)
  })
})

describe("UTF-8 byte scanning", () => {
  bench("TextEncoder per character", () => {
    findUtf8EndWithTextEncoder(utf8Sample, 0, utf8SampleBytes)
  })

  bench("manual byte count", () => {
    findUtf8EndManually(utf8Sample, 0, utf8SampleBytes)
  })
})
