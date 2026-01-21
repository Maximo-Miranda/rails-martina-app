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

interface Notebook {
  id?: number
  notebookType?: string
  code?: string
  description?: string
  volume?: number
}

const props = defineProps<{
  legalCase: LegalCase
  notebook: Notebook
  notebookTypes: string[]
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()

const formRef = ref<VForm | null>(null)
const isEditing = computed(() => !!props.notebook.id)

const form = useForm({
  notebook_type: props.notebook.notebookType ?? '',
  code: props.notebook.code ?? '',
  description: props.notebook.description ?? '',
  volume: props.notebook.volume ?? 1,
})

const rules = {
  required: (v: string | number | null | undefined) => !!v || t('validation.required'),
  minVolume: (v: number) => v >= 1 || t('validation.min_value', { min: 1 }),
}

const submit = async () => {
  const { valid } = await formRef.value!.validate()
  if (!valid) return

  if (isEditing.value) {
    form.patch(`/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}`)
  } else {
    form.post(`/legal_cases/${props.legalCase.id}/case_notebooks`)
  }
}

const cancel = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}?tab=notebooks`)
}

const notebookTypeLabels: Record<string, string> = {
  principal: 'Principal',
  medidas_cautelares: 'Medidas Cautelares',
  incidentes: 'Incidentes',
  ejecucion: 'Ejecución',
  apelacion: 'Apelación',
  casacion: 'Casación',
  otro: 'Otro',
}
</script>

<template>
  <v-container class="py-6" style="max-width: 700px;">
    <PageHeader
      :title="isEditing ? t('case_notebooks.edit') : t('case_notebooks.new')"
      :subtitle="`${t('legal_cases.case_number')}: ${legalCase.caseNumber}`"
    />

    <v-alert type="info" variant="tonal" class="mb-4" data-testid="case-notebooks-info">
      <span>{{ t('legal_cases.case_number') }}: <strong>{{ legalCase.caseNumber }}</strong></span>
    </v-alert>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form ref="formRef" @submit.prevent="submit" data-testid="case-notebooks-form">
          <v-select
            v-model="form.notebook_type"
            :items="notebookTypes"
            :label="t('case_notebooks.notebook_type') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.notebook_type"
            variant="outlined"
            class="mb-4"
            data-testid="case-notebooks-input-type"
          >
            <template #item="{ item, props: itemProps }">
              <v-list-item v-bind="itemProps" :title="notebookTypeLabels[item.value] || item.value" />
            </template>
            <template #selection="{ item }">
              {{ notebookTypeLabels[item.value] || item.value }}
            </template>
          </v-select>

          <v-text-field
            v-model="form.code"
            :label="t('case_notebooks.code') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.code"
            variant="outlined"
            class="mb-4"
            data-testid="case-notebooks-input-code"
          />

          <v-textarea
            v-model="form.description"
            :label="t('case_notebooks.description')"
            :error-messages="form.errors.description"
            variant="outlined"
            rows="3"
            class="mb-4"
            data-testid="case-notebooks-input-description"
          />

          <v-text-field
            v-model.number="form.volume"
            :label="t('case_notebooks.volume') + ' *'"
            :rules="[rules.required, rules.minVolume]"
            :error-messages="form.errors.volume"
            type="number"
            min="1"
            variant="outlined"
            class="mb-6"
            data-testid="case-notebooks-input-volume"
          />

          <FormActions
            :primary-label="isEditing ? t('common.save') : t('common.create')"
            :primary-loading="form.processing"
            :cancel-disabled="isNavigating"
            data-test-id="case-notebooks"
            @cancel="cancel"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
