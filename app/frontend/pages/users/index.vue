<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { usePermissions } from '@/composables/usePermissions'
import { useActionLoading } from '@/composables/useActionLoading'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { User } from '@/types'
import type { PagyPagination } from '@/types'

const props = defineProps<{
  users: User[]
  pagination: PagyPagination
  filters: Record<string, unknown>
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { can, canUser } = usePermissions()
const { isAnyLoading, startLoading, stopLoading } = useActionLoading()

const searchKey = 'full_name_or_email_cont'

const search = ref<string | null>(String(props.filters?.[searchKey] ?? ''))
const loading = ref(false)

// Dialog to delete user (super_admin only)
const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)

// Dialog to unlink user from project (owner/admin)
const unlinkDialog = ref(false)
const unlinkTargetId = ref<number | null>(null)
const unlinking = ref(false)

const headers = computed(() => [
  { title: t('users.name'), key: 'full_name', sortable: true },
  { title: t('users.email'), key: 'email', sortable: true },
  { title: t('users.joined'), key: 'created_at', sortable: true },
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
  router.get('/users', buildQueryParams(page, limit, sort), {
    preserveState: true,
    replace: true,
    onCancel: () => {
      loading.value = false
    },
    onError: () => {
      loading.value = false
    },
    onFinish: () => {
      loading.value = false
    }
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

const deleteUser = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const confirmDeleteUser = () => {
  if (!deleteTargetId.value) return

  deleting.value = true
  startLoading('delete', deleteTargetId.value)
  router.delete(`/users/${deleteTargetId.value}` as string, {
    onFinish: () => {
      stopLoading('delete', deleteTargetId.value!)
      deleting.value = false
      deleteDialog.value = false
      deleteTargetId.value = null
    }
  })
}

const unlinkUser = (id: number) => {
  unlinkTargetId.value = id
  unlinkDialog.value = true
}

const confirmUnlinkUser = () => {
  if (!unlinkTargetId.value) return

  unlinking.value = true
  startLoading('unlink', unlinkTargetId.value)
  router.delete(`/users/${unlinkTargetId.value}/remove_from_project` as string, {
    onFinish: () => {
      stopLoading('unlink', unlinkTargetId.value!)
      unlinking.value = false
      unlinkDialog.value = false
      unlinkTargetId.value = null
    }
  })
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader :title="t('users.title')" :subtitle="t('users.subtitle')">
      <template #actions>
        <v-btn
          v-if="can.inviteUsers"
          color="primary"
          prepend-icon="mdi-account-plus"
          size="small"
          data-testid="users-btn-invite"
          :disabled="isAnyLoading || isNavigating"
          @click="navigateTo('/users/new_invitation')"
        >
          {{ t('users.invite') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-4">
        <v-text-field
          v-model="search"
          data-testid="users-input-search"
          :label="t('users.search')"
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
        data-testid="users-table"
        :headers="headers"
        :items="users"
        :items-length="pagination.count"
        :loading="loading"
        :page="pagination.page"
        :items-per-page="pagination.limit"
        :sort-by="sortBy"
        :items-per-page-options="[10, 25, 50]"
        density="comfortable"
        mobile-breakpoint="sm"
        hover
        @update:options="onUpdateOptions"
      >
        <template #item.full_name="{ item }">
          <div class="d-flex align-center py-2">
            <v-avatar color="primary" size="32" class="mr-3">
              <span class="text-caption">{{ item.full_name?.charAt(0)?.toUpperCase() }}</span>
            </v-avatar>
            {{ item.full_name }}
          </div>
        </template>

        <template #item.created_at="{ item }">
          <span class="text-medium-emphasis">
            {{ item.created_at ? new Date(item.created_at).toLocaleDateString() : '-' }}
          </span>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex justify-end align-center gap-2">
            <v-btn
              icon="mdi-eye"
              variant="text"
              size="small"
              :disabled="isAnyLoading || isNavigating"
              :data-testid="`users-row-${item.id}-btn-view`"
              @click="navigateTo(`/users/${item.id}`)"
            />
            <v-btn
              v-if="canUser(item).removeFromProject"
              icon="mdi-account-remove"
              variant="text"
              size="small"
              color="warning"
              :disabled="isAnyLoading || isNavigating"
              :data-testid="`users-row-${item.id}-btn-unlink`"
              :title="t('users.remove_from_project')"
              @click="unlinkUser(item.id)"
            />
            <v-btn
              v-if="canUser(item).delete"
              icon="mdi-delete"
              variant="text"
              size="small"
              color="error"
              :disabled="isAnyLoading || isNavigating"
              :data-testid="`users-row-${item.id}-btn-delete`"
              @click="deleteUser(item.id)"
            />
          </div>
        </template>

        <template #no-data>
          <div class="text-center pa-8">
            <v-icon size="48" color="grey-lighten-1" class="mb-4">mdi-account-group-outline</v-icon>
            <p class="text-body-1 text-medium-emphasis">{{ t('users.empty') }}</p>
          </div>
        </template>
      </v-data-table-server>
    </v-card>

    <!-- Dialog to unlink user from project -->
    <ConfirmDialog
      v-model="unlinkDialog"
      data-test-id="users-dialog-unlink"
      :title="t('common.confirm')"
      :text="t('users.confirm_remove_from_project')"
      :confirm-label="t('users.remove_from_project')"
      :cancel-label="t('common.cancel')"
      :loading="unlinking"
      @confirm="confirmUnlinkUser"
    />

    <!-- Dialog to delete user (super_admin only) -->
    <ConfirmDialog
      v-model="deleteDialog"
      data-test-id="users-dialog-delete"
      :title="t('common.confirm')"
      :text="t('users.confirm_delete')"
      :confirm-label="t('common.delete')"
      :cancel-label="t('common.cancel')"
      :loading="deleting"
      @confirm="confirmDeleteUser"
    />
  </v-container>
</template>
