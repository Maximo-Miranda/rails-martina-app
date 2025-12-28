export interface User {
  id: number
  email: string
  full_name: string
  current_project_id?: number | null
  created_at?: string
  roles?: string[]
  // User-specific permissions
  can_view?: boolean
  can_edit?: boolean
  can_delete?: boolean
  can_remove_from_project?: boolean
}
