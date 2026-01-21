<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useActionLoading } from '@/composables/useActionLoading'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { LegalCase, PagyPagination, LegalCaseStatus, LegalCaseSpecialty } from '@/types'

const props = defineProps<{
  legalCases: LegalCase[]
  pagination: PagyPagination
  filters: Record<string, unknown>
  statuses: LegalCaseStatus[]
  specialties: LegalCaseSpecialty[]
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { isAnyLoading, startLoading, stopLoading } = useActionLoading()

const searchKey = 'case_number_cont'
const search = ref<string | null>(String(props.filters?.[searchKey] ?? ''))
const loading = ref(false)

const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)

const headers = computed(() => [
  { title: t('legal_cases.case_number'), key: 'caseNumber', sortable: true },
  { title: t('legal_cases.court'), key: 'court', sortable: true },
  { title: t('legal_cases.specialty'), key: 'specialty', sortable: true },
  { title: t('legal_cases.status'), key: 'status', sortable: true },
  { title: t('legal_cases.plaintiff'), key: 'plaintiff', sortable: true },
  { title: t('legal_cases.defendant'), key: 'defendant', sortable: true },
  { title: t('legal_cases.current_term_date'), key: 'currentTermDate', sortable: true },
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
  router.get('/legal_cases', buildQueryParams(page, limit, sort), {
    preserveState: true,
    replace: true,
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

const deleteLegalCase = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const confirmDelete = () => {
  if (!deleteTargetId.value) return
  deleting.value = true
  startLoading('delete', deleteTargetId.value)
  router.delete(`/legal_cases/${deleteTargetId.value}`, {
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
    case 'activo': return 'success'
    case 'archivado': return 'grey'
    case 'terminado': return 'info'
    case 'suspendido': return 'warning'
    default: return 'grey'
  }
}

const formatDate = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString()
}

const isTermDueSoon = (dateString: string | null) => {
  if (!dateString) return false
  const termDate = new Date(dateString)
  const today = new Date()
  const daysUntil = Math.ceil((termDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))
  return daysUntil >= 0 && daysUntil <= 3
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader :title="t('legal_cases.title')" :subtitle="t('legal_cases.subtitle')">
      <template #actions>
        <v-btn
          color="primary"
          prepend-icon="mdi-plus"
          size="small"
          data-testid="legal-cases-btn-new"
          :disabled="isAnyLoading || isNavigating"
          @click="navigateTo('/legal_cases/new')"
        >
          {{ t('legal_cases.new') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text>
        <v-text-field
          v-model="search"
          :label="t('common.search')"
          prepend-inner-icon="mdi-magnify"
          variant="outlined"
          density="compact"
          hide-details
          clearable
          class="mb-4"
          data-testid="legal-cases-input-search"
        />

        <v-data-table-server
          :headers="headers"
          :items="legalCases"
          :items-length="pagination.count"
          :loading="loading"
          :items-per-page="pagination.limit"
          :page="pagination.page"
          :sort-by="sortBy"
          item-value="id"
          @update:options="onUpdateOptions"
        >
          <template #item.caseNumber="{ item }">
            <a
              class="text-primary text-decoration-none font-weight-medium"
              style="cursor: pointer"
              @click="navigateTo(`/legal_cases/${item.id}`)"
            >
              {{ item.caseNumber }}
            </a>
          </template>

          <template #item.specialty="{ item }">
            <v-chip size="small" variant="tonal">
              {{ t(`legal_cases.specialties.${item.specialty}`) }}
            </v-chip>
          </template>

          <template #item.status="{ item }">
            <v-chip size="small" :color="getStatusColor(item.status)" variant="tonal">
              {{ t(`legal_cases.statuses.${item.status}`) }}
            </v-chip>
          </template>

          <template #item.currentTermDate="{ item }">
            <v-chip
              v-if="item.currentTermDate"
              size="small"
              :color="isTermDueSoon(item.currentTermDate) ? 'warning' : 'default'"
              variant="tonal"
            >
              {{ formatDate(item.currentTermDate) }}
            </v-chip>
            <span v-else class="text-grey">-</span>
          </template>

          <template #item.actions="{ item }">
            <v-btn
              icon="mdi-eye"
              size="small"
              variant="text"
              :data-testid="`legal-cases-btn-view-${item.id}`"
              @click="navigateTo(`/legal_cases/${item.id}`)"
            />
            <v-btn
              icon="mdi-pencil"
              size="small"
              variant="text"
              :data-testid="`legal-cases-btn-edit-${item.id}`"
              @click="navigateTo(`/legal_cases/${item.id}/edit`)"
            />
            <v-btn
              icon="mdi-delete"
              size="small"
              variant="text"
              color="error"
              :data-testid="`legal-cases-btn-delete-${item.id}`"
              @click="deleteLegalCase(item.id)"
            />
          </template>
        </v-data-table-server>
      </v-card-text>
    </v-card>

    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('legal_cases.delete_title')"
      :text="t('legal_cases.delete_message')"
      :confirm-label="t('common.delete')"
      :cancel-label="t('common.cancel')"
      confirm-color="error"
      :loading="deleting"
      @confirm="confirmDelete"
    />
  </v-container>
</template>
