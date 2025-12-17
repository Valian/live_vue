<template>
  <div>
    <h1>Navigation Test</h1>
    <div id="current-params">{{ JSON.stringify(params) }}</div>
    <div id="current-query">{{ JSON.stringify(query_params) }}</div>

    <button @click="patchQuery" id="patch-btn">Patch Query</button>
    <button @click="navigateToAlt" id="navigate-btn">Navigate to Alt</button>
    <button @click="navigateBack" id="navigate-back-btn">Navigate Back</button>
  </div>
</template>

<script setup lang="ts">
import { useLiveNavigation } from "live_vue"

interface Props {
  params: Record<string, any>
  query_params: Record<string, any>
}

const props = defineProps<Props>()
const { patch, navigate } = useLiveNavigation()

const patchQuery = () => {
  patch({ foo: "bar", timestamp: Date.now().toString() })
}

const navigateToAlt = () => {
  navigate("/navigation/alt/test2?baz=qux")
}

const navigateBack = () => {
  navigate("/navigation/test1")
}
</script>
