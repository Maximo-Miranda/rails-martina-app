import { ref } from 'vue'
import { createConsumer, type Consumer, type Subscription } from '@rails/actioncable'

let consumer: Consumer | null = null
const subscriptions = new Map<string, Subscription>()

function getConsumer(): Consumer {
  if (!consumer) {
    consumer = createConsumer()
  }
  return consumer
}

export function useActionCable() {
  const connected = ref(false)

  function subscribe<T>(
    channelName: string,
    params: Record<string, unknown> = {},
    callbacks: {
      received?: (data: T) => void
      connected?: () => void
      disconnected?: () => void
    } = {}
  ): Subscription {
    const key = `${channelName}:${JSON.stringify(params)}`

    if (subscriptions.has(key)) {
      return subscriptions.get(key)!
    }

    const subscription = getConsumer().subscriptions.create(
      { channel: channelName, ...params },
      {
        received: (data: T) => {
          callbacks.received?.(data)
        },
        connected: () => {
          connected.value = true
          callbacks.connected?.()
        },
        disconnected: () => {
          connected.value = false
          callbacks.disconnected?.()
        }
      }
    )

    subscriptions.set(key, subscription)
    return subscription
  }

  function unsubscribe(channelName: string, params: Record<string, unknown> = {}): void {
    const key = `${channelName}:${JSON.stringify(params)}`
    const subscription = subscriptions.get(key)

    if (subscription) {
      subscription.unsubscribe()
      subscriptions.delete(key)
    }
  }

  return {
    connected,
    subscribe,
    unsubscribe,
    getConsumer
  }
}
