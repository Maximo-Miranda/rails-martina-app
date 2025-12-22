import type { User, Flash } from './models'

export interface SharedProps {
  flash: Flash
  current_user: User | null
}
