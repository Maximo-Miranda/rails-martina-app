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

export interface SharedProps {
  flash: Flash
  current_user: User | null
}
