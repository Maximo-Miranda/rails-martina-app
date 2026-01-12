import { ref } from 'vue'
import { createConsumer, type Consumer, type Subscription } from '@rails/actioncable'

interface SubscriptionCallbacks<T = unknown> {
  received?: (data: T) => void
  connected?: () => void
  disconnected?: () => void
}

interface SubscriptionEntry {
  subscription: Subscription
  callbacks: SubscriptionCallbacks
}

// Singleton consumer and cache of subscriptions
let consumer: Consumer | null = null
const subscriptions = new Map<string, SubscriptionEntry>()

const getConsumer = (): Consumer => (consumer ??= createConsumer())

const buildKey = (channel: string, params: Record<string, unknown>): string =>
  `${channel}:${JSON.stringify(params)}`

export function useActionCable() {
  const connected = ref(false)

  function subscribe<T>(
    channelName: string,
    params: Record<string, unknown> = {},
    callbacks: SubscriptionCallbacks<T> = {}
  ): Subscription {
    const key = buildKey(channelName, params)
    const existing = subscriptions.get(key)

    if (existing) {
      existing.callbacks = callbacks as unknown as SubscriptionCallbacks
      return existing.subscription
    }

    const callbacksRef = callbacks as unknown as SubscriptionCallbacks

    const subscription = getConsumer().subscriptions.create(
      { channel: channelName, ...params },
      {
        received: (data: unknown) => callbacksRef.received?.(data),
        connected: () => {
          connected.value = true
          callbacksRef.connected?.()
        },
        disconnected: () => {
          connected.value = false
          callbacksRef.disconnected?.()
        }
      }
    )

    subscriptions.set(key, { subscription, callbacks: callbacksRef })
    return subscription
  }

  function unsubscribe(channelName: string, params: Record<string, unknown> = {}): void {
    const key = buildKey(channelName, params)
    const entry = subscriptions.get(key)

    if (entry) {
      entry.subscription.unsubscribe()
      subscriptions.delete(key)
    }
  }

  return { connected, subscribe, unsubscribe, getConsumer }
}
