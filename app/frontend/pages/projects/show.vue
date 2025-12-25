<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import type { Project } from '@/types'

const props = defineProps<{
  project: Project
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
</script>

<template>
  <v-container class="py-6" style="max-width: 600px;">
    <!-- Back button -->
    <v-btn
      variant="text"
      prepend-icon="mdi-arrow-left"
      class="mb-4 px-0"
      data-testid="projects-btn-back"
      :disabled="isNavigating"
      @click="navigateTo('/projects')"
    >
      {{ t('common.back') }}
    </v-btn>

    <v-card class="rounded-xl" elevation="0" border>
      <!-- Header with title and edit button -->
      <div class="d-flex align-start justify-space-between pa-6 pb-0">
        <div>
          <div class="text-h5 font-weight-bold">{{ project.name }}</div>
          <div class="text-body-2 text-medium-emphasis">/{{ project.slug }}</div>
        </div>
        <v-btn
          icon="mdi-pencil"
          variant="text"
          color="primary"
          size="small"
          class="mt-n1"
          data-testid="projects-btn-edit"
          :disabled="isNavigating"
          @click="navigateTo(`/projects/${project.slug}/edit`)"
        />
      </div>

      <v-card-text class="pa-6">
        <!-- Description -->
        <div class="mb-6">
          <div class="text-overline text-medium-emphasis mb-2">{{ t('projects.description') }}</div>
          <div class="text-body-1">
            {{ project.description || t('projects.no_description') }}
          </div>
        </div>

        <v-divider class="my-4" />

        <!-- Created at -->
        <div>
          <div class="text-overline text-medium-emphasis mb-2">{{ t('common.created_at') }}</div>
          <div class="text-body-1">
            {{ project.created_at ? new Date(project.created_at).toLocaleDateString() : '-' }}
          </div>
        </div>
      </v-card-text>
    </v-card>
  </v-container>
</template>
