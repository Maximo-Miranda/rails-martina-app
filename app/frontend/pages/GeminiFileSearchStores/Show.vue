<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'

interface GeminiStore {
  id: number
  display_name: string
  gemini_store_name: string | null
  status: string
  error_message: string | null
  active_documents_count: number
  size_bytes: number
  metadata: Record<string, unknown>
  created_at: string
  updated_at: string
}

const props = defineProps<{
  store: GeminiStore
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()

const getStatusColor = (status: string) => {
  switch (status) {
    case 'active': return 'success'
    case 'pending': return 'warning'
    case 'failed': return 'error'
    case 'deleted': return 'grey'
    default: return 'grey'
  }
}

const formatBytes = (bytes: number) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString()
}
</script>

<template>
  <v-container class="py-6" style="max-width: 600px;" data-testid="gemini-store-detail">
    <!-- Back button -->
    <v-tooltip location="bottom" :text="t('tooltips.back')" max-width="300px">
      <template #activator="{ props }">
        <v-btn
          v-bind="props"
          variant="text"
          prepend-icon="mdi-arrow-left"
          class="mb-4 px-0"
          data-testid="gemini-store-btn-back"
          :disabled="isNavigating"
          @click="navigateTo('/gemini_file_search_stores')"
        >
          {{ t('common.back') }}
        </v-btn>
      </template>
    </v-tooltip>

    <v-card class="rounded-xl" elevation="0" border>
      <!-- Header with title and edit button -->
      <div class="d-flex align-start justify-space-between pa-6 pb-0">
        <div>
          <div class="text-h5 font-weight-bold" data-testid="gemini-store-display-name">
            {{ store.display_name }}
          </div>
          <div class="text-body-2 text-medium-emphasis" data-testid="gemini-store-gemini-name">
            {{ store.gemini_store_name || t('gemini_stores.pending_sync') }}
          </div>
        </div>
        <v-tooltip v-if="store.status !== 'deleted'" location="top" :text="t('tooltips.edit')" max-width="300px">
          <template #activator="{ props }">
            <v-btn
              v-bind="props"
              icon="mdi-pencil"
              variant="text"
              color="primary"
              size="small"
              class="mt-n1"
              data-testid="gemini-store-btn-edit"
              :disabled="isNavigating"
              @click="navigateTo(`/gemini_file_search_stores/${store.id}/edit`)"
            />
          </template>
        </v-tooltip>
      </div>

      <v-card-text class="pa-6">
        <!-- Actions -->
        <div class="mb-6">
          <v-tooltip location="top" :text="t('gemini_stores.manage_documents')" max-width="300px">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                v-if="store.status === 'active'"
                color="primary"
                prepend-icon="mdi-file-document-multiple"
                data-testid="gemini-store-btn-documents"
                :disabled="isNavigating"
                @click="navigateTo(`/documents?scope=global&store_id=${store.id}`)"
              >
                {{ t('gemini_stores.manage_documents') }}
              </v-btn>
            </template>
          </v-tooltip>
        </div>

        <!-- Status -->
        <div class="mb-6">
          <div class="text-overline text-medium-emphasis mb-2">{{ t('gemini_stores.status') }}</div>
          <v-chip :color="getStatusColor(store.status)" size="small" variant="tonal" data-testid="gemini-store-status">
            {{ t(`gemini_stores.statuses.${store.status}`) }}
          </v-chip>
        </div>

        <!-- Error Message (Conditional) -->
        <div v-if="store.error_message" class="mb-6">
          <div class="text-overline text-error mb-1">{{ t('gemini_stores.error_message') }}</div>
          <div class="text-body-2 text-error bg-error-lighten-5 pa-3 rounded" data-testid="gemini-store-error">
            <v-icon icon="mdi-alert-circle" size="small" class="mr-2" />
            {{ store.error_message }}
          </div>
        </div>

        <v-divider class="my-4" />

        <!-- Stats Row -->
        <v-row class="mb-2">
          <v-col cols="6">
            <div class="text-overline text-medium-emphasis mb-1">{{ t('gemini_stores.documents_count') }}</div>
            <div class="d-flex align-center">
              <v-tooltip location="top" :text="t('tooltips.documents_icon')" max-width="300px">
                <template #activator="{ props }">
                  <v-icon v-bind="props" color="primary" size="small" class="mr-2">mdi-file-document-multiple</v-icon>
                </template>
              </v-tooltip>
              <span class="text-body-1" data-testid="gemini-store-documents">
                {{ store.active_documents_count }}
              </span>
            </div>
          </v-col>
          <v-col cols="6">
            <div class="text-overline text-medium-emphasis mb-1">{{ t('gemini_stores.size') }}</div>
            <div class="d-flex align-center">
              <v-tooltip location="top" :text="t('tooltips.storage_icon')" max-width="300px">
                <template #activator="{ props }">
                  <v-icon v-bind="props" color="primary" size="small" class="mr-2">mdi-harddisk</v-icon>
                </template>
              </v-tooltip>
              <span class="text-body-1" data-testid="gemini-store-size">
                {{ formatBytes(store.size_bytes) }}
              </span>
            </div>
          </v-col>
        </v-row>

        <v-divider class="my-4" />

        <!-- Timestamps -->
        <v-row>
          <v-col cols="6">
            <div class="text-overline text-medium-emphasis mb-1">{{ t('common.created_at') }}</div>
            <div class="text-body-2 text-medium-emphasis" data-testid="gemini-store-created-at">
              {{ formatDate(store.created_at) }}
            </div>
          </v-col>
          <v-col cols="6">
            <div class="text-overline text-medium-emphasis mb-1">{{ t('gemini_stores.updated_at') }}</div>
            <div class="text-body-2 text-medium-emphasis" data-testid="gemini-store-updated-at">
              {{ formatDate(store.updated_at) }}
            </div>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-container>
</template>
