import type { Flash, User } from './index'

// Documentación oficial: https://inertiajs.com/docs/v2/data-props/flash-data#typescript
// Usar declaration merging con InertiaConfig para tipar props globales
declare module '@inertiajs/core' {
  export interface InertiaConfig {
    // Flash data type (según documentación oficial)
    flashDataType: Flash

    // Shared props type (para page.props)
    sharedDataType: {
      current_user: User | null
      errors?: Record<string, string[]>
    }
  }
}
