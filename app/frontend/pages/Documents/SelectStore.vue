<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useFileFormat } from '@/composables/useFileFormat'
import PageHeader from '@/components/PageHeader.vue'
import type { GeminiStore } from '@/types'

const props = defineProps<{
  stores: GeminiStore[]
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { formatBytes } = useFileFormat()
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="t('documents.title')"
      :subtitle="t('documents.select_store_subtitle')"
    />

    <v-row v-if="stores.length > 0">
      <v-col
        v-for="store in stores"
        :key="store.id"
        cols="12"
        md="6"
        lg="4"
      >
        <v-card
          class="rounded-xl h-100"
          elevation="0"
          border
          hover
          :data-testid="`documents-store-card-${store.id}`"
          @click="navigateTo(`/documents?scope=global&store_id=${store.id}`)"
        >
          <v-card-text class="pa-6">
            <div class="d-flex align-center mb-4">
              <v-avatar color="primary" size="48" class="mr-4">
                <v-icon color="white">mdi-database</v-icon>
              </v-avatar>
              <div>
                <div class="text-h6 font-weight-medium">{{ store.display_name }}</div>
                <div class="text-caption text-grey">{{ store.gemini_store_name }}</div>
              </div>
            </div>

            <v-divider class="mb-4" />

            <div class="d-flex justify-space-between text-body-2">
              <div>
                <v-icon size="small" class="mr-1">mdi-file-document-multiple</v-icon>
                {{ store.active_documents_count }} {{ t('documents.documents_count') }}
              </div>
              <div>
                <v-icon size="small" class="mr-1">mdi-harddisk</v-icon>
                {{ formatBytes(store.size_bytes) }}
              </div>
            </div>

            <v-progress-linear
              :model-value="(store.size_bytes / (store.size_bytes + store.available_bytes)) * 100"
              color="primary"
              height="6"
              rounded
              class="mt-3"
            />
            <div class="text-caption text-grey mt-1 text-right">
              {{ formatBytes(store.available_bytes) }} {{ t('documents.available') }}
            </div>
          </v-card-text>

          <v-card-actions class="pa-4 pt-0">
            <v-spacer />
            <v-btn
              color="primary"
              variant="text"
              append-icon="mdi-arrow-right"
              :disabled="isNavigating"
              data-testid="documents-btn-select-store"
            >
              {{ t('documents.view_documents') }}
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>

    <!-- Empty state -->
    <v-card v-else class="rounded-xl text-center pa-8" elevation="0" border>
      <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-database-off</v-icon>
      <div class="text-h6 text-grey mb-2">{{ t('documents.no_stores') }}</div>
      <div class="text-body-2 text-grey mb-4">{{ t('documents.no_stores_description') }}</div>
      <v-btn
        color="primary"
        prepend-icon="mdi-plus"
        data-testid="documents-btn-create-store"
        :disabled="isNavigating"
        @click="navigateTo('/gemini_file_search_stores/new')"
      >
        {{ t('documents.create_store') }}
      </v-btn>
    </v-card>
  </v-container>
</template>
