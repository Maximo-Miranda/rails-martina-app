<script setup lang="ts">
import { useForm, Link } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import { rules } from '@/utils/validation'

const props = defineProps<{
  user: {
    id: number
    full_name: string
    email: string
    created_at: string
    last_sign_in_at: string | null
    sign_in_count: number
  }
}>()

const form = useForm({
  user: {
    full_name: props.user.full_name,
    email: props.user.email,
    current_password: '',
    password: '',
    password_confirmation: '',
  }
})

const showCurrentPassword = ref(false)
const showNewPassword = ref(false)
const showConfirmPassword = ref(false)
const formRef = ref<HTMLFormElement | null>(null)
const changePassword = ref(false)

// Reglas de validación
const nameRules = [
  rules.required('El nombre completo es requerido'),
  rules.minLength(3, 'El nombre debe tener al menos 3 caracteres'),
]

const emailRules = [
  rules.required('El correo electrónico es requerido'),
  rules.email('Ingresa un correo electrónico válido'),
]

const currentPasswordRules = computed(() => {
  if (!changePassword.value) return []
  return [rules.required('La contraseña actual es requerida')]
})

const newPasswordRules = computed(() => {
  if (!changePassword.value) return []
  return [
    rules.required('La nueva contraseña es requerida'),
    rules.password('La contraseña debe tener al menos 6 caracteres'),
  ]
})

const confirmPasswordRules = computed(() => {
  if (!changePassword.value) return []
  return [
    rules.required('La confirmación es requerida'),
    rules.passwordConfirmation(form.user.password, 'Las contraseñas no coinciden'),
  ]
})

// Limpiar campos de contraseña cuando se desactiva
const togglePasswordChange = () => {
  if (!changePassword.value) {
    form.user.current_password = ''
    form.user.password = ''
    form.user.password_confirmation = ''
  }
}

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.put('/users')
}
</script>

<template>
  <v-container class="py-8" style="max-width: 800px;">
    <!-- Header -->
    <div class="d-flex align-center mb-6">
      <Link href="/dashboard">
        <v-btn
          icon
          variant="text"
          class="mr-2"
        >
          <v-icon>mdi-arrow-left</v-icon>
        </v-btn>
      </Link>
      <div>
        <h1 class="text-h4 font-weight-bold">Mi Perfil</h1>
        <p class="text-body-2 text-medium-emphasis mt-1">
          Administra tu información personal
        </p>
      </div>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <!-- Información personal -->
      <v-card class="mb-6 rounded-xl" elevation="2">
        <v-card-title class="d-flex align-center pa-4 bg-grey-lighten-4">
          <v-icon color="primary" class="mr-3">mdi-account-circle</v-icon>
          <span class="text-h6">Información personal</span>
        </v-card-title>

        <v-card-text class="pa-6">
          <v-text-field
            v-model="form.user.full_name"
            label="Nombre completo"
            variant="outlined"
            color="primary"
            density="comfortable"
            prepend-inner-icon="mdi-account-outline"
            :rules="nameRules"
            :error-messages="form.errors['user.full_name']"
            class="mb-4"
          />

          <v-text-field
            v-model="form.user.email"
            label="Correo electrónico"
            type="email"
            variant="outlined"
            color="primary"
            density="comfortable"
            prepend-inner-icon="mdi-email-outline"
            :rules="emailRules"
            :error-messages="form.errors['user.email']"
          />
        </v-card-text>
      </v-card>

      <!-- Actividad de la cuenta -->
      <v-card class="mb-6 rounded-xl" elevation="2">
        <v-card-title class="d-flex align-center pa-4 bg-grey-lighten-4">
          <v-icon color="primary" class="mr-3">mdi-shield-account</v-icon>
          <span class="text-h6">Actividad de la cuenta</span>
        </v-card-title>

        <v-card-text class="pa-0">
          <v-list lines="two" density="compact">
            <v-list-item>
              <template v-slot:prepend>
                <v-icon color="grey-darken-1" size="small">mdi-calendar-plus</v-icon>
              </template>
              <v-list-item-title class="text-body-2 text-medium-emphasis">
                Miembro desde
              </v-list-item-title>
              <v-list-item-subtitle class="text-body-2 font-weight-medium text-high-emphasis">
                {{ user.created_at }}
              </v-list-item-subtitle>
            </v-list-item>

            <v-divider />

            <v-list-item>
              <template v-slot:prepend>
                <v-icon color="grey-darken-1" size="small">mdi-login</v-icon>
              </template>
              <v-list-item-title class="text-body-2 text-medium-emphasis">
                Último acceso
              </v-list-item-title>
              <v-list-item-subtitle class="text-body-2 font-weight-medium text-high-emphasis">
                {{ user.last_sign_in_at || 'Primera sesión' }}
              </v-list-item-subtitle>
            </v-list-item>

            <v-divider />

            <v-list-item>
              <template v-slot:prepend>
                <v-icon color="grey-darken-1" size="small">mdi-counter</v-icon>
              </template>
              <v-list-item-title class="text-body-2 text-medium-emphasis">
                Inicios de sesión
              </v-list-item-title>
              <v-list-item-subtitle class="text-body-2 font-weight-medium text-high-emphasis">
                {{ user.sign_in_count }} veces
              </v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </v-card-text>
      </v-card>

      <!-- Cambiar contraseña -->
      <v-card class="mb-6 rounded-xl" elevation="2">
        <v-card-title class="d-flex align-center justify-space-between pa-4 bg-grey-lighten-4">
          <div class="d-flex align-center">
            <v-icon color="primary" class="mr-3">mdi-lock-outline</v-icon>
            <span class="text-h6">Cambiar contraseña</span>
          </div>
          <v-switch
            v-model="changePassword"
            color="primary"
            hide-details
            density="compact"
            @update:model-value="togglePasswordChange"
          />
        </v-card-title>

        <v-expand-transition>
          <v-card-text v-if="changePassword" class="pa-6">
            <v-alert
              type="info"
              variant="tonal"
              density="compact"
              class="mb-4"
            >
              <template v-slot:text>
                Para cambiar tu contraseña, ingresa tu contraseña actual y la nueva contraseña.
              </template>
            </v-alert>

            <v-text-field
              v-model="form.user.current_password"
              label="Contraseña actual"
              :type="showCurrentPassword ? 'text' : 'password'"
              variant="outlined"
              color="primary"
              density="comfortable"
              prepend-inner-icon="mdi-lock-outline"
              :append-inner-icon="showCurrentPassword ? 'mdi-eye-off' : 'mdi-eye'"
              @click:append-inner="showCurrentPassword = !showCurrentPassword"
              :rules="currentPasswordRules"
              :error-messages="form.errors['user.current_password']"
              class="mb-4"
              autocomplete="current-password"
            />

            <v-row dense>
              <v-col cols="12" sm="6">
                <v-text-field
                  v-model="form.user.password"
                  label="Nueva contraseña"
                  :type="showNewPassword ? 'text' : 'password'"
                  variant="outlined"
                  color="primary"
                  density="comfortable"
                  prepend-inner-icon="mdi-lock-plus-outline"
                  :append-inner-icon="showNewPassword ? 'mdi-eye-off' : 'mdi-eye'"
                  @click:append-inner="showNewPassword = !showNewPassword"
                  :rules="newPasswordRules"
                  :error-messages="form.errors['user.password']"
                  autocomplete="new-password"
                />
              </v-col>
              <v-col cols="12" sm="6">
                <v-text-field
                  v-model="form.user.password_confirmation"
                  label="Confirmar contraseña"
                  :type="showConfirmPassword ? 'text' : 'password'"
                  variant="outlined"
                  color="primary"
                  density="comfortable"
                  prepend-inner-icon="mdi-lock-check-outline"
                  :append-inner-icon="showConfirmPassword ? 'mdi-eye-off' : 'mdi-eye'"
                  @click:append-inner="showConfirmPassword = !showConfirmPassword"
                  :rules="confirmPasswordRules"
                  :error-messages="form.errors['user.password_confirmation']"
                  autocomplete="new-password"
                />
              </v-col>
            </v-row>
          </v-card-text>
        </v-expand-transition>
      </v-card>

      <!-- Botones de acción -->
      <div class="d-flex justify-end gap-3">
        <Link href="/dashboard">
          <v-btn
            variant="outlined"
            color="grey"
            class="text-none"
          >
            Cancelar
          </v-btn>
        </Link>
        <v-btn
          type="submit"
          color="primary"
          :loading="form.processing"
          class="text-none"
        >
          Guardar cambios
        </v-btn>
      </div>
    </v-form>
  </v-container>
</template>
