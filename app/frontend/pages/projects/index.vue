<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import type { Project } from '@/types'

const props = defineProps<{
  projects: Project[]
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const switchProject = (slug: string) => {
  router.post(`/projects/${slug}/switch`)
}

const deleteProject = (slug: string) => {
  if (confirm(t('projects.confirm_delete'))) {
    router.delete(`/projects/${slug}`)
  }
}
</script>

<template>
  <v-container class="py-6">
    <div class="d-flex align-center justify-space-between mb-6">
      <div>
        <h1 class="text-h4 font-weight-bold mb-1">{{ t('projects.title') }}</h1>
        <p class="text-body-1 text-medium-emphasis">{{ t('projects.subtitle') }}</p>
      </div>
      <v-btn color="primary" prepend-icon="mdi-plus" @click="navigateTo('/projects/new')">
        {{ t('projects.new') }}
      </v-btn>
    </div>

    <v-row v-if="projects.length">
      <v-col v-for="project in projects" :key="project.id" cols="12" sm="6" lg="4">
        <v-card class="rounded-xl h-100" elevation="0" border>
          <v-card-text class="pa-4">
            <div class="d-flex align-center mb-3">
              <v-avatar color="primary" size="40" variant="tonal" class="mr-3">
                <v-icon>mdi-folder-outline</v-icon>
              </v-avatar>
              <div class="flex-grow-1">
                <h3 class="text-subtitle-1 font-weight-bold">{{ project.name }}</h3>
                <span class="text-caption text-medium-emphasis">/{{ project.slug }}</span>
              </div>
            </div>
            <p class="text-body-2 text-medium-emphasis mb-4" style="min-height: 40px;">
              {{ project.description || t('projects.no_description') }}
            </p>
          </v-card-text>
          <v-card-actions class="px-4 pb-4">
            <v-btn variant="tonal" color="primary" size="small" @click="switchProject(project.slug)">
              {{ t('projects.switch') }}
            </v-btn>
            <v-spacer />
            <v-btn icon="mdi-pencil" variant="text" size="small" @click="navigateTo(`/projects/${project.slug}/edit`)" />
            <v-btn icon="mdi-delete" variant="text" size="small" color="error" @click="deleteProject(project.slug)" />
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>

    <v-card v-else class="rounded-xl text-center pa-8" elevation="0" border>
      <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-folder-outline</v-icon>
      <h3 class="text-h6 mb-2">{{ t('projects.empty_title') }}</h3>
      <p class="text-body-2 text-medium-emphasis mb-4">{{ t('projects.empty_description') }}</p>
      <v-btn color="primary" @click="navigateTo('/projects/new')">{{ t('projects.create_first') }}</v-btn>
    </v-card>
  </v-container>
</template>
