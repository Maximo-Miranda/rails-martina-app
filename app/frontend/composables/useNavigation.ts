import { router } from '@inertiajs/vue3'
import { useGlobalLoading } from './useGlobalLoading'

/**
 * Protected navigation - blocks navigation during active requests
 * @example const { navigateTo, isNavigating } = useNavigation()
 */
export function useNavigation() {
  const { isLoading } = useGlobalLoading()

  const navigateTo = (path: string) => {
    if (isLoading.value) return
    router.visit(path)
  }

  const goBack = () => {
    if (isLoading.value) return
    window.history.back()
  }

  return {
    navigateTo,
    goBack,
    isNavigating: isLoading
  }
}
