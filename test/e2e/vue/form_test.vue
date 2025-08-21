<script setup lang="ts">
import { useLiveForm, type Form } from "live_vue"
import { watch } from "vue"

// Define a simple form structure for testing
type TestForm = {
  name: string
  email: string
  age: number
  profile: {
    bio: string
    skills: string[]
  }
  items: Array<{
    title: string
    tags: string[]
  }>
}

const props = defineProps<{
  form: Form<TestForm>
}>()

const form = useLiveForm(() => props.form, {
  changeEvent: "validate",
  submitEvent: "submit",
  debounceInMiliseconds: 50,
})

// Basic fields
const nameField = form.field("name")
const emailField = form.field("email")
const ageField = form.field("age")

// Nested object fields
const profileField = form.field("profile")
const bioField = profileField.field("bio")

// Array fields
const skillsArray = form.fieldArray("profile.skills")
const itemsArray = form.fieldArray("items")

const submitForm = async () => {
  try {
    await form.submit()
  } catch (error) {
    console.error("Form submission failed:", error)
  }
}

watch(
  () => props.form,
  newForm => {
    console.log("form changed", JSON.stringify(newForm, null, 2))
  },
  { deep: true }
)
</script>

<template>
  <div class="form-test-container" data-pw-form>
    <h1>Form Test</h1>

    <!-- Form State Display -->
    <div class="form-state" data-pw-form-state>
      <div data-pw-is-valid>Valid: {{ form.isValid.value ? "true" : "false" }}</div>
      <div data-pw-is-dirty>Dirty: {{ form.isDirty.value ? "true" : "false" }}</div>
      <div data-pw-is-touched>Touched: {{ form.isTouched.value ? "true" : "false" }}</div>
    </div>

    <!-- Basic Fields -->
    <div class="basic-fields">
      <div class="field">
        <label :for="nameField.inputAttrs.value.id">Name</label>
        <input
          :value="nameField.inputAttrs.value.value"
          @input="nameField.inputAttrs.value.onInput"
          @focus="nameField.inputAttrs.value.onFocus"
          @blur="nameField.inputAttrs.value.onBlur"
          :name="nameField.inputAttrs.value.name"
          :id="nameField.inputAttrs.value.id"
          :aria-invalid="nameField.inputAttrs.value['aria-invalid']"
          :aria-describedby="nameField.inputAttrs.value['aria-describedby']"
          data-pw-name-input
          placeholder="Enter name"
        />
        <div v-if="nameField.errorMessage.value" class="error" data-pw-name-error>
          {{ nameField.errorMessage.value }}
        </div>
      </div>

      <div class="field">
        <label :for="emailField.inputAttrs.value.id">Email</label>
        <input
          :value="emailField.inputAttrs.value.value"
          @input="emailField.inputAttrs.value.onInput"
          @focus="emailField.inputAttrs.value.onFocus"
          @blur="emailField.inputAttrs.value.onBlur"
          :name="emailField.inputAttrs.value.name"
          :id="emailField.inputAttrs.value.id"
          :aria-invalid="emailField.inputAttrs.value['aria-invalid']"
          :aria-describedby="emailField.inputAttrs.value['aria-describedby']"
          data-pw-email-input
          type="email"
          placeholder="Enter email"
        />
        <div v-if="emailField.errorMessage.value" class="error" data-pw-email-error>
          {{ emailField.errorMessage.value }}
        </div>
      </div>

      <div class="field">
        <label :for="ageField.inputAttrs.value.id">Age</label>
        <input v-bind="ageField.inputAttrs.value" data-pw-age-input type="number" placeholder="Enter age" />
        <div v-if="ageField.errorMessage.value" class="error" data-pw-age-error>
          {{ ageField.errorMessage.value }}
        </div>
      </div>
    </div>

    <!-- Nested Fields -->
    <div class="nested-fields">
      <h3>Profile</h3>
      <div class="field">
        <label :for="bioField.inputAttrs.value.id">Bio</label>
        <textarea v-bind="bioField.inputAttrs.value" data-pw-bio-input placeholder="Enter bio" rows="3"></textarea>
        <div v-if="bioField.errorMessage.value" class="error" data-pw-bio-error>
          {{ bioField.errorMessage.value }}
        </div>
      </div>
    </div>

    <!-- Skills Array -->
    <div class="skills-section">
      <div class="skills-header">
        <h3>Skills</h3>
        <pre>{{ JSON.stringify(skillsArray.value.value, null, 2) }}</pre>
        <button @click="skillsArray.add('')" data-pw-add-skill>Add Skill</button>
      </div>

      <div class="skills-list">
        <div
          v-for="(skillField, index) in skillsArray.fields.value"
          :key="index"
          class="skill-item"
          :data-pw-skill-item="index"
        >
          <input v-bind="skillField.inputAttrs.value" :data-pw-skill-input="index" placeholder="Enter skill" />
          <button @click="() => skillsArray.remove(index)" :data-pw-remove-skill="index">Remove</button>
        </div>
      </div>
    </div>

    <!-- Items Array with nested tags -->
    <div class="items-section">
      <div class="items-header">
        <h3>Items</h3>
        <button @click="() => itemsArray.add({ title: '', tags: [] })" data-pw-add-item>Add Item</button>
      </div>

      <div class="items-list">
        <div
          v-for="(itemField, itemIndex) in itemsArray.fields.value"
          :key="itemIndex"
          class="item"
          :data-pw-item="itemIndex"
        >
          <div class="item-header">
            <h4>Item {{ itemIndex + 1 }}</h4>
            <button @click="() => itemsArray.remove(itemIndex)" :data-pw-remove-item="itemIndex">Remove Item</button>
          </div>

          <div class="field">
            <label>Title</label>
            <input
              v-bind="itemField.field('title').inputAttrs.value"
              :data-pw-item-title="itemIndex"
              placeholder="Enter item title"
            />
            <div v-if="itemField.field('title').errorMessage.value" class="error">
              {{ itemField.field("title").errorMessage.value }}
            </div>
          </div>

          <!-- Tags for this item -->
          <div class="tags-section">
            <div class="tags-header">
              <label>Tags</label>
              <button @click="() => itemsArray.fieldArray(`[${itemIndex}].tags`).add('')" :data-pw-add-tag="itemIndex">
                Add Tag
              </button>
            </div>

            <div class="tags-list">
              <div
                v-for="(tagField, tagIndex) in itemField.fieldArray('tags').fields.value"
                :key="tagIndex"
                class="tag-item"
                :data-pw-tag-item="`${itemIndex}-${tagIndex}`"
              >
                <input
                  v-bind="tagField.inputAttrs.value"
                  :data-pw-tag-input="`${itemIndex}-${tagIndex}`"
                  placeholder="Enter tag"
                />
                <button
                  @click="() => itemsArray.fieldArray(`[${itemIndex}].tags`).remove(tagIndex)"
                  :data-pw-remove-tag="`${itemIndex}-${tagIndex}`"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Form Actions -->
    <div class="form-actions">
      <button @click="form.reset()" data-pw-reset>Reset</button>
      <button @click="submitForm" :disabled="!form.isValid.value" data-pw-submit>Submit</button>
    </div>
  </div>
</template>

<style scoped>
.form-test-container {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}

.form-state {
  background: #f5f5f5;
  padding: 10px;
  margin-bottom: 20px;
  border-radius: 4px;
}

.field {
  margin-bottom: 15px;
}

.field label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

.field input,
.field textarea {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.field input[aria-invalid="true"],
.field textarea[aria-invalid="true"] {
  border-color: #e74c3c;
}

.error {
  color: #e74c3c;
  font-size: 14px;
  margin-top: 5px;
}

.skills-header,
.items-header,
.tags-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.skill-item,
.tag-item {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
}

.skill-item input,
.tag-item input {
  flex: 1;
}

.item {
  border: 1px solid #ddd;
  padding: 15px;
  margin-bottom: 15px;
  border-radius: 4px;
}

.item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.tags-section {
  margin-top: 15px;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 30px;
}

.form-actions button {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.form-actions button[data-pw-reset] {
  background: #95a5a6;
  color: white;
}

.form-actions button[data-pw-submit] {
  background: #3498db;
  color: white;
}

.form-actions button:disabled {
  background: #bdc3c7;
  cursor: not-allowed;
}

button {
  padding: 5px 10px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  background: #3498db;
  color: white;
}

button:hover:not(:disabled) {
  background: #2980b9;
}
</style>
