<script setup lang="ts">
import { ref, computed } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { CourtOrder } from '@/types'

interface LegalCaseRef {
  id: number
  caseNumber: string
}

const props = defineProps<{
  legalCase: LegalCaseRef
  courtOrders: CourtOrder[]
  orderTypes: string[]
  statuses: string[]
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const showFormDialog = ref(false)
const editingOrder = ref<CourtOrder | null>(null)
const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)
const saving = ref(false)

const form = ref({
  order_type: 'auto_de_tramite',
  summary: '',
  order_date: null as string | null,
  deadline: null as string | null,
  status: 'pendiente',
})

const errors = ref<Record<string, string[]>>({})

const sortedOrders = computed(() =>
  [...props.courtOrders].sort((a, b) =>
    new Date(b.orderDate || 0).getTime() - new Date(a.orderDate || 0).getTime()
  )
)

const formatDate = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString()
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'pendiente': return 'warning'
    case 'cumplido': return 'success'
    case 'vencido': return 'error'
    case 'en_apelacion': return 'info'
    default: return 'grey'
  }
}

const openNewForm = () => {
  editingOrder.value = null
  form.value = {
    order_type: 'auto_de_tramite',
    summary: '',
    order_date: null,
    deadline: null,
    status: 'pendiente',
  }
  errors.value = {}
  showFormDialog.value = true
}

const openEditForm = (order: CourtOrder) => {
  editingOrder.value = order
  form.value = {
    order_type: order.orderType,
    summary: order.summary,
    order_date: order.orderDate,
    deadline: order.deadline,
    status: order.status,
  }
  errors.value = {}
  showFormDialog.value = true
}

const submitForm = () => {
  saving.value = true

  if (editingOrder.value) {
    router.put(
      `/legal_cases/${props.legalCase.id}/court_orders/${editingOrder.value.id}`,
      { court_order: form.value },
      {
        onSuccess: () => {
          showFormDialog.value = false
          saving.value = false
        },
        onError: (e) => {
          errors.value = e as Record<string, string[]>
          saving.value = false
        },
      }
    )
  } else {
    router.post(
      `/legal_cases/${props.legalCase.id}/court_orders`,
      { court_order: form.value },
      {
        onSuccess: () => {
          showFormDialog.value = false
          saving.value = false
        },
        onError: (e) => {
          errors.value = e as Record<string, string[]>
          saving.value = false
        },
      }
    )
  }
}

const confirmDelete = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const deleteOrder = () => {
  if (!deleteTargetId.value) return
  deleting.value = true

  router.delete(
    `/legal_cases/${props.legalCase.id}/court_orders/${deleteTargetId.value}`,
    {
      onFinish: () => {
        deleting.value = false
        deleteDialog.value = false
        deleteTargetId.value = null
      },
    }
  )
}

const goToOrder = (order: CourtOrder) => {
  navigateTo(`/legal_cases/${props.legalCase.id}/court_orders/${order.id}`)
}

const goBack = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=orders`)
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="t('court_orders.title')"
      :subtitle="legalCase.caseNumber"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          data-testid="court-orders-btn-back"
          @click="goBack"
        >
          {{ t('common.back') }}
        </v-btn>
        <v-btn
          color="primary"
          size="small"
          prepend-icon="mdi-plus"
          data-testid="court-orders-btn-new"
          @click="openNewForm"
        >
          {{ t('court_orders.new') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-table v-if="courtOrders.length > 0" hover>
        <thead>
          <tr>
            <th class="text-left">{{ t('court_orders.order_type') }}</th>
            <th class="text-left">{{ t('court_orders.summary') }}</th>
            <th class="text-left">{{ t('court_orders.order_date') }}</th>
            <th class="text-left">{{ t('court_orders.deadline') }}</th>
            <th class="text-left">{{ t('court_orders.status') }}</th>
            <th class="text-right">{{ t('common.actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="order in sortedOrders"
            :key="order.id"
            :data-testid="`court-order-row-${order.id}`"
            class="cursor-pointer"
            @click="goToOrder(order)"
          >
            <td>
              <v-chip size="small" variant="tonal">
                {{ t(`legal_cases.order_types.${order.orderType}`) }}
              </v-chip>
            </td>
            <td class="text-truncate" style="max-width: 300px;">{{ order.summary }}</td>
            <td>{{ formatDate(order.orderDate) }}</td>
            <td>
              <span :class="{ 'text-error font-weight-bold': order.overdue }">
                {{ formatDate(order.deadline) }}
              </span>
              <v-chip
                v-if="order.daysUntilDeadline !== null && order.daysUntilDeadline >= 0"
                size="x-small"
                :color="order.daysUntilDeadline <= 3 ? 'warning' : 'grey'"
                class="ml-2"
              >
                {{ order.daysUntilDeadline }}d
              </v-chip>
            </td>
            <td>
              <v-chip size="small" :color="getStatusColor(order.status)" variant="tonal">
                {{ t(`legal_cases.order_statuses.${order.status}`) }}
              </v-chip>
            </td>
            <td class="text-right">
              <v-btn
                icon
                variant="text"
                size="small"
                :data-testid="`court-order-btn-edit-${order.id}`"
                @click.stop="openEditForm(order)"
              >
                <v-icon>mdi-pencil</v-icon>
              </v-btn>
              <v-btn
                icon
                variant="text"
                size="small"
                color="error"
                :data-testid="`court-order-btn-delete-${order.id}`"
                @click.stop="confirmDelete(order.id)"
              >
                <v-icon>mdi-delete</v-icon>
              </v-btn>
            </td>
          </tr>
        </tbody>
      </v-table>

      <v-card-text v-else class="text-center py-8">
        <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-gavel</v-icon>
        <p class="text-grey">{{ t('legal_cases.no_orders') }}</p>
        <v-btn
          color="primary"
          variant="tonal"
          class="mt-4"
          prepend-icon="mdi-plus"
          data-testid="court-orders-btn-new-empty"
          @click="openNewForm"
        >
          {{ t('court_orders.new') }}
        </v-btn>
      </v-card-text>
    </v-card>

    <!-- Form Dialog -->
    <v-dialog v-model="showFormDialog" max-width="600" persistent>
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-gavel</v-icon>
          {{ editingOrder ? t('court_orders.edit') : t('court_orders.new') }}
        </v-card-title>

        <v-card-text>
          <v-form @submit.prevent="submitForm">
            <v-select
              v-model="form.order_type"
              :items="orderTypes"
              :label="t('court_orders.order_type')"
              :error-messages="errors.order_type"
              data-testid="court-order-input-type"
              required
            >
              <template #item="{ props: itemProps, item }">
                <v-list-item v-bind="itemProps" :title="t(`legal_cases.order_types.${item.raw}`)">
                </v-list-item>
              </template>
              <template #selection="{ item }">
                {{ t(`legal_cases.order_types.${item.raw}`) }}
              </template>
            </v-select>

            <v-textarea
              v-model="form.summary"
              :label="t('court_orders.summary')"
              :error-messages="errors.summary"
              data-testid="court-order-input-summary"
              rows="3"
              required
              class="mt-4"
            />

            <v-row class="mt-2">
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="form.order_date"
                  :label="t('court_orders.order_date')"
                  :error-messages="errors.order_date"
                  data-testid="court-order-input-date"
                  type="date"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="form.deadline"
                  :label="t('court_orders.deadline')"
                  :error-messages="errors.deadline"
                  data-testid="court-order-input-deadline"
                  type="date"
                />
              </v-col>
            </v-row>

            <v-select
              v-model="form.status"
              :items="statuses"
              :label="t('court_orders.status')"
              :error-messages="errors.status"
              data-testid="court-order-input-status"
              class="mt-4"
            >
              <template #item="{ props: itemProps, item }">
                <v-list-item v-bind="itemProps" :title="t(`legal_cases.order_statuses.${item.raw}`)">
                </v-list-item>
              </template>
              <template #selection="{ item }">
                {{ t(`legal_cases.order_statuses.${item.raw}`) }}
              </template>
            </v-select>
          </v-form>
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn
            variant="text"
            :disabled="saving"
            data-testid="court-order-btn-cancel"
            @click="showFormDialog = false"
          >
            {{ t('common.cancel') }}
          </v-btn>
          <v-btn
            color="primary"
            :loading="saving"
            data-testid="court-order-btn-submit"
            @click="submitForm"
          >
            {{ editingOrder ? t('common.save') : t('common.create') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete Confirmation -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('court_orders.delete_title')"
      :text="t('court_orders.delete_message')"
      :confirm-label="t('common.delete')"
      :confirm-color="error"
      :loading="deleting"
      @confirm="deleteOrder"
    />
  </v-container>
</template>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}
</style>
