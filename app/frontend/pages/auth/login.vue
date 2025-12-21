<script setup lang="ts">
import { useForm, Link } from '@inertiajs/vue3'
import { ref } from 'vue'

// Los parámetros deben estar bajo 'user' para que Devise los reconozca
const form = useForm({
  user: {
    email: '',
    password: '',
    remember_me: false,
  }
})

const showPassword = ref(false)

const submit = () => {
  form.post('/users/sign_in')
}
</script>

<template>
  <!-- Tarjeta centrada con diseño moderno -->
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-account-circle-outline</v-icon>
      <h1 class="text-h5 font-weight-bold mb-2">¡Bienvenido de vuelta!</h1>
      <p class="text-body-2 text-medium-emphasis">Ingresa tus credenciales para continuar</p>
    </div>

    <v-form @submit.prevent="submit">
      <v-text-field
        v-model="form.user.email"
        label="Correo electrónico"
        type="email"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-email-outline"
        :error-messages="form.errors['user.email'] || form.errors.email"
        class="mb-1"
        autocomplete="email"
      />

      <v-text-field
        v-model="form.user.password"
        label="Contraseña"
        :type="showPassword ? 'text' : 'password'"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-lock-outline"
        :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPassword = !showPassword"
        :error-messages="form.errors['user.password'] || form.errors.password"
        class="mb-1"
        autocomplete="current-password"
      />

      <div class="d-flex justify-space-between align-center mb-4">
        <v-checkbox
          v-model="form.user.remember_me"
          label="Recordarme"
          color="primary"
          density="compact"
          hide-details
        />

        <Link href="/users/password/new" class="text-decoration-none">
          <span class="text-primary text-body-2 font-weight-medium">
            ¿Olvidaste tu contraseña?
          </span>
        </Link>
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
        Iniciar sesión
      </v-btn>

      <div class="d-flex align-center my-4">
        <v-divider />
        <span class="mx-3 text-caption text-medium-emphasis">o</span>
        <v-divider />
      </div>

      <div class="text-center">
        <span class="text-body-2 text-medium-emphasis">¿No tienes cuenta?</span>
        <Link href="/users/sign_up" class="text-decoration-none ml-1">
          <span class="text-primary font-weight-medium">Crear una cuenta</span>
        </Link>
      </div>
    </v-form>
  </v-card>
</template>