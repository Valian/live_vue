import { describe, it, expect } from 'vitest'
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
  type TestOperation
} from './jsonPatch'

describe('getValueByPointer', () => {
  const testDoc = {
    foo: 'bar',
    baz: [1, 2, 3],
    nested: {
      key: 'value',
      array: ['a', 'b', 'c']
    },
    'special~key': 'tilde',
    'slash/key': 'slash'
  }

  it('should return root document for empty pointer', () => {
    expect(getValueByPointer(testDoc, '')).toBe(testDoc)
  })

  it('should get simple property', () => {
    expect(getValueByPointer(testDoc, '/foo')).toBe('bar')
  })

  it('should get array element by index', () => {
    expect(getValueByPointer(testDoc, '/baz/1')).toBe(2)
  })

  it('should get last array element with -', () => {
    expect(getValueByPointer(testDoc, '/baz/-')).toBe(3)
  })

  it('should get nested property', () => {
    expect(getValueByPointer(testDoc, '/nested/key')).toBe('value')
  })

  it('should get nested array element', () => {
    expect(getValueByPointer(testDoc, '/nested/array/0')).toBe('a')
  })

  it('should handle escaped tilde characters', () => {
    expect(getValueByPointer(testDoc, '/special~0key')).toBe('tilde')
  })

  it('should handle escaped slash characters', () => {
    expect(getValueByPointer(testDoc, '/slash~1key')).toBe('slash')
  })
})

describe('applyOperation', () => {
  describe('root operations', () => {
    it('should add to root', () => {
      const doc = { foo: 'bar' }
      const op: AddOperation = { op: 'add', path: '', value: { new: 'value' } }
      const result = applyOperation(doc, op)
      expect(result).toEqual({ new: 'value' })
    })

    it('should replace root', () => {
      const doc = { foo: 'bar' }
      const op: ReplaceOperation = { op: 'replace', path: '', value: { new: 'value' } }
      const result = applyOperation(doc, op)
      expect(result).toEqual({ new: 'value' })
    })

    it('should remove root', () => {
      const doc = { foo: 'bar' }
      const op: RemoveOperation = { op: 'remove', path: '' }
      const result = applyOperation(doc, op)
      expect(result).toBeNull()
    })

    it('should move from root', () => {
      const doc = { source: 'value', target: {} }
      const op: MoveOperation = { op: 'move', path: '', from: '/source' }
      const result = applyOperation(doc, op)
      expect(result).toBe('value')
    })

    it('should copy from root', () => {
      const doc = { source: 'value' }
      const op: CopyOperation = { op: 'copy', path: '', from: '/source' }
      const result = applyOperation(doc, op)
      expect(result).toBe('value')
    })

    it('should test root', () => {
      const doc = { foo: 'bar' }
      const op: TestOperation = { op: 'test', path: '', value: { foo: 'bar' } }
      const result = applyOperation(doc, op)
      expect(result).toBe(doc)
    })
  })

  describe('object operations', () => {
    it('should add property to object', () => {
      const doc = { foo: 'bar' }
      const op: AddOperation = { op: 'add', path: '/baz', value: 'qux' }
      applyOperation(doc, op)
      expect(doc).toEqual({ foo: 'bar', baz: 'qux' })
    })

    it('should replace property in object', () => {
      const doc = { foo: 'bar' }
      const op: ReplaceOperation = { op: 'replace', path: '/foo', value: 'baz' }
      applyOperation(doc, op)
      expect(doc).toEqual({ foo: 'baz' })
    })

    it('should remove property from object', () => {
      const doc = { foo: 'bar', baz: 'qux' }
      const op: RemoveOperation = { op: 'remove', path: '/foo' }
      applyOperation(doc, op)
      expect(doc).toEqual({ baz: 'qux' })
    })

    it('should move property within object', () => {
      const doc = { foo: 'bar', baz: 'qux' }
      const op: MoveOperation = { op: 'move', path: '/new', from: '/foo' }
      applyOperation(doc, op)
      expect(doc).toEqual({ baz: 'qux', new: 'bar' })
    })

    it('should copy property within object', () => {
      const doc = { foo: 'bar', baz: 'qux' }
      const op: CopyOperation = { op: 'copy', path: '/new', from: '/foo' }
      applyOperation(doc, op)
      expect(doc).toEqual({ foo: 'bar', baz: 'qux', new: 'bar' })
    })

    it('should handle nested object operations', () => {
      const doc = { nested: { foo: 'bar' } }
      const op: AddOperation = { op: 'add', path: '/nested/baz', value: 'qux' }
      applyOperation(doc, op)
      expect(doc).toEqual({ nested: { foo: 'bar', baz: 'qux' } })
    })
  })

  describe('array operations', () => {
    it('should add element to array at specific index', () => {
      const doc = { arr: [1, 2, 3] }
      const op: AddOperation = { op: 'add', path: '/arr/1', value: 'new' }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 'new', 2, 3] })
    })

    it('should add element to end of array with -', () => {
      const doc = { arr: [1, 2, 3] }
      const op: AddOperation = { op: 'add', path: '/arr/-', value: 'new' }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 2, 3, 'new'] })
    })

    it('should replace element in array', () => {
      const doc = { arr: [1, 2, 3] }
      const op: ReplaceOperation = { op: 'replace', path: '/arr/1', value: 'new' }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 'new', 3] })
    })

    it('should remove element from array', () => {
      const doc = { arr: [1, 2, 3] }
      const op: RemoveOperation = { op: 'remove', path: '/arr/1' }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 3] })
    })

    it('should move element within array', () => {
      const doc = { arr: [1, 2, 3], other: 'value' }
      const op: MoveOperation = { op: 'move', path: '/arr/0', from: '/arr/2' }
      applyOperation(doc, op)
      expect(doc.arr).toEqual([3, 1, 2])
    })

    it('should copy element within array', () => {
      const doc = { arr: [1, 2, 3] }
      const op: CopyOperation = { op: 'copy', path: '/arr/1', from: '/arr/0' }
      applyOperation(doc, op)
      expect(doc).toEqual({ arr: [1, 1, 2, 3] })
    })

    it('should handle move from object to array', () => {
      const doc = { obj: { foo: 'bar' }, arr: [1, 2] }
      const op: MoveOperation = { op: 'move', path: '/arr/1', from: '/obj/foo' }
      applyOperation(doc, op)
      expect(doc).toEqual({ obj: {}, arr: [1, 'bar', 2] })
    })
  })

  describe('escaped characters', () => {
    it('should handle tilde in property names', () => {
      const doc = { 'key~with~tilde': 'value' }
      const op: ReplaceOperation = { op: 'replace', path: '/key~0with~0tilde', value: 'new' }
      applyOperation(doc, op)
      expect(doc).toEqual({ 'key~with~tilde': 'new' })
    })

    it('should handle slash in property names', () => {
      const doc = { 'key/with/slash': 'value' }
      const op: ReplaceOperation = { op: 'replace', path: '/key~1with~1slash', value: 'new' }
      applyOperation(doc, op)
      expect(doc).toEqual({ 'key/with/slash': 'new' })
    })
  })

  describe('deep cloning in copy operations', () => {
    it('should deep clone objects when copying', () => {
      const doc = { source: { nested: { value: 'test' } }, target: {} }
      const op: CopyOperation = { op: 'copy', path: '/target/copy', from: '/source' }
      applyOperation(doc, op)
      
      // Modify the original
      doc.source.nested.value = 'modified'
      
      // Copy should remain unchanged
      expect(doc.target.copy.nested.value).toBe('test')
    })

    it('should deep clone arrays when copying', () => {
      const doc = { source: [{ value: 'test' }], target: [] }
      const op: CopyOperation = { op: 'copy', path: '/target/0', from: '/source/0' }
      applyOperation(doc, op)
      
      // Modify the original
      doc.source[0].value = 'modified'
      
      // Copy should remain unchanged
      expect(doc.target[0].value).toBe('test')
    })
  })
})

describe('applyPatch', () => {
  it('should apply multiple operations in sequence', () => {
    const doc = { foo: 'bar', arr: [1, 2, 3] }
    const patch: Operation[] = [
      { op: 'add', path: '/baz', value: 'qux' },
      { op: 'replace', path: '/foo', value: 'updated' },
      { op: 'add', path: '/arr/-', value: 4 },
      { op: 'remove', path: '/arr/0' }
    ]
    
    const result = applyPatch(doc, patch)
    
    expect(result).toBe(doc) // Should modify in place
    expect(doc).toEqual({
      foo: 'updated',
      baz: 'qux',
      arr: [2, 3, 4]
    })
  })

  it('should handle complex patch with nested operations', () => {
    const doc = {
      users: [
        { id: 1, name: 'John', active: true },
        { id: 2, name: 'Jane', active: false }
      ],
      settings: { theme: 'light' }
    }
    
    const patch: Operation[] = [
      { op: 'replace', path: '/users/0/name', value: 'Johnny' },
      { op: 'add', path: '/users/-', value: { id: 3, name: 'Bob', active: true } },
      { op: 'replace', path: '/settings/theme', value: 'dark' },
      { op: 'add', path: '/settings/notifications', value: true }
    ]
    
    applyPatch(doc, patch)
    
    expect(doc).toEqual({
      users: [
        { id: 1, name: 'Johnny', active: true },
        { id: 2, name: 'Jane', active: false },
        { id: 3, name: 'Bob', active: true }
      ],
      settings: { theme: 'dark', notifications: true }
    })
  })

  it('should handle move operations that affect subsequent operations', () => {
    const doc = { a: 1, b: 2, c: 3 }
    const patch: Operation[] = [
      { op: 'move', path: '/d', from: '/a' },
      { op: 'add', path: '/a', value: 10 }
    ]
    
    applyPatch(doc, patch)
    
    expect(doc).toEqual({ b: 2, c: 3, d: 1, a: 10 })
  })

  it('should return the modified document', () => {
    const doc = { foo: 'bar' }
    const patch: Operation[] = [{ op: 'add', path: '/baz', value: 'qux' }]
    
    const result = applyPatch(doc, patch)
    
    expect(result).toBe(doc)
    expect(result).toEqual({ foo: 'bar', baz: 'qux' })
  })

  it('should handle empty patch', () => {
    const doc = { foo: 'bar' }
    const patch: Operation[] = []
    
    const result = applyPatch(doc, patch)
    
    expect(result).toBe(doc)
    expect(result).toEqual({ foo: 'bar' })
  })
})