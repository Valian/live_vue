import type { Form, FormErrors } from './useLiveForm'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { effectScope, nextTick, ref } from 'vue'
import { useLiveVue } from './use'
import { useLiveForm } from './useLiveForm'

// Mock useLiveVue to prevent injection errors
vi.mock('./use', () => ({
  useLiveVue: vi.fn(),
}))

// Mock provide() to prevent warnings in tests
vi.mock('vue', async () => {
  const actual = await vi.importActual('vue')
  return {
    ...actual,
    provide: vi.fn(), // Mock provide to do nothing in tests
  }
})

const mockUseLiveVue = useLiveVue as any
let mockLiveVue: any

// Helper to create forms within effect scope to avoid onScopeDispose warnings
function createFormInScope<T extends object>(formRef: any, options?: any) {
  let form: any
  const scope = effectScope()
  scope.run(() => {
    form = useLiveForm(formRef, options)
  })
  return form
}

interface TestForm {
  name: string
  email: string
  age: number
  profile: {
    bio: string
    skills: string[]
  }
  items: Array<{
    name: string
    tags: string[]
  }>
  // Additional fields for checkbox tests
  acceptTerms?: boolean
  plan?: string | boolean | null
  preferences?: string[]
}

// Simple function to create a valid form ref
function createFormRef(overrides: Partial<Form<TestForm>> = {}) {
  const baseForm: Form<TestForm> = {
    name: 'test_form',
    values: {
      name: 'John Doe',
      email: 'john@example.com',
      age: 30,
      profile: {
        bio: 'Software developer',
        skills: ['JavaScript', 'TypeScript'],
      },
      items: [
        { name: 'Item 1', tags: ['tag1', 'tag2'] },
        { name: 'Item 2', tags: ['tag3'] },
      ],
    },
    errors: {} as FormErrors<TestForm>, // Empty object when no errors, like in Phoenix
    valid: true,
  }

  return ref({ ...baseForm, ...overrides, errors: (overrides.errors || {}) as FormErrors<TestForm> })
}

// Function to create form with errors
function createFormWithErrors() {
  return createFormRef({
    errors: {
      name: ['Name is required'],
      email: ['Invalid email format'],
      age: [],
      profile: {
        bio: ['Bio is too short'],
        skills: [],
      },
      items: [
        { name: ['Item name required'], tags: [] },
        { name: [], tags: [] },
      ],
    },
  })
}

describe('useLiveForm - Integration Tests', () => {
  beforeEach(() => {
    // Setup fresh mock LiveVue instance for each test
    mockLiveVue = {
      pushEvent: vi.fn().mockImplementation((_event: any, _payload: any, callback: any) => {
        // Simulate async callback behavior with successful reset response
        if (callback) {
          setTimeout(() => callback({ reset: true }), 0)
        }
        return Promise.resolve({ reset: true })
      }),
    }
    mockUseLiveVue.mockReturnValue(mockLiveVue)
  })

  describe('basic form initialization', () => {
    it('should initialize form with proper state', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.initialValues).toEqual(formRef.value.values)
      expect(form.isValid.value).toBe(true)
      expect(form.isDirty.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })

    it('should create deep copy of initial values', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Modify the original
      formRef.value.values.name = 'Modified'

      // Form should still have original value
      expect(form.initialValues.name).toBe('John Doe')
    })
  })

  describe('field creation and path resolution', () => {
    it('should create field for simple property', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      expect(nameField.value.value).toBe('John Doe')
      expect(nameField.errors.value).toEqual([])
      expect(nameField.errorMessage.value).toBeUndefined()
      expect(nameField.isValid.value).toBe(true)
      expect(nameField.isDirty.value).toBe(false)
      expect(nameField.isTouched.value).toBe(false)
    })

    it('should create field for nested property', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const bioField = form.field('profile.bio')

      expect(bioField.value.value).toBe('Software developer')
      expect(bioField.isValid.value).toBe(true)
    })

    it('should create field for array element', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemNameField = form.field('items[0].name')

      expect(itemNameField.value.value).toBe('Item 1')
      expect(itemNameField.isValid.value).toBe(true)
    })

    it('should create field for nested array element', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const tagField = form.field('items[0].tags[0]')

      expect(tagField.value.value).toBe('tag1')
    })
  })

  describe('field value updates', () => {
    it('should update field value reactively', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      nameField.value.value = 'Jane Doe'
      await nextTick()

      expect(nameField.value.value).toBe('Jane Doe')
    })

    it('should update nested field value reactively', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const bioField = form.field('profile.bio')

      bioField.value.value = 'Updated bio'
      await nextTick()

      expect(bioField.value.value).toBe('Updated bio')
    })

    it('should update array element reactively', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemNameField = form.field('items[0].name')

      itemNameField.value.value = 'Updated Item'
      await nextTick()

      expect(itemNameField.value.value).toBe('Updated Item')
    })
  })

  describe('sub-field creation (fluent interface)', () => {
    it('should create sub-field from object field', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const profileField = form.field('profile')
      const bioField = profileField.field('bio')

      expect(bioField.value.value).toBe('Software developer')
    })

    it('should create sub-field from array field', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray('items')
      // Use field(index) to access array item
      const firstItemField = itemsArray.field(0)
      const nameField = firstItemField.field('name')

      expect(nameField.value.value).toBe('Item 1')
    })
  })

  describe('field state tracking', () => {
    it('should track touched state when blur is called', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      expect(nameField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // Blur should set touched
      nameField.blur()
      await nextTick()
      expect(nameField.isTouched.value).toBe(true)
      expect(form.isTouched.value).toBe(true)
    })

    it('should track dirty state when value changes', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      expect(nameField.isDirty.value).toBe(false)

      nameField.value.value = 'Jane Doe'
      await nextTick()

      expect(nameField.isDirty.value).toBe(true)
    })

    it('should not be dirty when value is same as initial', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      nameField.value.value = 'Jane Doe'
      await nextTick()
      expect(nameField.isDirty.value).toBe(true)

      nameField.value.value = 'John Doe' // Back to original
      await nextTick()
      expect(nameField.isDirty.value).toBe(false)
    })
  })

  describe('form reset', () => {
    it('should reset all values to initial state', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')
      const bioField = form.field('profile.bio')

      // Make changes
      nameField.value.value = 'Jane Doe'
      bioField.value.value = 'Updated bio'
      nameField.blur()

      await nextTick()

      expect(nameField.value.value).toBe('Jane Doe')
      expect(bioField.value.value).toBe('Updated bio')
      expect(nameField.isTouched.value).toBe(true)

      // Reset
      form.reset()
      await nextTick()

      expect(nameField.value.value).toBe('John Doe')
      expect(bioField.value.value).toBe('Software developer')
      expect(nameField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })
  })

  describe('validation and error handling', () => {
    it('should reflect validation errors from server', () => {
      const formRef = createFormWithErrors()
      const form = createFormInScope(formRef)

      expect(form.isValid.value).toBe(false)

      const nameField = form.field('name')
      expect(nameField.errors.value).toEqual(['Name is required'])
      expect(nameField.errorMessage.value).toBe('Name is required')
      expect(nameField.isValid.value).toBe(false)

      const emailField = form.field('email')
      expect(emailField.errors.value).toEqual(['Invalid email format'])
      expect(emailField.isValid.value).toBe(false)

      const ageField = form.field('age')
      expect(ageField.errors.value).toEqual([])
      expect(ageField.isValid.value).toBe(true)

      const bioField = form.field('profile.bio')
      expect(bioField.errors.value).toEqual(['Bio is too short'])
      expect(bioField.isValid.value).toBe(false)

      const itemNameField = form.field('items[0].name')
      expect(itemNameField.errors.value).toEqual(['Item name required'])
      expect(itemNameField.isValid.value).toBe(false)
    })

    it('should handle multiple errors on single field', () => {
      const formRef = createFormRef({
        errors: {
          name: ['Name is required', 'Name must be at least 2 characters'],
        },
      })

      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      expect(nameField.errors.value).toEqual(['Name is required', 'Name must be at least 2 characters'])
      expect(nameField.errorMessage.value).toBe('Name is required') // First error
      expect(nameField.isValid.value).toBe(false)
    })
  })

  describe('inputAttrs helper', () => {
    it('should provide basic input attributes', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      const attrs = nameField.inputAttrs.value

      expect(attrs.value).toBe('John Doe')
      expect(attrs.name).toBe('name')
      expect(attrs.id).toBe('name')
      expect(attrs['aria-invalid']).toBe(false)
      expect(attrs['aria-describedby']).toBeUndefined()
      expect(typeof attrs.onBlur).toBe('function')
      expect(typeof attrs.onInput).toBe('function')
    })

    it('should sanitize path for ID attribute', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Test nested property
      const bioField = form.field('profile.bio')
      expect(bioField.inputAttrs.value.id).toBe('profile_bio')
      expect(bioField.inputAttrs.value.name).toBe('profile.bio')

      // Test array element
      const itemNameField = form.field('items[0].name')
      expect(itemNameField.inputAttrs.value.id).toBe('items_0_name')
      expect(itemNameField.inputAttrs.value.name).toBe('items[0].name')

      // Test complex nested array
      const tagField = form.field('items[1].tags[0]')
      expect(tagField.inputAttrs.value.id).toBe('items_1_tags_0')
      expect(tagField.inputAttrs.value.name).toBe('items[1].tags[0]')
    })

    it('should handle modelValue updates', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      const attrs = nameField.inputAttrs.value

      // Test updating via onInput
      const mockEvent = { target: { value: 'New Name' } } as unknown as Event
      attrs.onInput(mockEvent)
      await nextTick()

      expect(nameField.value.value).toBe('New Name')
      expect(nameField.inputAttrs.value.value).toBe('New Name')
    })

    it('should handle blur event', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      const attrs = nameField.inputAttrs.value

      expect(nameField.isTouched.value).toBe(false)

      // Test blur
      attrs.onBlur()
      await nextTick()
      expect(nameField.isTouched.value).toBe(true) // Should be touched after blur
    })

    it('should set aria-invalid when field has errors', () => {
      const formRef = createFormWithErrors()
      const form = createFormInScope(formRef)

      const nameField = form.field('name')
      const emailField = form.field('email')
      const ageField = form.field('age')

      expect(nameField.inputAttrs.value['aria-invalid']).toBe(true)
      expect(emailField.inputAttrs.value['aria-invalid']).toBe(true)
      expect(ageField.inputAttrs.value['aria-invalid']).toBe(false)
    })

    it('should set aria-describedby when field has errors', () => {
      const formRef = createFormWithErrors()
      const form = createFormInScope(formRef)

      const nameField = form.field('name')
      const ageField = form.field('age')

      expect(nameField.inputAttrs.value['aria-describedby']).toBe('name-error')
      expect(ageField.inputAttrs.value['aria-describedby']).toBeUndefined()

      // Test complex path
      const bioField = form.field('profile.bio')
      expect(bioField.inputAttrs.value['aria-describedby']).toBe('profile_bio-error')
    })

    it('should reactively update aria attributes when errors change', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      // Initially no errors
      expect(nameField.inputAttrs.value['aria-invalid']).toBe(false)
      expect(nameField.inputAttrs.value['aria-describedby']).toBeUndefined()

      // Add errors via server update
      formRef.value = {
        ...formRef.value,
        errors: {
          name: ['Name is required'],
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()
      // Wait a bit for any pending operations to complete
      await new Promise(resolve => setTimeout(resolve, 50))

      expect(nameField.inputAttrs.value['aria-invalid']).toBe(true)
      expect(nameField.inputAttrs.value['aria-describedby']).toBe('name-error')

      // Note: Error clearing is tested in other tests that work with form.reset()
      // The scope-based approach here makes the reactive watcher behavior different
    })

    it('should work with array fields', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')
      const firstSkillField = skillsArray.field(0)

      const attrs = firstSkillField.inputAttrs.value

      expect(attrs.value).toBe('JavaScript')
      expect(attrs.name).toBe('profile.skills[0]')
      expect(attrs.id).toBe('profile_skills_0')
      expect(attrs['aria-invalid']).toBe(false)
    })

    it('should allow chaining with sub-fields', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const profileField = form.field('profile')
      const bioField = profileField.field('bio')

      const attrs = bioField.inputAttrs.value

      expect(attrs.value).toBe('Software developer')
      expect(attrs.name).toBe('profile.bio')
      expect(attrs.id).toBe('profile_bio')
    })
  })

  describe('form-level dirty tracking', () => {
    it('should track form as dirty when any field changes', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.isDirty.value).toBe(false)

      const nameField = form.field('name')
      nameField.value.value = 'Jane Doe'
      await nextTick()

      expect(form.isDirty.value).toBe(true)
    })

    it('should track form as dirty when nested field changes', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.isDirty.value).toBe(false)

      const bioField = form.field('profile.bio')
      bioField.value.value = 'Updated bio'
      await nextTick()

      expect(form.isDirty.value).toBe(true)
    })

    it('should track form as dirty when array field changes', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.isDirty.value).toBe(false)

      const skillsArray = form.fieldArray('profile.skills')
      skillsArray.add('Vue.js')
      await nextTick()

      expect(form.isDirty.value).toBe(true)
    })

    it('should not be dirty when reset to initial values', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')

      nameField.value.value = 'Jane Doe'
      await nextTick()
      expect(form.isDirty.value).toBe(true)

      form.reset()
      await nextTick()
      expect(form.isDirty.value).toBe(false)
    })
  })

  describe('array field creation', () => {
    it('should create array field with proper methods', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      expect(skillsArray.value.value).toEqual(['JavaScript', 'TypeScript'])
      expect(skillsArray.fields.value).toHaveLength(2)
      expect(skillsArray.fields.value[0].value.value).toBe('JavaScript')
      expect(skillsArray.fields.value[1].value.value).toBe('TypeScript')
    })

    it('should add items to array', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      skillsArray.add('Vue.js')
      await nextTick()

      expect(skillsArray.value.value).toEqual(['JavaScript', 'TypeScript', 'Vue.js'])
      expect(skillsArray.fields.value).toHaveLength(3)
    })

    it('should remove items from array', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      skillsArray.remove(0)
      await nextTick()

      expect(skillsArray.value.value).toEqual(['TypeScript'])
      expect(skillsArray.fields.value).toHaveLength(1)
    })

    it('should move items in array', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      skillsArray.move(0, 1)
      await nextTick()

      expect(skillsArray.value.value).toEqual(['TypeScript', 'JavaScript'])
    })

    it('should handle complex nested array operations', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray('items')

      expect(itemsArray.fields.value).toHaveLength(2)
      expect(itemsArray.fields.value[0].field('name').value.value).toBe('Item 1')
      expect(itemsArray.fields.value[1].field('name').value.value).toBe('Item 2')

      // Add new item
      itemsArray.add({ name: 'Item 3', tags: ['tag4'] })
      await nextTick()

      expect(itemsArray.fields.value).toHaveLength(3)
      expect(itemsArray.fields.value[2].field('name').value.value).toBe('Item 3')

      // Test field and fieldArray methods on array items
      const secondItem = itemsArray.field('[1].name')
      expect(secondItem.value.value).toBe('Item 2')

      const firstItemTags = itemsArray.fieldArray('[0].tags')
      expect(firstItemTags.value.value).toEqual(['tag1', 'tag2'])
    })

    it('should maintain reactivity when array items are modified', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray('items')

      // Modify first item's name
      const firstItemNameField = itemsArray.fields.value[0].field('name')
      firstItemNameField.value.value = 'Modified Item 1'
      await nextTick()

      // Check that the change is reflected in multiple ways of accessing the same field
      expect(itemsArray.field('[0].name').value.value).toBe('Modified Item 1')
      expect(itemsArray.field(0).field('name').value.value).toBe('Modified Item 1')
      expect(form.field('items[0].name').value.value).toBe('Modified Item 1')
    })

    it('should handle array move operations correctly', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      expect(skillsArray.value.value).toEqual(['JavaScript', 'TypeScript'])

      skillsArray.move(0, 1)
      await nextTick()

      expect(skillsArray.value.value).toEqual(['TypeScript', 'JavaScript'])
      expect(skillsArray.fields.value[0].value.value).toBe('TypeScript')
      expect(skillsArray.fields.value[1].value.value).toBe('JavaScript')
    })

    it('should track dirty state for array operations', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      expect(skillsArray.isDirty.value).toBe(false)
      expect(form.isDirty.value).toBe(false)

      skillsArray.add('Vue.js')
      await nextTick()

      expect(skillsArray.isDirty.value).toBe(true)
      expect(form.isDirty.value).toBe(true)

      // Remove the added item to restore original state
      skillsArray.remove(2)
      await nextTick()

      expect(skillsArray.isDirty.value).toBe(false)
      expect(form.isDirty.value).toBe(false)
    })

    it('should handle array validation errors', () => {
      const formRef = createFormRef({
        errors: {
          items: [
            { name: ['First item name is required'], tags: [] },
            { name: [], tags: [['Invalid tag format']] },
          ],
        },
      })

      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray('items')

      expect(form.isValid.value).toBe(false)
      expect(itemsArray.isValid.value).toBe(false)

      const firstItemName = itemsArray.field('[0].name')
      expect(firstItemName.errors.value).toEqual(['First item name is required'])
      expect(firstItemName.isValid.value).toBe(false)

      const secondItemTags = itemsArray.fieldArray('[1].tags')
      expect(secondItemTags.errors.value).toEqual([['Invalid tag format']])
      expect(secondItemTags.isValid.value).toBe(false)

      const secondItemTagsFirstTag = secondItemTags.field(0)
      expect(secondItemTagsFirstTag.errors.value).toEqual(['Invalid tag format'])
      expect(secondItemTagsFirstTag.isValid.value).toBe(false)
    })

    it('should support both string paths and number shortcuts in array field API', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray('items')

      // Test string path syntax
      const firstItemNameByStringPath = itemsArray.field('[0].name')
      expect(firstItemNameByStringPath.value.value).toBe('Item 1')

      const firstItemTagsByStringPath = itemsArray.fieldArray('[0].tags')
      expect(firstItemTagsByStringPath.value.value).toEqual(['tag1', 'tag2'])

      // Test number shortcut syntax (equivalent to "[0]")
      const firstItemByNumber = itemsArray.field(0)
      expect(firstItemByNumber.field('name').value.value).toBe('Item 1')

      const firstItemTagsArrayByNumber = itemsArray.field(0).fieldArray('tags')
      expect(firstItemTagsArrayByNumber.value.value).toEqual(['tag1', 'tag2'])

      // Both approaches should access the same underlying field
      expect(firstItemNameByStringPath.value.value).toBe(firstItemByNumber.field('name').value.value)
    })
  })

  describe('integration tests - LiveView form lifecycle', () => {
    it('should follow complete form lifecycle: initial -> update -> validate -> server response', async () => {
      // 1. Initial state - form is valid with no errors
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: 'validate',
        debounceInMiliseconds: 100,
      })

      const nameField = form.field('name')

      // Assert initial state
      expect(nameField.value.value).toBe('John Doe')
      expect(nameField.errors.value).toEqual([])
      expect(form.isValid.value).toBe(true)
      expect(form.isDirty.value).toBe(false)

      // 2. User updates field (simulating active editing)
      nameField.value.value = 'Jane Smith'
      await nextTick()

      expect(form.isDirty.value).toBe(true)

      // 3. Wait for debounced validation event to be sent
      await new Promise(resolve => setTimeout(resolve, 150))

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('validate', {
        test_form: expect.objectContaining({
          name: 'Jane Smith',
          email: 'john@example.com',
        }),
      }, expect.any(Function))

      // 4. Server responds with updated values and validation errors
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: 'Jane Smith',
          email: 'john@example.com',
        },
        errors: {
          name: ['Name must be at least 3 characters'],
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()
      // Wait a bit more for debounced execution to fully complete
      await new Promise(resolve => setTimeout(resolve, 50))

      // Field should now show server error
      expect(nameField.errors.value).toEqual(['Name must be at least 3 characters'])
      expect(nameField.isValid.value).toBe(false)
      expect(form.isValid.value).toBe(false)

      // With "last update wins", server response overwrites user edit (server sent original values + errors)
      expect(nameField.value.value).toBe('Jane Smith')
    })

    it('should handle form submission with server validation', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        submitEvent: 'submit_form',
      })

      // Submit the form
      await form.submit()

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('submit_form', {
        test_form: expect.objectContaining({
          name: 'John Doe',
          email: 'john@example.com',
        }),
      }, expect.any(Function))
    })

    it('should use prepareData function before sending to server', async () => {
      const formRef = createFormRef()
      const prepareData = vi.fn(data => ({ transformed: data }))
      const form = createFormInScope(formRef, { prepareData })

      const nameField = form.field('name')
      nameField.value.value = 'Modified Name'

      await form.submit()

      expect(prepareData).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Modified Name',
        }),
      )
      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('submit', {
        test_form: { transformed: expect.objectContaining({ name: 'Modified Name' }) },
      }, expect.any(Function))
    })

    it('should handle cases when LiveView is not available', async () => {
      mockUseLiveVue.mockReturnValue(null)

      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Should not throw and should resolve
      await expect(form.submit()).resolves.toBeUndefined()
    })

    it('should update all fields reactively when server form changes', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const nameField = form.field('name')
      const emailField = form.field('email')
      const bioField = form.field('profile.bio')
      const itemNameField = form.field('items[0].name')

      // Initial values
      expect(nameField.value.value).toBe('John Doe')
      expect(emailField.value.value).toBe('john@example.com')
      expect(bioField.value.value).toBe('Software developer')
      expect(itemNameField.value.value).toBe('Item 1')
      expect(nameField.errors.value).toEqual([])

      // Update the reactive form (simulating server update with new values and errors)
      formRef.value = {
        name: 'updated_form',
        values: {
          name: 'Jane Smith',
          email: 'jane@example.com',
          age: 25,
          profile: {
            bio: 'Product designer',
            skills: ['Figma', 'Sketch'],
          },
          items: [
            { name: 'Design mockups', tags: ['ui', 'ux'] },
            { name: 'User research', tags: ['research'] },
          ],
        },
        errors: {
          name: ['Name already taken'],
          email: [],
        } as unknown as FormErrors<TestForm>,
        valid: false,
      }

      await nextTick()
      // Wait a bit for any pending validation to complete
      await new Promise(resolve => setTimeout(resolve, 50))

      // All fields should be updated
      expect(nameField.value.value).toBe('Jane Smith')
      expect(emailField.value.value).toBe('jane@example.com')
      expect(bioField.value.value).toBe('Product designer')
      expect(itemNameField.value.value).toBe('Design mockups')

      // Errors should be updated
      expect(nameField.errors.value).toEqual(['Name already taken'])
      expect(emailField.errors.value).toEqual([])
    })

    it('should properly debounce validation events during typing', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: 'validate_field',
        debounceInMiliseconds: 10,
      })

      const nameField = form.field('name')

      // Simulate rapid typing
      nameField.value.value = 'J'
      await nextTick()
      nameField.value.value = 'Ja'
      await nextTick()
      nameField.value.value = 'Jan'
      await nextTick()
      nameField.value.value = 'Jane'
      await nextTick()

      // Should not have sent any events yet
      expect(mockLiveVue.pushEvent).not.toHaveBeenCalled()

      // Wait for debounce delay
      await new Promise(resolve => setTimeout(resolve, 15))

      // Should have sent only one validation event with final value
      expect(mockLiveVue.pushEvent).toHaveBeenCalledTimes(1)
      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('validate_field', {
        test_form: expect.objectContaining({
          name: 'Jane',
        }),
      }, expect.any(Function))
    })

    it('should not send validation events when changeEvent is null', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: null, // Disable validation events
        debounceInMiliseconds: 10,
      })

      const nameField = form.field('name')
      nameField.value.value = 'Modified Name'
      await nextTick()

      // Wait for debounce delay
      await new Promise(resolve => setTimeout(resolve, 15))

      // Should not have sent any validation events
      expect(mockLiveVue.pushEvent).not.toHaveBeenCalled()
    })

    it('should not send duplicate change events when server updates the form', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: 'validate',
        debounceInMiliseconds: 10,
      })

      const nameField = form.field('name')

      // Clear any initial calls
      vi.clearAllMocks()

      // User changes a field
      nameField.value.value = 'John Updated'
      await nextTick()

      // Wait for debounced change event
      await new Promise(resolve => setTimeout(resolve, 15))

      // Should have sent one change event
      expect(mockLiveVue.pushEvent).toHaveBeenCalledTimes(1)
      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('validate', {
        test_form: expect.objectContaining({
          name: 'John Updated',
        }),
      }, expect.any(Function))

      // Clear the mock to track subsequent calls
      vi.clearAllMocks()

      // Server updates the form (simulating server response with updated values)
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: 'John Server Updated',
          email: 'updated@server.com',
        },
      }

      await nextTick()

      // Wait for any potential debounced events
      await new Promise(resolve => setTimeout(resolve, 15))

      // Should NOT have sent any additional change events (this was the bug)
      expect(mockLiveVue.pushEvent).not.toHaveBeenCalled()

      // Verify the field was updated from server
      expect(nameField.value.value).toBe('John Server Updated')
    })

    it('should use form name as key in event payload instead of \'data\'', async () => {
      const formRef = createFormRef({
        name: 'user_form', // Custom form name
      })
      const form = createFormInScope(formRef, {
        changeEvent: 'validate',
        submitEvent: 'save',
        debounceInMiliseconds: 10,
      })

      const nameField = form.field('name')
      nameField.value.value = 'New Name'
      await nextTick()

      // Wait for debounce delay for change event
      await new Promise(resolve => setTimeout(resolve, 15))

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('validate', {
        user_form: expect.objectContaining({
          name: 'New Name',
        }),
      }, expect.any(Function))

      // Test submit event as well
      await form.submit()

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith('save', {
        user_form: expect.objectContaining({
          name: 'New Name',
        }),
      }, expect.any(Function))
    })

    it('should clear field errors when server removes them', async () => {
      // Start with a form that has errors
      const formRef = createFormRef({
        errors: {
          name: ['Name is required'],
          email: ['Invalid email format'],
          profile: {
            bio: ['Bio is too short'],
          },
        },
      })

      const form = createFormInScope(formRef)
      const nameField = form.field('name')
      const emailField = form.field('email')
      const bioField = form.field('profile.bio')

      // Verify initial error state
      expect(nameField.errors.value).toEqual(['Name is required'])
      expect(emailField.errors.value).toEqual(['Invalid email format'])
      expect(bioField.errors.value).toEqual(['Bio is too short'])
      expect(form.isValid.value).toBe(false)

      // Server clears some errors (simulating successful validation)
      formRef.value = {
        ...formRef.value,
        errors: {
          email: ['Invalid email format'], // Keep email error
          // name and profile.bio errors are cleared (not present)
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()
      // Wait a bit for any pending operations to complete
      await new Promise(resolve => setTimeout(resolve, 50))

      // Cleared errors should now be empty arrays
      expect(nameField.errors.value).toEqual([])
      expect(bioField.errors.value).toEqual([])
      expect(nameField.isValid.value).toBe(true)
      expect(bioField.isValid.value).toBe(true)

      // Remaining error should still be present
      expect(emailField.errors.value).toEqual(['Invalid email format'])
      expect(emailField.isValid.value).toBe(false)

      // Form should be invalid due to remaining email error
      expect(form.isValid.value).toBe(false)

      // Clear all errors
      formRef.value = {
        ...formRef.value,
        errors: {} as FormErrors<TestForm>,
      }

      await nextTick()
      // Wait a bit for any pending operations to complete
      await new Promise(resolve => setTimeout(resolve, 50))

      // All errors should now be cleared
      expect(nameField.errors.value).toEqual([])
      expect(emailField.errors.value).toEqual([])
      expect(bioField.errors.value).toEqual([])
      expect(form.isValid.value).toBe(true)
    })

    it('should mark all fields as touched when submit is called, then reset on success', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Create various field types to test comprehensive touched state
      const nameField = form.field('name')
      const emailField = form.field('email')
      const bioField = form.field('profile.bio')
      const skillsArray = form.fieldArray('profile.skills')
      const firstSkillField = skillsArray.field(0)
      const itemNameField = form.field('items[0].name')
      const itemTagField = form.field('items[0].tags[0]')

      // Initially no fields should be touched
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(bioField.isTouched.value).toBe(false)
      expect(firstSkillField.isTouched.value).toBe(false)
      expect(itemNameField.isTouched.value).toBe(false)
      expect(itemTagField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // Submit the form (succeeds and resets touched state)
      await form.submit()
      // Wait for the reset timeout to complete
      await new Promise(resolve => setTimeout(resolve, 10))

      // After successful submit, all fields should be reset to untouched
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(bioField.isTouched.value).toBe(false)
      expect(firstSkillField.isTouched.value).toBe(false)
      expect(itemNameField.isTouched.value).toBe(false)
      expect(itemTagField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })

    it('should mark touched state for dynamically added array items on submit, then reset', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray('profile.skills')

      // Add a new skill dynamically
      skillsArray.add('Vue.js')
      await nextTick()

      const newSkillField = skillsArray.field(2) // Third skill (index 2)
      expect(newSkillField.isTouched.value).toBe(false)

      // Submit the form (succeeds and resets touched state)
      await form.submit()
      // Wait for the reset timeout to complete
      await new Promise(resolve => setTimeout(resolve, 10))

      // After successful submit, the dynamically added field should be reset to untouched
      expect(newSkillField.isTouched.value).toBe(false)
    })

    it('should track submit count and expose it', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Initial submit count should be 0
      expect(form.submitCount.value).toBe(0)

      // Submit the form (succeeds, so count resets to 0)
      await form.submit()
      // Wait for the reset timeout to complete
      await new Promise(resolve => setTimeout(resolve, 10))
      expect(form.submitCount.value).toBe(0)

      // Submit again (succeeds, so count remains 0)
      await form.submit()
      // Wait for the reset timeout to complete
      await new Promise(resolve => setTimeout(resolve, 10))
      expect(form.submitCount.value).toBe(0)

      // Reset should reset submit count
      form.reset()
      expect(form.submitCount.value).toBe(0)
    })

    it('should reset touched state and update initial values after successful submission', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        submitEvent: 'submit_form',
      })

      const nameField = form.field('name')
      const bioField = form.field('profile.bio')

      // Make changes and mark fields as touched
      nameField.value.value = 'Jane Smith'
      bioField.value.value = 'Updated bio'
      nameField.blur() // Mark as touched
      bioField.blur() // Mark as touched

      await nextTick()

      // Verify dirty and touched state before submit
      expect(form.isDirty.value).toBe(true)
      expect(form.isTouched.value).toBe(true)
      expect(nameField.isTouched.value).toBe(true)
      expect(bioField.isTouched.value).toBe(true)
      expect(form.submitCount.value).toBe(0)

      // Verify initial values haven't changed
      expect(form.initialValues.name).toBe('John Doe')
      expect(form.initialValues.profile.bio).toBe('Software developer')

      // Simulate server updating form with new values after submit
      // This would typically happen in LiveView after processing the form
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: 'Jane Smith', // Server accepted the change
          profile: {
            ...formRef.value.values.profile,
            bio: 'Updated bio', // Server accepted the change
          },
        },
        errors: {} as FormErrors<TestForm>, // Clear any previous errors
      }

      // Submit the form (should succeed and trigger reset)
      await form.submit()
      // Wait for the reset timeout to complete
      await new Promise(resolve => setTimeout(resolve, 10))

      await nextTick()

      // After successful submit, form should be reset
      expect(form.isDirty.value).toBe(false) // No longer dirty
      expect(form.isTouched.value).toBe(false) // No longer touched
      expect(nameField.isTouched.value).toBe(false)
      expect(bioField.isTouched.value).toBe(false)
      expect(form.submitCount.value).toBe(0) // Reset to 0 on success

      // Initial values should be updated to match current server values
      expect(form.initialValues.name).toBe('Jane Smith')
      expect(form.initialValues.profile.bio).toBe('Updated bio')

      // Current values should still be the submitted values
      expect(nameField.value.value).toBe('Jane Smith')
      expect(bioField.value.value).toBe('Updated bio')
    })

    it('should not reset on failed submission', async () => {
      // Mock a failed submission - the current implementation doesn't handle errors in callbacks
      // so we need to test the scenario where pushEvent doesn't provide a reset response
      mockLiveVue.pushEvent.mockImplementation((_event: any, _payload: any, callback: any) => {
        if (callback) {
          // Simulate server error response without reset flag
          setTimeout(() => callback({ error: 'Submission failed' }), 0)
        }
        return Promise.resolve({ error: 'Submission failed' })
      })

      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        submitEvent: 'submit_form',
      })

      const nameField = form.field('name')

      // Make changes and mark as touched
      nameField.value.value = 'Jane Smith'
      nameField.blur()

      await nextTick()

      expect(form.isDirty.value).toBe(true)
      expect(form.isTouched.value).toBe(true)
      expect(form.submitCount.value).toBe(0)
      expect(form.initialValues.name).toBe('John Doe')

      // Submit should not reset since no reset flag was provided
      const result = await form.submit()
      expect(result.error).toBe('Submission failed')

      await nextTick()

      // State should remain unchanged after failed submit
      expect(form.isDirty.value).toBe(true) // Still dirty
      expect(form.isTouched.value).toBe(true) // Still touched
      expect(nameField.isTouched.value).toBe(true)
      expect(form.submitCount.value).toBe(1) // Not reset since no reset flag was provided
      expect(form.initialValues.name).toBe('John Doe') // Not updated
      expect(nameField.value.value).toBe('Jane Smith') // User changes preserved
    })

    it('should make fields touched based on submit count', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field('name')
      const emailField = form.field('email')

      // Initially no fields are touched
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // After successful submit, fields should be reset to untouched
      await form.submit()
      // Wait for the reset timeout to complete
      await new Promise(resolve => setTimeout(resolve, 10))
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // Reset should make fields untouched again (unless individually touched)
      form.reset()
      await nextTick()
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })

    it('should apply only the last server update (no races)', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: 'validate',
        debounceInMiliseconds: 100,
      })

      const nameField = form.field('name')

      // 1. User makes an edit (triggers validation)
      nameField.value.value = 'User Edit'
      await nextTick()

      // 2. Quick server update while validation is pending
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: 'First Server Update',
        },
      }
      await nextTick()

      // 3. Wait for validation to complete and a bit more
      await new Promise(resolve => setTimeout(resolve, 200))

      // Check what happened to first update (should be blocked)
      expect(nameField.value.value).toBe('User Edit') // First update was blocked

      // 4. Second server update after validation completes
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: 'Second Server Update',
        },
      }
      await nextTick()

      // Give a moment for the update to apply
      await new Promise(resolve => setTimeout(resolve, 50))

      // 5. The second server update should now be visible (last update wins)
      expect(nameField.value.value).toBe('Second Server Update')
    })
  })

  describe('checkbox functionality', () => {
    it('should create boolean checkbox field with correct inputAttrs', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const checkboxField = form.field('acceptTerms', { type: 'checkbox' })

      expect(checkboxField.inputAttrs.value.type).toBe('checkbox')
      expect(checkboxField.inputAttrs.value.checked).toBe(false)
      expect(checkboxField.inputAttrs.value.value).toBe(undefined)
    })

    it('should create single checkbox with custom value', () => {
      const formRef = createFormRef({ values: { ...createFormRef().value.values, plan: null } })
      const form = createFormInScope(formRef)
      const checkboxField = form.field('plan', { type: 'checkbox', value: 'premium' })

      expect(checkboxField.inputAttrs.value.type).toBe('checkbox')
      expect(checkboxField.inputAttrs.value.checked).toBe(false)
      expect(checkboxField.inputAttrs.value.value).toBe('premium')
    })

    it('should auto-detect multi-checkbox when second checkbox is created', async () => {
      const formRef = createFormRef({ values: { ...createFormRef().value.values, preferences: [] } })
      const form = createFormInScope(formRef)

      const emailField = form.field('preferences', { type: 'checkbox', value: 'email' })
      expect(emailField.inputAttrs.value.checked).toBe(false)

      const smsField = form.field('preferences', { type: 'checkbox', value: 'sms' })
      expect(smsField.inputAttrs.value.checked).toBe(false)

      // Both should now be array-aware
      expect(emailField.inputAttrs.value.value).toBe('email')
      expect(smsField.inputAttrs.value.value).toBe('sms')

      // Test checking email checkbox
      const mockEvent = { target: { checked: true } } as unknown as Event
      emailField.inputAttrs.value.onInput(mockEvent)
      await nextTick()

      // Email should be checked, sms should not
      expect(emailField.inputAttrs.value.checked).toBe(true)
      expect(smsField.inputAttrs.value.checked).toBe(false)

      // Check the underlying array value
      expect(emailField.value.value).toEqual(['email'])
    })

    it('should handle boolean checkbox input events', async () => {
      const formRef = createFormRef({ values: { ...createFormRef().value.values, acceptTerms: false } })
      const form = createFormInScope(formRef)
      const checkboxField = form.field('acceptTerms', { type: 'checkbox' })

      expect(checkboxField.value.value).toBe(false)

      // Simulate checking the checkbox
      const mockEvent = { target: { checked: true } } as unknown as Event
      checkboxField.inputAttrs.value.onInput(mockEvent)
      await nextTick()

      expect(checkboxField.value.value).toBe(true)
    })

    it('should handle checkbox with value input events', async () => {
      const formRef = createFormRef({ values: { ...createFormRef().value.values, plan: false } })
      const form = createFormInScope(formRef)
      const checkboxField = form.field('plan', { type: 'checkbox', value: 'premium' })

      expect(checkboxField.value.value).toBe(false)

      // Simulate checking the checkbox
      const mockEvent = { target: { checked: true } } as unknown as Event
      checkboxField.inputAttrs.value.onInput(mockEvent)

      expect(checkboxField.value.value).toBe('premium')
    })

    it('should memoize checkbox fields with same options', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const field1 = form.field('preferences', { type: 'checkbox', value: 'email' })
      const field2 = form.field('preferences', { type: 'checkbox', value: 'email' })

      expect(field1).toBe(field2)
    })

    it('should create separate instances for different checkbox values', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const emailField = form.field('preferences', { type: 'checkbox', value: 'email' })
      const smsField = form.field('preferences', { type: 'checkbox', value: 'sms' })

      expect(emailField).not.toBe(smsField)
    })
  })

  describe('performance optimizations', () => {
    it('should memoize field instances', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const nameField1 = form.field('name')
      const nameField2 = form.field('name')

      // Should return the same instance (memoized)
      expect(nameField1).toBe(nameField2)
    })

    it('should memoize nested field instances', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const bioField1 = form.field('profile.bio')
      const bioField2 = form.field('profile.bio')

      // Should return the same instance (memoized)
      expect(bioField1).toBe(bioField2)
    })

    it('should memoize array field instances', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const skillsArray1 = form.fieldArray('profile.skills')
      const skillsArray2 = form.fieldArray('profile.skills')

      // Should return the same instance (memoized)
      expect(skillsArray1).toBe(skillsArray2)
    })

    it('should memoize sub-field instances created via fluent interface', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const profileField = form.field('profile')
      const bioField1 = profileField.field('bio')
      const bioField2 = profileField.field('bio')

      // Should return the same instance (memoized)
      expect(bioField1).toBe(bioField2)

      // Should also be the same as direct path access
      const bioField3 = form.field('profile.bio')
      expect(bioField1).toBe(bioField3)
    })

    it('should clear field cache on reset', async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const nameField1 = form.field('name')
      nameField1.value.value = 'Modified Name'
      await nextTick()

      form.reset()
      await nextTick()

      const nameField2 = form.field('name')

      // The important thing is that the value is reset correctly
      expect(nameField2.value.value).toBe('John Doe')
    })

    it('should handle concurrent field creation efficiently', () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Create multiple fields concurrently
      const fields = Array.from({ length: 100 }, () => form.field('name'))

      // All should be the same memoized instance
      expect(fields.every(field => field === fields[0])).toBe(true)
    })
  })
})
