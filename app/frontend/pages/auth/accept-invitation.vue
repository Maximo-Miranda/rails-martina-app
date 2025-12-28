<script setup lang="ts">
import { ref } from 'vue'
import { useForm } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { rules } from '@/utils/validation'

const props = defineProps<{
  invitation_token: string
}>()

const { t } = useTranslations()
const showPassword = ref(false)
const showPasswordConfirmation = ref(false)
const formRef = ref<HTMLFormElement | null>(null)

const form = useForm({
  full_name: '',
  password: '',
  password_confirmation: '',
  invitation_token: props.invitation_token
})

const fullNameRules = [
  rules.required(t('validation.required')),
]

const passwordRules = [
  rules.required(t('validation.required')),
  rules.minLength(6, t('validation.min_length', { count: 6 })),
]

const passwordConfirmationRules = [
  rules.required(t('validation.required')),
  (v: string) => v === form.password || t('validation.password_mismatch'),
]

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.put('/users/invitation')
}
</script>

<template>
  <v-card data-testid="accept-invitation-card" class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-account-plus-outline</v-icon>
      <h1 data-testid="accept-invitation-title" class="text-h5 font-weight-bold mb-2">{{ t('auth.accept_invitation.title') }}</h1>
      <p class="text-body-2 text-medium-emphasis">{{ t('auth.accept_invitation.subtitle') }}</p>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <v-text-field
        data-testid="input-full-name"
        v-model="form.full_name"
        :label="t('auth.accept_invitation.full_name')"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-account-outline"
        :rules="fullNameRules"
        :error-messages="form.errors.full_name"
        class="mb-1"
        autocomplete="name"
      />

      <v-text-field
        data-testid="input-password"
        v-model="form.password"
        :label="t('auth.accept_invitation.password')"
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
      />

      <v-text-field
        data-testid="input-password-confirmation"
        v-model="form.password_confirmation"
        :label="t('auth.accept_invitation.password_confirmation')"
        :type="showPasswordConfirmation ? 'text' : 'password'"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-lock-check-outline"
        :append-inner-icon="showPasswordConfirmation ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPasswordConfirmation = !showPasswordConfirmation"
        :rules="passwordConfirmationRules"
        :error-messages="form.errors.password_confirmation"
        class="mb-4"
        autocomplete="new-password"
      />

      <v-btn
        data-testid="btn-submit"
        type="submit"
        color="primary"
        block
        size="large"
        :loading="form.processing"
        :disabled="form.processing"
        class="text-none font-weight-bold"
        rounded="lg"
      >
        {{ t('auth.accept_invitation.submit') }}
      </v-btn>
    </v-form>
  </v-card>
</template>
