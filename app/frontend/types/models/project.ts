export interface Project {
  id: number
  name: string
  slug: string
  description?: string | null
  created_at?: string
  updated_at?: string | null
  // Project-specific permissions
  can_edit?: boolean
  can_delete?: boolean
  can_switch?: boolean
}
