<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
}>()
</script>

<template>
  <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between mb-6 page-header">
    <div class="mb-4 mb-sm-0 page-header__content">
      <h1 class="text-h5 text-sm-h4 font-weight-bold mb-1 page-header__title">{{ title }}</h1>
      <p v-if="subtitle" class="text-body-2 text-sm-body-1 text-medium-emphasis">{{ subtitle }}</p>
    </div>
    <div class="d-flex align-center flex-wrap page-header__actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<style scoped>
.page-header {
  gap: 1rem;
}

.page-header__content {
  min-width: 0;
  flex: 1;
}

.page-header__title {
  word-break: break-word;
  overflow-wrap: break-word;
  hyphens: auto;
}

.page-header__actions {
  gap: 0.5rem;
}

@media (max-width: 599px) {
  .page-header__actions {
    width: 100%;
    justify-content: flex-start;
  }

  :deep(.v-btn) {
    flex: 1 1 auto;
  }
}
</style>
