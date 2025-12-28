<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
}>()
</script>

<template>
  <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between mb-6">
    <div class="mb-4 mb-sm-0">
      <h1 class="text-h5 text-sm-h4 font-weight-bold mb-1">{{ title }}</h1>
      <p v-if="subtitle" class="text-body-2 text-sm-body-1 text-medium-emphasis">{{ subtitle }}</p>
    </div>
    <div class="d-flex align-center gap-2 w-100 w-sm-auto">
      <slot name="actions" />
    </div>
  </div>
</template>

<style scoped>
@media (max-width: 599px) {
  :deep(.v-btn) {
    width: 100%;
  }
}
</style>
