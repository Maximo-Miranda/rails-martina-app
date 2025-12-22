<script setup lang="ts">
import { ref, computed } from 'vue'
import { rules } from '@/utils/validation'
import { useForm, Link } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const form = useForm({
  full_name: '',
  email: '',
  password: '',
  password_confirmation: '',
})

const showPassword = ref(false)
const showPasswordConfirmation = ref(false)
const formRef = ref<HTMLFormElement | null>(null)

const nameRules = [
  rules.required(t('validation.required')),
  rules.minLength(3, t('validation.min_length', { count: 3 })),
]

const emailRules = [
  rules.required(t('validation.required')),
  rules.email(t('validation.email_invalid')),
]

const passwordRules = [
  rules.required(t('validation.required')),
  rules.password(t('validation.min_length', { count: 6 })),
]

const passwordConfirmationRules = computed(() => [
  rules.required(t('validation.required')),
  rules.passwordConfirmation(form.password, t('validation.passwords_no_match')),
])

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.post('/users')
}
</script>

<template>
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-account-plus-outline</v-icon>
      <h1 class="text-h5 font-weight-bold mb-2">{{ t('auth.register.title') }}</h1>
      <p class="text-body-2 text-medium-emphasis">{{ t('auth.register.subtitle') }}</p>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <v-text-field
        v-model="form.full_name"
        :label="t('auth.register.full_name')"
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
        :label="t('auth.register.email')"
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
            :label="t('auth.register.password')"
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
            :label="t('auth.register.password_confirmation')"
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
        {{ t('validation.password_hint') }}
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
        {{ t('auth.register.submit') }}
      </v-btn>

      <div class="d-flex align-center my-4">
        <v-divider />
        <span class="mx-3 text-caption text-medium-emphasis">{{ t('common.or') }}</span>
        <v-divider />
      </div>

      <div class="text-center">
        <span class="text-body-2 text-medium-emphasis">{{ t('auth.register.has_account') }}</span>
        <Link href="/users/sign_in" class="text-decoration-none ml-1">
          <span class="text-primary font-weight-medium">{{ t('auth.register.login_link') }}</span>
        </Link>
      </div>
    </v-form>
  </v-card>
</template>