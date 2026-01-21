<script setup lang="ts">
import { ref, computed } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { CaseReminder } from '@/types'

interface LegalCaseRef {
  id: number
  caseNumber: string
}

interface ProjectUser {
  id: number
  name: string
}

const props = defineProps<{
  legalCase: LegalCaseRef
  reminders: CaseReminder[]
  reminderTypes: string[]
  projectUsers: ProjectUser[]
  currentUserId: number
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const showFormDialog = ref(false)
const editingReminder = ref<CaseReminder | null>(null)
const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)
const saving = ref(false)

const form = ref({
  title: '',
  reminder_type: 'vencimiento_termino',
  custom_type: '',
  description: '',
  reminder_at: '',
  location: '',
  user_ids: [props.currentUserId] as number[],
})

const errors = ref<Record<string, string[]>>({})

const sortedReminders = computed(() =>
  [...props.reminders].sort((a, b) =>
    new Date(a.reminderAt).getTime() - new Date(b.reminderAt).getTime()
  )
)

const upcomingReminders = computed(() =>
  sortedReminders.value.filter(r => new Date(r.reminderAt) > new Date() && !r.acknowledged)
)

const pastReminders = computed(() =>
  sortedReminders.value.filter(r => new Date(r.reminderAt) <= new Date() || r.acknowledged)
)

const formatDateTime = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString()
}

const isOverdue = (reminder: CaseReminder) => {
  return new Date(reminder.reminderAt) < new Date() && !reminder.acknowledged
}

const openNewForm = () => {
  editingReminder.value = null
  form.value = {
    title: '',
    reminder_type: 'vencimiento_termino',
    custom_type: '',
    description: '',
    reminder_at: '',
    location: '',
    user_ids: [props.currentUserId],
  }
  errors.value = {}
  showFormDialog.value = true
}

const openEditForm = (reminder: CaseReminder) => {
  editingReminder.value = reminder
  form.value = {
    title: reminder.title,
    reminder_type: reminder.reminderType,
    custom_type: '',
    description: '',
    reminder_at: reminder.reminderAt ? new Date(reminder.reminderAt).toISOString().slice(0, 16) : '',
    location: reminder.location || '',
    user_ids: [props.currentUserId],
  }
  errors.value = {}
  showFormDialog.value = true
}

const submitForm = () => {
  saving.value = true

  if (editingReminder.value) {
    router.put(
      `/legal_cases/${props.legalCase.id}/case_reminders/${editingReminder.value.id}`,
      { case_reminder: form.value },
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
      `/legal_cases/${props.legalCase.id}/case_reminders`,
      { case_reminder: form.value },
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

const deleteReminder = () => {
  if (!deleteTargetId.value) return
  deleting.value = true

  router.delete(
    `/legal_cases/${props.legalCase.id}/case_reminders/${deleteTargetId.value}`,
    {
      onFinish: () => {
        deleting.value = false
        deleteDialog.value = false
        deleteTargetId.value = null
      },
    }
  )
}

const acknowledgeReminder = (reminder: CaseReminder) => {
  router.post(`/legal_cases/${props.legalCase.id}/case_reminders/${reminder.id}/acknowledge`)
}

const goToReminder = (reminder: CaseReminder) => {
  navigateTo(`/legal_cases/${props.legalCase.id}/case_reminders/${reminder.id}`)
}

const goBack = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=reminders`)
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="t('case_reminders.title')"
      :subtitle="legalCase.caseNumber"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          data-testid="case-reminders-btn-back"
          @click="goBack"
        >
          {{ t('common.back') }}
        </v-btn>
        <v-btn
          color="primary"
          size="small"
          prepend-icon="mdi-plus"
          data-testid="case-reminders-btn-new"
          @click="openNewForm"
        >
          {{ t('case_reminders.new') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Upcoming Reminders -->
    <v-card class="rounded-xl mb-4" elevation="0" border>
      <v-card-title class="d-flex align-center">
        <v-icon class="mr-2" color="warning">mdi-bell-ring</v-icon>
        Recordatorios Próximos
        <v-chip v-if="upcomingReminders.length > 0" size="small" color="warning" class="ml-2">
          {{ upcomingReminders.length }}
        </v-chip>
      </v-card-title>

      <v-divider />

      <v-list v-if="upcomingReminders.length > 0" lines="two">
        <v-list-item
          v-for="reminder in upcomingReminders"
          :key="reminder.id"
          :data-testid="`case-reminder-item-${reminder.id}`"
          @click="goToReminder(reminder)"
        >
          <template #prepend>
            <v-icon :color="isOverdue(reminder) ? 'error' : 'warning'">
              {{ isOverdue(reminder) ? 'mdi-bell-alert' : 'mdi-bell' }}
            </v-icon>
          </template>

          <v-list-item-title class="font-weight-medium">
            {{ reminder.title }}
          </v-list-item-title>
          <v-list-item-subtitle>
            <v-icon size="x-small" class="mr-1">mdi-clock</v-icon>
            {{ formatDateTime(reminder.reminderAt) }}
            <span v-if="reminder.location" class="ml-2">
              <v-icon size="x-small" class="mr-1">mdi-map-marker</v-icon>
              {{ reminder.location }}
            </span>
          </v-list-item-subtitle>

          <template #append>
            <v-chip size="small" variant="tonal" class="mr-2">
              {{ t(`legal_cases.reminder_types.${reminder.reminderType}`) }}
            </v-chip>
            <v-btn
              icon
              variant="text"
              size="small"
              color="success"
              :data-testid="`case-reminder-btn-ack-${reminder.id}`"
              @click.stop="acknowledgeReminder(reminder)"
            >
              <v-icon>mdi-check</v-icon>
              <v-tooltip activator="parent" location="top">{{ t('case_reminders.acknowledge') }}</v-tooltip>
            </v-btn>
            <v-btn
              icon
              variant="text"
              size="small"
              :data-testid="`case-reminder-btn-edit-${reminder.id}`"
              @click.stop="openEditForm(reminder)"
            >
              <v-icon>mdi-pencil</v-icon>
            </v-btn>
            <v-btn
              icon
              variant="text"
              size="small"
              color="error"
              :data-testid="`case-reminder-btn-delete-${reminder.id}`"
              @click.stop="confirmDelete(reminder.id)"
            >
              <v-icon>mdi-delete</v-icon>
            </v-btn>
          </template>
        </v-list-item>
      </v-list>

      <v-card-text v-else class="text-center py-4">
        <p class="text-grey">No hay recordatorios próximos</p>
      </v-card-text>
    </v-card>

    <!-- Past/Acknowledged Reminders -->
    <v-card v-if="pastReminders.length > 0" class="rounded-xl" elevation="0" border>
      <v-card-title class="d-flex align-center">
        <v-icon class="mr-2" color="grey">mdi-bell-check</v-icon>
        Historial
      </v-card-title>

      <v-divider />

      <v-list lines="two">
        <v-list-item
          v-for="reminder in pastReminders"
          :key="reminder.id"
          :data-testid="`case-reminder-past-${reminder.id}`"
          @click="goToReminder(reminder)"
        >
          <template #prepend>
            <v-icon color="grey">mdi-bell-check</v-icon>
          </template>

          <v-list-item-title :class="{ 'text-decoration-line-through text-grey': reminder.acknowledged }">
            {{ reminder.title }}
          </v-list-item-title>
          <v-list-item-subtitle>
            {{ formatDateTime(reminder.reminderAt) }}
          </v-list-item-subtitle>

          <template #append>
            <v-chip size="small" :color="reminder.acknowledged ? 'success' : 'grey'" variant="tonal">
              {{ reminder.acknowledged ? t('case_reminders.acknowledged') : t('case_reminders.not_acknowledged') }}
            </v-chip>
          </template>
        </v-list-item>
      </v-list>
    </v-card>

    <!-- Empty State -->
    <v-card v-if="reminders.length === 0" class="rounded-xl" elevation="0" border>
      <v-card-text class="text-center py-8">
        <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-bell-outline</v-icon>
        <p class="text-grey">{{ t('legal_cases.no_reminders') }}</p>
        <v-btn
          color="primary"
          variant="tonal"
          class="mt-4"
          prepend-icon="mdi-plus"
          data-testid="case-reminders-btn-new-empty"
          @click="openNewForm"
        >
          {{ t('case_reminders.new') }}
        </v-btn>
      </v-card-text>
    </v-card>

    <!-- Form Dialog -->
    <v-dialog v-model="showFormDialog" max-width="600" persistent>
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-bell</v-icon>
          {{ editingReminder ? t('case_reminders.edit') : t('case_reminders.new') }}
        </v-card-title>

        <v-card-text>
          <v-form @submit.prevent="submitForm">
            <v-text-field
              v-model="form.title"
              :label="t('common.title')"
              :error-messages="errors.title"
              data-testid="case-reminder-input-title"
              required
            />

            <v-select
              v-model="form.reminder_type"
              :items="reminderTypes"
              :label="t('case_reminders.reminder_type')"
              :error-messages="errors.reminder_type"
              data-testid="case-reminder-input-type"
              required
              class="mt-4"
            >
              <template #item="{ props: itemProps, item }">
                <v-list-item v-bind="itemProps" :title="t(`legal_cases.reminder_types.${item.raw}`)">
                </v-list-item>
              </template>
              <template #selection="{ item }">
                {{ t(`legal_cases.reminder_types.${item.raw}`) }}
              </template>
            </v-select>

            <v-text-field
              v-if="form.reminder_type === 'otro'"
              v-model="form.custom_type"
              :label="t('case_reminders.custom_type')"
              :error-messages="errors.custom_type"
              data-testid="case-reminder-input-custom-type"
              class="mt-4"
            />

            <v-textarea
              v-model="form.description"
              :label="t('common.description')"
              :error-messages="errors.description"
              data-testid="case-reminder-input-description"
              rows="2"
              class="mt-4"
            />

            <v-text-field
              v-model="form.reminder_at"
              :label="t('case_reminders.reminder_at')"
              :error-messages="errors.reminder_at"
              data-testid="case-reminder-input-datetime"
              type="datetime-local"
              required
              class="mt-4"
            />

            <v-text-field
              v-model="form.location"
              :label="t('case_reminders.location')"
              :error-messages="errors.location"
              data-testid="case-reminder-input-location"
              prepend-inner-icon="mdi-map-marker"
              class="mt-4"
            />

            <!-- Debug: {{ projectUsers }} -->
            <v-select
              v-if="!editingReminder && projectUsers?.length > 0"
              v-model="form.user_ids"
              :items="projectUsers"
              item-value="id"
              item-title="name"
              :label="t('case_reminders.add_users')"
              :error-messages="errors.user_ids"
              data-testid="case-reminder-input-users"
              prepend-inner-icon="mdi-account-multiple"
              multiple
              chips
              closable-chips
              class="mt-4"
            />
          </v-form>
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn
            variant="text"
            :disabled="saving"
            data-testid="case-reminder-btn-cancel"
            @click="showFormDialog = false"
          >
            {{ t('common.cancel') }}
          </v-btn>
          <v-btn
            color="primary"
            :loading="saving"
            data-testid="case-reminder-btn-submit"
            @click="submitForm"
          >
            {{ editingReminder ? t('common.save') : t('common.create') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete Confirmation -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('case_reminders.delete_title')"
      :text="t('case_reminders.delete_message')"
      :confirm-label="t('common.delete')"
      confirm-color="error"
      :loading="deleting"
      @confirm="deleteReminder"
    />
  </v-container>
</template>
