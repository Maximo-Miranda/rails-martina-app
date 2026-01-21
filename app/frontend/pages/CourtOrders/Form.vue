<script setup lang="ts">
import { computed, ref } from 'vue'
import { useForm } from '@inertiajs/vue3'
import type { VForm } from 'vuetify/components'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'

interface LegalCase {
  id: number
  caseNumber: string
}

interface CourtOrder {
  id?: number
  orderType?: string
  summary?: string
  orderDate?: string
  deadline?: string
  status?: string
}

const props = defineProps<{
  legalCase: LegalCase
  courtOrder: CourtOrder
  orderTypes: string[]
  statuses: string[]
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()

const formRef = ref<VForm | null>(null)
const isEditing = computed(() => !!props.courtOrder.id)

const form = useForm({
  order_type: props.courtOrder.orderType ?? '',
  summary: props.courtOrder.summary ?? '',
  order_date: props.courtOrder.orderDate ?? '',
  deadline: props.courtOrder.deadline ?? '',
  status: props.courtOrder.status ?? 'pendiente',
})

const rules = {
  required: (v: string | number | null | undefined) => !!v || t('validation.required'),
}

const submit = async () => {
  const { valid } = await formRef.value!.validate()
  if (!valid) return

  if (isEditing.value) {
    form.patch(`/legal_cases/${props.legalCase.id}/court_orders/${props.courtOrder.id}`)
  } else {
    form.post(`/legal_cases/${props.legalCase.id}/court_orders`)
  }
}

const cancel = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=orders`)
}

const orderTypeLabels: Record<string, string> = {
  auto_interlocutorio: 'Auto Interlocutorio',
  auto_de_tramite: 'Auto de Trámite',
  sentencia: 'Sentencia',
  providencia: 'Providencia',
  resolucion: 'Resolución',
  otro: 'Otro',
}

const statusLabels: Record<string, string> = {
  pendiente: 'Pendiente',
  cumplido: 'Cumplido',
  vencido: 'Vencido',
  en_apelacion: 'En Apelación',
}
</script>

<template>
  <v-container class="py-6" style="max-width: 700px;">
    <PageHeader
      :title="isEditing ? t('court_orders.edit') : t('court_orders.new')"
      :subtitle="`${t('legal_cases.case_number')}: ${legalCase.caseNumber}`"
    />

    <v-alert type="info" variant="tonal" class="mb-4" data-testid="court-orders-info">
      <span>{{ t('court_orders.order_info') }}</span>
    </v-alert>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form ref="formRef" @submit.prevent="submit" data-testid="court-orders-form">
          <v-select
            v-model="form.order_type"
            :items="orderTypes"
            :label="t('court_orders.order_type') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.order_type"
            variant="outlined"
            class="mb-4"
            data-testid="court-orders-input-type"
          >
            <template #item="{ item, props: itemProps }">
              <v-list-item v-bind="itemProps" :title="orderTypeLabels[item.value] || item.value" />
            </template>
            <template #selection="{ item }">
              {{ orderTypeLabels[item.value] || item.value }}
            </template>
          </v-select>

          <v-textarea
            v-model="form.summary"
            :label="t('court_orders.summary') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.summary"
            variant="outlined"
            rows="3"
            class="mb-4"
            data-testid="court-orders-input-summary"
          />

          <v-text-field
            v-model="form.order_date"
            :label="t('court_orders.order_date') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.order_date"
            type="date"
            variant="outlined"
            class="mb-4"
            data-testid="court-orders-input-date"
          />

          <v-text-field
            v-model="form.deadline"
            :label="t('court_orders.deadline')"
            :error-messages="form.errors.deadline"
            type="date"
            variant="outlined"
            class="mb-4"
            data-testid="court-orders-input-deadline"
          />

          <v-select
            v-model="form.status"
            :items="statuses"
            :label="t('court_orders.status')"
            :error-messages="form.errors.status"
            variant="outlined"
            class="mb-6"
            data-testid="court-orders-input-status"
          >
            <template #item="{ item, props: itemProps }">
              <v-list-item v-bind="itemProps" :title="statusLabels[item.value] || item.value" />
            </template>
            <template #selection="{ item }">
              {{ statusLabels[item.value] || item.value }}
            </template>
          </v-select>

          <FormActions
            :primary-label="isEditing ? t('common.save') : t('common.create')"
            :primary-loading="form.processing"
            :cancel-disabled="isNavigating"
            data-test-id="court-orders"
            @cancel="cancel"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
