<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    modelValue: boolean
    title: string
    text: string
    confirmLabel?: string
    cancelLabel?: string
    loading?: boolean
    dataTestId?: string
  }>(),
  {
    confirmLabel: 'Confirmar',
    cancelLabel: 'Cancelar',
    loading: false,
    dataTestId: 'confirm-dialog'
  }
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'confirm'): void
  (e: 'cancel'): void
}>()

function close() {
  emit('update:modelValue', false)
}
</script>

<template>
  <v-dialog
    :model-value="props.modelValue"
    max-width="440"
    @update:model-value="(v) => emit('update:modelValue', v)"
  >
    <v-card class="rounded-xl" elevation="0" border :data-testid="props.dataTestId">
      <v-card-title class="text-h6">{{ props.title }}</v-card-title>
      <v-card-text class="text-body-2 text-medium-emphasis">
        {{ props.text }}
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn
          variant="text"
          :disabled="props.loading"
          :data-testid="`${props.dataTestId}-btn-cancel`"
          @click="emit('cancel'); close()"
        >
          {{ props.cancelLabel }}
        </v-btn>
        <v-btn
          color="error"
          :loading="props.loading"
          :disabled="props.loading"
          :data-testid="`${props.dataTestId}-btn-confirm`"
          @click="emit('confirm')"
        >
          {{ props.confirmLabel }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>
