<!-- filepath: /home/mhmh/code/wudok/rails-martina-app/app/frontend/pages/Auth/Register.vue -->
<script setup lang="ts">
import { useForm, Link } from '@inertiajs/vue3'

// Inicializamos el formulario con los campos necesarios
const form = useForm({
  full_name: '',
  email: '',
  password: '',
  password_confirmation: '',
})

const submit = () => {
  form.post('/users')
}
</script>

<template>
  <v-container class="fill-height justify-center bg-grey-lighten-4" fluid>
    <!-- Tarjeta centrada estilo Google -->
    <v-card width="450" class="pa-6 rounded-lg" elevation="1">
      <div class="text-center mb-8">
        <!-- Aquí podrías poner tu logo -->
        <h1 class="text-h5 font-weight-medium mb-2">Crear una cuenta</h1>
        <p class="text-body-2 text-medium-emphasis">Ir a Wudok</p>
      </div>

      <v-form @submit.prevent="submit">
        <v-text-field
          v-model="form.full_name"
          label="Nombre completo"
          variant="outlined"
          color="primary"
          density="comfortable"
          :error-messages="form.errors.full_name"
          class="mb-2"
        ></v-text-field>

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

        <v-row dense>
          <v-col cols="12" sm="6">
            <v-text-field
              v-model="form.password"
              label="Contraseña"
              type="password"
              variant="outlined"
              color="primary"
              density="comfortable"
              :error-messages="form.errors.password"
            ></v-text-field>
          </v-col>
          <v-col cols="12" sm="6">
            <v-text-field
              v-model="form.password_confirmation"
              label="Confirmación"
              type="password"
              variant="outlined"
              color="primary"
              density="comfortable"
              :error-messages="form.errors.password_confirmation"
            ></v-text-field>
          </v-col>
        </v-row>

        <div class="text-caption text-medium-emphasis mb-6">
          Usa 6 caracteres o más con una combinación de letras, números y símbolos.
        </div>

        <div class="d-flex justify-space-between align-center mt-2">
          <Link href="/users/sign_in" as="div">
            <v-btn variant="text" color="primary" class="text-capitalize px-0">
              Acceder a mi cuenta
            </v-btn>
          </Link>

          <v-btn
            type="submit"
            color="primary"
            :loading="form.processing"
            flat
            class="text-capitalize"
            height="40"
          >
            Siguiente
          </v-btn>
        </div>
      </v-form>
    </v-card>
  </v-container>
</template>