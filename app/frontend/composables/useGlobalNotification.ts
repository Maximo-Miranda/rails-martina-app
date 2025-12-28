import { ref } from 'vue'

interface Notification {
  message: string
  color: 'success' | 'warning' | 'error' | 'info'
}

const notification = ref<Notification | null>(null)

export function useGlobalNotification() {
  const show = (message: string, color: Notification['color'] = 'error') => {
    notification.value = { message, color }
  }

  const clear = () => {
    notification.value = null
  }

  return {
    notification,
    show,
    clear,
  }
}
