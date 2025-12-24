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
const { navigateTo } = useNavigation()

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
            :label="t('projects.name')"
            :error-messages="form.errors.name || errors?.name"
            variant="outlined"
            class="mb-4"
            required
          />

          <v-textarea
            v-model="form.description"
            :label="t('projects.description')"
            :error-messages="form.errors.description || errors?.description"
            variant="outlined"
            rows="3"
            class="mb-4"
          />

          <FormActions
            :primary-label="isEditing ? t('common.save') : t('common.create')"
            :primary-loading="form.processing"
            :primary-disabled="form.processing"
            :cancel-label="t('common.cancel')"
            @cancel="navigateTo('/projects')"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
