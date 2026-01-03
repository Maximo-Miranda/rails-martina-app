<script setup lang="ts">
import { computed } from 'vue'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useDocumentContext } from '@/composables/useDocumentContext'
import { useFileFormat } from '@/composables/useFileFormat'
import PageHeader from '@/components/PageHeader.vue'
import type { Document, GeminiStore } from '@/types'
import type { Project } from '@/composables/useDocumentContext'

const props = defineProps<{
  project?: Project | null
  document: Document
  store: GeminiStore
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { routes, testIdPrefix } = useDocumentContext()
const { formatBytes, getContentTypeIcon, formatContentType } = useFileFormat()

const getStatusColor = (status: string) => {
  switch (status) {
    case 'synced': return 'success'
    case 'pending': return 'warning'
    case 'failed': return 'error'
    case 'deleted': return 'grey'
    default: return 'grey'
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString()
}

const hasMetadata = computed(() => {
  const meta = props.document.custom_metadata
  if (!meta) return false
  return meta.chat_correlation_id || meta.source_url || (meta.context_tags && meta.context_tags.length > 0)
})
</script>

<template>
  <v-container class="py-6" style="max-width: 800px;">
    <PageHeader
      :title="document.display_name"
      :subtitle="project ? t('documents.document_details_project', { project: project.name }) : t('documents.document_details')"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          prepend-icon="mdi-arrow-left"
          size="small"
          :data-testid="`${testIdPrefix}-btn-back`"
          :disabled="isNavigating"
          @click="navigateTo(routes.index(store.id))"
        >
          {{ t('common.back') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Project Badge (only for project scope) -->
    <v-alert
      v-if="project"
      type="info"
      variant="tonal"
      class="mb-4"
      density="comfortable"
    >
      <template #prepend>
        <v-icon icon="mdi-folder-outline" />
      </template>
      {{ t('documents.project_context', { name: project.name }) }}
    </v-alert>

    <!-- Status Alert -->
    <v-alert
      v-if="document.status === 'pending'"
      type="info"
      variant="tonal"
      class="mb-4"
      :data-testid="`${testIdPrefix}-pending-alert`"
    >
      <v-progress-circular indeterminate size="20" class="mr-2" />
      {{ t('documents.pending_message') }}
    </v-alert>

    <v-alert
      v-if="document.status === 'failed'"
      type="error"
      variant="tonal"
      class="mb-4"
      :data-testid="`${testIdPrefix}-failed-alert`"
    >
      {{ t('documents.failed_message') }}
      <template v-if="document.error_message">
        <br /><span class="text-caption">{{ document.error_message }}</span>
      </template>
    </v-alert>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <!-- File Preview -->
        <div class="d-flex align-center mb-6 pa-4 bg-grey-lighten-4 rounded-lg">
          <v-icon :icon="getContentTypeIcon(document.content_type)" size="48" class="mr-4" />
          <div class="flex-grow-1 overflow-hidden">
            <div class="text-h6 text-truncate">{{ document.display_name }}</div>
            <div class="text-body-2 text-grey">{{ formatContentType(document.content_type) }}</div>
          </div>
          <div class="text-right ml-2">
            <v-chip
              :color="getStatusColor(document.status)"
              size="small"
              :data-testid="`${testIdPrefix}-status`"
            >
              {{ t(`documents.status_${document.status}`) }}
            </v-chip>
          </div>
        </div>

        <!-- Details Grid -->
        <v-row>
          <v-col cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('documents.size') }}</div>
            <div class="text-body-1" :data-testid="`${testIdPrefix}-size`">{{ formatBytes(document.size_bytes) }}</div>
          </v-col>

          <v-col cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('documents.file_hash') }}</div>
            <div class="text-body-2 font-monospace" :data-testid="`${testIdPrefix}-hash`">
              {{ document.file_hash?.substring(0, 16) }}...
            </div>
          </v-col>

          <v-col cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('documents.uploaded_by') }}</div>
            <div class="text-body-1" :data-testid="`${testIdPrefix}-uploader`">
              {{ document.uploaded_by.full_name }}
              <span class="text-grey">({{ document.uploaded_by.email }})</span>
            </div>
          </v-col>

          <v-col cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('common.created_at') }}</div>
            <div class="text-body-1" :data-testid="`${testIdPrefix}-created-at`">
              {{ formatDate(document.created_at) }}
            </div>
          </v-col>

          <v-col cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('documents.store') }}</div>
            <div class="text-body-1" :data-testid="`${testIdPrefix}-store`">{{ store.display_name }}</div>
          </v-col>

          <v-col v-if="document.remote_id" cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('documents.remote_id') }}</div>
            <div class="text-body-2 font-monospace" :data-testid="`${testIdPrefix}-remote-id`">
              {{ document.remote_id }}
            </div>
          </v-col>

          <v-col v-if="document.gemini_document_path" cols="12">
            <div class="text-caption text-grey mb-1">{{ t('documents.gemini_path') }}</div>
            <div class="text-body-2 font-monospace" :data-testid="`${testIdPrefix}-gemini-path`">
              {{ document.gemini_document_path }}
            </div>
          </v-col>

          <v-col v-if="project" cols="12" md="6">
            <div class="text-caption text-grey mb-1">{{ t('documents.project') }}</div>
            <div class="text-body-1" :data-testid="`${testIdPrefix}-project`">
              <v-chip size="small" color="primary" variant="outlined">
                {{ project.name }}
              </v-chip>
            </div>
          </v-col>
        </v-row>

        <!-- Custom Metadata -->
        <template v-if="hasMetadata">
          <v-divider class="my-6" />

          <div class="text-subtitle-1 mb-4">
            <v-icon icon="mdi-tag-multiple" class="mr-2" />
            {{ t('documents.custom_metadata') }}
          </div>

          <v-row>
            <v-col v-if="document.custom_metadata?.chat_correlation_id" cols="12" md="6">
              <div class="text-caption text-grey mb-1">{{ t('documents.metadata_correlation_id') }}</div>
              <div class="text-body-2 font-monospace" :data-testid="`${testIdPrefix}-correlation-id`">
                {{ document.custom_metadata.chat_correlation_id }}
              </div>
            </v-col>

            <v-col v-if="document.custom_metadata?.source_url" cols="12" md="6">
              <div class="text-caption text-grey mb-1">{{ t('documents.metadata_source_url') }}</div>
              <div class="text-body-2" :data-testid="`${testIdPrefix}-source-url`">
                <a :href="document.custom_metadata.source_url" target="_blank" rel="noopener">
                  {{ document.custom_metadata.source_url }}
                </a>
              </div>
            </v-col>

            <v-col v-if="document.custom_metadata?.context_tags?.length" cols="12">
              <div class="text-caption text-grey mb-1">{{ t('documents.metadata_tags') }}</div>
              <div :data-testid="`${testIdPrefix}-tags`">
                <v-chip
                  v-for="(tag, index) in document.custom_metadata.context_tags"
                  :key="index"
                  size="small"
                  class="ma-1"
                >
                  {{ tag }}
                </v-chip>
              </div>
            </v-col>
          </v-row>
        </template>

        <!-- Download -->
        <v-divider class="my-6" />

        <div class="d-flex justify-end">
          <v-btn
            v-if="document.file_url"
            :href="document.file_url"
            :download="document.display_name"
            color="primary"
            variant="outlined"
            prepend-icon="mdi-download"
            :data-testid="`${testIdPrefix}-btn-download`"
          >
            {{ t('documents.download') }}
          </v-btn>
        </div>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<style scoped>
.font-monospace {
  word-break: break-all;
  overflow-wrap: break-word;
}
</style>
