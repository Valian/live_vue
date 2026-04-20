<script setup lang="ts">
import { useLiveVue } from "live_vue"

const source = useLiveVue("data-source")
</script>

<template>
  <div v-if="source">
    <span data-pw-count>{{ source.vue.props.count }}</span>
    <span data-pw-label>{{ source.vue.props.label }}</span>
  </div>
</template>
