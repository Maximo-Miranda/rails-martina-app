<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useActionLoading } from '@/composables/useActionLoading'
import { useDocumentNotifications } from '@/composables/useDocumentNotifications'
import { useFileFormat } from '@/composables/useFileFormat'
import { useDocumentContext } from '@/composables/useDocumentContext'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { Document, GeminiStore, PagyPagination } from '@/types'
import type { Project } from '@/composables/useDocumentContext'

const props = defineProps<{
  project?: Project | null
  documents: Document[]
  store: GeminiStore
  pagination: PagyPagination
  filters: Record<string, unknown>
  supportedContentTypes: string[]
  maxFileSize: number
  metadataKeys: string[]
  canCreateDocument: boolean
  canDeleteDocument: boolean
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { isAnyLoading, startLoading, stopLoading } = useActionLoading()
const { formatContentType, getContentTypeIcon, formatBytes } = useFileFormat()
const { isGlobal, routes, testIdPrefix } = useDocumentContext()

// Permission check
const canCreateDocument = computed(() => props.canCreateDocument)
const canDeleteDocument = computed(() => props.canDeleteDocument)

// Enable real-time updates via Action Cable
useDocumentNotifications()

const searchKey = 'display_name_cont'
const search = ref<string | null>(String(props.filters?.[searchKey] ?? ''))
const loading = ref(false)

const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)

const pageTitle = computed(() => t('documents.title'))
const pageSubtitle = computed(() =>
  isGlobal ? t('documents.global_subtitle') : t('documents.project_title')
)

const headers = computed(() => [
  { title: t('documents.display_name'), key: 'display_name', sortable: true },
  { title: t('documents.content_type'), key: 'content_type', sortable: true },
  { title: t('documents.size'), key: 'size_bytes', sortable: true },
  { title: t('documents.status'), key: 'status', sortable: true },
  { title: t('common.created_at'), key: 'created_at', sortable: true },
  { title: t('common.actions'), key: 'actions', sortable: false, align: 'end' as const }
])

function parseSort(s: unknown): Array<{ key: string; order: 'asc' | 'desc' }> {
  if (typeof s !== 'string') return []
  const [key, order] = s.split(' ')
  if (!key || (order !== 'asc' && order !== 'desc')) return []
  return [{ key, order }]
}

const sortBy = ref(parseSort(props.filters?.s))

function buildQueryParams(page: number, limit: number, sort: string | null) {
  const payload: Record<string, string | number> = { page, limit }
  if (isGlobal) {
    payload.scope = 'global'
    payload.store_id = props.store.id
  }
  const trimmed = (search.value ?? '').trim()
  if (trimmed) payload[`q[${searchKey}]`] = trimmed
  if (sort) payload['q[s]'] = sort
  return payload
}

function visit(page: number, limit: number, sort: string | null) {
  loading.value = true
  router.get(routes.index(), buildQueryParams(page, limit, sort), {
    preserveState: true,
    replace: true,
    onCancel: () => { loading.value = false },
    onError: () => { loading.value = false },
    onFinish: () => { loading.value = false }
  })
}

function onUpdateOptions(options: { page: number; itemsPerPage: number; sortBy?: Array<{ key: string; order: 'asc' | 'desc' }> }) {
  sortBy.value = options.sortBy ?? []
  const first = options.sortBy?.[0]
  const sort = first ? `${first.key} ${first.order}` : null
  visit(options.page, options.itemsPerPage, sort)
}

let searchDebounce: number | null = null
watch(search, () => {
  if (searchDebounce) window.clearTimeout(searchDebounce)
  searchDebounce = window.setTimeout(() => {
    const currentSort = sortBy.value[0]
    const sort = currentSort ? `${currentSort.key} ${currentSort.order}` : null
    visit(1, props.pagination.limit ?? 10, sort)
  }, 350)
})

const deleteDocument = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const confirmDeleteDocument = () => {
  if (!deleteTargetId.value) return

  deleting.value = true
  startLoading('delete', deleteTargetId.value)
  router.delete(routes.destroy(deleteTargetId.value), {
    onFinish: () => {
      stopLoading('delete', deleteTargetId.value!)
      deleting.value = false
      deleteDialog.value = false
      deleteTargetId.value = null
    }
  })
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'active': return 'success'
    case 'pending': return 'warning'
    case 'processing': return 'info'
    case 'failed': return 'error'
    case 'deleted': return 'grey'
    case 'synced': return 'success'
    default: return 'grey'
  }
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString()
}

const storeCapacityPercent = computed(() => {
  const used = props.store.size_bytes
  const total = used + props.store.available_bytes
  return Math.round((used / total) * 100)
})
</script>

<template>
  <v-container class="py-6">
    <PageHeader :title="pageTitle" :subtitle="pageSubtitle">
      <template #actions>
        <v-btn
          v-if="canCreateDocument"
          color="primary"
          prepend-icon="mdi-upload"
          size="small"
          :data-testid="`${testIdPrefix}-btn-upload`"
          :disabled="isAnyLoading || isNavigating"
          @click="navigateTo(routes.new(store.id))"
        >
          {{ t('documents.upload') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Store Info Card -->
    <v-card class="rounded-xl mb-4" elevation="0" border>
      <v-card-text class="pa-4">
        <div class="d-flex align-center justify-space-between">
          <div>
            <div class="d-flex align-center gap-2">
              <span class="text-subtitle-2 text-grey">{{ t('documents.current_store') }}</span>
              <v-chip
                v-if="isGlobal"
                size="x-small"
                variant="tonal"
                color="secondary"
              >
                Global
              </v-chip>
            </div>
            <div class="text-h6">{{ store.display_name }}</div>
          </div>
          <div class="text-right">
            <div class="text-caption text-grey">{{ t('documents.storage_used') }}</div>
            <div class="d-flex align-center">
              <v-progress-linear
                :model-value="storeCapacityPercent"
                :color="storeCapacityPercent > 80 ? 'error' : 'primary'"
                height="8"
                rounded
                style="width: 120px"
                class="mr-2"
              />
              <span class="text-body-2">{{ formatBytes(store.size_bytes) }} / {{ formatBytes(store.size_bytes + store.available_bytes) }}</span>
            </div>
          </div>
        </div>
      </v-card-text>
    </v-card>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-4">
        <v-text-field
          v-model="search"
          :data-testid="`${testIdPrefix}-input-search`"
          :label="t('documents.search')"
          prepend-inner-icon="mdi-magnify"
          variant="outlined"
          density="comfortable"
          bg-color="surface"
          rounded="lg"
          hide-details
          clearable
          :disabled="loading || isNavigating"
          style="max-width: 520px;"
        />
      </v-card-text>

      <v-divider />

      <v-data-table-server
        :data-testid="`${testIdPrefix}-table`"
        :headers="headers"
        :items="documents"
        :items-length="pagination.count"
        :loading="loading"
        :page="pagination.page"
        :items-per-page="pagination.limit"
        :sort-by="sortBy"
        hover
        @update:options="onUpdateOptions"
      >
        <template #item.display_name="{ item }">
          <div class="d-flex align-center py-2">
            <v-icon :icon="getContentTypeIcon(item.content_type)" class="mr-2" />
            <div class="d-flex flex-column">
              <span class="font-weight-medium">{{ item.display_name }}</span>
              <span class="text-caption text-grey">
                {{ t('documents.uploaded_by') }}: {{ item.uploaded_by.full_name }}
              </span>
            </div>
          </div>
        </template>

        <template #item.content_type="{ item }">
          <v-chip size="small" variant="outlined">
            {{ formatContentType(item.content_type) }}
          </v-chip>
        </template>

        <template #item.size_bytes="{ item }">
          {{ formatBytes(item.size_bytes) }}
        </template>

        <template #item.status="{ item }">
          <v-chip
            :color="getStatusColor(item.status)"
            size="small"
            :data-testid="`document-status-${item.id}`"
          >
            {{ t(`documents.status_${item.status}`) }}
          </v-chip>
        </template>

        <template #item.created_at="{ item }">
          {{ formatDate(item.created_at) }}
        </template>

        <template #item.actions="{ item }">
          <v-tooltip location="top" :text="t('tooltips.view')" max-width="300px">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon="mdi-eye"
                size="small"
                variant="text"
                :data-testid="`${testIdPrefix}-btn-show-${item.id}`"
                :disabled="isAnyLoading || isNavigating"
                @click="navigateTo(routes.show(item.id, store.id))"
              />
            </template>
          </v-tooltip>
          <v-tooltip v-if="canDeleteDocument" location="top" :text="t('tooltips.delete')" max-width="300px">
            <template #activator="{ props }">
              <v-btn
                v-bind="props"
                icon="mdi-delete"
                size="small"
                variant="text"
                color="error"
                :data-testid="`${testIdPrefix}-btn-delete-${item.id}`"
                :disabled="isAnyLoading || item.status === 'deleted'"
                @click="deleteDocument(item.id)"
              />
            </template>
          </v-tooltip>
        </template>

        <template #no-data>
          <div class="text-center pa-8">
            <v-tooltip location="top" :text="t('tooltips.empty_documents')" max-width="300px">
              <template #activator="{ props }">
                <v-icon v-bind="props" icon="mdi-file-document-outline" size="64" color="grey-lighten-1" class="mb-4" />
              </template>
            </v-tooltip>
            <p class="text-grey">{{ t('documents.no_documents') }}</p>
          </div>
        </template>
      </v-data-table-server>
    </v-card>

    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('documents.delete_title')"
      :text="t('documents.delete_message')"
      :confirm-label="t('common.delete')"
      :cancel-label="t('common.cancel')"
      :loading="deleting"
      :data-testid="`${testIdPrefix}-delete-dialog`"
      @confirm="confirmDeleteDocument"
    />
  </v-container>
</template>
