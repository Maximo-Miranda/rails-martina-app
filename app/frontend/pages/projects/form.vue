<script setup lang="ts">
import { useForm } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
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
    <div class="mb-6">
      <h1 class="text-h4 font-weight-bold mb-1">
        {{ isEditing ? t('projects.edit') : t('projects.new') }}
      </h1>
      <p class="text-body-1 text-medium-emphasis">
        {{ isEditing ? t('projects.edit_description') : t('projects.new_description') }}
      </p>
    </div>

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

          <div class="d-flex gap-3">
            <v-btn
              type="submit"
              color="primary"
              :loading="form.processing"
              :disabled="form.processing"
            >
              {{ isEditing ? t('common.save') : t('common.create') }}
            </v-btn>
            <v-btn variant="text" @click="navigateTo('/projects')">
              {{ t('common.cancel') }}
            </v-btn>
          </div>
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
