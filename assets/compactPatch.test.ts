import { describe, expect, it } from "vitest"
import { decodeCompactPatch } from "./compactPatch"

describe("decodeCompactPatch", () => {
  it("decodes scalar add, replace, remove, and nonce operations", () => {
    expect(decodeCompactPatch("n123r5:countn1:6a7:items.3s1:dd7:items.0")).toEqual([
      { op: "replace", path: "/count", value: 6 },
      { op: "add", path: "/items/3", value: "d" },
      { op: "remove", path: "/items/0" },
    ])
  })

  it("decodes base64url JSON values", () => {
    expect(decodeCompactPatch("a4:rowsJ34:eyJpZCI6MywibmFtZSI6IkNoYXJsaWUifQ")).toEqual([
      { op: "add", path: "/rows", value: { id: 3, name: "Charlie" } },
    ])
  })

  it("decodes dot-separated paths back to JSON pointer paths", () => {
    expect(decodeCompactPatch("r21:settings.a~1b~0c|d~2es5:value")).toEqual([
      { op: "replace", path: "/settings/a~1b~0c|d.e", value: "value" },
    ])
  })

  it("uses UTF-8 byte lengths for strings and paths", () => {
    expect(decodeCompactPatch("r14:profile.na~2mes10:zażółć")).toEqual([
      { op: "replace", path: "/profile/na.me", value: "zażółć" },
    ])
  })

  it("decodes null, booleans, floats, upsert, and limit", () => {
    expect(decodeCompactPatch("r5:titlezu5:itemsJ11:eyJpZCI6MX0l5:itemsn2:-3r4:flagb0r5:pricen4:22.5")).toEqual([
      { op: "replace", path: "/title", value: null },
      { op: "upsert", path: "/items", value: { id: 1 } },
      { op: "limit", path: "/items", value: -3 },
      { op: "replace", path: "/flag", value: false },
      { op: "replace", path: "/price", value: 22.5 },
    ])
  })
})
