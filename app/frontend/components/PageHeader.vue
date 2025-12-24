<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
}>()
</script>

<template>
  <div class="d-flex align-center justify-space-between mb-6">
    <div>
      <h1 class="text-h4 font-weight-bold mb-1">{{ title }}</h1>
      <p v-if="subtitle" class="text-body-1 text-medium-emphasis">{{ subtitle }}</p>
    </div>
    <div class="d-flex align-center gap-3">
      <slot name="actions" />
    </div>
  </div>
</template>
