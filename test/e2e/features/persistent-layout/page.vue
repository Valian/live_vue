<script setup lang="ts">
import { useLiveNavigation } from "live_vue"

// These are merged from slot props and live view props
defineProps<{ page: string; layoutCount: number }>()

const { patch } = useLiveNavigation()
</script>

<template>
  <div>
    <h2>Page Component</h2>
    <p>
      Current page: <span data-pw-page>{{ page }}</span>
    </p>
    <p>
      Layout counter (from slot props): <span data-pw-page-layout-count>{{ layoutCount }}</span>
    </p>
    <nav>
      <a href="#" data-pw-nav-page1 @click.prevent="patch('/persistent-layout/page1')">Page 1</a>
      |
      <a href="#" data-pw-nav-page2 @click.prevent="patch('/persistent-layout/page2')">Page 2</a>
      |
      <a href="#" data-pw-nav-page3 @click.prevent="patch('/persistent-layout/page3')">Page 3</a>
    </nav>
    <div data-pw-page-slot>
      <slot />
    </div>
  </div>
</template>
