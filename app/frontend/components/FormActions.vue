<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    primaryLabel: string
    primaryLoading?: boolean
    primaryDisabled?: boolean
    cancelLabel?: string
  }>(),
  {
    cancelLabel: 'Cancelar'
  }
)

defineEmits<{
  (e: 'cancel'): void
}>()
</script>

<template>
  <div class="d-flex justify-end gap-3">
    <v-btn variant="text" :disabled="props.primaryLoading" @click="$emit('cancel')">
      {{ props.cancelLabel }}
    </v-btn>
    <v-btn
      color="primary"
      type="submit"
      :loading="props.primaryLoading"
      :disabled="props.primaryDisabled || props.primaryLoading"
    >
      {{ props.primaryLabel }}
    </v-btn>
  </div>
</template>
