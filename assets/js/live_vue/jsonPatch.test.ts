import { describe, it, expect, vi } from "vitest"
import {
  getValueByPointer,
  applyOperation,
  applyPatch,
  type Operation,
  type AddOperation,
  type RemoveOperation,
  type ReplaceOperation,
  type MoveOperation,
  type CopyOperation,
  type TestOperation,
  type UpsertOperation,
  type LimitOperation,
} from "./jsonPatch"

describe("getValueByPointer", () => {
  const testDoc = {
    foo: "bar",
    baz: [1, 2, 3],
    nested: {
      key: "value",
      array: ["a", "b", "c"],
    },
    "special~key": "tilde",
    "slash/key": "slash",
  }

  it("should return root document for empty pointer", () => {
    expect(getValueByPointer(testDoc, "")).toBe(testDoc)
  })

  it("should get simple property", () => {
    expect(getValueByPointer(testDoc, "/foo")).toBe("bar")
  })

  it("should get array element by index", () => {
    expect(getValueByPointer(testDoc, "/baz/1")).toBe(2)
  })

  it("should get last array element with -", () => {
    expect(getValueByPointer(testDoc, "/baz/-")).toBe(3)
  })

  it("should get nested property", () => {
    expect(getValueByPointer(testDoc, "/nested/key")).toBe("value")
  })

  it("should get nested array element", () => {
    expect(getValueByPointer(testDoc, "/nested/array/0")).toBe("a")
  })

  it("should handle escaped tilde characters", () => {
    expect(getValueByPointer(testDoc, "/special~0key")).toBe("tilde")
  })

  it("should handle escaped slash characters", () => {
    expect(getValueByPointer(testDoc, "/slash~1key")).toBe("slash")
  })
})

describe("applyOperation", () => {
  describe("root operations", () => {
    it("should add to root", () => {
      const doc = { foo: "bar" }
      const op: AddOperation = { op: "add", path: "", value: { new: "value" } }
      const result = applyOperation(doc, op)
      expect(result).toEqual({ new: "value" })
    })

    it("should replace root", () => {
      const doc = { foo: "bar" }
      const op: ReplaceOperation = { op: "replace", path: "", value: { new: "value" } }
      const result = applyOperation(doc, op)
      expect(result).toEqual({ new: "value" })
    })

    it("should remove root", () => {
      const doc = { foo: "bar" }
      const op: RemoveOperation = { op: "remove", path: "" }
      const result = applyOperation(doc, op)
      expect(result).toBeNull()
    })

    it("should move from root", () => {
      const doc = { source: "value", target: {} }
      const op: MoveOperation = { op: "move", path: "", from: "/source" }
      const result = applyOperation(doc, op)
      expect(result).toBe("value")
    })

    it("should copy from root", () => {
      const doc = { source: "value" }
      const op: CopyOperation = { op: "copy", path: "", from: "/source" }
      const result = applyOperation(doc, op)
      expect(result).toBe("value")
    })

    it("should test root", () => {
      const doc = { foo: "bar" }
      const op: TestOperation = { op: "test", path: "", value: { foo: "bar" } }
      const result = applyOperation(doc, op)
      expect(result).toBe(doc)
    })
  })

  describe("object operations", () => {
    it("should add property to object", () => {
      const doc = { foo: "bar" }
      const op: AddOperation = { op: "add", path: "/baz", value: "qux" }
      applyOperation(doc, op)
      expect(doc).toEqual({ foo: "bar", baz: "qux" })
    })

    it("should replace property in object", () => {
      const doc = { foo: "bar" }
      const op: ReplaceOperation = { op: "replace", path: "/foo", value: "baz" }
      applyOperation(doc, op)
      expect(doc).toEqual({ foo: "baz" })
    })

    it("should remove property from object", () => {
      const doc = { foo: "bar", baz: "qux" }
      const op: RemoveOperation = { op: "remove", path: "/foo" }
      applyOperation(doc, op)
      expect(doc).toEqual({ baz: "qux" })
    })

    it("should move property within object", () => {
      const doc = { foo: "bar", baz: "qux" }
      const op: MoveOperation = { op: "move", path: "/new", from: "/foo" }
      applyOperation(doc, op)
      expect(doc).toEqual({ baz: "qux", new: "bar" })
    })

    it("should copy property within object", () => {
      const doc = { foo: "bar", baz: "qux" }
      const op: CopyOperation = { op: "copy", path: "/new", from: "/foo" }
      applyOperation(doc, op)
      expect(doc).toEqual({ foo: "bar", baz: "qux", new: "bar" })
    })

    it("should handle nested object operations", () => {
      const doc = { nested: { foo: "bar" } }
      const op: AddOperation = { op: "add", path: "/nested/baz", value: "qux" }
      applyOperation(doc, op)
      expect(doc).toEqual({ nested: { foo: "bar", baz: "qux" } })
    })
  })

  describe("array operations", () => {
    it("should add element to array at specific index", () => {
      const doc = { arr: [1, 2, 3] }
      const op: AddOperation = { op: "add", path: "/arr/1", value: "new" }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, "new", 2, 3] })
    })

    it("should add element to end of array with -", () => {
      const doc = { arr: [1, 2, 3] }
      const op: AddOperation = { op: "add", path: "/arr/-", value: "new" }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 2, 3, "new"] })
    })

    it("should replace element in array", () => {
      const doc = { arr: [1, 2, 3] }
      const op: ReplaceOperation = { op: "replace", path: "/arr/1", value: "new" }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, "new", 3] })
    })

    it("should remove element from array", () => {
      const doc = { arr: [1, 2, 3] }
      const op: RemoveOperation = { op: "remove", path: "/arr/1" }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 3] })
    })

    it("should move element within array", () => {
      const doc = { arr: [1, 2, 3], other: "value" }
      const op: MoveOperation = { op: "move", path: "/arr/0", from: "/arr/2" }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([3, 1, 2])
    })

    it("should copy element within array", () => {
      const doc = { arr: [1, 2, 3] }
      const op: CopyOperation = { op: "copy", path: "/arr/1", from: "/arr/0" }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 1, 2, 3] })
    })

    it("should handle move from object to array", () => {
      const doc = { obj: { foo: "bar" }, arr: [1, 2] }
      const op: MoveOperation = { op: "move", path: "/arr/1", from: "/obj/foo" }
      applyOperation(doc, op)
      expect(doc).toEqual({ obj: {}, arr: [1, "bar", 2] })
    })
  })

  describe("escaped characters", () => {
    it("should handle tilde in property names", () => {
      const doc = { "key~with~tilde": "value" }
      const op: ReplaceOperation = { op: "replace", path: "/key~0with~0tilde", value: "new" }
      applyOperation(doc, op)
      expect(doc).toEqual({ "key~with~tilde": "new" })
    })

    it("should handle slash in property names", () => {
      const doc = { "key/with/slash": "value" }
      const op: ReplaceOperation = { op: "replace", path: "/key~1with~1slash", value: "new" }
      applyOperation(doc, op)
      expect(doc).toEqual({ "key/with/slash": "new" })
    })
  })

  describe("deep cloning in copy operations", () => {
    it("should deep clone objects when copying", () => {
      const doc = { source: { nested: { value: "test" } }, target: {} }
      const op: CopyOperation = { op: "copy", path: "/target/copy", from: "/source" }
      applyOperation(doc, op)

      // Modify the original
      doc.source.nested.value = "modified"

      // Copy should remain unchanged
      expect((doc.target as any).copy.nested.value).toBe("test")
    })

    it("should deep clone arrays when copying", () => {
      const doc = { source: [{ value: "test" }], target: [] }
      const op: CopyOperation = { op: "copy", path: "/target/0", from: "/source/0" }
      applyOperation(doc, op)

      // Modify the original
      doc.source[0].value = "modified"

      // Copy should remain unchanged
      expect((doc.target[0] as any).value).toBe("test")
    })
  })
})

describe("applyPatch", () => {
  it("should apply multiple operations in sequence", () => {
    const doc = { foo: "bar", arr: [1, 2, 3] }
    const patch: Operation[] = [
      { op: "add", path: "/baz", value: "qux" },
      { op: "replace", path: "/foo", value: "updated" },
      { op: "add", path: "/arr/-", value: 4 },
      { op: "remove", path: "/arr/0" },
    ]

    const result = applyPatch(doc, patch)

    expect(result).toBe(doc) // Should modify in place
    expect(doc).toEqual({
      foo: "updated",
      baz: "qux",
      arr: [2, 3, 4],
    })
  })

  it("should handle complex patch with nested operations", () => {
    const doc = {
      users: [
        { __dom_id: 1, name: "John", active: true },
        { __dom_id: 2, name: "Jane", active: false },
      ],
      settings: { theme: "light" },
    }

    const patch: Operation[] = [
      { op: "replace", path: "/users/0/name", value: "Johnny" },
      { op: "add", path: "/users/-", value: { __dom_id: 3, name: "Bob", active: true } },
      { op: "replace", path: "/settings/theme", value: "dark" },
      { op: "add", path: "/settings/notifications", value: true },
    ]

    applyPatch(doc, patch)

    expect(doc).toEqual({
      users: [
        { __dom_id: 1, name: "Johnny", active: true },
        { __dom_id: 2, name: "Jane", active: false },
        { __dom_id: 3, name: "Bob", active: true },
      ],
      settings: { theme: "dark", notifications: true },
    })
  })

  it("should handle move operations that affect subsequent operations", () => {
    const doc = { a: 1, b: 2, c: 3 }
    const patch: Operation[] = [
      { op: "move", path: "/d", from: "/a" },
      { op: "add", path: "/a", value: 10 },
    ]

    applyPatch(doc, patch)

    expect(doc).toEqual({ b: 2, c: 3, d: 1, a: 10 })
  })

  it("should return the modified document", () => {
    const doc = { foo: "bar" }
    const patch: Operation[] = [{ op: "add", path: "/baz", value: "qux" }]

    const result = applyPatch(doc, patch)

    expect(result).toBe(doc)
    expect(result).toEqual({ foo: "bar", baz: "qux" })
  })

  it("should handle empty patch", () => {
    const doc = { foo: "bar" }
    const patch: Operation[] = []

    const result = applyPatch(doc, patch)

    expect(result).toBe(doc)
    expect(result).toEqual({ foo: "bar" })
  })
})

describe("special path syntax ($$__dom_id)", () => {
  const testDoc = {
    items: [
      { __dom_id: 1, name: "Item 1", value: 10 },
      { __dom_id: 2, name: "Item 2", value: 20 },
      { __dom_id: 3, name: "Item 3", value: 30 },
    ],
    users: [
      { __dom_id: "user1", email: "user1@example.com", active: true },
      { __dom_id: "user2", email: "user2@example.com", active: false },
    ],
  }

  describe("replace operations", () => {
    it("should replace item by __dom_id", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: ReplaceOperation = {
        op: "replace",
        path: "/items/$$2",
        value: { __dom_id: 2, name: "Updated Item 2", value: 25 },
      }

      applyOperation(doc, op)

      expect(doc.items[1]).toEqual({ __dom_id: 2, name: "Updated Item 2", value: 25 })
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1", value: 10 })
      expect(doc.items[2]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
    })

    it("should replace nested property by __dom_id", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: ReplaceOperation = {
        op: "replace",
        path: "/items/$$1/name",
        value: "Updated Name",
      }

      applyOperation(doc, op)

      expect(doc.items[0].name).toBe("Updated Name")
      expect(doc.items[0].__dom_id).toBe(1)
      expect(doc.items[0].value).toBe(10)
    })

    it("should handle string __dom_ids", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: ReplaceOperation = {
        op: "replace",
        path: "/users/$$user2/active",
        value: true,
      }

      applyOperation(doc, op)

      expect(doc.users[1].active).toBe(true)
      expect(doc.users[1].__dom_id).toBe("user2")
    })

    it("should log warning and skip operation when __dom_id not found", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const consoleSpy = vi.spyOn(console, "warn").mockImplementation(() => {})

      const op: ReplaceOperation = {
        op: "replace",
        path: "/items/$$999",
        value: { __dom_id: 999, name: "Non-existent" },
      }

      applyOperation(doc, op)

      expect(consoleSpy).toHaveBeenCalledWith(
        'JSON Patch: Item with __dom_id "999" not found in array, skipping operation'
      )
      expect(doc.items).toHaveLength(3)
      expect(doc.items).toEqual(testDoc.items)

      consoleSpy.mockRestore()
    })
  })

  describe("remove operations", () => {
    it("should remove item by __dom_id", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: RemoveOperation = {
        op: "remove",
        path: "/items/$$2",
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(2)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1", value: 10 })
      expect(doc.items[1]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
    })

    it("should log warning and skip when removing non-existent __dom_id", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const consoleSpy = vi.spyOn(console, "warn").mockImplementation(() => {})

      const op: RemoveOperation = {
        op: "remove",
        path: "/items/$$999",
      }

      applyOperation(doc, op)

      expect(consoleSpy).toHaveBeenCalledWith(
        'JSON Patch: Item with __dom_id "999" not found in array, skipping operation'
      )
      expect(doc.items).toHaveLength(3)

      consoleSpy.mockRestore()
    })
  })

  describe("move operations", () => {
    it("should move item by __dom_id within same array", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: MoveOperation = {
        op: "move",
        path: "/items/0",
        from: "/items/$$3",
      }

      applyOperation(doc, op)

      expect(doc.items[0]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
      expect(doc.items[1]).toEqual({ __dom_id: 1, name: "Item 1", value: 10 })
      expect(doc.items[2]).toEqual({ __dom_id: 2, name: "Item 2", value: 20 })
    })

    it("should move item by __dom_id to different array", () => {
      const doc = {
        source: [
          { __dom_id: "a", data: "first" },
          { __dom_id: "b", data: "second" },
        ],
        target: [],
      }

      const op: MoveOperation = {
        op: "move",
        path: "/target/0",
        from: "/source/$$b",
      }

      applyOperation(doc, op)

      expect(doc.source).toHaveLength(1)
      expect(doc.source[0]).toEqual({ __dom_id: "a", data: "first" })
      expect(doc.target).toHaveLength(1)
      expect(doc.target[0]).toEqual({ __dom_id: "b", data: "second" })
    })

    it("should log warning and skip when moving from non-existent __dom_id", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const consoleSpy = vi.spyOn(console, "warn").mockImplementation(() => {})

      const op: MoveOperation = {
        op: "move",
        path: "/items/0",
        from: "/items/$$999",
      }

      applyOperation(doc, op)

      expect(consoleSpy).toHaveBeenCalledWith(
        'JSON Patch: Item with __dom_id "999" not found in array, skipping operation'
      )
      expect(doc.items).toEqual(testDoc.items)

      consoleSpy.mockRestore()
    })
  })

  describe("mixed operations with special paths", () => {
    it("should handle patch with both regular and special path operations", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const patch: Operation[] = [
        { op: "replace", path: "/items/$$1/value", value: 15 },
        { op: "add", path: "/items/-", value: { __dom_id: 4, name: "Item 4", value: 40 } },
        { op: "remove", path: "/items/$$3" },
        { op: "replace", path: "/users/0/email", value: "newemail@example.com" },
      ]

      applyPatch(doc, patch)

      expect(doc.items).toHaveLength(3)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1", value: 15 })
      expect(doc.items[1]).toEqual({ __dom_id: 2, name: "Item 2", value: 20 })
      expect(doc.items[2]).toEqual({ __dom_id: 4, name: "Item 4", value: 40 })
      expect(doc.users[0].email).toBe("newemail@example.com")
    })
  })

  describe("edge cases", () => {
    it("should handle arrays with objects missing __dom_id property", () => {
      const doc = {
        mixed: [
          { __dom_id: 1, name: "Has __dom_id" },
          { name: "No __dom_id" },
          { __dom_id: 2, name: "Also has __dom_id" },
        ],
      }

      const consoleSpy = vi.spyOn(console, "warn").mockImplementation(() => {})

      const op: ReplaceOperation = {
        op: "replace",
        path: "/mixed/$$2/name",
        value: "Updated",
      }

      applyOperation(doc, op)

      expect(doc.mixed[2].name).toBe("Updated")
      expect(consoleSpy).not.toHaveBeenCalled()

      consoleSpy.mockRestore()
    })

    it("should handle empty arrays", () => {
      const doc = { empty: [] }
      const consoleSpy = vi.spyOn(console, "warn").mockImplementation(() => {})

      const op: ReplaceOperation = {
        op: "replace",
        path: "/empty/$$1",
        value: { __dom_id: 1 },
      }

      applyOperation(doc, op)

      expect(consoleSpy).toHaveBeenCalledWith(
        'JSON Patch: Item with __dom_id "1" not found in array, skipping operation'
      )
      expect(doc.empty).toHaveLength(0)

      consoleSpy.mockRestore()
    })
  })
})

describe("upsert operation", () => {
  const testDoc = {
    items: [
      { __dom_id: 1, name: "Item 1", value: 10 },
      { __dom_id: 2, name: "Item 2", value: 20 },
      { __dom_id: 3, name: "Item 3", value: 30 },
    ],
    users: [
      { __dom_id: "user1", email: "user1@example.com", active: true },
      { __dom_id: "user2", email: "user2@example.com", active: false },
    ],
  }

  describe("update existing items", () => {
    it("should update existing item by __dom_id (numeric)", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/0",
        value: { __dom_id: 2, name: "Updated Item 2", value: 25 },
      }

      applyOperation(doc, op)

      // Should update the existing item with __dom_id=2 (at index 1), not insert at index 0
      expect(doc.items).toHaveLength(3)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1", value: 10 })
      expect(doc.items[1]).toEqual({ __dom_id: 2, name: "Updated Item 2", value: 25 })
      expect(doc.items[2]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
    })

    it("should update existing item by __dom_id (string)", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: UpsertOperation = {
        op: "upsert",
        path: "/users/0",
        value: { __dom_id: "user2", email: "updated@example.com", active: true },
      }

      applyOperation(doc, op)

      // Should update the existing item with __dom_id='user2' (at index 1)
      expect(doc.users).toHaveLength(2)
      expect(doc.users[0]).toEqual({ __dom_id: "user1", email: "user1@example.com", active: true })
      expect(doc.users[1]).toEqual({ __dom_id: "user2", email: "updated@example.com", active: true })
    })
  })

  describe("insert new items", () => {
    it("should insert new item at specified index when __dom_id does not exist", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/1",
        value: { __dom_id: 4, name: "New Item 4", value: 40 },
      }

      applyOperation(doc, op)

      // Should insert at index 1
      expect(doc.items).toHaveLength(4)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1", value: 10 })
      expect(doc.items[1]).toEqual({ __dom_id: 4, name: "New Item 4", value: 40 })
      expect(doc.items[2]).toEqual({ __dom_id: 2, name: "Item 2", value: 20 })
      expect(doc.items[3]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
    })

    it("should append new item when using index -1", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/-",
        value: { __dom_id: 4, name: "New Item 4", value: 40 },
      }

      applyOperation(doc, op)

      // Should append to the end
      expect(doc.items).toHaveLength(4)
      expect(doc.items[3]).toEqual({ __dom_id: 4, name: "New Item 4", value: 40 })
    })

    it("should insert at end when index equals array length", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/3",
        value: { __dom_id: 4, name: "New Item 4", value: 40 },
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(4)
      expect(doc.items[3]).toEqual({ __dom_id: 4, name: "New Item 4", value: 40 })
    })
  })

  describe("edge cases", () => {
    it("should handle items without __dom_id property by inserting at index", () => {
      const doc = { items: [{ name: "No __dom_id" }] }
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/0",
        value: { name: "Also no __dom_id" },
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(2)
      expect(doc.items[0]).toEqual({ name: "Also no __dom_id" })
      expect(doc.items[1]).toEqual({ name: "No __dom_id" })
    })

    it("should handle null/undefined values by inserting at index", () => {
      const doc = { items: [{ __dom_id: 1, name: "Item 1" }] }
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/0",
        value: null,
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(2)
      expect(doc.items[0]).toBeNull()
      expect(doc.items[1]).toEqual({ __dom_id: 1, name: "Item 1" })
    })

    it("should handle primitive values by inserting at index", () => {
      const doc = { items: [{ __dom_id: 1, name: "Item 1" }] }
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/1",
        value: "primitive string",
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(2)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1" })
      expect(doc.items[1]).toBe("primitive string")
    })

    it("should handle empty arrays", () => {
      const doc = { items: [] }
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/0",
        value: { __dom_id: 1, name: "First Item" },
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(1)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "First Item" })
    })
  })

  describe("complex scenarios", () => {
    it("should handle multiple upsert operations in sequence", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const patch: Operation[] = [
        { op: "upsert", path: "/items/0", value: { __dom_id: 2, name: "Updated Item 2", value: 25 } },
        { op: "upsert", path: "/items/-", value: { __dom_id: 4, name: "New Item 4", value: 40 } },
        { op: "upsert", path: "/items/1", value: { __dom_id: 1, name: "Updated Item 1", value: 15 } },
      ]

      applyPatch(doc, patch)

      expect(doc.items).toHaveLength(4)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Updated Item 1", value: 15 })
      expect(doc.items[1]).toEqual({ __dom_id: 2, name: "Updated Item 2", value: 25 })
      expect(doc.items[2]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
      expect(doc.items[3]).toEqual({ __dom_id: 4, name: "New Item 4", value: 40 })
    })

    it("should work correctly with mixed operation types", () => {
      const doc = JSON.parse(JSON.stringify(testDoc))
      const patch: Operation[] = [
        { op: "upsert", path: "/items/0", value: { __dom_id: 4, name: "New Item 4", value: 40 } },
        { op: "remove", path: "/items/$$2" },
        { op: "upsert", path: "/items/1", value: { __dom_id: 1, name: "Updated Item 1", value: 15 } },
      ]

      applyPatch(doc, patch)

      expect(doc.items).toHaveLength(3)
      expect(doc.items[0]).toEqual({ __dom_id: 4, name: "New Item 4", value: 40 })
      expect(doc.items[1]).toEqual({ __dom_id: 1, name: "Updated Item 1", value: 15 })
      expect(doc.items[2]).toEqual({ __dom_id: 3, name: "Item 3", value: 30 })
    })
  })

  describe("stream-like scenarios", () => {
    it("should simulate Phoenix LiveView stream behavior - insert new", () => {
      const doc = {
        items: [
          { __dom_id: 1, name: "Item 1" },
          { __dom_id: 2, name: "Item 2" },
        ],
      }

      // Simulate stream_insert with new item at position 1
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/1",
        value: { __dom_id: 3, name: "Item 3" },
      }

      applyOperation(doc, op)

      expect(doc.items).toHaveLength(3)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1" })
      expect(doc.items[1]).toEqual({ __dom_id: 3, name: "Item 3" })
      expect(doc.items[2]).toEqual({ __dom_id: 2, name: "Item 2" })
    })

    it("should simulate Phoenix LiveView stream behavior - update existing", () => {
      const doc = {
        items: [
          { __dom_id: 1, name: "Item 1" },
          { __dom_id: 2, name: "Item 2" },
        ],
      }

      // Simulate stream_insert trying to insert at position 0, but item with __dom_id=2 already exists
      const op: UpsertOperation = {
        op: "upsert",
        path: "/items/0",
        value: { __dom_id: 2, name: "Updated Item 2" },
      }

      applyOperation(doc, op)

      // Should update existing item, not insert at position 0
      expect(doc.items).toHaveLength(2)
      expect(doc.items[0]).toEqual({ __dom_id: 1, name: "Item 1" })
      expect(doc.items[1]).toEqual({ __dom_id: 2, name: "Updated Item 2" })
    })
  })
})

describe("limit operation", () => {
  describe("positive limits (keep from start)", () => {
    it("should keep first 2 elements from array of 5", () => {
      const doc = { arr: [1, 2, 3, 4, 5] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 2 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([1, 2])
    })

    it("should keep first 1 element from array of 3", () => {
      const doc = { arr: ["a", "b", "c"] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 1 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual(["a"])
    })

    it("should not modify array when limit equals array length", () => {
      const doc = { arr: [1, 2, 3] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 3 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([1, 2, 3])
    })

    it("should not modify array when limit exceeds array length", () => {
      const doc = { arr: [1, 2] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 5 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([1, 2])
    })

    it("should empty array when limit is 0", () => {
      const doc = { arr: [1, 2, 3] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 0 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([])
    })
  })

  describe("negative limits (keep from end)", () => {
    it("should keep last 2 elements from array of 5", () => {
      const doc = { arr: [1, 2, 3, 4, 5] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: -2 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([4, 5])
    })

    it("should keep last 1 element from array of 3", () => {
      const doc = { arr: ["a", "b", "c"] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: -1 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual(["c"])
    })

    it("should not modify array when negative limit equals array length", () => {
      const doc = { arr: [1, 2, 3] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: -3 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([1, 2, 3])
    })

    it("should not modify array when negative limit exceeds array length", () => {
      const doc = { arr: [1, 2] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: -5 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([1, 2])
    })
  })

  describe("nested array limits", () => {
    it("should limit nested array with positive value", () => {
      const doc = { nested: { items: [1, 2, 3, 4, 5] } }
      const op: LimitOperation = { op: "limit", path: "/nested/items", value: 3 }
      applyOperation(doc, op)
      expect(doc.nested.items).toEqual([1, 2, 3])
    })

    it("should limit nested array with negative value", () => {
      const doc = { nested: { items: [1, 2, 3, 4, 5] } }
      const op: LimitOperation = { op: "limit", path: "/nested/items", value: -2 }
      applyOperation(doc, op)
      expect(doc.nested.items).toEqual([4, 5])
    })
  })

  describe("complex object arrays", () => {
    it("should limit array of objects with positive value", () => {
      const doc = {
        users: [
          { __dom_id: 1, name: "Alice" },
          { __dom_id: 2, name: "Bob" },
          { __dom_id: 3, name: "Charlie" },
          { __dom_id: 4, name: "David" },
        ],
      }
      const op: LimitOperation = { op: "limit", path: "/users", value: 2 }
      applyOperation(doc, op)
      expect(doc.users).toEqual([
        { __dom_id: 1, name: "Alice" },
        { __dom_id: 2, name: "Bob" },
      ])
    })

    it("should limit array of objects with negative value", () => {
      const doc = {
        users: [
          { __dom_id: 1, name: "Alice" },
          { __dom_id: 2, name: "Bob" },
          { __dom_id: 3, name: "Charlie" },
          { __dom_id: 4, name: "David" },
        ],
      }
      const op: LimitOperation = { op: "limit", path: "/users", value: -2 }
      applyOperation(doc, op)
      expect(doc.users).toEqual([
        { __dom_id: 3, name: "Charlie" },
        { __dom_id: 4, name: "David" },
      ])
    })
  })

  describe("edge cases", () => {
    it("should handle empty arrays", () => {
      const doc = { arr: [] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 3 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([])
    })

    it("should handle single element arrays with positive limit", () => {
      const doc = { arr: ["only"] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 5 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual(["only"])
    })

    it("should handle single element arrays with negative limit", () => {
      const doc = { arr: ["only"] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: -5 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual(["only"])
    })

    it("should handle zero limit on empty array", () => {
      const doc = { arr: [] }
      const op: LimitOperation = { op: "limit", path: "/arr", value: 0 }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([])
    })
  })

  describe("patch sequences with limit operations", () => {
    it("should work with other operations in sequence", () => {
      const doc = { arr: [1, 2, 3, 4, 5] }
      const patch: Operation[] = [
        { op: "add", path: "/arr/-", value: 6 },
        { op: "limit", path: "/arr", value: 3 },
      ]
      applyPatch(doc, patch)
      expect(doc.arr).toEqual([1, 2, 3])
    })

    it("should work when applied after other modifications", () => {
      const doc = { arr: [1, 2, 3] }
      const patch: Operation[] = [
        { op: "add", path: "/arr/0", value: 0 },
        { op: "add", path: "/arr/-", value: 4 },
        { op: "add", path: "/arr/-", value: 5 },
        { op: "limit", path: "/arr", value: -2 },
      ]
      applyPatch(doc, patch)
      expect(doc.arr).toEqual([4, 5])
    })

    it("should handle multiple limit operations", () => {
      const doc = { arr: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }
      const patch: Operation[] = [
        { op: "limit", path: "/arr", value: 7 }, // Keep first 7: [1,2,3,4,5,6,7]
        { op: "limit", path: "/arr", value: -4 }, // Keep last 4: [4,5,6,7]
      ]
      applyPatch(doc, patch)
      expect(doc.arr).toEqual([4, 5, 6, 7])
    })
  })
})
