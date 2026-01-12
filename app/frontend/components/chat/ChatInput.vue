<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{
  modelValue: string
  disabled?: boolean
  loading?: boolean
  placeholder?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'send'): void
}>()

const textareaRef = ref<HTMLTextAreaElement | null>(null)

const localValue = computed({
  get: () => props.modelValue,
  set: (value: string) => emit('update:modelValue', value)
})

const canSend = computed(() =>
  localValue.value.trim().length > 0 && !props.disabled && !props.loading
)

function handleKeyDown(event: KeyboardEvent) {
  // Send on Enter (without Shift)
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    if (canSend.value) {
      emit('send')
    }
  }
}

function handleSend() {
  if (canSend.value) {
    emit('send')
  }
}
</script>

<template>
  <div class="chat-input-container">
    <v-textarea
      ref="textareaRef"
      v-model="localValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :loading="loading"
      variant="outlined"
      density="compact"
      rows="1"
      max-rows="5"
      auto-grow
      hide-details
      class="chat-textarea"
      data-testid="chat-input-textarea"
      @keydown="handleKeyDown"
    >
      <template #append-inner>
        <v-btn
          icon
          variant="text"
          size="small"
          color="primary"
          :disabled="!canSend"
          :loading="loading"
          data-testid="chat-btn-send"
          @click="handleSend"
        >
          <v-icon>mdi-send</v-icon>
        </v-btn>
      </template>
    </v-textarea>

    <div class="text-caption text-grey mt-1 px-1">
      <kbd>Enter</kbd> para enviar · <kbd>Shift + Enter</kbd> para nueva línea
    </div>
  </div>
</template>

<style scoped>
.chat-input-container {
  width: 100%;
}

.chat-textarea :deep(.v-field__input) {
  padding-right: 48px;
}

kbd {
  background-color: rgba(0, 0, 0, 0.08);
  border-radius: 4px;
  padding: 2px 6px;
  font-size: 0.75rem;
  font-family: monospace;
}
</style>
