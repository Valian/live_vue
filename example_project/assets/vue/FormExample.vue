<script setup lang="ts">
import { toRef } from "vue"
import { Form, useLiveForm } from "live_vue"
import ShowState from "./ShowState.vue"

type User = {
  first_name: string
  last_name: string
  email: string
  country: string
}

const props = defineProps<{
  form: Form<User>
}>()

const { submit, form, fields, isSubmitting } = useLiveForm<User>(toRef(props, "form"), {
  changeEvent: "validate",
  submitEvent: "submit",
})

const firstName = fields["first_name"]
const lastName = fields["last_name"]
const email = fields["email"]
const country = fields["country"]
</script>

<template>
  <ShowState :server-state="props" :client-state="{ formMeta: form.meta }">
    <form class="flex flex-col gap-4">
      <input
        v-model="firstName.value"
        class="rounded"
        :name="firstName.name"
        :error="firstName.touched && firstName.errorMessage"
        placeholder="name"
      />
      <div v-if="firstName.touched && firstName.errorMessage" class="text-red-500">{{ firstName.errorMessage }}</div>
      <input
        v-model="lastName.value"
        class="rounded"
        :name="lastName.name"
        :error="lastName.touched && lastName.errorMessage"
        placeholder="surname"
      />
      <div v-if="lastName.touched && lastName.errorMessage" class="text-red-500">{{ lastName.errorMessage }}</div>
      <input
        v-model="email.value"
        class="rounded"
        :name="email.name"
        :error="email.touched && email.errorMessage"
        placeholder="email"
      />
      <div v-if="email.touched && email.errorMessage" class="text-red-500">{{ email.errorMessage }}</div>
      <select v-model="country.value" class="rounded" :name="country.name">
        <option value="USA">USA</option>
        <option value="Canada">Canada</option>
        <option value="UK">UK</option>
        <option value="Germany">Germany</option>
        <option value="France">France</option>
        <option value="Japan">Japan</option>
      </select>
      <div v-if="country.touched && country.errorMessage" class="text-red-500">{{ country.errorMessage }}</div>
      <button
        :disabled="(form.touched && !form.meta.valid) || isSubmitting || !form.meta.dirty"
        type="button"
        @click="submit"
        class="mt-4 bg-black text-white rounded p-2 block disabled:opacity-50"
      >
        Save
      </button>
    </form>
  </ShowState>
</template>
