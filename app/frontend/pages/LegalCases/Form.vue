<script setup lang="ts">
import { ref, computed } from 'vue'
import { useForm } from '@inertiajs/vue3'
import type { VForm } from 'vuetify/components'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import type { LegalCaseDetail, LegalCaseStatus, LegalCaseSpecialty } from '@/types'

const props = defineProps<{
  legalCase?: LegalCaseDetail
  statuses: LegalCaseStatus[]
  specialties: LegalCaseSpecialty[]
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const formRef = ref<VForm | null>(null)
const isEditing = computed(() => !!props.legalCase?.id)

const form = useForm({
  case_number: props.legalCase?.caseNumber ?? '',
  court: props.legalCase?.court ?? '',
  specialty: props.legalCase?.specialty ?? 'civil',
  status: props.legalCase?.status ?? 'activo',
  action_type: props.legalCase?.actionType ?? '',
  filing_date: props.legalCase?.filingDate ?? '',
  plaintiff: props.legalCase?.plaintiff ?? '',
  defendant: props.legalCase?.defendant ?? '',
  plaintiff_lawyer: props.legalCase?.plaintiffLawyer ?? '',
  defendant_lawyer: props.legalCase?.defendantLawyer ?? '',
  lawyer_in_charge: props.legalCase?.lawyerInCharge ?? '',
  lawyer_phone: props.legalCase?.lawyerPhone ?? '',
  lawyer_email: props.legalCase?.lawyerEmail ?? '',
  lawyer_professional_card: props.legalCase?.lawyerProfessionalCard ?? '',
  current_term_date: props.legalCase?.currentTermDate ?? '',
  last_action_date: props.legalCase?.lastActionDate ?? '',
  notes: props.legalCase?.notes ?? '',
})

const submitting = ref(false)

const statusOptions = computed(() =>
  props.statuses.map(s => ({
    title: t(`legal_cases.statuses.${s}`),
    value: s,
  }))
)

const specialtyOptions = computed(() =>
  props.specialties.map(s => ({
    title: t(`legal_cases.specialties.${s}`),
    value: s,
  }))
)

const rules = {
  required: (v: string | number | null | undefined) => !!v || t('validation.required'),
  email: (v: string) => !v || /.+@.+\..+/.test(v) || t('validation.email'),
}

const submit = async () => {
  const { valid } = await formRef.value!.validate()
  if (!valid) return

  submitting.value = true

  if (isEditing.value) {
    form.put(`/legal_cases/${props.legalCase!.id}`, {
      onFinish: () => { submitting.value = false },
    })
  } else {
    form.post('/legal_cases', {
      onFinish: () => { submitting.value = false },
    })
  }
}

const cancel = () => {
  if (isEditing.value) {
    navigateTo(`/legal_cases/${props.legalCase!.id}`)
  } else {
    navigateTo('/legal_cases')
  }
}
</script>

<template>
  <v-container class="py-6" style="max-width: 900px;">
    <PageHeader
      :title="isEditing ? t('legal_cases.edit') : t('legal_cases.new')"
      :subtitle="isEditing ? legalCase?.caseNumber : t('legal_cases.new_subtitle')"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          data-testid="legal-case-form-btn-back"
          @click="cancel"
        >
          {{ t('common.back') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-form ref="formRef" @submit.prevent="submit">
      <v-card class="rounded-xl mb-4" elevation="0" border>
        <v-card-title class="text-h6 pa-4">
          {{ t('legal_cases.case_info') }}
        </v-card-title>
        <v-divider />
        <v-card-text>
          <v-row>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.case_number"
                :label="t('legal_cases.case_number') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.case_number"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-case-number"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.court"
                :label="t('legal_cases.court') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.court"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-court"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-select
                v-model="form.specialty"
                :items="specialtyOptions"
                :label="t('legal_cases.specialty') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.specialty"
                variant="outlined"
                density="compact"
                data-testid="legal-case-select-specialty"
              />
            </v-col>
          </v-row>

          <v-row>
            <v-col cols="12" md="4">
              <v-select
                v-model="form.status"
                :items="statusOptions"
                :label="t('legal_cases.status') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.status"
                variant="outlined"
                density="compact"
                data-testid="legal-case-select-status"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.action_type"
                :label="t('legal_cases.action_type') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.action_type"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-action-type"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.filing_date"
                :label="t('legal_cases.filing_date') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.filing_date"
                type="date"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-filing-date"
              />
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>

      <v-card class="rounded-xl mb-4" elevation="0" border>
        <v-card-title class="text-h6 pa-4">
          {{ t('legal_cases.parties') }}
        </v-card-title>
        <v-divider />
        <v-card-text>
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.plaintiff"
                :label="t('legal_cases.plaintiff') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.plaintiff"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-plaintiff"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.plaintiff_lawyer"
                :label="t('legal_cases.plaintiff_lawyer')"
                :error-messages="form.errors.plaintiff_lawyer"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-plaintiff-lawyer"
              />
            </v-col>
          </v-row>

          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.defendant"
                :label="t('legal_cases.defendant') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.defendant"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-defendant"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.defendant_lawyer"
                :label="t('legal_cases.defendant_lawyer')"
                :error-messages="form.errors.defendant_lawyer"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-defendant-lawyer"
              />
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>

      <v-card class="rounded-xl mb-4" elevation="0" border>
        <v-card-title class="text-h6 pa-4">
          {{ t('legal_cases.lawyer_info') }}
        </v-card-title>
        <v-divider />
        <v-card-text>
          <v-row>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.lawyer_in_charge"
                :label="t('legal_cases.lawyer_in_charge') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.lawyer_in_charge"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-lawyer-in-charge"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.lawyer_professional_card"
                :label="t('legal_cases.lawyer_professional_card') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.lawyer_professional_card"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-lawyer-professional-card"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.lawyer_phone"
                :label="t('legal_cases.lawyer_phone') + ' *'"
                :rules="[rules.required]"
                :error-messages="form.errors.lawyer_phone"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-lawyer-phone"
              />
            </v-col>
          </v-row>
          <v-row>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.lawyer_email"
                :label="t('legal_cases.lawyer_email') + ' *'"
                :rules="[rules.required, rules.email]"
                :error-messages="form.errors.lawyer_email"
                type="email"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-lawyer-email"
              />
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>

      <v-card class="rounded-xl mb-4" elevation="0" border>
        <v-card-title class="text-h6 pa-4">
          {{ t('legal_cases.dates_and_terms') }}
        </v-card-title>
        <v-divider />
        <v-card-text>
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.current_term_date"
                :label="t('legal_cases.current_term_date')"
                :error-messages="form.errors.current_term_date"
                type="date"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-current-term-date"
              />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="form.last_action_date"
                :label="t('legal_cases.last_action_date')"
                :error-messages="form.errors.last_action_date"
                type="date"
                variant="outlined"
                density="compact"
                data-testid="legal-case-input-last-action-date"
              />
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>

      <v-card class="rounded-xl mb-4" elevation="0" border>
        <v-card-title class="text-h6 pa-4">
          {{ t('legal_cases.notes') }}
        </v-card-title>
        <v-divider />
        <v-card-text>
          <v-textarea
            v-model="form.notes"
            :label="t('legal_cases.notes')"
            :error-messages="form.errors.notes"
            variant="outlined"
            rows="4"
            data-testid="legal-case-input-notes"
          />
        </v-card-text>
      </v-card>

      <div class="d-flex justify-end gap-3 mt-6">
        <v-btn
          variant="text"
          :disabled="submitting"
          data-testid="legal-case-form-btn-cancel-bottom"
          @click="cancel"
        >
          {{ t('common.cancel') }}
        </v-btn>
        <v-btn
          type="submit"
          color="primary"
          :loading="submitting"
          :disabled="form.processing"
          data-testid="legal-case-form-btn-submit"
        >
          {{ isEditing ? t('common.save') : t('common.create') }}
        </v-btn>
      </div>
    </v-form>
  </v-container>
</template>
