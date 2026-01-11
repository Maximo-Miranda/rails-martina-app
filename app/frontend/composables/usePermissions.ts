import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

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
  can_access_documents: boolean
  can_access_project_documents: boolean
  can_access_chats: boolean

  // Feature flags
  can_view_analytics: boolean
  can_access_admin_panel: boolean
}

export interface ProjectPermissions {
  can_edit: boolean
  can_delete: boolean
  can_switch: boolean
}

export interface UserPermissions {
  can_view: boolean
  can_edit: boolean
  can_delete: boolean
  can_remove_from_project: boolean
}

// Interface for users with optional permission flags (from backend)
export interface UserWithPermissions {
  can_view?: boolean
  can_edit?: boolean
  can_delete?: boolean
  can_remove_from_project?: boolean
}

// Interface for projects with optional permission flags (from backend)
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
    inviteUsers: permissions.value?.can_invite_users ?? false,
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
    accessGeminiStores: permissions.value?.can_access_gemini_stores ?? false,
    accessDocuments: permissions.value?.can_access_documents ?? false,
    accessProjectDocuments: permissions.value?.can_access_project_documents ?? false,
    accessChats: permissions.value?.can_access_chats ?? false,

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
  // Accepts projects with optional permission flags
  const canProject = (project: ProjectWithPermissions) => ({
    edit: project.can_edit ?? false,
    delete: project.can_delete ?? false,
    switch: project.can_switch ?? false,
  })

  // Helper for user-specific permissions (for users list, etc.)
  // Accepts users with optional permission flags
  const canUser = (user: UserWithPermissions) => ({
    view: user.can_view ?? false,
    edit: user.can_edit ?? false,
    delete: user.can_delete ?? false,
    removeFromProject: user.can_remove_from_project ?? false,
  })

  return {
    permissions,
    can,
    hasAnyPermission,
    hasAllPermissions,
    hasAnyOfPermissions,
    canProject,
    canUser,
  }
}
