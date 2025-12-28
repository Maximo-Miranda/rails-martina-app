<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useActionLoading } from '@/composables/useActionLoading'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { PagyPagination } from '@/types'

interface GeminiStore {
  id: number
  display_name: string
  gemini_store_name: string | null
  status: string
  error_message: string | null
  active_documents_count: number
  size_bytes: number
  created_at: string
}

const props = defineProps<{
  stores: GeminiStore[]
  pagination: PagyPagination
  filters: Record<string, unknown>
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { isAnyLoading, startLoading, stopLoading } = useActionLoading()

const searchKey = 'display_name_or_gemini_store_name_cont'

const search = ref<string | null>(String(props.filters?.[searchKey] ?? ''))
const loading = ref(false)

// Dialog to delete store
const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)

const headers = computed(() => [
  { title: t('gemini_stores.display_name'), key: 'display_name', sortable: true },
  { title: t('gemini_stores.status'), key: 'status', sortable: true },
  { title: t('gemini_stores.documents_count'), key: 'active_documents_count', sortable: false },
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
  const trimmed = (search.value ?? '').trim()
  if (trimmed) payload[`q[${searchKey}]`] = trimmed
  if (sort) payload['q[s]'] = sort
  return payload
}

function visit(page: number, limit: number, sort: string | null) {
  loading.value = true
  router.get('/gemini_file_search_stores', buildQueryParams(page, limit, sort), {
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

const deleteStore = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const confirmDeleteStore = () => {
  if (!deleteTargetId.value) return

  deleting.value = true
  startLoading('delete', deleteTargetId.value)
  router.delete(`/gemini_file_search_stores/${deleteTargetId.value}` as string, {
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
  return new Date(dateString).toLocaleDateString()
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader :title="t('gemini_stores.title')" :subtitle="t('gemini_stores.subtitle')">
      <template #actions>
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          size="small"
          data-testid="gemini-stores-btn-create"
          :disabled="isAnyLoading || isNavigating"
          @click="navigateTo('/gemini_file_search_stores/new')"
        >
          {{ t('gemini_stores.new') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-4">
        <v-text-field
          v-model="search"
          data-testid="gemini-stores-input-search"
          :label="t('gemini_stores.search')"
          prepend-inner-icon="mdi-magnify"
          variant="outlined"
          density="comfortable"
          bg-color="surface"
          rounded="lg"
          hide-details
          clearable
          style="max-width: 520px;"
        />
      </v-card-text>

      <v-divider />

      <v-data-table-server
        data-testid="gemini-stores-table"
        :headers="headers"
        :items="stores"
        :items-length="pagination.count"
        :loading="loading"
        :page="pagination.page"
        :items-per-page="pagination.limit"
        :sort-by="sortBy"
        hover
        @update:options="onUpdateOptions"
      >
        <template #item.display_name="{ item }">
          <div class="d-flex flex-column py-2">
            <span class="font-weight-medium">{{ item.display_name }}</span>
            <span v-if="item.gemini_store_name" class="text-caption text-grey">
              {{ item.gemini_store_name }}
            </span>
          </div>
        </template>

        <template #item.status="{ item }">
          <v-chip
            :color="getStatusColor(item.status)"
            size="small"
            :data-testid="`gemini-store-status-${item.id}`"
          >
            {{ t(`gemini_stores.statuses.${item.status}`) }}
          </v-chip>
          <v-tooltip v-if="item.error_message" location="top">
            <template #activator="{ props }">
              <v-icon v-bind="props" color="error" size="small" class="ml-1">
                mdi-alert-circle
              </v-icon>
            </template>
            {{ item.error_message }}
          </v-tooltip>
        </template>

        <template #item.active_documents_count="{ item }">
          <span>{{ item.active_documents_count }}</span>
          <span class="text-caption text-grey ml-2">({{ formatBytes(item.size_bytes) }})</span>
        </template>

        <template #item.created_at="{ item }">
          {{ formatDate(item.created_at) }}
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex justify-end gap-1">
            <v-btn
              icon
              size="small"
              variant="text"
              :data-testid="`gemini-store-btn-show-${item.id}`"
              :disabled="isAnyLoading || isNavigating"
              @click="navigateTo(`/gemini_file_search_stores/${item.id}`)"
            >
              <v-icon size="small">mdi-eye</v-icon>
            </v-btn>
            <v-btn
              icon
              size="small"
              variant="text"
              :data-testid="`gemini-store-btn-edit-${item.id}`"
              :disabled="isAnyLoading || isNavigating || item.status === 'deleted'"
              @click="navigateTo(`/gemini_file_search_stores/${item.id}/edit`)"
            >
              <v-icon size="small">mdi-pencil</v-icon>
            </v-btn>
            <v-btn
              icon
              size="small"
              variant="text"
              color="error"
              :data-testid="`gemini-store-btn-delete-${item.id}`"
              :disabled="isAnyLoading || isNavigating || item.status === 'deleted'"
              @click="deleteStore(item.id)"
            >
              <v-icon size="small">mdi-delete</v-icon>
            </v-btn>
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-8">
            <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-database-off</v-icon>
            <p class="text-h6 text-grey">{{ t('gemini_stores.empty_title') }}</p>
            <p class="text-body-2 text-grey mb-4">{{ t('gemini_stores.empty_description') }}</p>
            <v-btn
              color="primary"
              prepend-icon="mdi-plus"
              data-testid="gemini-stores-btn-create-empty"
              @click="navigateTo('/gemini_file_search_stores/new')"
            >
              {{ t('gemini_stores.new') }}
            </v-btn>
          </div>
        </template>
      </v-data-table-server>
    </v-card>

    <!-- Delete confirmation dialog -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('common.confirm')"
      :text="t('gemini_stores.confirm_delete')"
      :confirm-label="t('common.delete')"
      :cancel-label="t('common.cancel')"
      :loading="deleting"
      data-testid="gemini-stores-delete-dialog"
      @confirm="confirmDeleteStore"
    />
  </v-container>
</template>
