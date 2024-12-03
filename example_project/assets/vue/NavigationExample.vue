<template>
  <div class="flex flex-col gap-8">
    <div class="flex gap-4">
      <Link v-if="hasParams" :patch="currentPath" class="border border-white px-4 py-2 rounded">
        Page {{ page }}: Patch
        <small>Remove params</small>
      </Link>
      <Link v-else :patch="`${currentPath}?one=1&two=hello&three=world`" class="border border-white px-4 py-2 rounded">
        Page {{ page }}: Patch
      </Link>
      <Link :navigate="otherPagePath" class="border border-white px-4 py-2 rounded"
        >Page {{ otherPage }}: Navigate</Link
      >
      <Link href="/dead" class="border border-white px-4 py-2 rounded">
        Back to Examples <small>Normal Link</small>
      </Link>
    </div>

    <div class="flex flex-col gap-2">
      <p><strong>Page:</strong> {{ page }}</p>
      <div>
        <p><strong>Params:</strong></p>
        <pre v-if="params">{{ JSON.stringify(params, null, 2) }}</pre>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Link } from "live_vue"
import { computed } from "vue"

const props = defineProps<{
  page: string
  otherPage: string
  otherPagePath: string
  params?: Record<string, any>
}>()
const hasParams = computed(() => Object.keys(props.params ?? {})?.length)
const currentPath = window.location.pathname
</script>
