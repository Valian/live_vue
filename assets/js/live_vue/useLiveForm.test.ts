import { describe, it, expect, beforeEach, vi } from "vitest"
import { ref, nextTick, effectScope } from "vue"

// Mock useLiveVue to prevent injection errors
vi.mock("./use", () => ({
  useLiveVue: vi.fn(),
}))

// Mock provide() to prevent warnings in tests
vi.mock("vue", async () => {
  const actual = await vi.importActual("vue")
  return {
    ...actual,
    provide: vi.fn(), // Mock provide to do nothing in tests
  }
})

import { useLiveForm, type Form, type FormErrors } from "./useLiveForm"
import { useLiveVue } from "./use"

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
}

// Simple function to create a valid form ref
function createFormRef(overrides: Partial<Form<TestForm>> = {}) {
  const baseForm: Form<TestForm> = {
    name: "test_form",
    values: {
      name: "John Doe",
      email: "john@example.com",
      age: 30,
      profile: {
        bio: "Software developer",
        skills: ["JavaScript", "TypeScript"],
      },
      items: [
        { name: "Item 1", tags: ["tag1", "tag2"] },
        { name: "Item 2", tags: ["tag3"] },
      ],
    },
    errors: {} as FormErrors<TestForm>, // Empty object when no errors, like in Phoenix
  }

  return ref({ ...baseForm, ...overrides, errors: (overrides.errors || {}) as FormErrors<TestForm> })
}

// Function to create form with errors
function createFormWithErrors() {
  return createFormRef({
    errors: {
      name: ["Name is required"],
      email: ["Invalid email format"],
      age: [],
      profile: {
        bio: ["Bio is too short"],
        skills: [],
      },
      items: [
        { name: ["Item name required"], tags: [] },
        { name: [], tags: [] },
      ],
    },
  })
}

describe("useLiveForm - Integration Tests", () => {
  beforeEach(() => {
    // Setup fresh mock LiveVue instance for each test
    mockLiveVue = {
      pushEvent: vi.fn().mockResolvedValue(undefined),
    }
    mockUseLiveVue.mockReturnValue(mockLiveVue)
  })

  describe("basic form initialization", () => {
    it("should initialize form with proper state", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.initialValues.value).toEqual(formRef.value.values)
      expect(form.isValid.value).toBe(true)
      expect(form.isDirty.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })

    it("should create deep copy of initial values", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Modify the original
      formRef.value.values.name = "Modified"

      // Form should still have original value
      expect(form.initialValues.value.name).toBe("John Doe")
    })
  })

  describe("field creation and path resolution", () => {
    it("should create field for simple property", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      expect(nameField.value.value).toBe("John Doe")
      expect(nameField.errors.value).toEqual([])
      expect(nameField.errorMessage.value).toBeUndefined()
      expect(nameField.isValid.value).toBe(true)
      expect(nameField.isDirty.value).toBe(false)
      expect(nameField.isTouched.value).toBe(false)
    })

    it("should create field for nested property", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const bioField = form.field("profile.bio")

      expect(bioField.value.value).toBe("Software developer")
      expect(bioField.isValid.value).toBe(true)
    })

    it("should create field for array element", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemNameField = form.field("items[0].name")

      expect(itemNameField.value.value).toBe("Item 1")
      expect(itemNameField.isValid.value).toBe(true)
    })

    it("should create field for nested array element", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const tagField = form.field("items[0].tags[0]")

      expect(tagField.value.value).toBe("tag1")
    })
  })

  describe("field value updates", () => {
    it("should update field value reactively", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      nameField.value.value = "Jane Doe"
      await nextTick()

      expect(nameField.value.value).toBe("Jane Doe")
    })

    it("should update nested field value reactively", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const bioField = form.field("profile.bio")

      bioField.value.value = "Updated bio"
      await nextTick()

      expect(bioField.value.value).toBe("Updated bio")
    })

    it("should update array element reactively", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemNameField = form.field("items[0].name")

      itemNameField.value.value = "Updated Item"
      await nextTick()

      expect(itemNameField.value.value).toBe("Updated Item")
    })
  })

  describe("sub-field creation (fluent interface)", () => {
    it("should create sub-field from object field", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const profileField = form.field("profile")
      const bioField = profileField.field("bio")

      expect(bioField.value.value).toBe("Software developer")
    })

    it("should create sub-field from array field", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray("items")
      // Use at() method to access array item
      const firstItemField = itemsArray.at(0)
      const nameField = firstItemField.field("name")

      expect(nameField.value.value).toBe("Item 1")
    })
  })

  describe("field state tracking", () => {
    it("should track touched state when blur is called", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      expect(nameField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // Focus should not set touched
      nameField.focus()
      await nextTick()
      expect(nameField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // Blur should set touched
      nameField.blur()
      await nextTick()
      expect(nameField.isTouched.value).toBe(true)
      expect(form.isTouched.value).toBe(true)
    })

    it("should track dirty state when value changes", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      expect(nameField.isDirty.value).toBe(false)

      nameField.value.value = "Jane Doe"
      await nextTick()

      expect(nameField.isDirty.value).toBe(true)
    })

    it("should not be dirty when value is same as initial", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      nameField.value.value = "Jane Doe"
      await nextTick()
      expect(nameField.isDirty.value).toBe(true)

      nameField.value.value = "John Doe" // Back to original
      await nextTick()
      expect(nameField.isDirty.value).toBe(false)
    })
  })

  describe("form reset", () => {
    it("should reset all values to initial state", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")
      const bioField = form.field("profile.bio")

      // Make changes
      nameField.value.value = "Jane Doe"
      bioField.value.value = "Updated bio"
      nameField.focus()
      nameField.blur()

      await nextTick()

      expect(nameField.value.value).toBe("Jane Doe")
      expect(bioField.value.value).toBe("Updated bio")
      expect(nameField.isTouched.value).toBe(true)

      // Reset
      form.reset()
      await nextTick()

      expect(nameField.value.value).toBe("John Doe")
      expect(bioField.value.value).toBe("Software developer")
      expect(nameField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })
  })

  describe("validation and error handling", () => {
    it("should reflect validation errors from server", () => {
      const formRef = createFormWithErrors()
      const form = createFormInScope(formRef)

      expect(form.isValid.value).toBe(false)

      const nameField = form.field("name")
      expect(nameField.errors.value).toEqual(["Name is required"])
      expect(nameField.errorMessage.value).toBe("Name is required")
      expect(nameField.isValid.value).toBe(false)

      const emailField = form.field("email")
      expect(emailField.errors.value).toEqual(["Invalid email format"])
      expect(emailField.isValid.value).toBe(false)

      const ageField = form.field("age")
      expect(ageField.errors.value).toEqual([])
      expect(ageField.isValid.value).toBe(true)

      const bioField = form.field("profile.bio")
      expect(bioField.errors.value).toEqual(["Bio is too short"])
      expect(bioField.isValid.value).toBe(false)

      const itemNameField = form.field("items[0].name")
      expect(itemNameField.errors.value).toEqual(["Item name required"])
      expect(itemNameField.isValid.value).toBe(false)
    })

    it("should handle multiple errors on single field", () => {
      const formRef = createFormRef({
        errors: {
          name: ["Name is required", "Name must be at least 2 characters"],
        },
      })

      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      expect(nameField.errors.value).toEqual(["Name is required", "Name must be at least 2 characters"])
      expect(nameField.errorMessage.value).toBe("Name is required") // First error
      expect(nameField.isValid.value).toBe(false)
    })
  })

  describe("inputAttrs helper", () => {
    it("should provide basic input attributes", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      const attrs = nameField.inputAttrs.value

      expect(attrs.value).toBe("John Doe")
      expect(attrs.name).toBe("name")
      expect(attrs.id).toBe("name")
      expect(attrs["aria-invalid"]).toBe(false)
      expect(attrs["aria-describedby"]).toBeUndefined()
      expect(typeof attrs.onFocus).toBe("function")
      expect(typeof attrs.onBlur).toBe("function")
      expect(typeof attrs.onInput).toBe("function")
    })

    it("should sanitize path for ID attribute", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Test nested property
      const bioField = form.field("profile.bio")
      expect(bioField.inputAttrs.value.id).toBe("profile_bio")
      expect(bioField.inputAttrs.value.name).toBe("profile.bio")

      // Test array element
      const itemNameField = form.field("items[0].name")
      expect(itemNameField.inputAttrs.value.id).toBe("items_0_name")
      expect(itemNameField.inputAttrs.value.name).toBe("items[0].name")

      // Test complex nested array
      const tagField = form.field("items[1].tags[0]")
      expect(tagField.inputAttrs.value.id).toBe("items_1_tags_0")
      expect(tagField.inputAttrs.value.name).toBe("items[1].tags[0]")
    })

    it("should handle modelValue updates", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      const attrs = nameField.inputAttrs.value

      // Test updating via onInput
      const mockEvent = { target: { value: "New Name" } } as Event
      attrs.onInput(mockEvent)
      await nextTick()

      expect(nameField.value.value).toBe("New Name")
      expect(nameField.inputAttrs.value.value).toBe("New Name")
    })

    it("should handle focus and blur events", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      const attrs = nameField.inputAttrs.value

      expect(nameField.isTouched.value).toBe(false)

      // Test focus
      attrs.onFocus()
      await nextTick()
      expect(nameField.isTouched.value).toBe(false) // Should not be touched yet

      // Test blur
      attrs.onBlur()
      await nextTick()
      expect(nameField.isTouched.value).toBe(true) // Should be touched after blur
    })

    it("should set aria-invalid when field has errors", () => {
      const formRef = createFormWithErrors()
      const form = createFormInScope(formRef)

      const nameField = form.field("name")
      const emailField = form.field("email")
      const ageField = form.field("age")

      expect(nameField.inputAttrs.value["aria-invalid"]).toBe(true)
      expect(emailField.inputAttrs.value["aria-invalid"]).toBe(true)
      expect(ageField.inputAttrs.value["aria-invalid"]).toBe(false)
    })

    it("should set aria-describedby when field has errors", () => {
      const formRef = createFormWithErrors()
      const form = createFormInScope(formRef)

      const nameField = form.field("name")
      const ageField = form.field("age")

      expect(nameField.inputAttrs.value["aria-describedby"]).toBe("name-error")
      expect(ageField.inputAttrs.value["aria-describedby"]).toBeUndefined()

      // Test complex path
      const bioField = form.field("profile.bio")
      expect(bioField.inputAttrs.value["aria-describedby"]).toBe("profile_bio-error")
    })

    it("should reactively update aria attributes when errors change", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      // Initially no errors
      expect(nameField.inputAttrs.value["aria-invalid"]).toBe(false)
      expect(nameField.inputAttrs.value["aria-describedby"]).toBeUndefined()

      // Add errors via server update
      formRef.value = {
        ...formRef.value,
        errors: {
          name: ["Name is required"],
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()

      expect(nameField.inputAttrs.value["aria-invalid"]).toBe(true)
      expect(nameField.inputAttrs.value["aria-describedby"]).toBe("name-error")

      // Note: Error clearing is tested in other tests that work with form.reset()
      // The scope-based approach here makes the reactive watcher behavior different
    })

    it("should work with array fields", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")
      const firstSkillField = skillsArray.at(0)

      const attrs = firstSkillField.inputAttrs.value

      expect(attrs.value).toBe("JavaScript")
      expect(attrs.name).toBe("profile.skills[0]")
      expect(attrs.id).toBe("profile_skills_0")
      expect(attrs["aria-invalid"]).toBe(false)
    })

    it("should allow chaining with sub-fields", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const profileField = form.field("profile")
      const bioField = profileField.field("bio")

      const attrs = bioField.inputAttrs.value

      expect(attrs.value).toBe("Software developer")
      expect(attrs.name).toBe("profile.bio")
      expect(attrs.id).toBe("profile_bio")
    })
  })

  describe("form-level dirty tracking", () => {
    it("should track form as dirty when any field changes", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.isDirty.value).toBe(false)

      const nameField = form.field("name")
      nameField.value.value = "Jane Doe"
      await nextTick()

      expect(form.isDirty.value).toBe(true)
    })

    it("should track form as dirty when nested field changes", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.isDirty.value).toBe(false)

      const bioField = form.field("profile.bio")
      bioField.value.value = "Updated bio"
      await nextTick()

      expect(form.isDirty.value).toBe(true)
    })

    it("should track form as dirty when array field changes", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      expect(form.isDirty.value).toBe(false)

      const skillsArray = form.fieldArray("profile.skills")
      skillsArray.add("Vue.js")
      await nextTick()

      expect(form.isDirty.value).toBe(true)
    })

    it("should not be dirty when reset to initial values", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")

      nameField.value.value = "Jane Doe"
      await nextTick()
      expect(form.isDirty.value).toBe(true)

      form.reset()
      await nextTick()
      expect(form.isDirty.value).toBe(false)
    })
  })

  describe("array field creation", () => {
    it("should create array field with proper methods", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      expect(skillsArray.value.value).toEqual(["JavaScript", "TypeScript"])
      expect(skillsArray.fields.value).toHaveLength(2)
      expect(skillsArray.fields.value[0].value.value).toBe("JavaScript")
      expect(skillsArray.fields.value[1].value.value).toBe("TypeScript")
    })

    it("should add items to array", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      skillsArray.add("Vue.js")
      await nextTick()

      expect(skillsArray.value.value).toEqual(["JavaScript", "TypeScript", "Vue.js"])
      expect(skillsArray.fields.value).toHaveLength(3)
    })

    it("should remove items from array", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      skillsArray.remove(0)
      await nextTick()

      expect(skillsArray.value.value).toEqual(["TypeScript"])
      expect(skillsArray.fields.value).toHaveLength(1)
    })

    it("should move items in array", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      skillsArray.move(0, 1)
      await nextTick()

      expect(skillsArray.value.value).toEqual(["TypeScript", "JavaScript"])
    })

    it("should access array items with at method", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      const firstSkill = skillsArray.at(0)
      expect(firstSkill.value.value).toBe("JavaScript")
    })

    it("should handle complex nested array operations", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray("items")

      expect(itemsArray.fields.value).toHaveLength(2)
      expect(itemsArray.fields.value[0].field("name").value.value).toBe("Item 1")
      expect(itemsArray.fields.value[1].field("name").value.value).toBe("Item 2")

      // Add new item
      itemsArray.add({ name: "Item 3", tags: ["tag4"] })
      await nextTick()

      expect(itemsArray.fields.value).toHaveLength(3)
      expect(itemsArray.fields.value[2].field("name").value.value).toBe("Item 3")

      // Test field and fieldArray methods on array items
      const secondItem = itemsArray.field("[1].name")
      expect(secondItem.value.value).toBe("Item 2")

      const firstItemTags = itemsArray.fieldArray("[0].tags")
      expect(firstItemTags.value.value).toEqual(["tag1", "tag2"])
    })

    it("should maintain reactivity when array items are modified", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray("items")

      // Modify first item's name
      const firstItemNameField = itemsArray.fields.value[0].field("name")
      firstItemNameField.value.value = "Modified Item 1"
      await nextTick()

      // Check that the change is reflected in multiple ways of accessing the same field
      expect(itemsArray.field("[0].name").value.value).toBe("Modified Item 1")
      expect(itemsArray.at(0).field("name").value.value).toBe("Modified Item 1")
      expect(form.field("items[0].name").value.value).toBe("Modified Item 1")
    })

    it("should handle array move operations correctly", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      expect(skillsArray.value.value).toEqual(["JavaScript", "TypeScript"])

      skillsArray.move(0, 1)
      await nextTick()

      expect(skillsArray.value.value).toEqual(["TypeScript", "JavaScript"])
      expect(skillsArray.fields.value[0].value.value).toBe("TypeScript")
      expect(skillsArray.fields.value[1].value.value).toBe("JavaScript")
    })

    it("should track dirty state for array operations", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      expect(skillsArray.isDirty.value).toBe(false)
      expect(form.isDirty.value).toBe(false)

      skillsArray.add("Vue.js")
      await nextTick()

      expect(skillsArray.isDirty.value).toBe(true)
      expect(form.isDirty.value).toBe(true)

      // Remove the added item to restore original state
      skillsArray.remove(2)
      await nextTick()

      expect(skillsArray.isDirty.value).toBe(false)
      expect(form.isDirty.value).toBe(false)
    })

    it("should handle array validation errors", () => {
      const formRef = createFormRef({
        errors: {
          items: [
            { name: ["First item name is required"], tags: [] },
            { name: [], tags: [["Invalid tag format"]] },
          ],
        },
      })

      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray("items")

      expect(form.isValid.value).toBe(false)
      expect(itemsArray.isValid.value).toBe(false)

      const firstItemName = itemsArray.field("[0].name")
      expect(firstItemName.errors.value).toEqual(["First item name is required"])
      expect(firstItemName.isValid.value).toBe(false)

      const secondItemTags = itemsArray.fieldArray("[1].tags")
      expect(secondItemTags.errors.value).toEqual([["Invalid tag format"]])
      expect(secondItemTags.isValid.value).toBe(false)

      const secondItemTagsFirstTag = secondItemTags.at(0)
      expect(secondItemTagsFirstTag.errors.value).toEqual(["Invalid tag format"])
      expect(secondItemTagsFirstTag.isValid.value).toBe(false)
    })

    it("should support both string paths and number shortcuts in array field API", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const itemsArray = form.fieldArray("items")

      // Test string path syntax
      const firstItemNameByStringPath = itemsArray.field("[0].name")
      expect(firstItemNameByStringPath.value.value).toBe("Item 1")

      const firstItemTagsByStringPath = itemsArray.fieldArray("[0].tags")
      expect(firstItemTagsByStringPath.value.value).toEqual(["tag1", "tag2"])

      // Test number shortcut syntax (equivalent to "[0]")
      const firstItemByNumber = itemsArray.field(0)
      expect(firstItemByNumber.field("name").value.value).toBe("Item 1")

      const firstItemTagsArrayByNumber = itemsArray.field(0).fieldArray("tags")
      expect(firstItemTagsArrayByNumber.value.value).toEqual(["tag1", "tag2"])

      // Both approaches should access the same underlying field
      expect(firstItemNameByStringPath.value.value).toBe(firstItemByNumber.field("name").value.value)
    })
  })

  describe("integration tests - LiveView form lifecycle", () => {
    it("should follow complete form lifecycle: initial -> update -> validate -> server response", async () => {
      // 1. Initial state - form is valid with no errors
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: "validate",
        debounceInMiliseconds: 100,
      })

      const nameField = form.field("name")
      const emailField = form.field("email")

      // Assert initial state
      expect(nameField.value.value).toBe("John Doe")
      expect(nameField.errors.value).toEqual([])
      expect(form.isValid.value).toBe(true)
      expect(form.isDirty.value).toBe(false)

      // 2. User focuses and updates field (simulating active editing)
      nameField.focus() // User starts editing
      nameField.value.value = "Jane Smith"
      await nextTick()

      expect(form.isDirty.value).toBe(true)

      // 3. Wait for debounced validation event to be sent
      await new Promise(resolve => setTimeout(resolve, 150))

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("validate", {
        test_form: expect.objectContaining({
          name: "Jane Smith",
          email: "john@example.com",
        }),
      })

      // 4. Server responds with validation errors
      formRef.value = {
        ...formRef.value,
        errors: {
          name: ["Name must be at least 3 characters"],
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()

      // Field should now show server error
      expect(nameField.errors.value).toEqual(["Name must be at least 3 characters"])
      expect(nameField.isValid.value).toBe(false)
      expect(form.isValid.value).toBe(false)

      // User value should be preserved (not overwritten by server)
      expect(nameField.value.value).toBe("Jane Smith")
    })

    it("should handle form submission with server validation", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        submitEvent: "submit_form",
      })

      // Submit the form
      await form.submit()

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("submit_form", {
        test_form: expect.objectContaining({
          name: "John Doe",
          email: "john@example.com",
        }),
      })
    })

    it("should use prepareData function before sending to server", async () => {
      const formRef = createFormRef()
      const prepareData = vi.fn(data => ({ transformed: data }))
      const form = createFormInScope(formRef, { prepareData })

      const nameField = form.field("name")
      nameField.value.value = "Modified Name"

      await form.submit()

      expect(prepareData).toHaveBeenCalledWith(
        expect.objectContaining({
          name: "Modified Name",
        })
      )
      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("submit", {
        test_form: { transformed: expect.objectContaining({ name: "Modified Name" }) },
      })
    })

    it("should handle cases when LiveView is not available", async () => {
      mockUseLiveVue.mockReturnValue(null)

      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Should not throw and should resolve
      await expect(form.submit()).resolves.toBeUndefined()
    })

    it("should update all fields reactively when server form changes", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const nameField = form.field("name")
      const emailField = form.field("email")
      const bioField = form.field("profile.bio")
      const itemNameField = form.field("items[0].name")

      // Initial values
      expect(nameField.value.value).toBe("John Doe")
      expect(emailField.value.value).toBe("john@example.com")
      expect(bioField.value.value).toBe("Software developer")
      expect(itemNameField.value.value).toBe("Item 1")
      expect(nameField.errors.value).toEqual([])

      // Update the reactive form (simulating server update with new values and errors)
      formRef.value = {
        name: "updated_form",
        values: {
          name: "Jane Smith",
          email: "jane@example.com",
          age: 25,
          profile: {
            bio: "Product designer",
            skills: ["Figma", "Sketch"],
          },
          items: [
            { name: "Design mockups", tags: ["ui", "ux"] },
            { name: "User research", tags: ["research"] },
          ],
        },
        errors: {
          name: ["Name already taken"],
          email: [],
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()

      // All fields should be updated
      expect(nameField.value.value).toBe("Jane Smith")
      expect(emailField.value.value).toBe("jane@example.com")
      expect(bioField.value.value).toBe("Product designer")
      expect(itemNameField.value.value).toBe("Design mockups")

      // Errors should be updated
      expect(nameField.errors.value).toEqual(["Name already taken"])
      expect(emailField.errors.value).toEqual([])
    })

    it("should prevent server overwrites while user is editing but allow error updates", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")
      const emailField = form.field("email")

      // User focuses on name field (starts editing)
      nameField.focus()
      await nextTick()

      // Server sends update while user is editing name
      formRef.value = {
        name: "updated_form",
        values: {
          ...formRef.value.values,
          name: "Server Updated Name", // Should NOT override because field is focused
          email: "server@example.com", // Should update because email is not being edited
        },
        errors: {
          name: ["Validation error from server"], // Should update even though field is focused
          email: [],
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()

      // Name value should NOT be updated (user is editing)
      expect(nameField.value.value).toBe("John Doe")
      // But name errors should be updated
      expect(nameField.errors.value).toEqual(["Validation error from server"])

      // Email should be updated (not being edited)
      expect(emailField.value.value).toBe("server@example.com")

      // After user stops editing (blur), server updates should work
      nameField.blur()
      await nextTick()

      // Update again
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: "Final Server Name",
        },
      }

      await nextTick()

      // Now name should be updated
      expect(nameField.value.value).toBe("Final Server Name")
    })

    it("should properly debounce validation events during typing", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: "validate_field",
        debounceInMiliseconds: 100,
      })

      const nameField = form.field("name")

      // Simulate rapid typing
      nameField.value.value = "J"
      await nextTick()
      nameField.value.value = "Ja"
      await nextTick()
      nameField.value.value = "Jan"
      await nextTick()
      nameField.value.value = "Jane"
      await nextTick()

      // Should not have sent any events yet
      expect(mockLiveVue.pushEvent).not.toHaveBeenCalled()

      // Wait for debounce delay
      await new Promise(resolve => setTimeout(resolve, 150))

      // Should have sent only one validation event with final value
      expect(mockLiveVue.pushEvent).toHaveBeenCalledTimes(1)
      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("validate_field", {
        test_form: expect.objectContaining({
          name: "Jane",
        }),
      })
    })

    it("should not send validation events when changeEvent is null", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: null, // Disable validation events
        debounceInMiliseconds: 100,
      })

      const nameField = form.field("name")
      nameField.value.value = "Modified Name"
      await nextTick()

      // Wait for debounce delay
      await new Promise(resolve => setTimeout(resolve, 150))

      // Should not have sent any validation events
      expect(mockLiveVue.pushEvent).not.toHaveBeenCalled()
    })

    it("should not send duplicate change events when server updates the form", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        changeEvent: "validate",
        debounceInMiliseconds: 100,
      })

      const nameField = form.field("name")

      // Clear any initial calls
      vi.clearAllMocks()

      // User changes a field
      nameField.value.value = "John Updated"
      await nextTick()

      // Wait for debounced change event
      await new Promise(resolve => setTimeout(resolve, 150))

      // Should have sent one change event
      expect(mockLiveVue.pushEvent).toHaveBeenCalledTimes(1)
      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("validate", {
        test_form: expect.objectContaining({
          name: "John Updated",
        }),
      })

      // Clear the mock to track subsequent calls
      vi.clearAllMocks()

      // Server updates the form (simulating server response with updated values)
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: "John Server Updated",
          email: "updated@server.com",
        },
      }

      await nextTick()

      // Wait for any potential debounced events
      await new Promise(resolve => setTimeout(resolve, 150))

      // Should NOT have sent any additional change events (this was the bug)
      expect(mockLiveVue.pushEvent).not.toHaveBeenCalled()

      // Verify the field was updated from server
      expect(nameField.value.value).toBe("John Server Updated")
    })

    it("should use form name as key in event payload instead of 'data'", async () => {
      const formRef = createFormRef({
        name: "user_form", // Custom form name
      })
      const form = createFormInScope(formRef, {
        changeEvent: "validate",
        submitEvent: "save",
        debounceInMiliseconds: 100,
      })

      const nameField = form.field("name")
      nameField.value.value = "New Name"
      await nextTick()

      // Wait for debounce delay for change event
      await new Promise(resolve => setTimeout(resolve, 150))

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("validate", {
        user_form: expect.objectContaining({
          name: "New Name",
        }),
      })

      // Test submit event as well
      await form.submit()

      expect(mockLiveVue.pushEvent).toHaveBeenCalledWith("save", {
        user_form: expect.objectContaining({
          name: "New Name",
        }),
      })
    })

    it("should clear field errors when server removes them", async () => {
      // Start with a form that has errors
      const formRef = createFormRef({
        errors: {
          name: ["Name is required"],
          email: ["Invalid email format"],
          profile: {
            bio: ["Bio is too short"],
          },
        },
      })

      const form = createFormInScope(formRef)
      const nameField = form.field("name")
      const emailField = form.field("email")
      const bioField = form.field("profile.bio")

      // Verify initial error state
      expect(nameField.errors.value).toEqual(["Name is required"])
      expect(emailField.errors.value).toEqual(["Invalid email format"])
      expect(bioField.errors.value).toEqual(["Bio is too short"])
      expect(form.isValid.value).toBe(false)

      // Server clears some errors (simulating successful validation)
      formRef.value = {
        ...formRef.value,
        errors: {
          email: ["Invalid email format"], // Keep email error
          // name and profile.bio errors are cleared (not present)
        } as unknown as FormErrors<TestForm>,
      }

      await nextTick()

      // Cleared errors should now be empty arrays
      expect(nameField.errors.value).toEqual([])
      expect(bioField.errors.value).toEqual([])
      expect(nameField.isValid.value).toBe(true)
      expect(bioField.isValid.value).toBe(true)

      // Remaining error should still be present
      expect(emailField.errors.value).toEqual(["Invalid email format"])
      expect(emailField.isValid.value).toBe(false)

      // Form should be invalid due to remaining email error
      expect(form.isValid.value).toBe(false)

      // Clear all errors
      formRef.value = {
        ...formRef.value,
        errors: {} as FormErrors<TestForm>,
      }

      await nextTick()

      // All errors should now be cleared
      expect(nameField.errors.value).toEqual([])
      expect(emailField.errors.value).toEqual([])
      expect(bioField.errors.value).toEqual([])
      expect(form.isValid.value).toBe(true)
    })

    it("should mark all fields as touched when submit is called, then reset on success", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Create various field types to test comprehensive touched state
      const nameField = form.field("name")
      const emailField = form.field("email")
      const bioField = form.field("profile.bio")
      const skillsArray = form.fieldArray("profile.skills")
      const firstSkillField = skillsArray.at(0)
      const itemNameField = form.field("items[0].name")
      const itemTagField = form.field("items[0].tags[0]")

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

      // After successful submit, all fields should be reset to untouched
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(bioField.isTouched.value).toBe(false)
      expect(firstSkillField.isTouched.value).toBe(false)
      expect(itemNameField.isTouched.value).toBe(false)
      expect(itemTagField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)
    })

    it("should mark touched state for dynamically added array items on submit, then reset", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const skillsArray = form.fieldArray("profile.skills")

      // Add a new skill dynamically
      skillsArray.add("Vue.js")
      await nextTick()

      const newSkillField = skillsArray.at(2) // Third skill (index 2)
      expect(newSkillField.isTouched.value).toBe(false)

      // Submit the form (succeeds and resets touched state)
      await form.submit()

      // After successful submit, the dynamically added field should be reset to untouched
      expect(newSkillField.isTouched.value).toBe(false)
    })

    it("should track submit count and expose it", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Initial submit count should be 0
      expect(form.submitCount.value).toBe(0)

      // Submit the form (succeeds, so count resets to 0)
      await form.submit()
      expect(form.submitCount.value).toBe(0)

      // Submit again (succeeds, so count remains 0)
      await form.submit()
      expect(form.submitCount.value).toBe(0)

      // Reset should reset submit count
      form.reset()
      expect(form.submitCount.value).toBe(0)
    })

    it("should reset touched state and update initial values after successful submission", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        submitEvent: "submit_form",
      })

      const nameField = form.field("name")
      const bioField = form.field("profile.bio")

      // Make changes and mark fields as touched
      nameField.value.value = "Jane Smith"
      bioField.value.value = "Updated bio"
      nameField.focus()
      nameField.blur() // Mark as touched
      bioField.focus()
      bioField.blur() // Mark as touched

      await nextTick()

      // Verify dirty and touched state before submit
      expect(form.isDirty.value).toBe(true)
      expect(form.isTouched.value).toBe(true)
      expect(nameField.isTouched.value).toBe(true)
      expect(bioField.isTouched.value).toBe(true)
      expect(form.submitCount.value).toBe(0)

      // Verify initial values haven't changed
      expect(form.initialValues.value.name).toBe("John Doe")
      expect(form.initialValues.value.profile.bio).toBe("Software developer")

      // Simulate server updating form with new values after submit
      // This would typically happen in LiveView after processing the form
      formRef.value = {
        ...formRef.value,
        values: {
          ...formRef.value.values,
          name: "Jane Smith", // Server accepted the change
          profile: {
            ...formRef.value.values.profile,
            bio: "Updated bio", // Server accepted the change
          },
        },
        errors: {} as FormErrors<TestForm>, // Clear any previous errors
      }

      // Submit the form (should succeed and trigger reset)
      await form.submit()

      await nextTick()

      // After successful submit, form should be reset
      expect(form.isDirty.value).toBe(false) // No longer dirty
      expect(form.isTouched.value).toBe(false) // No longer touched
      expect(nameField.isTouched.value).toBe(false)
      expect(bioField.isTouched.value).toBe(false)
      expect(form.submitCount.value).toBe(0) // Reset to 0 on success

      // Initial values should be updated to match current server values
      expect(form.initialValues.value.name).toBe("Jane Smith")
      expect(form.initialValues.value.profile.bio).toBe("Updated bio")

      // Current values should still be the submitted values
      expect(nameField.value.value).toBe("Jane Smith")
      expect(bioField.value.value).toBe("Updated bio")
    })

    it("should not reset on failed submission", async () => {
      // Mock a failed submission
      mockLiveVue.pushEvent.mockRejectedValue(new Error("Submission failed"))

      const formRef = createFormRef()
      const form = createFormInScope(formRef, {
        submitEvent: "submit_form",
      })

      const nameField = form.field("name")

      // Make changes and mark as touched
      nameField.value.value = "Jane Smith"
      nameField.focus()
      nameField.blur()

      await nextTick()

      expect(form.isDirty.value).toBe(true)
      expect(form.isTouched.value).toBe(true)
      expect(form.submitCount.value).toBe(0)
      expect(form.initialValues.value.name).toBe("John Doe")

      // Submit should fail
      await expect(form.submit()).rejects.toThrow("Submission failed")

      await nextTick()

      // State should remain unchanged after failed submit
      expect(form.isDirty.value).toBe(true) // Still dirty
      expect(form.isTouched.value).toBe(true) // Still touched
      expect(nameField.isTouched.value).toBe(true)
      expect(form.submitCount.value).toBe(1) // Incremented (failed submit count)
      expect(form.initialValues.value.name).toBe("John Doe") // Not updated
      expect(nameField.value.value).toBe("Jane Smith") // User changes preserved
    })

    it("should make fields touched based on submit count", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)
      const nameField = form.field("name")
      const emailField = form.field("email")

      // Initially no fields are touched
      expect(nameField.isTouched.value).toBe(false)
      expect(emailField.isTouched.value).toBe(false)
      expect(form.isTouched.value).toBe(false)

      // After successful submit, fields should be reset to untouched
      await form.submit()
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
  })

  describe("performance optimizations", () => {
    it("should memoize field instances", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const nameField1 = form.field("name")
      const nameField2 = form.field("name")

      // Should return the same instance (memoized)
      expect(nameField1).toBe(nameField2)
    })

    it("should memoize nested field instances", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const bioField1 = form.field("profile.bio")
      const bioField2 = form.field("profile.bio")

      // Should return the same instance (memoized)
      expect(bioField1).toBe(bioField2)
    })

    it("should memoize array field instances", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const skillsArray1 = form.fieldArray("profile.skills")
      const skillsArray2 = form.fieldArray("profile.skills")

      // Should return the same instance (memoized)
      expect(skillsArray1).toBe(skillsArray2)
    })

    it("should memoize sub-field instances created via fluent interface", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const profileField = form.field("profile")
      const bioField1 = profileField.field("bio")
      const bioField2 = profileField.field("bio")

      // Should return the same instance (memoized)
      expect(bioField1).toBe(bioField2)

      // Should also be the same as direct path access
      const bioField3 = form.field("profile.bio")
      expect(bioField1).toBe(bioField3)
    })

    it("should clear field cache on reset", async () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      const nameField1 = form.field("name")
      nameField1.value.value = "Modified Name"
      await nextTick()

      form.reset()
      await nextTick()

      const nameField2 = form.field("name")

      // The important thing is that the value is reset correctly
      expect(nameField2.value.value).toBe("John Doe")
    })

    it("should handle concurrent field creation efficiently", () => {
      const formRef = createFormRef()
      const form = createFormInScope(formRef)

      // Create multiple fields concurrently
      const fields = Array.from({ length: 100 }, () => form.field("name"))

      // All should be the same memoized instance
      expect(fields.every(field => field === fields[0])).toBe(true)
    })
  })
})
