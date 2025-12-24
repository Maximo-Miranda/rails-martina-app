<script setup lang="ts">
import { ref } from 'vue'
import { useForm } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import type { Project } from '@/types'

const props = defineProps<{
  current_project: Project
  errors?: Record<string, string[]>
}>()

const { t } = useTranslations()

const inviteToProject = ref(true)
const selectedRole = ref('coworker')

const roles = [
  { title: t('roles.coworker'), value: 'coworker' },
  { title: t('roles.client'), value: 'client' }
]

const form = useForm({
  email: '',
  role: 'coworker',
  invite_to_project: 'true'
})

const submit = () => {
  form.role = selectedRole.value
  form.invite_to_project = inviteToProject.value ? 'true' : 'false'
  form.post('/users/invite')
}
</script>

<template>
  <v-container class="py-6" style="max-width: 600px;">
    <div class="mb-6">
      <h1 class="text-h4 font-weight-bold mb-1">{{ t('users.invite_title') }}</h1>
      <p class="text-body-1 text-medium-emphasis">{{ t('users.invite_description') }}</p>
    </div>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form @submit.prevent="submit">
          <v-text-field
            v-model="form.email"
            :label="t('users.email')"
            :error-messages="form.errors.email || errors?.email"
            type="email"
            variant="outlined"
            class="mb-4"
            required
          />

          <v-checkbox
            v-model="inviteToProject"
            :label="t('users.invite_to_project', { project: current_project.name })"
            class="mb-2"
          />

          <v-select
            v-if="inviteToProject"
            v-model="selectedRole"
            :items="roles"
            :label="t('users.role')"
            variant="outlined"
            class="mb-4"
          />

          <v-alert v-if="!inviteToProject" type="info" variant="tonal" class="mb-4">
            {{ t('users.invite_platform_only') }}
          </v-alert>

          <div class="d-flex gap-3">
            <v-btn
              type="submit"
              color="primary"
              :loading="form.processing"
              :disabled="form.processing"
            >
              {{ t('users.send_invitation') }}
            </v-btn>
            <v-btn variant="text" href="/users">
              {{ t('common.cancel') }}
            </v-btn>
          </div>
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
