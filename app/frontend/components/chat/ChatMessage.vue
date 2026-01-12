<script setup lang="ts">
import { computed } from 'vue'
import { marked } from 'marked'
import { useTypingEffect } from '@/composables/useTypingEffect'
import ChatCitations from './ChatCitations.vue'
import type { Message } from '@/types'

const props = defineProps<{
  message: Message
  /** Whether this is a newly received message (enables typing effect) */
  isNew?: boolean
}>()

const isUser = computed(() => props.message.role === 'user_role')
const isAssistant = computed(() => props.message.role === 'assistant_role')
const hasCitations = computed(() => (props.message.citations?.length ?? 0) > 0)

// Typing effect for new assistant messages only
const { displayedContent, isTyping, skipToEnd } = useTypingEffect(
  () => props.message.content || '',
  {
    speed: 70,
    enabled: isAssistant.value && !!props.isNew,
  }
)

const renderedContent = computed(() => {
  const content = isAssistant.value && props.isNew
    ? displayedContent.value
    : props.message.content

  if (!content) return ''
  if (!isAssistant.value) return content

  return marked.parse(content, { breaks: true, gfm: true }) as string
})

// Status indicators for user messages
const STATUS_CONFIG: Record<string, { icon: string; color: string }> = {
  pending: { icon: 'mdi-check', color: 'grey' },
  processing: { icon: 'mdi-check', color: 'grey' },
  completed: { icon: 'mdi-check-all', color: 'info' },
  failed: { icon: 'mdi-alert-circle', color: 'error' },
}

const statusIcon = computed(() => STATUS_CONFIG[props.message.status]?.icon ?? '')
const statusColor = computed(() => STATUS_CONFIG[props.message.status]?.color ?? 'grey')

const formattedTime = computed(() =>
  new Date(props.message.created_at).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit'
  })
)
</script>

<template>
  <div
    class="message-container"
    :class="{
      'message-user': isUser,
      'message-assistant': isAssistant
    }"
    :data-testid="`chat-message-${message.id}`"
  >
    <!-- Avatar -->
    <v-avatar
      :color="isUser ? 'primary' : 'secondary'"
      size="36"
      class="message-avatar"
    >
      <v-icon :icon="isUser ? 'mdi-account' : 'mdi-robot'" />
    </v-avatar>

    <!-- Content -->
    <div class="message-content">
      <v-card
        :color="isUser ? 'primary' : 'grey-lighten-4'"
        :class="{ 'text-white': isUser }"
        class="rounded-lg pa-3"
        elevation="0"
      >
        <!-- Message text: markdown for assistant, plain text for user -->
        <div
          v-if="isAssistant"
          class="message-text text-body-1 markdown-content"
          v-html="renderedContent"
          @click="isTyping && skipToEnd()"
        />
        <div
          v-else
          class="message-text text-body-1"
          style="white-space: pre-wrap;"
        >
          {{ message.content }}
        </div>

        <!-- Error message -->
        <v-alert
          v-if="message.status === 'failed' && message.error_message"
          type="error"
          variant="tonal"
          density="compact"
          class="mt-2"
        >
          {{ message.error_message }}
        </v-alert>
      </v-card>

      <!-- Citations (only for assistant messages, shown after typing completes) -->
      <ChatCitations
        v-if="isAssistant && hasCitations && !isTyping"
        :citations="message.citations"
        class="mt-2"
      />

      <!-- Footer: time and status -->
      <div class="d-flex align-center gap-2 mt-1 px-1">
        <span class="text-caption text-grey">{{ formattedTime }}</span>

        <!-- Status indicator for user messages -->
        <v-icon
          v-if="isUser && statusIcon"
          :icon="statusIcon"
          :color="statusColor"
          size="x-small"
        />

        <!-- Token count for assistant messages -->
        <span v-if="isAssistant && message.token_count" class="text-caption text-grey ml-2">{{ message.token_count }} tokens
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.message-container {
  display: flex;
  gap: 12px;
  max-width: 80%;
}

.message-user {
  margin-left: auto;
  flex-direction: row-reverse;
}

.message-assistant {
  margin-right: auto;
}

.message-content {
  flex: 1;
  min-width: 0;
}

.message-user .message-content {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.message-avatar {
  flex-shrink: 0;
}

.message-text {
  word-break: break-word;
}

/* Espaciado para listas en markdown */
.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  padding-left: 1.5em;
  margin: 0.5em 0;
}

.markdown-content :deep(p:last-child),
.markdown-content :deep(ul:last-child),
.markdown-content :deep(ol:last-child) {
  margin-bottom: 0;
}
</style>
