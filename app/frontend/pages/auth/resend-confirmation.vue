<script setup lang="ts">
import { ref } from 'vue'
import { useForm, Link } from '@inertiajs/vue3'
import { rules } from '@/utils/validation'
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const form = useForm({
  email: '',
})

const formRef = ref<HTMLFormElement | null>(null)

const emailRules = [
  rules.required(t('validation.required')),
  rules.email(t('validation.email_invalid')),
]

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.post('/users/confirmation')
}
</script>

<template>
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-email-check-outline</v-icon>
      <h1 class="text-h5 font-weight-bold mb-2">{{ t('auth.resend_confirmation.title') }}</h1>
      <p class="text-body-2 text-medium-emphasis">
        {{ t('auth.resend_confirmation.subtitle') }}
      </p>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <v-text-field
        v-model="form.email"
        :label="t('auth.resend_confirmation.email')"
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
        {{ t('auth.resend_confirmation.submit') }}
      </v-btn>

      <div class="d-flex align-center my-4">
        <v-divider />
        <span class="mx-3 text-caption text-medium-emphasis">{{ t('common.or') }}</span>
        <v-divider />
      </div>

      <div class="text-center">
        <Link href="/users/sign_in" class="text-decoration-none">
          <span class="text-primary font-weight-medium">{{ t('auth.resend_confirmation.back_to_login') }}</span>
        </Link>
      </div>
    </v-form>
  </v-card>
</template>
