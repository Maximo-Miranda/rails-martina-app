import { computed, reactive, type ComputedRef } from 'vue'
import { useGlobalLoading } from './useGlobalLoading'

export interface UseActionLoadingReturn {
  isActionLoading: (action: string, id: string | number) => boolean
  isAnyLoading: ComputedRef<boolean>
  isAnyLoadingGlobal: ComputedRef<boolean>
  startLoading: (action: string, id: string | number) => void
  stopLoading: (action: string, id: string | number) => void
  clearAll: () => void
}

/**
 * Manages loading states for individual actions (useful for table buttons)
 * @example
 * const { isActionLoading, isAnyLoading, startLoading, stopLoading } = useActionLoading()
 * startLoading('delete', item.id)
 * router.delete(`/items/${item.id}`, { onFinish: () => stopLoading('delete', item.id) })
 */
export function useActionLoading(): UseActionLoadingReturn {
  const activeActions = reactive<Map<string, boolean>>(new Map())
  const { isLoading: isGlobalLoading } = useGlobalLoading()

  const getKey = (action: string, id: string | number): string => `${action}:${id}`

  const startLoading = (action: string, id: string | number): void => {
    activeActions.set(getKey(action, id), true)
  }

  const stopLoading = (action: string, id: string | number): void => {
    activeActions.delete(getKey(action, id))
  }

  const isActionLoading = (action: string, id: string | number): boolean => {
    return activeActions.get(getKey(action, id)) ?? false
  }

  const isAnyLoading = computed(() => activeActions.size > 0)

  const isAnyLoadingGlobal = computed(() => isAnyLoading.value || isGlobalLoading.value)

  const clearAll = (): void => {
    activeActions.clear()
  }

  return {
    isActionLoading,
    isAnyLoading,
    isAnyLoadingGlobal,
    startLoading,
    stopLoading,
    clearAll
  }
}
