import { router } from '@inertiajs/vue3'

export function useNavigation() {
  const navigateTo = (path: string) => {
    router.visit(path)
  }

  const goBack = () => {
    window.history.back()
  }

  return {
    navigateTo,
    goBack
  }
}
