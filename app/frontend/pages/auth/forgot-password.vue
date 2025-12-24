<script setup lang="ts">
import { useForm, Link } from '@inertiajs/vue3'
import { ref } from 'vue'
import { rules } from '@/utils/validation'
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const form = useForm({
  email: '',
})

const submitted = ref(false)
const formRef = ref<HTMLFormElement | null>(null)

// Reglas de validación
const emailRules = [
  rules.required(t('validation.required')),
  rules.email(t('validation.email_invalid')),
]

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.post('/users/password', {
    onSuccess: () => {
      submitted.value = true
    }
  })
}
</script>

<template>
  <!-- Tarjeta centrada con diseño moderno -->
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <!-- Estado inicial - formulario -->
    <template v-if="!submitted">
      <div class="text-center mb-6">
        <v-icon color="primary" size="48" class="mb-4">mdi-lock-reset</v-icon>
        <h1 class="text-h5 font-weight-bold mb-2">{{ t('auth.forgot_password.title') }}</h1>
        <p class="text-body-2 text-medium-emphasis">
          {{ t('auth.forgot_password.subtitle') }}
        </p>
      </div>

      <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
        <v-text-field
          v-model="form.email"
          :label="t('auth.forgot_password.email')"
          type="email"
          variant="outlined"
          color="primary"
          density="comfortable"
          prepend-inner-icon="mdi-email-outline"
          :rules="emailRules"
          :error-messages="form.errors.email"
          class="mb-4"
          autocomplete="email"
          autofocus
        />

        <v-btn
          type="submit"
          color="primary"
          :loading="form.processing"
          block
          size="large"
          class="text-none font-weight-medium mb-4"
          rounded="lg"
        >
          {{ t('auth.forgot_password.submit') }}
        </v-btn>

        <div class="d-flex align-center my-4">
          <v-divider />
          <span class="mx-3 text-caption text-medium-emphasis">{{ t('common.or') }}</span>
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
              {{ t('auth.forgot_password.back_to_login') }}
            </v-btn>
          </Link>
        </div>
      </v-form>
    </template>

    <!-- Estado de éxito - correo enviado -->
    <template v-else>
      <div class="text-center">
        <v-icon color="success" size="64" class="mb-4">mdi-email-check-outline</v-icon>
        <h1 class="text-h5 font-weight-bold mb-2">{{ t('auth.forgot_password.success_title') }}</h1>
        <p class="text-body-2 text-medium-emphasis mb-6">
          {{ t('auth.forgot_password.success_message') }}
          <strong>{{ form.email }}</strong>
        </p>

        <v-alert
          type="info"
          variant="tonal"
          density="compact"
          class="mb-6 text-left"
        >
          <template v-slot:text>
            <div class="text-body-2">
              {{ t('auth.forgot_password.spam_notice') }}
            </div>
          </template>
        </v-alert>

        <Link href="/users/sign_in" class="text-decoration-none">
          <v-btn
            color="primary"
            size="large"
            class="text-none font-weight-medium"
            rounded="lg"
            block
          >
            {{ t('auth.forgot_password.back_to_login') }}
          </v-btn>
        </Link>
      </div>
    </template>
  </v-card>
</template>
