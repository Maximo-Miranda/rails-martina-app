<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useActionLoading } from '@/composables/useActionLoading'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { ChatSummary, ChatStore, PagyPagination } from '@/types'

const props = defineProps<{
  chats: ChatSummary[]
  pagination: PagyPagination
  filters: Record<string, unknown>
  store: ChatStore | null
  canCreateChat: boolean
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { isAnyLoading, startLoading, stopLoading } = useActionLoading()

const searchKey = 'title_cont'
const search = ref<string | null>(String(props.filters?.[searchKey] ?? ''))
const loading = ref(false)

const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)

// Can create chat only if has permission AND store has documents
const canCreate = computed(() =>
  props.canCreateChat &&
  props.store?.status === 'active' &&
  (props.store?.active_documents_count ?? 0) > 0
)

const headers = computed(() => [
  { title: t('chats.default_title'), key: 'title', sortable: true },
  { title: t('chats.messages_count'), key: 'messages_count', sortable: true },
  { title: t('chats.last_message'), key: 'last_message_at', sortable: true },
  { title: t('chats.statuses.active'), key: 'status', sortable: true },
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
  router.get('/chats', buildQueryParams(page, limit, sort), {
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

const deleteChat = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const confirmDeleteChat = () => {
  if (!deleteTargetId.value) return

  deleting.value = true
  startLoading('delete', deleteTargetId.value)
  router.delete(`/chats/${deleteTargetId.value}`, {
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
    case 'archived': return 'grey'
    default: return 'grey'
  }
}

const formatDate = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString()
}

const formatDateTime = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString()
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader :title="t('chats.title')" :subtitle="t('chats.subtitle')">
      <template #actions>
        <v-btn
          v-if="canCreate"
          color="primary"
          prepend-icon="mdi-plus"
          size="small"
          data-testid="chats-btn-new"
          :disabled="isAnyLoading || isNavigating"
          @click="navigateTo('/chats/new')"
        >
          {{ t('chats.new_chat') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Store Info Card -->
    <v-card v-if="store" class="rounded-xl mb-4" elevation="0" border>
      <v-card-text class="pa-4">
        <div class="d-flex align-center justify-space-between">
          <div>
            <div class="text-subtitle-2 text-grey">{{ t('documents.current_store') }}</div>
            <div class="text-h6">{{ store.display_name }}</div>
          </div>
          <div class="d-flex align-center gap-2">
            <v-chip size="small" variant="tonal" color="primary">
              {{ store.active_documents_count }} {{ t('documents.documents_count') }}
            </v-chip>
            <v-chip
              :color="store.status === 'active' ? 'success' : 'warning'"
              size="small"
              variant="tonal"
            >
              {{ store.status }}
            </v-chip>
          </div>
        </div>
      </v-card-text>
    </v-card>

    <!-- Alert when store is not ready -->
    <v-alert
      v-if="store && store.status !== 'active'"
      type="warning"
      variant="tonal"
      class="mb-4"
      data-testid="chats-alert-store-not-synced"
    >
      {{ t('chats.store_not_synced') }}
    </v-alert>

    <!-- Alert when store has no documents -->
    <v-alert
      v-if="store && store.status === 'active' && store.active_documents_count === 0"
      type="info"
      variant="tonal"
      class="mb-4"
      data-testid="chats-alert-no-documents"
    >
      {{ t('chats.no_documents') }}
    </v-alert>

    <!-- Empty State (only when no chats exist and no search filter) -->
    <v-card v-if="!chats.length && !loading && !search?.trim()" class="rounded-xl" elevation="0" border>
      <v-card-text class="text-center py-12">
        <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-chat-outline</v-icon>
        <h3 class="text-h6 mb-2">{{ t('chats.no_chats') }}</h3>
        <p class="text-body-2 text-grey mb-6">{{ t('chats.no_chats_description') }}</p>
        <v-btn
          v-if="canCreate"
          color="primary"
          prepend-icon="mdi-plus"
          data-testid="chats-btn-start"
          :disabled="isAnyLoading || isNavigating"
          @click="navigateTo('/chats/new')"
        >
          {{ t('chats.start_chat') }}
        </v-btn>
      </v-card-text>
    </v-card>

    <!-- Chats Table (show when there are chats OR when searching) -->
    <v-card v-else class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-4">
        <v-text-field
          v-model="search"
          :placeholder="t('chats.search')"
          prepend-inner-icon="mdi-magnify"
          density="compact"
          variant="outlined"
          hide-details
          clearable
          class="mb-4"
          style="max-width: 400px"
          data-testid="chats-input-search"
        />

        <!-- No results message -->
        <div v-if="!chats.length && search?.trim()" class="text-center py-8">
          <v-icon size="48" color="grey-lighten-1" class="mb-3">mdi-magnify</v-icon>
          <p class="text-body-1 text-grey">{{ t('common.no_results') }}</p>
        </div>

        <v-data-table-server
          v-else
          :headers="headers"
          :items="chats"
          :items-length="pagination.count"
          :items-per-page="pagination.limit"
          :page="pagination.page"
          :sort-by="sortBy"
          :loading="loading"
          item-value="id"
          density="comfortable"
          hover
          data-testid="chats-table"
          @update:options="onUpdateOptions"
        >
          <template #item.title="{ item }">
            <div class="d-flex align-center">
              <v-icon size="small" class="mr-2" color="primary">mdi-chat</v-icon>
              <a
                class="text-primary text-decoration-none cursor-pointer"
                data-testid="chats-link-show"
                @click="navigateTo(`/chats/${item.id}`)"
              >
                {{ item.title }}
              </a>
            </div>
          </template>

          <template #item.messages_count="{ item }">
            <v-chip size="small" variant="tonal" color="primary">
              {{ item.messages_count }} {{ t('chats.messages_count') }}
            </v-chip>
          </template>

          <template #item.last_message_at="{ item }">
            <span class="text-body-2 text-grey">
              {{ formatDateTime(item.last_message_at) }}
            </span>
          </template>

          <template #item.status="{ item }">
            <v-chip
              :color="getStatusColor(item.status)"
              size="small"
              variant="tonal"
            >
              {{ t(`chats.statuses.${item.status}`) }}
            </v-chip>
          </template>

          <template #item.created_at="{ item }">
            <span class="text-body-2 text-grey">
              {{ formatDate(item.created_at) }}
            </span>
          </template>

          <template #item.actions="{ item }">
            <div class="d-flex justify-end gap-1">
              <v-btn
                icon
                size="small"
                variant="text"
                color="primary"
                :title="t('tooltips.view')"
                data-testid="chats-btn-view"
                @click="navigateTo(`/chats/${item.id}`)"
              >
                <v-icon size="small">mdi-eye</v-icon>
              </v-btn>
              <v-btn
                icon
                size="small"
                variant="text"
                color="error"
                :title="t('tooltips.delete')"
                data-testid="chats-btn-delete"
                @click="deleteChat(item.id)"
              >
                <v-icon size="small">mdi-delete</v-icon>
              </v-btn>
            </div>
          </template>
        </v-data-table-server>
      </v-card-text>
    </v-card>

    <!-- Delete Confirmation Dialog -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('chats.delete_title')"
      :text="t('chats.delete_message')"
      :loading="deleting"
      data-testid="chats-dialog-delete"
      @confirm="confirmDeleteChat"
    />
  </v-container>
</template>
