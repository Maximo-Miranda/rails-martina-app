<script setup lang="ts">
import { useForm, Link, usePage } from '@inertiajs/vue3'
import { computed } from 'vue'

const page = usePage()
const flash = computed(() => page.props.flash as { notice?: string; alert?: string })

const form = useForm({
  email: '',
  password: '',
  remember: false,
})

const submit = () => {
  form.post('/users/sign_in')
}
</script>

<template>
  <v-container class="fill-height justify-center bg-grey-lighten-4" fluid>
    <!-- Tarjeta centrada estilo Google -->
    <v-card width="450" class="pa-6 rounded-lg" elevation="1">
      <div class="text-center mb-8">
        <!-- Aquí podrías poner tu logo -->
        <h1 class="text-h5 font-weight-medium mb-2">Iniciar sesión</h1>
        <p class="text-body-2 text-medium-emphasis">Accede a tu cuenta de Wudok</p>
      </div>

      <!-- Mensaje flash de confirmación (ej: después de registrarse) -->
      <v-alert
        v-if="flash.notice"
        type="info"
        variant="tonal"
        class="mb-4"
        density="compact"
      >
        {{ flash.notice }}
      </v-alert>

      <!-- Mensaje flash de error -->
      <v-alert
        v-if="flash.alert"
        type="error"
        variant="tonal"
        class="mb-4"
        density="compact"
      >
        {{ flash.alert }}
      </v-alert>

      <v-form @submit.prevent="submit">
        <v-text-field
          v-model="form.email"
          label="Correo electrónico"
          type="email"
          variant="outlined"
          color="primary"
          density="comfortable"
          :error-messages="form.errors.email"
          class="mb-2"
        ></v-text-field>

        <v-text-field
          v-model="form.password"
          label="Contraseña"
          type="password"
          variant="outlined"
          color="primary"
          density="comfortable"
          :error-messages="form.errors.password"
          class="mb-2"
        ></v-text-field>

        <div class="d-flex justify-space-between align-center mb-4">
          <v-checkbox
            v-model="form.remember"
            label="Recordarme"
            color="primary"
            density="compact"
            hide-details
          ></v-checkbox>

          <Link href="/users/password/new" as="span">
            <v-btn variant="text" color="primary" class="text-capitalize px-0" size="small">
              ¿Olvidaste tu contraseña?
            </v-btn>
          </Link>
        </div>

        <v-btn
          type="submit"
          color="primary"
          :loading="form.processing"
          block
          flat
          class="text-capitalize mb-4"
          height="44"
        >
          Iniciar sesión
        </v-btn>

        <v-divider class="my-4"></v-divider>

        <div class="text-center">
          <span class="text-body-2 text-medium-emphasis">¿No tienes cuenta?</span>
          <Link href="/users/sign_up" as="span">
            <v-btn variant="text" color="primary" class="text-capitalize">
              Crear una cuenta
            </v-btn>
          </Link>
        </div>
      </v-form>
    </v-card>
  </v-container>
</template>