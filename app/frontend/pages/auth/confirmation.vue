<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import SafeLink from '@/components/SafeLink.vue'

const { t } = useTranslations()

const props = defineProps<{
  confirmation_token?: string
  errors?: Record<string, string[]>
}>()

const hasErrors = props.errors && Object.keys(props.errors).length > 0
</script>

<template>
  <v-card class="pa-6 pa-sm-8 rounded-xl" elevation="2">
    <div class="text-center mb-6">
      <!-- Icono de error -->
      <v-icon
        :color="hasErrors ? 'error' : 'success'"
        size="64"
        class="mb-4"
      >
        {{ hasErrors ? 'mdi-alert-circle-outline' : 'mdi-check-circle-outline' }}
      </v-icon>

      <h1 class="text-h5 font-weight-bold mb-2">
        {{ hasErrors ? t('auth.confirmation.error_title') : t('auth.confirmation.success_title') }}
      </h1>

      <p class="text-body-2 text-medium-emphasis">
        {{ hasErrors ? t('auth.confirmation.error_subtitle') : t('auth.confirmation.success_subtitle') }}
      </p>
    </div>

    <!-- Mostrar errores si existen -->
    <v-alert
      v-if="hasErrors"
      type="error"
      variant="tonal"
      class="mb-4"
    >
      <div v-for="(messages, field) in errors" :key="field">
        <div v-for="message in messages" :key="message">
          {{ message }}
        </div>
      </div>
    </v-alert>

    <!-- Acciones -->
    <div class="d-flex flex-column">
      <SafeLink href="/users/sign_in" class="text-decoration-none">
        <v-btn
          color="primary"
          block
          size="large"
          class="text-none font-weight-medium"
          rounded="lg"
        >
          {{ t('auth.confirmation.go_to_login') }}
        </v-btn>
      </SafeLink>

      <SafeLink
        v-if="hasErrors"
        href="/users/confirmation/new"
        class="text-decoration-none mt-4"
      >
        <v-btn
          variant="outlined"
          color="primary"
          block
          size="large"
          class="text-none font-weight-medium"
          rounded="lg"
        >
          {{ t('auth.confirmation.resend_link') }}
        </v-btn>
      </SafeLink>
    </div>

    <div class="d-flex align-center my-4">
      <v-divider />
      <span class="mx-3 text-caption text-medium-emphasis">{{ t('common.or') }}</span>
      <v-divider />
    </div>

    <div class="text-center">
      <span class="text-body-2 text-medium-emphasis">{{ t('auth.confirmation.no_account') }}</span>
      <SafeLink href="/users/sign_up" class="text-decoration-none ml-1">
        <span class="text-primary font-weight-medium">{{ t('auth.confirmation.create_account') }}</span>
      </SafeLink>
    </div>
  </v-card>
</template>
