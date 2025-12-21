<script setup lang="ts">
import { useForm, Link } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import { rules } from '@/utils/validation'

const props = defineProps<{
  reset_password_token: string
}>()

const form = useForm({
  password: '',
  password_confirmation: '',
  reset_password_token: props.reset_password_token,
})

const showPassword = ref(false)
const showPasswordConfirmation = ref(false)
const formRef = ref<HTMLFormElement | null>(null)

// Reglas de validación
const passwordRules = [
  rules.required('La contraseña es requerida'),
  rules.password('La contraseña debe tener al menos 6 caracteres'),
]

const passwordConfirmationRules = computed(() => [
  rules.required('La confirmación de contraseña es requerida'),
  rules.passwordConfirmation(form.password, 'Las contraseñas no coinciden'),
])

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.put('/users/password')
}
</script>

<template>
  <!-- Tarjeta centrada con diseño moderno -->
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-lock-outline</v-icon>
      <h1 class="text-h5 font-weight-bold mb-2">Crear nueva contraseña</h1>
      <p class="text-body-2 text-medium-emphasis">
        Ingresa tu nueva contraseña para restablecer el acceso a tu cuenta.
      </p>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <v-text-field
        v-model="form.password"
        label="Nueva contraseña"
        :type="showPassword ? 'text' : 'password'"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-lock-outline"
        :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPassword = !showPassword"
        :rules="passwordRules"
        :error-messages="form.errors.password"
        class="mb-1"
        autocomplete="new-password"
        autofocus
      />

      <v-text-field
        v-model="form.password_confirmation"
        label="Confirmar contraseña"
        :type="showPasswordConfirmation ? 'text' : 'password'"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-lock-check-outline"
        :append-inner-icon="showPasswordConfirmation ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPasswordConfirmation = !showPasswordConfirmation"
        :rules="passwordConfirmationRules"
        :error-messages="form.errors.password_confirmation"
        class="mb-1"
        autocomplete="new-password"
      />

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
        Restablecer contraseña
      </v-btn>

      <div class="d-flex align-center my-4">
        <v-divider />
        <span class="mx-3 text-caption text-medium-emphasis">o</span>
        <v-divider />
      </div>

      <div class="text-center">
        <Link href="/users/sign_in" class="text-decoration-none">
          <v-btn
            variant="text"
            color="primary"
            prepend-icon="mdi-arrow-left"
            class="text-none"
          >
            Volver a iniciar sesión
          </v-btn>
        </Link>
      </div>
    </v-form>
  </v-card>
</template>
