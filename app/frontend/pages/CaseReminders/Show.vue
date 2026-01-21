<script setup lang="ts">
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { CaseReminderDetail, CaseReminderUser } from '@/types'

interface LegalCaseRef {
  id: number
  caseNumber: string
}

const props = defineProps<{
  legalCase: LegalCaseRef
  reminder: CaseReminderDetail
  users: CaseReminderUser[]
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const deleteDialog = ref(false)
const deleting = ref(false)
const acknowledging = ref(false)

const formatDateTime = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString()
}

const isOverdue = () => {
  return new Date(props.reminder.reminderAt) < new Date() && !props.reminder.acknowledged
}

const isPast = () => {
  return new Date(props.reminder.reminderAt) < new Date()
}

const confirmDelete = () => {
  deleteDialog.value = true
}

const deleteReminder = () => {
  deleting.value = true
  router.delete(
    `/legal_cases/${props.legalCase.id}/case_reminders/${props.reminder.id}`,
    {
      onFinish: () => {
        deleting.value = false
        deleteDialog.value = false
      },
    }
  )
}

const acknowledge = () => {
  acknowledging.value = true
  router.post(
    `/legal_cases/${props.legalCase.id}/case_reminders/${props.reminder.id}/acknowledge`,
    {},
    {
      onFinish: () => {
        acknowledging.value = false
      },
    }
  )
}

const goBack = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=reminders`)
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="reminder.title"
      :subtitle="legalCase.caseNumber"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          data-testid="case-reminder-btn-back"
          @click="goBack"
        >
          {{ t('common.back') }}
        </v-btn>
        <v-btn
          v-if="!reminder.acknowledged"
          color="success"
          size="small"
          prepend-icon="mdi-check"
          :loading="acknowledging"
          data-testid="case-reminder-btn-acknowledge"
          @click="acknowledge"
        >
          {{ t('case_reminders.acknowledge') }}
        </v-btn>
        <v-btn
          color="error"
          variant="outlined"
          size="small"
          prepend-icon="mdi-delete"
          data-testid="case-reminder-btn-delete"
          @click="confirmDelete"
        >
          {{ t('common.delete') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Alert if overdue -->
    <v-alert
      v-if="isOverdue()"
      type="error"
      variant="tonal"
      class="mb-4"
    >
      Este recordatorio está vencido desde {{ formatDateTime(reminder.reminderAt) }}
    </v-alert>

    <v-row>
      <v-col cols="12" md="8">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center justify-space-between">
            <div class="d-flex align-center">
              <v-icon class="mr-2">mdi-bell</v-icon>
              Detalle del Recordatorio
            </div>
            <v-chip
              :color="reminder.acknowledged ? 'success' : (isOverdue() ? 'error' : 'warning')"
              variant="tonal"
            >
              {{
                reminder.acknowledged
                  ? t('case_reminders.acknowledged')
                  : (isOverdue() ? 'Vencido' : 'Pendiente')
              }}
            </v-chip>
          </v-card-title>

          <v-divider />

          <v-card-text>
            <v-list density="compact">
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-tag</v-icon>
                </template>
                <v-list-item-title>{{ t('case_reminders.reminder_type') }}</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip size="small" variant="tonal">
                    {{ reminder.displayType || t(`legal_cases.reminder_types.${reminder.reminderType}`) }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon :color="isOverdue() ? 'error' : ''">mdi-clock</v-icon>
                </template>
                <v-list-item-title>{{ t('case_reminders.reminder_at') }}</v-list-item-title>
                <v-list-item-subtitle :class="{ 'text-error font-weight-bold': isOverdue() }">
                  {{ formatDateTime(reminder.reminderAt) }}
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item v-if="reminder.location">
                <template #prepend>
                  <v-icon>mdi-map-marker</v-icon>
                </template>
                <v-list-item-title>{{ t('case_reminders.location') }}</v-list-item-title>
                <v-list-item-subtitle>{{ reminder.location }}</v-list-item-subtitle>
              </v-list-item>
            </v-list>

            <template v-if="reminder.description">
              <v-divider class="my-4" />
              <h4 class="text-subtitle-2 mb-2">{{ t('common.description') }}</h4>
              <p class="text-body-2" style="white-space: pre-wrap;">{{ reminder.description }}</p>
            </template>
          </v-card-text>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-account-group</v-icon>
            Usuarios Asignados
          </v-card-title>

          <v-divider />

          <v-list v-if="users.length > 0" density="compact">
            <v-list-item
              v-for="ru in users"
              :key="ru.id"
            >
              <template #prepend>
                <v-icon :color="ru.acknowledged ? 'success' : 'grey'">
                  {{ ru.acknowledged ? 'mdi-account-check' : 'mdi-account' }}
                </v-icon>
              </template>
              <v-list-item-title>{{ ru.userName }}</v-list-item-title>
              <v-list-item-subtitle v-if="ru.acknowledgedAt">
                Confirmado: {{ formatDateTime(ru.acknowledgedAt) }}
              </v-list-item-subtitle>
              <template #append>
                <v-chip
                  size="x-small"
                  :color="ru.acknowledged ? 'success' : 'grey'"
                  variant="tonal"
                >
                  {{ ru.acknowledged ? 'Confirmado' : 'Pendiente' }}
                </v-chip>
              </template>
            </v-list-item>
          </v-list>

          <v-card-text v-else class="text-center py-4">
            <p class="text-grey text-caption">No hay usuarios asignados</p>
          </v-card-text>
        </v-card>

        <v-card class="rounded-xl mt-4" elevation="0" border>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-email</v-icon>
            Notificaciones
          </v-card-title>

          <v-divider />

          <v-card-text>
            <p class="text-caption text-grey mb-2">
              Se enviarán notificaciones automáticas:
            </p>
            <ul class="text-caption pl-4">
              <li :class="{ 'text-grey': isPast() }">3 días antes</li>
              <li :class="{ 'text-grey': isPast() }">1 día antes</li>
              <li :class="{ 'text-grey': isPast() }">4 horas antes</li>
              <li :class="{ 'text-grey': isPast() }">1 hora antes</li>
            </ul>
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
                <v-list-item-subtitle>{{ formatDateTime(reminder.createdAt) }}</v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Delete Confirmation -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('case_reminders.delete_title')"
      :text="t('case_reminders.delete_message')"
      :confirm-label="t('common.delete')"
      :confirm-color="error"
      :loading="deleting"
      @confirm="deleteReminder"
    />
  </v-container>
</template>
