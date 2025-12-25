import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

export interface Permissions {
  // Global permissions
  can_manage_users: boolean
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

  // Feature flags
  can_view_analytics: boolean
  can_access_admin_panel: boolean
}

export interface ProjectPermissions {
  can_edit: boolean
  can_delete: boolean
  can_switch: boolean
}

// Interface for projects with optional permissions (from backend)
export interface ProjectWithPermissions {
  can_edit?: boolean
  can_delete?: boolean
  can_switch?: boolean
}

export function usePermissions() {
  const page = usePage()

  // Raw permissions from page props
  const permissions = computed(() =>
    page.props.permissions as Permissions | null
  )

  // Type-safe permission checks with camelCase for better JS/TS usage
  const can = computed(() => ({
    // Global permissions
    manageUsers: permissions.value?.can_manage_users ?? false,
    manageProjects: permissions.value?.can_manage_projects ?? false,
    createProject: permissions.value?.can_create_project ?? false,

    // Project-scoped permissions
    editCurrentProject: permissions.value?.can_edit_current_project ?? false,
    deleteCurrentProject: permissions.value?.can_delete_current_project ?? false,

    // User permissions
    updateProfile: permissions.value?.can_update_profile ?? false,
    deleteAccount: permissions.value?.can_delete_account ?? false,

    // Navigation permissions
    accessDashboard: permissions.value?.can_access_dashboard ?? false,
    accessProjects: permissions.value?.can_access_projects ?? false,
    accessUsers: permissions.value?.can_access_users ?? false,

    // Feature flags
    viewAnalytics: permissions.value?.can_view_analytics ?? false,
    accessAdminPanel: permissions.value?.can_access_admin_panel ?? false,
  }))

  // Check if user has any permission (useful for showing/hiding admin sections)
  const hasAnyPermission = computed(() =>
    Object.values(can.value).some(Boolean)
  )

  // Check if user has all specified permissions
  const hasAllPermissions = (...perms: (keyof typeof can.value)[]) => {
    return perms.every(perm => can.value[perm])
  }

  // Check if user has any of the specified permissions
  const hasAnyOfPermissions = (...perms: (keyof typeof can.value)[]) => {
    return perms.some(perm => can.value[perm])
  }

  // Helper for project-specific permissions (for projects list, etc.)
  // Accepts projects with optional permission properties
  const canProject = (project: ProjectWithPermissions) => ({
    edit: project.can_edit ?? false,
    delete: project.can_delete ?? false,
    switch: project.can_switch ?? false,
  })

  return {
    permissions,
    can,
    hasAnyPermission,
    hasAllPermissions,
    hasAnyOfPermissions,
    canProject,
  }
}
