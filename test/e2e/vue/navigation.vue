<script setup lang="ts">
import { useLiveNavigation } from 'live_vue'

interface Props {
  params: Record<string, any>
  query_params: Record<string, any>
}

const props = defineProps<Props>()
const { patch, navigate } = useLiveNavigation()

function patchQuery() {
  patch({ foo: 'bar', timestamp: Date.now().toString() })
}

function navigateToAlt() {
  navigate('/navigation/alt/test2?baz=qux')
}

function navigateBack() {
  navigate('/navigation/test1')
}
</script>

<template>
  <div>
    <h1>Navigation Test</h1>
    <div id="current-params">
      {{ JSON.stringify(params) }}
    </div>
    <div id="current-query">
      {{ JSON.stringify(query_params) }}
    </div>

    <button id="patch-btn" @click="patchQuery">
      Patch Query
    </button>
    <button id="navigate-btn" @click="navigateToAlt">
      Navigate to Alt
    </button>
    <button id="navigate-back-btn" @click="navigateBack">
      Navigate Back
    </button>
  </div>
</template>
