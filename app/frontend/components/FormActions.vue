<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    primaryLabel: string
    primaryLoading?: boolean
    primaryDisabled?: boolean
    cancelLabel?: string
    cancelDisabled?: boolean
    dataTestId?: string
  }>(),
  {
    cancelLabel: 'Cancelar',
    dataTestId: 'form'
  }
)

defineEmits<{
  (e: 'cancel'): void
}>()
</script>

<template>
  <div class="d-flex justify-end gap-3">
    <v-btn
      variant="text"
      :disabled="props.primaryLoading || props.cancelDisabled"
      :data-testid="`${props.dataTestId}-btn-cancel`"
      @click="$emit('cancel')"
    >
      {{ props.cancelLabel }}
    </v-btn>
    <v-btn
      color="primary"
      type="submit"
      :loading="props.primaryLoading"
      :disabled="props.primaryDisabled || props.primaryLoading"
      :data-testid="`${props.dataTestId}-btn-submit`"
    >
      {{ props.primaryLabel }}
    </v-btn>
  </div>
</template>
