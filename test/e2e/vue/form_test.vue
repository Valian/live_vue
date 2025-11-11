<script setup lang="ts">
import type { Form } from 'live_vue'
import { useLiveForm } from 'live_vue'

// Define a simple form structure for testing
interface TestForm {
  name: string
  email: string
  age: number
  acceptTerms: boolean
  newsletter: boolean
  preferences: string[]
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
  changeEvent: 'validate',
  submitEvent: 'submit',
  debounceInMiliseconds: 300,
})

// Basic fields
const nameField = form.field('name')
const emailField = form.field('email')
const ageField = form.field('age')

// Checkbox fields
const acceptTermsField = form.field('acceptTerms', { type: 'checkbox' })
const newsletterField = form.field('newsletter', { type: 'checkbox' })

// Multi-checkbox fields for preferences
const emailPrefField = form.field('preferences', { type: 'checkbox', value: 'email' })
const smsPrefField = form.field('preferences', { type: 'checkbox', value: 'sms' })
const pushPrefField = form.field('preferences', { type: 'checkbox', value: 'push' })

// Nested object fields
const profileField = form.field('profile')
const bioField = profileField.field('bio')

// Array fields
const skillsArray = form.fieldArray('profile.skills')
const itemsArray = form.fieldArray('items')

async function submitForm() {
  try {
    await form.submit()
  }
  catch (error) {
    console.error('Form submission failed:', error)
  }
}
</script>

<template>
  <div class="form-test-container" data-pw-form>
    <h1>Form Test</h1>

    <!-- Form State Display -->
    <div class="form-state" data-pw-form-state>
      <div data-pw-is-valid>
        Valid: {{ form.isValid.value ? "true" : "false" }}
      </div>
      <div data-pw-is-dirty>
        Dirty: {{ form.isDirty.value ? "true" : "false" }}
      </div>
      <div data-pw-is-touched>
        Touched: {{ form.isTouched.value ? "true" : "false" }}
      </div>
      <div data-pw-values>
        Values:
        <pre>{{ JSON.stringify(props.form, null, 2) }}</pre>
      </div>
    </div>

    <!-- Basic Fields -->
    <div class="basic-fields">
      <div class="field">
        <label :for="nameField.inputAttrs.value.id">Name</label>
        <input
          :id="nameField.inputAttrs.value.id"
          :value="nameField.inputAttrs.value.value"
          :name="nameField.inputAttrs.value.name"
          :aria-invalid="nameField.inputAttrs.value['aria-invalid']"
          :aria-describedby="nameField.inputAttrs.value['aria-describedby']"
          data-pw-name-input
          placeholder="Enter name"
          @input="nameField.inputAttrs.value.onInput"
          @blur="nameField.inputAttrs.value.onBlur"
        >
        <div v-if="nameField.errorMessage.value" class="error" data-pw-name-error>
          {{ nameField.errorMessage.value }}
        </div>
      </div>

      <div class="field">
        <label :for="emailField.inputAttrs.value.id">Email</label>
        <input
          :id="emailField.inputAttrs.value.id"
          :value="emailField.inputAttrs.value.value"
          :name="emailField.inputAttrs.value.name"
          :aria-invalid="emailField.inputAttrs.value['aria-invalid']"
          :aria-describedby="emailField.inputAttrs.value['aria-describedby']"
          data-pw-email-input
          type="email"
          placeholder="Enter email"
          @input="emailField.inputAttrs.value.onInput"
          @blur="emailField.inputAttrs.value.onBlur"
        >
        <div v-if="emailField.errorMessage.value" class="error" data-pw-email-error>
          {{ emailField.errorMessage.value }}
        </div>
      </div>

      <div class="field">
        <label :for="ageField.inputAttrs.value.id">Age</label>
        <input v-bind="ageField.inputAttrs.value" data-pw-age-input type="number" placeholder="Enter age">
        <div v-if="ageField.errorMessage.value" class="error" data-pw-age-error>
          {{ ageField.errorMessage.value }}
        </div>
      </div>
    </div>

    <!-- Checkbox Fields -->
    <div class="checkbox-fields">
      <h3>Checkboxes</h3>

      <!-- Single Checkbox -->
      <div class="field checkbox-field">
        <label>
          <input v-bind="acceptTermsField.inputAttrs.value" data-pw-accept-terms>
          Accept Terms and Conditions
        </label>
        <div v-if="acceptTermsField.errorMessage.value" class="error" data-pw-accept-terms-error>
          {{ acceptTermsField.errorMessage.value }}
        </div>
      </div>

      <!-- Another Single Checkbox -->
      <div class="field checkbox-field">
        <label>
          <input v-bind="newsletterField.inputAttrs.value" data-pw-newsletter>
          Subscribe to Newsletter
        </label>
        <div v-if="newsletterField.errorMessage.value" class="error" data-pw-newsletter-error>
          {{ newsletterField.errorMessage.value }}
        </div>
      </div>

      <!-- Multi-Checkbox (Array of Values) -->
      <div class="field">
        <label>Preferences (select multiple)</label>
        <div class="checkbox-group">
          <label class="checkbox-option">
            <input v-bind="emailPrefField.inputAttrs.value" data-pw-preferences-email>
            Email Notifications
          </label>
          <label class="checkbox-option">
            <input v-bind="smsPrefField.inputAttrs.value" data-pw-preferences-sms>
            SMS Notifications
          </label>
          <label class="checkbox-option">
            <input v-bind="pushPrefField.inputAttrs.value" data-pw-preferences-push>
            Push Notifications
          </label>
        </div>
        <div v-if="emailPrefField.errorMessage.value" class="error" data-pw-preferences-error>
          {{ emailPrefField.errorMessage.value }}
        </div>
      </div>
    </div>

    <!-- Nested Fields -->
    <div class="nested-fields">
      <h3>Profile</h3>
      <div class="field">
        <label :for="bioField.inputAttrs.value.id">Bio</label>
        <textarea v-bind="bioField.inputAttrs.value" data-pw-bio-input placeholder="Enter bio" rows="3" />
        <div v-if="bioField.errorMessage.value" class="error" data-pw-bio-error>
          {{ bioField.errorMessage.value }}
        </div>
      </div>
    </div>

    <!-- Skills Array -->
    <div class="skills-section">
      <div class="skills-header">
        <h3>Skills</h3>
        <button data-pw-add-skill @click="skillsArray.add('')">
          Add Skill
        </button>
      </div>

      <div class="skills-list">
        <div
          v-for="(skillField, index) in skillsArray.fields.value"
          :key="index"
          class="skill-item"
          :data-pw-skill-item="index"
        >
          <input v-bind="skillField.inputAttrs.value" :data-pw-skill-input="index" placeholder="Enter skill">
          <button :data-pw-remove-skill="index" @click="() => skillsArray.remove(index)">
            Remove
          </button>
        </div>
      </div>
    </div>

    <!-- Items Array with nested tags -->
    <div class="items-section">
      <div class="items-header">
        <h3>Items</h3>
        <button data-pw-add-item @click="() => itemsArray.add({ title: '', tags: [] })">
          Add Item
        </button>
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
            <button :data-pw-remove-item="itemIndex" @click="() => itemsArray.remove(itemIndex)">
              Remove Item
            </button>
          </div>

          <div class="field">
            <label>Title</label>
            <input
              v-bind="itemField.field('title').inputAttrs.value"
              :data-pw-item-title="itemIndex"
              placeholder="Enter item title"
            >
            <div v-if="itemField.field('title').errorMessage.value" class="error">
              {{ itemField.field("title").errorMessage.value }}
            </div>
          </div>

          <!-- Tags for this item -->
          <div class="tags-section">
            <div class="tags-header">
              <label>Tags</label>
              <button :data-pw-add-tag="itemIndex" @click="() => itemsArray.fieldArray(`[${itemIndex}].tags`).add('')">
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
                >
                <button
                  :data-pw-remove-tag="`${itemIndex}-${tagIndex}`"
                  @click="() => itemsArray.fieldArray(`[${itemIndex}].tags`).remove(tagIndex)"
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
      <button data-pw-reset @click="form.reset()">
        Reset
      </button>
      <button :disabled="!form.isValid.value" data-pw-submit @click="submitForm">
        Submit
      </button>
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

.checkbox-fields {
  border: 1px solid #ddd;
  padding: 15px;
  margin-bottom: 20px;
  border-radius: 4px;
}

.checkbox-field label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: normal;
  cursor: pointer;
}

.checkbox-field input[type="checkbox"] {
  width: auto;
  margin: 0;
}

.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 8px;
}

.checkbox-option {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: normal;
  cursor: pointer;
}

.checkbox-option input[type="checkbox"] {
  width: auto;
  margin: 0;
}
</style>
