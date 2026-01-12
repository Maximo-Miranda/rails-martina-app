import { ref, onUnmounted } from 'vue'
import { useActionCable } from './useActionCable'
import type { Message, ChatsChannelMessage } from '@/types'

interface ChannelCallbacks {
  onMessageCreated?: (message: Message) => void
  onMessageUpdated?: (message: Message) => void
  onChatUpdated?: (title: string) => void
  onMessageFailed?: (messageId: number, errorType: string, content: string) => void
}

export function useChatsChannel(chatId: number) {
  const { subscribe, unsubscribe, connected } = useActionCable()

  const messages = ref<Message[]>([])
  const chatTitle = ref<string>('')
  const isConnected = ref(false)
  const isReconnecting = ref(false)
  const newMessageIds = ref<Set<number>>(new Set())

  let subscription: ReturnType<typeof subscribe> | null = null

  function initializeMessages(initialMessages: Message[], title: string) {
    messages.value = initialMessages
    chatTitle.value = title
    newMessageIds.value.clear()
  }

  function connect(callbacks?: ChannelCallbacks) {
    subscription = subscribe<ChatsChannelMessage>(
      'ChatsChannel',
      { chat_id: chatId },
      {
        received: (data) => handleMessage(data, callbacks),
        connected: () => {
          isConnected.value = true
          isReconnecting.value = false
        },
        disconnected: () => {
          isConnected.value = false
          isReconnecting.value = true
        }
      }
    )
    return subscription
  }

  function handleMessage(data: ChatsChannelMessage, callbacks?: ChannelCallbacks) {
    switch (data.type) {
      case 'new_message':
      case 'message_created': {
        if (!data.message) break
        const message = data.citations
          ? { ...data.message, citations: data.citations }
          : data.message
        addOrUpdateMessage(message, true)
        callbacks?.onMessageCreated?.(message)
        break
      }

      case 'message_updated':
        if (data.message) {
          updateMessage(data.message)
          callbacks?.onMessageUpdated?.(data.message)
        }
        break

      case 'chat_updated':
        if (data.chat?.title) {
          chatTitle.value = data.chat.title
          callbacks?.onChatUpdated?.(data.chat.title)
        }
        break

      case 'message_failed':
        if (data.message_id && data.content) {
          callbacks?.onMessageFailed?.(data.message_id, data.error_type || 'unknown', data.content)
        }
        break

      case 'error':
        console.error('Chat channel error:', data.content)
        break
    }
  }

  function addOrUpdateMessage(message: Message, markAsNew = false) {
    const existingIndex = messages.value.findIndex(m => m.id === message.id)

    if (existingIndex >= 0) {
      messages.value[existingIndex] = message
      return
    }

    messages.value.push(message)
    if (markAsNew && message.role === 'assistant_role') {
      newMessageIds.value.add(message.id)
    }
  }

  function updateMessage(message: Message) {
    const index = messages.value.findIndex(m => m.id === message.id)
    if (index >= 0) {
      messages.value[index] = message
    }
  }

  function clearNewMessageFlag(messageId: number) {
    newMessageIds.value.delete(messageId)
  }

  function isNewMessage(messageId: number): boolean {
    return newMessageIds.value.has(messageId)
  }

  function disconnect() {
    if (subscription) {
      unsubscribe('ChatsChannel', { chat_id: chatId })
      subscription = null
    }
  }

  onUnmounted(disconnect)

  return {
    messages,
    chatTitle,
    isConnected,
    isReconnecting,
    connected,
    newMessageIds,
    initializeMessages,
    connect,
    disconnect,
    isNewMessage,
    clearNewMessageFlag
  }
}
