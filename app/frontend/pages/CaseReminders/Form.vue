<script setup lang="ts">
import { computed, ref } from 'vue'
import { useForm } from '@inertiajs/vue3'
import type { VForm } from 'vuetify/components'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useUser } from '@/composables/useUser'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'

interface LegalCase {
  id: number
  caseNumber: string
}

interface Reminder {
  id?: number
  title?: string
  reminderType?: string
  customType?: string
  description?: string
  reminderAt?: string
  location?: string
  userIds?: number[]
}

interface ProjectUser {
  id: number
  name: string
}

const props = defineProps<{
  legalCase: LegalCase
  reminder: Reminder
  reminderTypes: string[]
  projectUsers: ProjectUser[]
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { currentUser } = useUser()

const formRef = ref<VForm | null>(null)
const isEditing = computed(() => !!props.reminder.id)

const availableUsers = computed(() =>
  props.projectUsers.filter(user => user.id !== currentUser.value?.id)
)

const getInitialUserIds = () => {
  const existingIds = props.reminder.userIds ?? []
  return existingIds.filter(id => id !== currentUser.value?.id)
}

const form = useForm({
  title: props.reminder.title ?? '',
  reminder_type: props.reminder.reminderType ?? '',
  custom_type: props.reminder.customType ?? '',
  description: props.reminder.description ?? '',
  reminder_at: props.reminder.reminderAt ?? '',
  location: props.reminder.location ?? '',
  user_ids: getInitialUserIds(),
})

const rules = {
  required: (v: string | number | null | undefined) => !!v || t('validation.required'),
  requiredIfOtro: (v: string) => form.reminder_type !== 'otro' || !!v || t('validation.required'),
}

const submit = async () => {
  const { valid } = await formRef.value!.validate()
  if (!valid) return

  if (isEditing.value) {
    form.patch(`/legal_cases/${props.legalCase.id}/case_reminders/${props.reminder.id}`)
  } else {
    form.post(`/legal_cases/${props.legalCase.id}/case_reminders`)
  }
}

const cancel = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=reminders`)
}

const reminderTypeLabels: Record<string, string> = {
  audiencia: 'Audiencia',
  vencimiento_termino: 'Vencimiento de Término',
  presentar_memorial: 'Presentar Memorial',
  revision_expediente: 'Revisión de Expediente',
  pago_arancel: 'Pago de Arancel',
  cita_cliente: 'Cita con Cliente',
  otro: 'Otro',
}
</script>

<template>
  <v-container class="py-6" style="max-width: 700px;">
    <PageHeader
      :title="isEditing ? t('case_reminders.edit') : t('case_reminders.new')"
      :subtitle="`${t('legal_cases.case_number')}: ${legalCase.caseNumber}`"
    />

    <v-alert type="info" variant="tonal" class="mb-4" data-testid="case-reminders-info">
      <span>{{ t('case_reminders.reminder_info') }}</span>
    </v-alert>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form ref="formRef" @submit.prevent="submit" data-testid="case-reminders-form">
          <v-text-field
            v-model="form.title"
            :label="t('case_reminders.reminder_title') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.title"
            variant="outlined"
            class="mb-4"
            data-testid="case-reminders-input-title"
          />

          <v-select
            v-model="form.reminder_type"
            :items="reminderTypes"
            :label="t('case_reminders.reminder_type') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.reminder_type"
            variant="outlined"
            class="mb-4"
            data-testid="case-reminders-input-type"
          >
            <template #item="{ item, props: itemProps }">
              <v-list-item v-bind="itemProps" :title="reminderTypeLabels[item.value] || item.value" />
            </template>
            <template #selection="{ item }">
              {{ reminderTypeLabels[item.value] || item.value }}
            </template>
          </v-select>

          <v-text-field
            v-if="form.reminder_type === 'otro'"
            v-model="form.custom_type"
            :label="t('case_reminders.custom_type') + ' *'"
            :rules="[rules.requiredIfOtro]"
            :error-messages="form.errors.custom_type"
            variant="outlined"
            class="mb-4"
            data-testid="case-reminders-input-custom-type"
          />

          <v-textarea
            v-model="form.description"
            :label="t('case_reminders.description')"
            :error-messages="form.errors.description"
            variant="outlined"
            rows="3"
            class="mb-4"
            data-testid="case-reminders-input-description"
          />

          <v-text-field
            v-model="form.reminder_at"
            :label="t('case_reminders.reminder_at') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.reminder_at"
            type="datetime-local"
            variant="outlined"
            class="mb-4"
            data-testid="case-reminders-input-datetime"
          />

          <v-text-field
            v-model="form.location"
            :label="t('case_reminders.location')"
            :error-messages="form.errors.location"
            variant="outlined"
            class="mb-4"
            data-testid="case-reminders-input-location"
          />

          <v-autocomplete
            v-model="form.user_ids"
            :items="availableUsers"
            item-title="name"
            item-value="id"
            :label="t('case_reminders.assigned_users')"
            :error-messages="form.errors.user_ids"
            variant="outlined"
            multiple
            chips
            closable-chips
            class="mb-6"
            data-testid="case-reminders-input-users"
          />

          <FormActions
            :primary-label="isEditing ? t('common.save') : t('common.create')"
            :primary-loading="form.processing"
            :cancel-disabled="isNavigating"
            data-test-id="case-reminders"
            @cancel="cancel"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
