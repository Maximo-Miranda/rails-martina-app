import { computed } from 'vue'
import { usePage, router } from '@inertiajs/vue3'
import type { User } from '@/types'

export function useUser() {
  const page = usePage()

  const currentUser = computed(() => page.props.current_user as User | null)

  const isAuthenticated = computed(() => !!currentUser.value)

  const userInitials = computed(() => {
    if (!currentUser.value?.full_name) return 'U'
    const names = currentUser.value.full_name.split(' ')
    return names.length >= 2
      ? `${names[0][0]}${names[1][0]}`.toUpperCase()
      : names[0].substring(0, 2).toUpperCase()
  })

  const firstName = computed(() =>
    currentUser.value?.full_name?.split(' ')[0] || 'Usuario'
  )

  const logout = () => router.delete('/users/sign_out')

  return {
    currentUser,
    isAuthenticated,
    userInitials,
    firstName,
    logout,
  }
}
