// Reglas de validación reutilizables para formularios
// Basado en el sistema nativo de validación de Vuetify

export const rules = {
  // Campo requerido
  required: (message = 'Este campo es requerido') => {
    return (value: string | null | undefined) => !!value || message
  },

  // Email válido
  email: (message = 'Ingresa un correo electrónico válido') => {
    return (value: string) => {
      if (!value) return true
      const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      return pattern.test(value) || message
    }
  },

  // Longitud mínima
  minLength: (min: number, message?: string) => {
    return (value: string) => {
      if (!value) return true
      return value.length >= min || message || `Debe tener al menos ${min} caracteres`
    }
  },

  // Longitud máxima
  maxLength: (max: number, message?: string) => {
    return (value: string) => {
      if (!value) return true
      return value.length <= max || message || `Debe tener máximo ${max} caracteres`
    }
  },

  // Contraseña segura (mínimo 6 caracteres)
  password: (message = 'La contraseña debe tener al menos 6 caracteres') => {
    return (value: string) => {
      if (!value) return true
      return value.length >= 6 || message
    }
  },

  // Confirmación de contraseña
  passwordConfirmation: (password: string, message = 'Las contraseñas no coinciden') => {
    return (value: string) => {
      if (!value) return true
      return value === password || message
    }
  },

  // Solo letras y espacios (para nombres)
  name: (message = 'Solo se permiten letras y espacios') => {
    return (value: string) => {
      if (!value) return true
      const pattern = /^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/
      return pattern.test(value) || message
    }
  },
}
