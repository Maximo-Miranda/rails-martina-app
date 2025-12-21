<!-- filepath: /home/mhmh/code/wudok/rails-martina-app/app/frontend/pages/Auth/Register.vue -->
<script setup lang="ts">
import { useForm, Link } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import { rules } from '@/utils/validation'

const form = useForm({
  full_name: '',
  email: '',
  password: '',
  password_confirmation: '',
})

const showPassword = ref(false)
const showPasswordConfirmation = ref(false)
const formRef = ref<HTMLFormElement | null>(null)

// Reglas de validación
const nameRules = [
  rules.required('El nombre completo es requerido'),
  rules.minLength(3, 'El nombre debe tener al menos 3 caracteres'),
]

const emailRules = [
  rules.required('El correo electrónico es requerido'),
  rules.email('Ingresa un correo electrónico válido'),
]

const passwordRules = [
  rules.required('La contraseña es requerida'),
  rules.password('La contraseña debe tener al menos 6 caracteres'),
]

// Regla dinámica para confirmación de contraseña
const passwordConfirmationRules = computed(() => [
  rules.required('La confirmación de contraseña es requerida'),
  rules.passwordConfirmation(form.password, 'Las contraseñas no coinciden'),
])

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.post('/users')
}
</script>

<template>
  <!-- Tarjeta centrada con diseño moderno -->
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-account-plus-outline</v-icon>
      <h1 class="text-h5 font-weight-bold mb-2">Crea tu cuenta</h1>
      <p class="text-body-2 text-medium-emphasis">Únete a Martina y comienza hoy</p>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <v-text-field
        v-model="form.full_name"
        label="Nombre completo"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-account-outline"
        :rules="nameRules"
        :error-messages="form.errors.full_name"
        class="mb-1"
        autocomplete="name"
      />

      <v-text-field
        v-model="form.email"
        label="Correo electrónico"
        type="email"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-email-outline"
        :rules="emailRules"
        :error-messages="form.errors.email"
        class="mb-1"
        autocomplete="email"
      />

      <v-row dense>
        <v-col cols="12" sm="6">
          <v-text-field
            v-model="form.password"
            label="Contraseña"
            :type="showPassword ? 'text' : 'password'"
            variant="outlined"
            color="primary"
            density="comfortable"
            prepend-inner-icon="mdi-lock-outline"
            :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
            @click:append-inner="showPassword = !showPassword"
            :rules="passwordRules"
            :error-messages="form.errors.password"
            autocomplete="new-password"
          />
        </v-col>
        <v-col cols="12" sm="6">
          <v-text-field
            v-model="form.password_confirmation"
            label="Confirmar"
            :type="showPasswordConfirmation ? 'text' : 'password'"
            variant="outlined"
            color="primary"
            density="comfortable"
            prepend-inner-icon="mdi-lock-check-outline"
            :append-inner-icon="showPasswordConfirmation ? 'mdi-eye-off' : 'mdi-eye'"
            @click:append-inner="showPasswordConfirmation = !showPasswordConfirmation"
            :rules="passwordConfirmationRules"
            :error-messages="form.errors.password_confirmation"
            autocomplete="new-password"
          />
        </v-col>
      </v-row>

      <div class="text-caption text-medium-emphasis mb-4 mt-1">
        <v-icon size="x-small" class="mr-1">mdi-information-outline</v-icon>
        Usa 6 caracteres o más con letras, números y símbolos.
      </div>

      <v-btn
        type="submit"
        color="primary"
        :loading="form.processing"
        block
        size="large"
        class="text-none font-weight-medium mb-4"
        rounded="lg"
      >
        Crear cuenta
      </v-btn>

      <div class="d-flex align-center my-4">
        <v-divider />
        <span class="mx-3 text-caption text-medium-emphasis">o</span>
        <v-divider />
      </div>

      <div class="text-center">
        <span class="text-body-2 text-medium-emphasis">¿Ya tienes cuenta?</span>
        <Link href="/users/sign_in" class="text-decoration-none ml-1">
          <span class="text-primary font-weight-medium">Iniciar sesión</span>
        </Link>
      </div>
    </v-form>
  </v-card>
</template>