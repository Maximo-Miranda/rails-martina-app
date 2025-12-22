<script setup lang="ts">
import { ref, computed } from 'vue'
import { rules } from '@/utils/validation'
import { useForm, Link, usePage } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()
const page = usePage()

const serverErrors = computed(() => page.props.errors || {})

const form = useForm({
  user: {
    email: '',
    password: '',
    remember_me: false,
  }
})

const showPassword = ref(false)
const formRef = ref<HTMLFormElement | null>(null)

const emailRules = [
  rules.required(t('validation.required')),
  rules.email(t('validation.email_invalid')),
]

const passwordRules = [
  rules.required(t('validation.required')),
  rules.minLength(6, t('validation.min_length', { count: 6 })),
]

const submit = async () => {
  const { valid } = await formRef.value?.validate()
  if (!valid) return

  form.post('/users/sign_in')
}
</script>

<template>
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <v-icon color="primary" size="48" class="mb-4">mdi-account-circle-outline</v-icon>
      <h1 class="text-h5 font-weight-bold mb-2">{{ t('auth.login.title') }}</h1>
      <p class="text-body-2 text-medium-emphasis">{{ t('auth.login.subtitle') }}</p>
    </div>

    <v-form ref="formRef" @submit.prevent="submit" validate-on="blur lazy">
      <v-text-field
        v-model="form.user.email"
        :label="t('auth.login.email')"
        type="email"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-email-outline"
        :rules="emailRules"
        :error-messages="serverErrors.email"
        class="mb-1"
        autocomplete="email"
      />

      <v-text-field
        v-model="form.user.password"
        :label="t('auth.login.password')"
        :type="showPassword ? 'text' : 'password'"
        variant="outlined"
        color="primary"
        density="comfortable"
        prepend-inner-icon="mdi-lock-outline"
        :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPassword = !showPassword"
        :rules="passwordRules"
        :error-messages="serverErrors.password"
        class="mb-1"
        autocomplete="current-password"
      />

      <div class="d-flex flex-column flex-sm-row justify-space-between align-sm-center mb-4 ga-2">
        <v-checkbox
          v-model="form.user.remember_me"
          :label="t('auth.login.remember_me')"
          color="primary"
          density="compact"
          hide-details
          class="grow-0"
        />

        <Link href="/users/password/new" class="text-decoration-none">
          <span class="text-primary text-body-2 font-weight-medium">
            {{ t('auth.login.forgot_password') }}
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
        {{ t('auth.login.submit') }}
      </v-btn>

      <div class="d-flex align-center my-4">
        <v-divider />
        <span class="mx-3 text-caption text-medium-emphasis">{{ t('common.or') }}</span>
        <v-divider />
      </div>

      <div class="text-center">
        <span class="text-body-2 text-medium-emphasis">{{ t('auth.login.no_account') }}</span>
        <Link href="/users/sign_up" class="text-decoration-none ml-1">
          <span class="text-primary font-weight-medium">{{ t('auth.login.create_account') }}</span>
        </Link>
      </div>
    </v-form>
  </v-card>
</template>