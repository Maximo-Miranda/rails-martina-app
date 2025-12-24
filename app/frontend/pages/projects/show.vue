<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import type { Project } from '@/types'

const props = defineProps<{
  project: Project
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()
</script>

<template>
  <v-container class="py-6" style="max-width: 900px;">
    <PageHeader :title="project.name" :subtitle="`/${project.slug}`">
      <template #actions>
        <v-btn variant="text" prepend-icon="mdi-arrow-left" @click="navigateTo('/projects')">
          {{ t('common.back') }}
        </v-btn>
        <v-btn color="primary" prepend-icon="mdi-pencil" @click="navigateTo(`/projects/${project.slug}/edit`)">
          {{ t('common.edit') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <div class="mb-6">
          <div class="text-overline text-medium-emphasis mb-2">{{ t('projects.description') }}</div>
          <div class="text-body-1">
            {{ project.description || t('projects.no_description') }}
          </div>
        </div>

        <v-divider class="my-6" />

        <v-row>
          <v-col cols="12" sm="6">
            <div class="text-overline text-medium-emphasis mb-2">{{ t('projects.slug') }}</div>
            <div class="text-body-1">/{{ project.slug }}</div>
          </v-col>
          <v-col cols="12" sm="6">
            <div class="text-overline text-medium-emphasis mb-2">{{ t('common.created_at') }}</div>
            <div class="text-body-1">
              {{ project.created_at ? new Date(project.created_at).toLocaleDateString() : '-' }}
            </div>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-container>
</template>
