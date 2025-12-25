<script setup lang="ts">
import { ref } from 'vue'
import { useForm } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'
import type { Project } from '@/types'

const props = defineProps<{
  current_project: Project
  errors?: Record<string, string[]>
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

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
    <PageHeader :title="t('users.invite_title')" :subtitle="t('users.invite_description')" />

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form @submit.prevent="submit">
          <v-text-field
            v-model="form.email"
            data-testid="users-input-email"
            :label="t('users.email')"
            :error-messages="form.errors.email || errors?.email"
            type="email"
            variant="outlined"
            class="mb-4"
            required
          />

          <v-checkbox
            v-model="inviteToProject"
            data-testid="users-checkbox-invite-to-project"
            :label="t('users.invite_to_project', { project: current_project.name })"
            class="mb-2"
          />

          <v-select
            v-if="inviteToProject"
            v-model="selectedRole"
            data-testid="users-select-role"
            :items="roles"
            :label="t('users.role')"
            variant="outlined"
            class="mb-4"
          />

          <v-alert v-if="!inviteToProject" type="info" variant="tonal" class="mb-4">
            {{ t('users.invite_platform_only') }}
          </v-alert>

          <FormActions
            data-test-id="users-invite-form"
            :primary-label="t('users.send_invitation')"
            :primary-loading="form.processing"
            :primary-disabled="form.processing"
            :cancel-label="t('common.cancel')"
            @cancel="navigateTo('/users')"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
