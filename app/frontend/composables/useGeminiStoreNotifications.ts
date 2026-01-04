import { onMounted, onUnmounted } from 'vue'
import { router } from '@inertiajs/vue3'
import { useActionCable } from './useActionCable'
import { useGlobalNotification } from './useGlobalNotification'
import { useTranslations } from './useTranslations'

interface GeminiStoreNotification {
  type: 'store_created' | 'store_creation_failed' | 'store_deleted' | 'store_deletion_failed'
  store_id: number
  display_name: string
  status?: string
  error?: string
  message?: string
}

export function useGeminiStoreNotifications() {
  const { subscribe, unsubscribe } = useActionCable()
  const { show } = useGlobalNotification()
  const { t } = useTranslations()

  function handleNotification(data: GeminiStoreNotification) {
    switch (data.type) {
      case 'store_created':
        show(t('gemini_stores.creation_success', { name: data.display_name }), 'success')
        // Reload the current page to reflect the updated status
        router.reload({ only: ['stores'] })
        break

      case 'store_creation_failed':
        show(t('gemini_stores.creation_error', { name: data.display_name }), 'error')
        // Reload to show the failed status
        router.reload({ only: ['stores'] })
        break

      case 'store_deleted':
        show(t('gemini_stores.deletion_success', { name: data.display_name }), 'success')
        // Reload the current page to reflect the deletion
        router.reload({ only: ['stores'] })
        break

      case 'store_deletion_failed':
        show(t('gemini_stores.deletion_error', { name: data.display_name }), 'error')
        // Reload to show the error
        router.reload({ only: ['stores'] })
        break
    }
  }

  function startListening() {
    subscribe<GeminiStoreNotification>('NotificationsChannel', {}, {
      received: handleNotification,
      connected: () => {
        console.log('[GeminiStoreNotifications] Connected to notifications channel')
      },
      disconnected: () => {
        console.log('[GeminiStoreNotifications] Disconnected from notifications channel')
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
