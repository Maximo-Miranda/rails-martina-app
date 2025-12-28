import type { User, Flash } from './models'

export interface PagyPagination {
  count: number
  page: number
  limit: number
  pages: number
  previous: number | null
  next: number | null
  from: number | null
  to: number | null
}

export interface Permissions {
  // Global permissions
  can_manage_users: boolean
  can_invite_users: boolean
  can_manage_projects: boolean
  can_create_project: boolean

  // Project-scoped permissions (for current project)
  can_edit_current_project: boolean
  can_delete_current_project: boolean

  // User permissions
  can_update_profile: boolean
  can_delete_account: boolean

  // Navigation permissions
  can_access_dashboard: boolean
  can_access_projects: boolean
  can_access_users: boolean
  can_access_gemini_stores: boolean

  // Feature flags
  can_view_analytics: boolean
  can_access_admin_panel: boolean
}

export interface SharedProps {
  flash: Flash
  current_user: User | null
  current_project: { id: number, name: string, slug: string } | null
  permissions: Permissions
}
