import { describe, expect, it } from "vitest"
import { decodeCompactPatch } from "./compactPatch"

describe("decodeCompactPatch", () => {
  it("decodes scalar add, replace, remove, and nonce operations", () => {
    expect(decodeCompactPatch("n123r6:/countn1:6a8:/items/3s1:dd8:/items/0")).toEqual([
      { op: "replace", path: "/count", value: 6 },
      { op: "add", path: "/items/3", value: "d" },
      { op: "remove", path: "/items/0" },
    ])
  })

  it("decodes caret-encoded JSON values", () => {
    expect(decodeCompactPatch("a5:/rowsJ25:{^id^:3,^name^:^Charlie^}")).toEqual([
      { op: "add", path: "/rows", value: { id: 3, name: "Charlie" } },
    ])
  })

  it("decodes JSON pointer paths", () => {
    expect(decodeCompactPatch("r21:/settings/a~1b~0c|d.es5:value")).toEqual([
      { op: "replace", path: "/settings/a~1b~0c|d.e", value: "value" },
    ])
  })

  it("uses UTF-8 byte lengths for strings and paths", () => {
    expect(decodeCompactPatch("r14:/profile/na.mes10:zażółć")).toEqual([
      { op: "replace", path: "/profile/na.me", value: "zażółć" },
    ])
  })

  it("decodes null, booleans, floats, upsert, and limit", () => {
    expect(decodeCompactPatch("r6:/titlezu6:/itemsJ8:{^id^:1}l6:/itemsn2:-3r5:/flagb0r6:/pricen4:22.5")).toEqual([
      { op: "replace", path: "/title", value: null },
      { op: "upsert", path: "/items", value: { id: 1 } },
      { op: "limit", path: "/items", value: -3 },
      { op: "replace", path: "/flag", value: false },
      { op: "replace", path: "/price", value: 22.5 },
    ])
  })
})
