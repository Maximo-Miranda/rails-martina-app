export type Flash = {
  notice?: string
  alert?: string
}

export type User = {
  id: number
  email: string
  full_name: string
}

export type SharedProps = {
  flash: Flash
  current_user: User | null
}
