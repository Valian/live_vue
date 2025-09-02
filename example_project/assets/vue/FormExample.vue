<script setup lang="ts">
import { Form, useLiveForm } from "live_vue"

// Complex form structure with nested arrays
type ProjectForm = {
  name: string
  description: string
  status: string
  is_public: boolean
  owner: {
    name: string
    email: string
    role: string
  }
  team_members: Array<{
    name: string
    email: string
    skills: string[]
  }>
  tasks: Array<{
    title: string
    description: string
    priority: string
    assignees: Array<{
      member_id: string
      role: string
    }>
  }>
}

const props = defineProps<{
  form: Form<ProjectForm>
}>()

const form = useLiveForm<ProjectForm>(() => props.form, {
  changeEvent: "validate",
  submitEvent: "submit",
  debounceInMiliseconds: 200,
})

// Basic fields
const nameField = form.field("name")
const descriptionField = form.field("description")
const statusField = form.field("status")
const isPublicField = form.field("is_public")

// Nested object fields
const ownerField = form.field("owner")
const ownerNameField = ownerField.field("name")
const ownerEmailField = ownerField.field("email")
const ownerRoleField = ownerField.field("role")

// Array fields
const teamMembersArray = form.fieldArray("team_members")
const tasksArray = form.fieldArray("tasks")

// Array operations
const addTeamMember = () => {
  teamMembersArray.add({
    name: "",
    email: "",
    skills: [],
  })
}

const removeTeamMember = (index: number) => {
  teamMembersArray.remove(index)
}

const addTask = () => {
  tasksArray.add({
    title: "",
    description: "",
    priority: "medium",
    assignees: [],
  })
}

const removeTask = (index: number) => {
  tasksArray.remove(index)
}

const addSkillToMember = (memberIndex: number) => {
  const member = teamMembersArray.field(memberIndex)
  const skillsArray = member.fieldArray("skills")
  skillsArray.add("")
}

const removeSkillFromMember = (memberIndex: number, skillIndex: number) => {
  const member = teamMembersArray.field(memberIndex)
  const skillsArray = member.fieldArray("skills")
  skillsArray.remove(skillIndex)
}

const addAssigneeToTask = (taskIndex: number) => {
  const task = tasksArray.fieldArray(`[${taskIndex}].assignees`)
  task.add({
    member_id: "",
    role: "contributor",
  })
}

const removeAssigneeFromTask = (taskIndex: number, assigneeIndex: number) => {
  tasksArray.fieldArray(`[${taskIndex}].assignees`).remove(assigneeIndex)
}

const submitForm = async () => {
  try {
    await form.submit()
    console.log("Form submitted successfully")
  } catch (error) {
    console.error("Form submission failed:", error)
  }
}
</script>

<template>
  <div class="flex flex-col lg:flex-row gap-6 max-w-7xl mx-auto p-6 items-start text-gray-900">
    <!-- Main Form Content -->
    <div class="flex-1">
      <div class="space-y-8">
        <!-- Basic Project Info -->
        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h2 class="text-xl font-semibold mb-4 text-gray-900">Project Information</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label :for="nameField.inputAttrs.value.id" class="block text-sm font-medium text-gray-700 mb-1"
                >Project Name</label
              >
              <input
                v-bind="nameField.inputAttrs.value"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                :class="{ 'border-red-500': nameField.isTouched.value && nameField.errorMessage.value }"
                placeholder="Enter project name"
              />
              <div
                v-if="nameField.isTouched.value && nameField.errorMessage.value"
                :id="nameField.inputAttrs.value.id + '-error'"
                class="text-red-500 text-sm mt-1"
              >
                {{ nameField.errorMessage.value }}
              </div>
            </div>

            <div>
              <label :for="statusField.inputAttrs.value.id" class="block text-sm font-medium text-gray-700 mb-1"
                >Status</label
              >
              <select
                v-bind="statusField.inputAttrs.value"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              >
                <option value="planning">Planning</option>
                <option value="active">Active</option>
                <option value="on_hold">On Hold</option>
                <option value="completed">Completed</option>
              </select>
            </div>
          </div>

          <div class="mt-4">
            <label :for="descriptionField.inputAttrs.value.id" class="block text-sm font-medium text-gray-700 mb-1"
              >Description</label
            >
            <textarea
              v-bind="descriptionField.inputAttrs.value"
              rows="3"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              placeholder="Describe your project"
            ></textarea>
            <div
              v-if="descriptionField.isTouched.value && descriptionField.errorMessage.value"
              :id="descriptionField.inputAttrs.value.id + '-error'"
              class="text-red-500 text-sm mt-1"
            >
              {{ descriptionField.errorMessage.value }}
            </div>
          </div>

          <div class="mt-4">
            <div class="flex items-center">
              <input
                v-bind="isPublicField.inputAttrs.value"
                type="checkbox"
                class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
              />
              <label :for="isPublicField.inputAttrs.value.id" class="ml-2 block text-sm text-gray-700">
                Make this project public
              </label>
            </div>
          </div>
        </div>

        <!-- Project Owner -->
        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h2 class="text-xl font-semibold mb-4 text-gray-900">Project Owner</h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label :for="ownerNameField.inputAttrs.value.id" class="block text-sm font-medium text-gray-700 mb-1"
                >Name</label
              >
              <input
                v-bind="ownerNameField.inputAttrs.value"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                :class="{ 'border-red-500': ownerNameField.isTouched.value && ownerNameField.errorMessage.value }"
                placeholder="Owner name"
              />
              <div
                v-if="ownerNameField.isTouched.value && ownerNameField.errorMessage.value"
                :id="ownerNameField.inputAttrs.value.id + '-error'"
                class="text-red-500 text-sm mt-1"
              >
                {{ ownerNameField.errorMessage.value }}
              </div>
            </div>

            <div>
              <label :for="ownerEmailField.inputAttrs.value.id" class="block text-sm font-medium text-gray-700 mb-1"
                >Email</label
              >
              <input
                v-bind="ownerEmailField.inputAttrs.value"
                type="email"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                :class="{ 'border-red-500': ownerEmailField.isTouched.value && ownerEmailField.errorMessage.value }"
                placeholder="owner@example.com"
              />
              <div
                v-if="ownerEmailField.isTouched.value && ownerEmailField.errorMessage.value"
                :id="ownerEmailField.inputAttrs.value.id + '-error'"
                class="text-red-500 text-sm mt-1"
              >
                {{ ownerEmailField.errorMessage.value }}
              </div>
            </div>

            <div>
              <label :for="ownerRoleField.inputAttrs.value.id" class="block text-sm font-medium text-gray-700 mb-1"
                >Role</label
              >
              <select
                v-bind="ownerRoleField.inputAttrs.value"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              >
                <option value="project_manager">Project Manager</option>
                <option value="tech_lead">Tech Lead</option>
                <option value="product_owner">Product Owner</option>
                <option value="team_lead">Team Lead</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Team Members -->
        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-xl font-semibold text-gray-900">Team Members</h2>
            <button
              @click="addTeamMember"
              class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 transition-colors"
            >
              Add Member
            </button>
          </div>

          <div v-if="teamMembersArray.fields.value.length === 0" class="text-gray-500 text-center py-8">
            No team members added yet
          </div>

          <div
            v-for="(memberField, memberIndex) in teamMembersArray.fields.value"
            :key="memberIndex"
            class="border border-gray-200 rounded-lg p-4 mb-4"
          >
            <div class="flex justify-between items-start mb-4">
              <h3 class="text-lg font-medium">Member {{ memberIndex + 1 }}</h3>
              <button @click="removeTeamMember(memberIndex)" class="text-red-600 hover:text-red-800 transition-colors">
                Remove
              </button>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label
                  :for="memberField.field('name').inputAttrs.value.id"
                  class="block text-sm font-medium text-gray-700 mb-1"
                  >Name</label
                >
                <input
                  v-bind="memberField.field('name').inputAttrs.value"
                  class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  :class="{
                    'border-red-500':
                      memberField.field('name').isTouched.value && memberField.field('name').errorMessage.value,
                  }"
                  placeholder="Member name"
                />
                <div
                  v-if="memberField.field('name').errorMessage.value"
                  :id="memberField.field('name').inputAttrs.value.id + '-error'"
                  class="text-red-500 text-sm mt-1"
                >
                  {{ memberField.field("name").errorMessage.value }}
                </div>
              </div>

              <div>
                <label
                  :for="memberField.field('email').inputAttrs.value.id"
                  class="block text-sm font-medium text-gray-700 mb-1"
                  >Email</label
                >
                <input
                  v-bind="memberField.field('email').inputAttrs.value"
                  type="email"
                  class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  :class="{
                    'border-red-500':
                      memberField.field('email').isTouched.value && memberField.field('email').errorMessage.value,
                  }"
                  placeholder="member@example.com"
                />
                <div
                  v-if="memberField.field('email').isTouched.value && memberField.field('email').errorMessage.value"
                  :id="memberField.field('email').inputAttrs.value.id + '-error'"
                  class="text-red-500 text-sm mt-1"
                >
                  {{ memberField.field("email").errorMessage.value }}
                </div>
              </div>
            </div>

            <!-- Skills array for each member -->
            <div>
              <div class="flex justify-between items-center mb-2">
                <label class="block text-sm font-medium text-gray-700">Skills</label>
                <button
                  @click="addSkillToMember(memberIndex)"
                  class="text-blue-600 hover:text-blue-800 text-sm transition-colors"
                >
                  Add Skill
                </button>
              </div>

              <div class="space-y-2">
                <div
                  v-for="(skillField, skillIndex) in memberField.fieldArray('skills').fields.value"
                  :key="skillIndex"
                  class="flex gap-2"
                >
                  <input
                    v-bind="skillField.inputAttrs.value"
                    class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    placeholder="Enter skill"
                  />
                  <button
                    @click="removeSkillFromMember(memberIndex, skillIndex)"
                    class="text-red-600 hover:text-red-800 px-2 transition-colors"
                  >
                    ×
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tasks with Nested Assignees -->
        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-xl font-semibold">Tasks</h2>
            <button
              @click="addTask"
              class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
            >
              Add Task
            </button>
          </div>

          <div v-if="tasksArray.fields.value.length === 0" class="text-gray-500 text-center py-8">
            No tasks added yet
          </div>

          <div
            v-for="(taskField, taskIndex) in tasksArray.fields.value"
            :key="taskIndex"
            class="border border-gray-200 rounded-lg p-4 mb-4"
          >
            <div class="flex justify-between items-start mb-4">
              <h3 class="text-lg font-medium">Task {{ taskIndex + 1 }}</h3>
              <button @click="removeTask(taskIndex)" class="text-red-600 hover:text-red-800 transition-colors">
                Remove
              </button>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <label
                  :for="taskField.field('title').inputAttrs.value.id"
                  class="block text-sm font-medium text-gray-700 mb-1"
                  >Title</label
                >
                <input
                  v-bind="taskField.field('title').inputAttrs.value"
                  class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  :class="{
                    'border-red-500':
                      taskField.field('title').isTouched.value && taskField.field('title').errorMessage.value,
                  }"
                  placeholder="Task title"
                />
                <div
                  v-if="taskField.field('title').isTouched.value && taskField.field('title').errorMessage.value"
                  :id="taskField.field('title').inputAttrs.value.id + '-error'"
                  class="text-red-500 text-sm mt-1"
                >
                  {{ taskField.field("title").errorMessage.value }}
                </div>
              </div>

              <div>
                <label
                  :for="taskField.field('priority').inputAttrs.value.id"
                  class="block text-sm font-medium text-gray-700 mb-1"
                  >Priority</label
                >
                <select
                  v-bind="taskField.field('priority').inputAttrs.value"
                  class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                  <option value="urgent">Urgent</option>
                </select>
              </div>
            </div>

            <div class="mb-4">
              <label
                :for="taskField.field('description').inputAttrs.value.id"
                class="block text-sm font-medium text-gray-700 mb-1"
                >Description</label
              >
              <textarea
                v-bind="taskField.field('description').inputAttrs.value"
                rows="2"
                class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                placeholder="Task description"
              ></textarea>
            </div>

            <!-- Assignees nested array -->
            <div>
              <div class="flex justify-between items-center mb-2">
                <label class="block text-sm font-medium text-gray-700">Assignees</label>
                <button
                  @click="addAssigneeToTask(taskIndex)"
                  class="text-purple-600 hover:text-purple-800 text-sm transition-colors"
                >
                  Add Assignee
                </button>
              </div>

              <div class="space-y-2">
                <div
                  v-for="(assigneeField, assigneeIndex) in taskField.fieldArray('assignees').fields.value"
                  :key="assigneeIndex"
                  class="flex gap-2 items-end"
                >
                  <div class="flex-1">
                    <input
                      v-bind="assigneeField.field('member_id').inputAttrs.value"
                      class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      placeholder="Member ID"
                    />
                  </div>
                  <div class="flex-1">
                    <select
                      v-bind="assigneeField.field('role').inputAttrs.value"
                      class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    >
                      <option value="contributor">Contributor</option>
                      <option value="reviewer">Reviewer</option>
                      <option value="lead">Lead</option>
                    </select>
                  </div>
                  <button
                    @click="removeAssigneeFromTask(taskIndex, assigneeIndex)"
                    class="text-red-600 hover:text-red-800 px-2 pb-2 transition-colors"
                  >
                    ×
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Sticky Sidebar -->
    <div class="w-full lg:w-80 lg:sticky lg:top-6 lg:self-start">
      <div class="bg-white p-6 rounded-lg shadow-sm border space-y-6">
        <!-- Form Status -->
        <div>
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Form Status</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium text-gray-700">Valid:</span>
              <span :class="form.isValid.value ? 'text-green-600' : 'text-red-600'" class="text-sm font-semibold">
                {{ form.isValid.value ? "Yes" : "No" }}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium text-gray-700">Dirty:</span>
              <span :class="form.isDirty.value ? 'text-orange-600' : 'text-gray-600'" class="text-sm font-semibold">
                {{ form.isDirty.value ? "Yes" : "No" }}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium text-gray-700">Touched:</span>
              <span :class="form.isTouched.value ? 'text-blue-600' : 'text-gray-600'" class="text-sm font-semibold">
                {{ form.isTouched.value ? "Yes" : "No" }}
              </span>
            </div>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-gray-200"></div>

        <!-- Form Actions -->
        <div>
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Actions</h3>
          <div class="space-y-3">
            <button
              @click="form.reset()"
              class="w-full bg-gray-600 text-white px-6 py-3 rounded-md hover:bg-gray-700 transition-colors text-sm font-medium"
            >
              Reset Form
            </button>
            <button
              @click="submitForm"
              :disabled="!form.isValid.value"
              class="w-full bg-indigo-600 text-white px-6 py-3 rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm font-medium"
            >
              Submit Project
            </button>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-gray-200"></div>

        <!-- Server State -->
        <div>
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Form Data</h3>
          <div class="space-y-3">
            <div class="bg-gray-50 rounded-md p-3">
              <h4 class="text-sm font-medium text-gray-700 mb-2">Form Name</h4>
              <p class="text-sm text-gray-600">{{ props.form.name }}</p>
            </div>
            <div class="bg-gray-50 rounded-md p-3">
              <h4 class="text-sm font-medium text-gray-700 mb-2">Validation</h4>
              <p class="text-xs text-gray-500">Valid: {{ props.form.valid }}</p>
              <div v-if="Object.keys(props.form.errors || {}).length > 0" class="mt-2">
                <p class="text-xs font-medium text-red-600 mb-1">Current Errors:</p>
                <ul class="text-xs text-red-500 space-y-1">
                  <li v-for="(errors, field) in props.form.errors" :key="field" class="flex justify-between">
                    <span class="font-mono">{{ field }}:</span>
                    <span>{{ Array.isArray(errors) ? errors[0] : errors }}</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
