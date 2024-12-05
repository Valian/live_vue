<template>
  <div class="space-y-8">
    <!-- Link navigate section -->
    <div class="space-y-3">
      <h2 class="text-xl font-semibold text-orange-phoenix">Link navigate</h2>
      <p class="text-white/70 mb-4">
        Navigate dismounts the current LiveView and mounts a new one, while keeping the current layout. During
        navigation, a <code class="text-orange-300">phx-loading</code> class is added to indicate loading state. Only
        works between LiveViews in the same session.
      </p>
      <div class="flex gap-4">
        <Link
          v-for="page in ['one', 'two']"
          :key="page"
          :navigate="`/navigation/page_${page}`"
          class="inline-block px-4 py-2 rounded-lg bg-white/10 hover:bg-orange-600/20 transition-colors border border-orange-600/30"
        >
          Page {{ page }}
        </Link>
      </div>
    </div>

    <!-- Patch section -->
    <div class="space-y-3">
      <h2 class="text-xl font-semibold text-orange-phoenix">Patch</h2>
      <p class="text-white/70 mb-4">
        Patch updates the current LiveView without mounting/dismounting, sending only minimal diffs to the client. It
        triggers <code class="text-orange-300">handle_params/3</code> callback and maintains scroll position. If you try
        to patch to a different LiveView, it falls back to full page reload.
      </p>
      <Link
        :patch="hasParams ? '?' : `?sort=asc&filter=active`"
        class="inline-block px-4 py-2 rounded-lg bg-white/10 hover:bg-orange-600/20 transition-colors border border-orange-600/30"
      >
        {{ hasParams ? "Remove params" : "Add params" }}
      </Link>

      <div v-if="params" class="mt-4 p-4 rounded-lg bg-white/5 border border-white/10">
        <p class="text-orange-phoenix font-medium mb-2">URL Parameters:</p>
        <pre class="font-mono text-sm">{{ JSON.stringify(params, null, 2) }}</pre>
      </div>
    </div>

    <!-- Href section -->
    <div class="space-y-3">
      <h2 class="text-xl font-semibold text-orange-phoenix">Href</h2>
      <p class="text-white/70 mb-4">
        Regular href performs HTTP-based navigation with full page reloads. It works everywhere, including across
        different LiveView sessions and external links. This is the fallback mechanism when live navigation isn't
        possible.
      </p>
      <Link
        href="/dead"
        class="inline-block px-4 py-2 rounded-lg bg-white/10 hover:bg-orange-600/20 transition-colors border border-orange-600/30"
      >
        Back to Examples
      </Link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Link } from "live_vue"
import { computed } from "vue"

const props = defineProps<{
  params: Record<string, string>
}>()

const hasParams = computed(() => Object.keys(props.params).length > 0)
</script>
