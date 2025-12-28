<script setup lang="ts">
import { useForm } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'
import type { Project } from '@/types'

const props = defineProps<{
  project: Partial<Project>
  errors?: Record<string, string[]>
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()

const isEditing = !!props.project.id

const form = useForm({
  name: props.project.name || '',
  description: props.project.description || ''
})

const submit = () => {
  if (isEditing) {
    form.put(`/projects/${props.project.slug}`)
  } else {
    form.post('/projects')
  }
}
</script>

<template>
  <v-container class="py-6" style="max-width: 600px;">
    <PageHeader
      :title="isEditing ? t('projects.edit') : t('projects.new')"
      :subtitle="isEditing ? t('projects.edit_description') : t('projects.new_description')"
    />

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form @submit.prevent="submit">
          <v-text-field
            v-model="form.name"
            data-testid="projects-input-name"
            :label="t('projects.name')"
            :error-messages="form.errors.name || errors?.name"
            :disabled="form.processing"
            variant="outlined"
            class="mb-4"
            required
          />

          <v-textarea
            v-model="form.description"
            data-testid="projects-input-description"
            :label="t('projects.description')"
            :error-messages="form.errors.description || errors?.description"
            :disabled="form.processing"
            variant="outlined"
            rows="3"
            class="mb-4"
          />

          <FormActions
            data-test-id="projects-form"
            :primary-label="isEditing ? t('common.save') : t('common.create')"
            :primary-loading="form.processing"
            :primary-disabled="form.processing || isNavigating"
            :cancel-label="t('common.cancel')"
            :cancel-disabled="form.processing || isNavigating"
            @cancel="navigateTo('/projects')"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
