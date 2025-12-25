// Reusable validation rules for forms
// Based on Vuetify's native validation system

export const rules = {
  // Required field
  required: (message = 'This field is required') => {
    return (value: string | null | undefined) => !!value || message
  },

  // Valid email
  email: (message = 'Enter a valid email address') => {
    return (value: string) => {
      if (!value) return true
      const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      return pattern.test(value) || message
    }
  },

  // Minimum length
  minLength: (min: number, message?: string) => {
    return (value: string) => {
      if (!value) return true
      return value.length >= min || message || `Must be at least ${min} characters`
    }
  },

  // Maximum length
  maxLength: (max: number, message?: string) => {
    return (value: string) => {
      if (!value) return true
      return value.length <= max || message || `Must be at most ${max} characters`
    }
  },

  // Secure password (minimum 6 characters)
  password: (message = 'Password must be at least 6 characters') => {
    return (value: string) => {
      if (!value) return true
      return value.length >= 6 || message
    }
  },

  // Password confirmation
  passwordConfirmation: (password: string, message = 'Passwords do not match') => {
    return (value: string) => {
      if (!value) return true
      return value === password || message
    }
  },

  // Letters and spaces only (for names)
  name: (message = 'Only letters and spaces are allowed') => {
    return (value: string) => {
      if (!value) return true
      const pattern = /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/
      return pattern.test(value) || message
    }
  },
}
