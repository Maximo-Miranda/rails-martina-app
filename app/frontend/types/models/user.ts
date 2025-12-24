export interface User {
  id: number
  email: string
  full_name: string
  current_project_id?: number | null
  created_at?: string
  roles?: string[]
}
