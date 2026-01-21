<script setup lang="ts">
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { CourtOrderDetail, CaseReminder } from '@/types'

interface LegalCaseRef {
  id: number
  caseNumber: string
}

const props = defineProps<{
  legalCase: LegalCaseRef
  courtOrder: CourtOrderDetail
  reminders: CaseReminder[]
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const deleteDialog = ref(false)
const deleting = ref(false)

const formatDate = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString()
}

const formatDateTime = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString()
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

const confirmDelete = () => {
  deleteDialog.value = true
}

const deleteOrder = () => {
  deleting.value = true
  router.delete(
    `/legal_cases/${props.legalCase.id}/court_orders/${props.courtOrder.id}`,
    {
      onFinish: () => {
        deleting.value = false
        deleteDialog.value = false
      },
    }
  )
}

const goBack = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=orders`)
}

const markAsCumplido = () => {
  router.put(
    `/legal_cases/${props.legalCase.id}/court_orders/${props.courtOrder.id}`,
    { court_order: { status: 'cumplido' } }
  )
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="t(`legal_cases.order_types.${courtOrder.orderType}`)"
      :subtitle="legalCase.caseNumber"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          data-testid="court-order-btn-back"
          @click="goBack"
        >
          {{ t('common.back') }}
        </v-btn>
        <v-btn
          v-if="courtOrder.status === 'pendiente'"
          color="success"
          size="small"
          prepend-icon="mdi-check"
          data-testid="court-order-btn-complete"
          @click="markAsCumplido"
        >
          Marcar Cumplido
        </v-btn>
        <v-btn
          color="error"
          variant="outlined"
          size="small"
          prepend-icon="mdi-delete"
          data-testid="court-order-btn-delete"
          @click="confirmDelete"
        >
          {{ t('common.delete') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Alert if overdue -->
    <v-alert
      v-if="courtOrder.overdue"
      type="error"
      variant="tonal"
      class="mb-4"
    >
      Este auto está vencido desde {{ formatDate(courtOrder.deadline) }}
    </v-alert>

    <v-row>
      <v-col cols="12" md="8">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center justify-space-between">
            <div class="d-flex align-center">
              <v-icon class="mr-2">mdi-gavel</v-icon>
              Detalle del Auto
            </div>
            <v-chip :color="getStatusColor(courtOrder.status)" variant="tonal">
              {{ t(`legal_cases.order_statuses.${courtOrder.status}`) }}
            </v-chip>
          </v-card-title>

          <v-divider />

          <v-card-text>
            <v-list density="compact">
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-tag</v-icon>
                </template>
                <v-list-item-title>{{ t('court_orders.order_type') }}</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip size="small" variant="tonal">
                    {{ t(`legal_cases.order_types.${courtOrder.orderType}`) }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-calendar</v-icon>
                </template>
                <v-list-item-title>{{ t('court_orders.order_date') }}</v-list-item-title>
                <v-list-item-subtitle>{{ formatDate(courtOrder.orderDate) }}</v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon :color="courtOrder.overdue ? 'error' : ''">mdi-calendar-clock</v-icon>
                </template>
                <v-list-item-title>{{ t('court_orders.deadline') }}</v-list-item-title>
                <v-list-item-subtitle>
                  <span :class="{ 'text-error font-weight-bold': courtOrder.overdue }">
                    {{ formatDate(courtOrder.deadline) }}
                  </span>
                  <v-chip
                    v-if="courtOrder.daysUntilDeadline !== null"
                    size="x-small"
                    :color="courtOrder.daysUntilDeadline < 0 ? 'error' : (courtOrder.daysUntilDeadline <= 3 ? 'warning' : 'grey')"
                    class="ml-2"
                  >
                    {{ courtOrder.daysUntilDeadline < 0 ? `${Math.abs(courtOrder.daysUntilDeadline)}d vencido` : `${courtOrder.daysUntilDeadline}d restantes` }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>

            <v-divider class="my-4" />

            <h4 class="text-subtitle-2 mb-2">{{ t('court_orders.summary') }}</h4>
            <p class="text-body-2" style="white-space: pre-wrap;">{{ courtOrder.summary }}</p>
          </v-card-text>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-bell</v-icon>
            Recordatorios Asociados
          </v-card-title>

          <v-divider />

          <v-list v-if="reminders.length > 0" density="compact">
            <v-list-item
              v-for="reminder in reminders"
              :key="reminder.id"
            >
              <v-list-item-title>{{ reminder.title }}</v-list-item-title>
              <v-list-item-subtitle>{{ formatDateTime(reminder.reminderAt) }}</v-list-item-subtitle>
              <template #append>
                <v-chip size="x-small" variant="tonal">
                  {{ t(`legal_cases.reminder_types.${reminder.reminderType}`) }}
                </v-chip>
              </template>
            </v-list-item>
          </v-list>

          <v-card-text v-else class="text-center py-4">
            <p class="text-grey text-caption">No hay recordatorios para este auto</p>
          </v-card-text>
        </v-card>

        <v-card class="rounded-xl mt-4" elevation="0" border>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-information</v-icon>
            Metadatos
          </v-card-title>

          <v-divider />

          <v-card-text>
            <v-list density="compact">
              <v-list-item>
                <v-list-item-title class="text-caption">Creado</v-list-item-title>
                <v-list-item-subtitle>{{ formatDateTime(courtOrder.createdAt) }}</v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

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
