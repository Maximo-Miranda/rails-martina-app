import { computed, ref, type ComputedRef } from 'vue'
import { router } from '@inertiajs/vue3'

// Global singleton state
const requestCount = ref(0)
let isInitialized = false

function initializeListeners() {
  if (isInitialized) return
  isInitialized = true

  router.on('start', () => {
    requestCount.value++
  })

  router.on('finish', () => {
    if (requestCount.value > 0) {
      requestCount.value--
    }
  })
}

initializeListeners()

export interface UseGlobalLoadingReturn {
  isLoading: ComputedRef<boolean>
  requestCount: ComputedRef<number>
}

/**
 * Monitors global loading state for all Inertia.js requests
 * @example const { isLoading } = useGlobalLoading()
 */
export function useGlobalLoading(): UseGlobalLoadingReturn {
  const isLoading = computed(() => requestCount.value > 0)

  return {
    isLoading,
    requestCount: computed(() => requestCount.value)
  }
}
