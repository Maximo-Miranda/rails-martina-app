import { usePage } from '@inertiajs/vue3'

/**
 * Tipos de las traducciones del frontend
 * Estructura que refleja frontend.es.yml
 */
export interface Translations {
  common: {
    save: string
    cancel: string
    delete: string
    edit: string
    back: string
    confirm: string
    loading: string
    or: string
    see_all: string
    times: string
  }
  validation: {
    required: string
    email_invalid: string
    min_length: string
    password_hint: string
    passwords_no_match: string
  }
  navigation: {
    dashboard: string
    projects: string
    tasks: string
    reports: string
    settings: string
    my_profile: string
    logout: string
    login: string
    register: string
  }
  auth: {
    login: {
      title: string
      subtitle: string
      email: string
      password: string
      remember_me: string
      forgot_password: string
      submit: string
      no_account: string
      create_account: string
    }
    register: {
      title: string
      subtitle: string
      full_name: string
      email: string
      password: string
      password_confirmation: string
      submit: string
      has_account: string
      login_link: string
    }
    forgot_password: {
      title: string
      subtitle: string
      email: string
      submit: string
      back_to_login: string
      success_title: string
      success_message: string
      spam_notice: string
    }
    reset_password: {
      title: string
      subtitle: string
      password: string
      password_confirmation: string
      submit: string
      back_to_login: string
    }
    profile: {
      title: string
      subtitle: string
      personal_info: string
      full_name: string
      email: string
      account_activity: string
      member_since: string
      last_access: string
      first_session: string
      login_count: string
      change_password: string
      change_password_hint: string
      current_password: string
      new_password: string
      confirm_password: string
      save_changes: string
    }
  }
  dashboard: {
    greeting: string
    summary: string
    stats: {
      active_projects: string
      pending_tasks: string
      completed_today: string
      in_review: string
    }
    recent_activity: string
    quick_actions: string
    new_project: string
    create_task: string
    invite_team: string
    tip_title: string
    tip_message: string
  }
  activities: {
    new_project: string
    task_completed: string
    comment_added: string
    file_uploaded: string
    time: {
      hours_ago: string
      yesterday: string
    }
  }
}

/**
 * Composable para acceder a las traducciones del backend
 * Las traducciones se cachean en el cliente con InertiaRails.once
 */
export function useTranslations() {
  const page = usePage()
  const translations = page.props.t as Translations

  /**
   * Obtiene una traducción por su clave con soporte para interpolación
   * @param key - Clave de traducción (ej: 'auth.login.title')
   * @param replacements - Objeto con variables a reemplazar (ej: { name: 'Juan' })
   * @returns La traducción o la clave si no existe
   *
   * @example
   * t('auth.login.title') // "¡Bienvenido de vuelta!"
   * t('dashboard.greeting', { name: 'Juan' }) // "¡Hola, Juan!"
   */
  function t(key: string, replacements?: Record<string, string | number>): string {
    const keys = key.split('.')
    let value: unknown = translations

    for (const k of keys) {
      if (value && typeof value === 'object' && k in value) {
        value = (value as Record<string, unknown>)[k]
      } else {
        return key // Retorna la clave si no encuentra la traducción
      }
    }

    if (typeof value !== 'string') {
      return key
    }

    // Reemplazar variables %{variable}
    if (replacements) {
      return value.replace(/%\{(\w+)\}/g, (_, name) =>
        String(replacements[name] ?? `%{${name}}`)
      )
    }

    return value
  }

  return { t, translations }
}
