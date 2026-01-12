<script setup lang="ts">
import { ref, computed, nextTick, onMounted, watch } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useChatsChannel } from '@/composables/useChatsChannel'
import { useGlobalNotification } from '@/composables/useGlobalNotification'
import ChatMessage from '@/components/chat/ChatMessage.vue'
import ChatInput from '@/components/chat/ChatInput.vue'
import type { Chat, Message, GlobalStore } from '@/types'

const props = defineProps<{
  chat: Chat
  messages: Message[]
  canSendMessage: boolean
  chatGlobalStores: GlobalStore[]
  globalStores: GlobalStore[]
  canEditGlobalStores: boolean
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()
const { show: showNotification } = useGlobalNotification()

// Chat channel for real-time updates
const {
  messages: channelMessages,
  chatTitle,
  isConnected,
  isReconnecting,
  initializeMessages,
  connect,
  isNewMessage
} = useChatsChannel(props.chat.id)

// Local state
const newMessage = ref('')
const sending = ref(false)
const editingTitle = ref(false)
const titleInput = ref('')
const messagesContainer = ref<HTMLElement | null>(null)
const showGlobalStoresDialog = ref(false)
const selectedGlobalStoreIds = ref<number[]>([])
const savingGlobalStores = ref(false)

// Computed
const displayTitle = computed(() => chatTitle.value || props.chat.title)
const displayMessages = computed(() => channelMessages.value)
const hasMessages = computed(() => displayMessages.value.length > 0)
const isThinking = computed(() => {
  const lastMessage = displayMessages.value[displayMessages.value.length - 1]
  return lastMessage?.role === 'user_role' &&
    (lastMessage.status === 'pending' || lastMessage.status === 'processing')
})

// Connection status
const connection = computed(() => {
  if (isReconnecting.value) return { status: 'reconnecting', color: 'warning' }
  if (isConnected.value) return { status: 'connected', color: 'success' }
  return { status: 'disconnected', color: 'error' }
})

// Initialize
onMounted(() => {
  initializeMessages(props.messages, props.chat.title)
  connect({
    onMessageCreated: () => scrollToBottom(),
    onMessageUpdated: () => scrollToBottom(),
    onMessageFailed: handleMessageFailed
  })
  scrollToBottom()
})

function handleMessageFailed(messageId: number, _errorType: string, content: string) {
  // Find the message - try by ID first, then fallback to last pending user message
  let message = channelMessages.value.find(m => m.id === messageId)

  if (!message) {
    // Fallback: find the last pending/processing user message (optimistic message)
    message = [...channelMessages.value]
      .reverse()
      .find(m => m.role === 'user_role' && (m.status === 'pending' || m.status === 'processing'))
  }

  if (message) {
    message.status = 'failed'
    message.error_message = content
  }

  // Show notification
  showNotification(content, 'error')
}

// Watch for new messages to scroll
watch(displayMessages, () => {
  nextTick(() => scrollToBottom())
}, { deep: true })

// Methods
function scrollToBottom() {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
  })
}

async function sendMessage() {
  if (!newMessage.value.trim() || sending.value) return

  const content = newMessage.value.trim()
  newMessage.value = ''
  sending.value = true

  try {
    // Optimistic update - add pending message
    const optimisticMessage: Message = {
      id: Date.now(), // Temporary ID
      role: 'user_role',
      content,
      status: 'pending',
      token_count: null,
      error_message: null,
      created_at: new Date().toISOString(),
      citations: []
    }
    channelMessages.value.push(optimisticMessage)
    scrollToBottom()

    // Send via HTTP
    await new Promise<void>((resolve, reject) => {
      router.post(
        `/chats/${props.chat.id}/messages`,
        { message: { content } },
        {
          preserveState: true,
          preserveScroll: true,
          onSuccess: () => resolve(),
          onError: () => reject(new Error('Failed to send message')),
          onFinish: () => {
            sending.value = false
          }
        }
      )
    })
  } catch {
    // Remove optimistic message on error
    channelMessages.value = channelMessages.value.filter(m => m.id !== Date.now())
    sending.value = false
  }
}

function startEditingTitle() {
  titleInput.value = displayTitle.value
  editingTitle.value = true
}

function saveTitle() {
  if (!titleInput.value.trim()) {
    editingTitle.value = false
    return
  }

  router.patch(
    `/chats/${props.chat.id}`,
    { chat: { title: titleInput.value.trim() } },
    {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => {
        chatTitle.value = titleInput.value.trim()
        editingTitle.value = false
      },
      onError: () => {
        editingTitle.value = false
      }
    }
  )
}

function cancelEditingTitle() {
  editingTitle.value = false
}

function openGlobalStoresDialog() {
  selectedGlobalStoreIds.value = props.chatGlobalStores.map(s => s.id)
  showGlobalStoresDialog.value = true
}

function saveGlobalStores() {
  savingGlobalStores.value = true
  router.patch(
    `/chats/${props.chat.id}`,
    { chat: { global_store_ids: selectedGlobalStoreIds.value } },
    {
      preserveState: false,
      preserveScroll: true,
      onFinish: () => {
        savingGlobalStores.value = false
        showGlobalStoresDialog.value = false
      }
    }
  )
}
</script>

<template>
  <v-container class="py-6 fill-height" fluid>
    <v-row class="fill-height">
      <v-col cols="12" class="d-flex flex-column" style="max-height: calc(100vh - 120px);">
        <!-- Header -->
        <div class="d-flex align-center justify-space-between mb-4 flex-wrap gap-2">
          <div class="d-flex align-center gap-2 grow min-width-0">
            <v-btn
              icon
              variant="text"
              size="small"
              :title="t('common.back')"
              data-testid="chats-btn-back"
              class="shrink-0"
              @click="navigateTo('/chats')"
            >
              <v-icon>mdi-arrow-left</v-icon>
            </v-btn>

            <!-- Title display/edit -->
            <template v-if="!editingTitle">
              <h1 class="text-h5 font-weight-medium text-truncate" data-testid="chats-title">
                {{ displayTitle }}
              </h1>
              <v-btn
                v-if="canSendMessage"
                icon
                variant="text"
                size="x-small"
                :title="t('chats.chat_detail.edit_title')"
                data-testid="chats-btn-edit-title"
                class="shrink-0"
                @click="startEditingTitle"
              >
                <v-icon size="small">mdi-pencil</v-icon>
              </v-btn>
            </template>
            <template v-else>
              <v-text-field
                v-model="titleInput"
                density="compact"
                variant="outlined"
                hide-details
                autofocus
                class="title-edit-input"
                data-testid="chats-input-title"
                @keyup.enter="saveTitle"
                @keyup.esc="cancelEditingTitle"
              />
              <v-btn
                icon
                variant="text"
                size="x-small"
                color="success"
                :title="t('chats.chat_detail.save_title')"
                data-testid="chats-btn-save-title"
                class="shrink-0"
                @click="saveTitle"
              >
                <v-icon size="small">mdi-check</v-icon>
              </v-btn>
              <v-btn
                icon
                variant="text"
                size="x-small"
                :title="t('common.cancel')"
                data-testid="chats-btn-cancel-title"
                class="shrink-0"
                @click="cancelEditingTitle"
              >
                <v-icon size="small">mdi-close</v-icon>
              </v-btn>
            </template>
          </div>

          <!-- Connection status -->
          <v-chip
            :color="connection.color"
            size="small"
            variant="tonal"
            class="shrink-0"
            data-testid="chats-connection-status"
          >
            <v-icon start size="x-small">
              {{ connection.status === 'connected' ? 'mdi-wifi' : 'mdi-wifi-off' }}
            </v-icon>
            {{ t(`chats.chat_detail.${connection.status}`) }}
          </v-chip>
        </div>

        <!-- Global Stores Info -->
        <div v-if="chatGlobalStores.length > 0 || (globalStores.length > 0 && canEditGlobalStores)" class="mb-4">
          <div class="d-flex align-center gap-2 flex-wrap">
            <span class="text-caption text-grey mr-1">{{ t('chats.selected_global_stores') }}:</span>
            <template v-if="chatGlobalStores.length > 0">
              <v-chip
                v-for="store in chatGlobalStores"
                :key="store.id"
                size="small"
                color="primary"
                variant="tonal"
                data-testid="chats-global-store-chip"
              >
                <v-icon start size="small">mdi-database</v-icon>
                {{ store.display_name }}
              </v-chip>
            </template>
            <span v-else class="text-caption text-grey-darken-1">{{ t('chats.no_global_stores') }}</span>
            <v-btn
              v-if="canEditGlobalStores && globalStores.length > 0"
              icon
              variant="text"
              size="x-small"
              :title="t('chats.edit_global_stores')"
              data-testid="chats-btn-edit-global-stores"
              @click="openGlobalStoresDialog"
            >
              <v-icon size="small">mdi-pencil</v-icon>
            </v-btn>
          </div>
        </div>

        <!-- Messages Area -->
        <v-card class="grow d-flex flex-column rounded-xl" elevation="0" border>
          <!-- Messages Container -->
          <div
            ref="messagesContainer"
            class="grow overflow-y-auto pa-4"
            style="max-height: calc(100vh - 320px);"
          >
            <!-- Empty state -->
            <div
              v-if="!hasMessages"
              class="d-flex flex-column align-center justify-center fill-height text-center"
            >
              <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-chat-outline</v-icon>
              <p class="text-body-1 text-grey">{{ t('chats.chat_detail.empty_messages') }}</p>
            </div>

            <!-- Messages list -->
            <div v-else class="messages-list">
              <ChatMessage
                v-for="message in displayMessages"
                :key="message.id"
                :message="message"
                :is-new="isNewMessage(message.id)"
                class="mb-4"
              />

              <!-- Thinking indicator -->
              <div v-if="isThinking" class="d-flex align-center gap-3 pa-3">
                <v-progress-circular
                  indeterminate
                  size="20"
                  width="2"
                  color="primary"
                  class="mr-2"
                />
                <span class="text-body-2 text-grey">{{ t('chats.chat_detail.thinking') }}</span>
              </div>
            </div>
          </div>

          <!-- Input Area -->
          <v-divider />
          <div class="pa-4">
            <ChatInput
              v-model="newMessage"
              :disabled="!canSendMessage || sending || isThinking"
              :loading="sending || isThinking"
              :placeholder="t('chats.chat_detail.placeholder')"
              data-testid="chats-input-message"
              @send="sendMessage"
            />
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Global Stores Dialog -->
    <v-dialog v-model="showGlobalStoresDialog" max-width="500">
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon start>mdi-database-edit</v-icon>
          {{ t('chats.edit_global_stores') }}
        </v-card-title>
        <v-card-text>
          <v-select
            v-model="selectedGlobalStoreIds"
            :items="globalStores"
            item-title="display_name"
            item-value="id"
            :label="t('chats.select_global_stores')"
            :hint="t('chats.global_stores_hint')"
            multiple
            chips
            closable-chips
            variant="outlined"
            density="comfortable"
            data-testid="chats-dialog-select-global-stores"
          >
            <template #chip="{ props: chipProps, item }">
              <v-chip
                v-bind="chipProps"
                color="primary"
                variant="tonal"
              >
                <v-icon start size="small">mdi-database</v-icon>
                {{ item.title }}
              </v-chip>
            </template>
            <template #item="{ props: itemProps, item }">
              <v-list-item
                v-bind="itemProps"
                :subtitle="`${item.raw.active_documents_count} ${t('chats.documents_count')}`"
              >
                <template #prepend>
                  <v-icon color="primary">mdi-database</v-icon>
                </template>
              </v-list-item>
            </template>
          </v-select>
        </v-card-text>
        <v-card-actions>
          <v-spacer />
          <v-btn
            variant="text"
            data-testid="chats-dialog-btn-cancel"
            @click="showGlobalStoresDialog = false"
          >
            {{ t('common.cancel') }}
          </v-btn>
          <v-btn
            color="primary"
            variant="flat"
            :loading="savingGlobalStores"
            data-testid="chats-dialog-btn-save"
            @click="saveGlobalStores"
          >
            {{ t('common.save') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<style scoped>
.messages-list {
  display: flex;
  flex-direction: column;
}

.min-width-0 {
  min-width: 0;
}

.title-edit-input {
  flex: 1;
  min-width: 120px;
  max-width: 400px;
}

@media (max-width: 600px) {
  .title-edit-input {
    max-width: 100%;
  }
}
</style>
