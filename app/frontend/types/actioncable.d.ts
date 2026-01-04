declare module '@rails/actioncable' {
  export interface Consumer {
    subscriptions: Subscriptions
    connect(): void
    disconnect(): void
    send(data: object): void
    ensureActiveConnection(): void
  }

  export interface Subscriptions {
    create<T>(
      channel: string | ChannelNameWithParams,
      callbacks?: SubscriptionCallbacks<T>
    ): Subscription
    remove(subscription: Subscription): void
  }

  export interface ChannelNameWithParams {
    channel: string
    [key: string]: unknown
  }

  export interface SubscriptionCallbacks<T = unknown> {
    received?: (data: T) => void
    connected?: () => void
    disconnected?: () => void
    rejected?: () => void
    initialized?: () => void
  }

  export interface Subscription {
    unsubscribe(): void
    perform(action: string, data?: object): void
    send(data: object): void
    identifier: string
  }

  export function createConsumer(url?: string): Consumer
  export function getConfig(name: string): string | undefined
}
