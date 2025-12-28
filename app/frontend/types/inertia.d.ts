import type { Flash, User } from './index'

// Official documentation: https://inertiajs.com/docs/v2/data-props/flash-data#typescript
// Use declaration merging with InertiaConfig to type global props
declare module '@inertiajs/core' {
  export interface InertiaConfig {
    // Flash data type (per official documentation)
    flashDataType: Flash

    // Shared props type (for page.props)
    sharedDataType: {
      current_user: User | null
      errors?: Record<string, string[]>
    }
  }
}
