import { onMounted, onUnmounted } from 'vue'
import { router } from '@inertiajs/vue3'
import { useActionCable } from './useActionCable'
import { useGlobalNotification } from './useGlobalNotification'
import { useTranslations } from './useTranslations'

interface DocumentNotification {
  type: 'document_uploaded' | 'document_upload_failed' | 'document_deleted'
  document_id: number
  display_name: string
  status?: string
  error?: string
  message?: string
}

export function useDocumentNotifications() {
  const { subscribe, unsubscribe } = useActionCable()
  const { show } = useGlobalNotification()
  const { t } = useTranslations()

  function handleNotification(data: DocumentNotification) {
    switch (data.type) {
      case 'document_uploaded':
        show(t('documents.upload_success', { name: data.display_name }), 'success')
        router.reload({ only: ['documents'] })
        break

      case 'document_upload_failed':
        show(t('documents.upload_error', { name: data.display_name }), 'error')
        router.reload({ only: ['documents'] })
        break

      case 'document_deleted':
        show(t('documents.delete_success', { name: data.display_name }), 'success')
        router.reload({ only: ['documents'] })
        break
    }
  }

  function startListening() {
    subscribe<DocumentNotification>('NotificationsChannel', {}, {
      received: handleNotification,
      connected: () => {
        console.log('[DocumentNotifications] Connected to notifications channel')
      },
      disconnected: () => {
        console.log('[DocumentNotifications] Disconnected from notifications channel')
      }
    })
  }

  function stopListening() {
    unsubscribe('NotificationsChannel', {})
  }

  onMounted(() => {
    startListening()
  })

  onUnmounted(() => {
    stopListening()
  })

  return {
    startListening,
    stopListening
  }
}
