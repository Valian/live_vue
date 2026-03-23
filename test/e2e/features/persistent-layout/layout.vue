<script setup lang="ts">
import { ref } from "vue"
const count = ref(0)
</script>

<template>
  <div>
    <h2>Persistent Layout</h2>
    <p>
      Layout counter (Vue-only state):
      <span data-pw-layout-counter>{{ count }}</span>
    </p>
    <button data-pw-layout-btn @click="count++">Increment layout counter</button>
    <hr />
    <slot :layout-count="count" />
    <aside data-pw-sidebar>
      <slot name="sidebar" :layout-count="count" />
    </aside>
  </div>
</template>
