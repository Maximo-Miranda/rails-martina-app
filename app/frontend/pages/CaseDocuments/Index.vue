<script setup lang="ts">
import { ref, computed } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { CaseDocumentItem } from '@/types'

interface LegalCaseRef {
  id: number
  caseNumber: string
}

interface NotebookRef {
  id: number
  code: string
}

const props = defineProps<{
  legalCase: LegalCaseRef
  notebook: NotebookRef
  documents: CaseDocumentItem[]
  documentTypes: string[]
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const showDocumentForm = ref(false)
const deleteDialog = ref(false)
const deleteTargetId = ref<number | null>(null)
const deleting = ref(false)
const saving = ref(false)
const fileInput = ref<File | null>(null)

const form = ref({
  document_type: 'otro',
  name: '',
  description: '',
  folio_start: null as number | null,
  folio_end: null as number | null,
  page_count: null as number | null,
  document_date: null as string | null,
  issuer: '',
})

const errors = ref<Record<string, string[]>>({})

const sortedDocuments = computed(() =>
  [...props.documents].sort((a, b) => (a.itemNumber || 0) - (b.itemNumber || 0))
)

const openNewDocumentForm = () => {
  fileInput.value = null
  form.value = {
    document_type: 'otro',
    name: '',
    description: '',
    folio_start: null,
    folio_end: null,
    page_count: null,
    document_date: null,
    issuer: '',
  }
  errors.value = {}
  showDocumentForm.value = true
}

const formatDate = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString()
}

const submitDocumentForm = () => {
  saving.value = true

  const formData = new FormData()
  Object.entries(form.value).forEach(([key, value]) => {
    if (value !== null && value !== '') {
      formData.append(`case_document[${key}]`, String(value))
    }
  })

  if (fileInput.value) {
    formData.append('case_document[file]', fileInput.value)
  }

  const url = `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents`

  router.post(url, formData, {
    forceFormData: true,
    onSuccess: () => {
      showDocumentForm.value = false
      saving.value = false
    },
    onError: (e) => {
      errors.value = e as Record<string, string[]>
      saving.value = false
    },
  })
}

const confirmDeleteDocument = (id: number) => {
  deleteTargetId.value = id
  deleteDialog.value = true
}

const deleteDocument = () => {
  if (!deleteTargetId.value) return
  deleting.value = true

  router.delete(
    `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents/${deleteTargetId.value}`,
    {
      onFinish: () => {
        deleting.value = false
        deleteDialog.value = false
        deleteTargetId.value = null
      },
    }
  )
}

const goToDocument = (doc: CaseDocumentItem) => {
  navigateTo(`/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents/${doc.id}`)
}

const goBack = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}`)
}

const handleFileChange = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    fileInput.value = target.files[0]
    if (!form.value.name) {
      form.value.name = target.files[0].name.replace(/\.[^/.]+$/, '')
    }
  }
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="t('case_documents.title')"
      :subtitle="`${notebook.code} - ${legalCase.caseNumber}`"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          data-testid="case-documents-btn-back"
          @click="goBack"
        >
          {{ t('common.back') }}
        </v-btn>
        <v-btn
          color="primary"
          size="small"
          prepend-icon="mdi-plus"
          data-testid="case-documents-btn-new"
          @click="openNewDocumentForm"
        >
          {{ t('case_documents.new') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-table v-if="documents.length > 0" hover>
        <thead>
          <tr>
            <th class="text-left">#</th>
            <th class="text-left">{{ t('case_documents.name') }}</th>
            <th class="text-left">{{ t('case_documents.document_type') }}</th>
            <th class="text-left">{{ t('case_documents.foliation') }}</th>
            <th class="text-left">{{ t('case_documents.document_date') }}</th>
            <th class="text-center">{{ t('case_documents.ai') }}</th>
            <th class="text-right">{{ t('common.actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="doc in sortedDocuments"
            :key="doc.id"
            :data-testid="`case-document-row-${doc.id}`"
            class="cursor-pointer"
            @click="goToDocument(doc)"
          >
            <td>{{ doc.itemNumber }}</td>
            <td>{{ doc.name }}</td>
            <td>
              <v-chip size="small" variant="tonal">
                {{ t(`case_documents.document_types.${doc.documentType}`) }}
              </v-chip>
            </td>
            <td>{{ doc.foliation || '-' }}</td>
            <td>{{ formatDate(doc.documentDate) }}</td>
            <td class="text-center">
              <v-icon v-if="doc.aiEnabled" color="success" size="small">mdi-brain</v-icon>
              <v-icon v-else color="grey" size="small">mdi-brain</v-icon>
            </td>
            <td class="text-right">
              <v-btn
                icon
                variant="text"
                size="small"
                color="error"
                :data-testid="`case-document-btn-delete-${doc.id}`"
                @click.stop="confirmDeleteDocument(doc.id)"
              >
                <v-icon>mdi-delete</v-icon>
              </v-btn>
            </td>
          </tr>
        </tbody>
      </v-table>

      <v-card-text v-else class="text-center py-8">
        <v-icon size="64" color="grey-lighten-1" class="mb-4">mdi-file-document-outline</v-icon>
        <p class="text-grey">{{ t('case_documents.no_documents') }}</p>
        <v-btn
          color="primary"
          variant="tonal"
          class="mt-4"
          prepend-icon="mdi-plus"
          data-testid="case-documents-btn-new-empty"
          @click="openNewDocumentForm"
        >
          {{ t('case_documents.new') }}
        </v-btn>
      </v-card-text>
    </v-card>

    <!-- Document Form Dialog -->
    <v-dialog v-model="showDocumentForm" max-width="700" persistent>
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-file-document</v-icon>
          {{ t('case_documents.new') }}
        </v-card-title>

        <v-card-text>
          <v-form @submit.prevent="submitDocumentForm">
            <v-file-input
              :label="t('case_documents.file')"
              :error-messages="errors.file"
              data-testid="case-document-input-file"
              prepend-icon="mdi-paperclip"
              accept=".pdf,.doc,.docx,.xls,.xlsx,.pptx,.odt,.txt,.md,.csv"
              @change="handleFileChange"
            />

            <v-row class="mt-2">
              <v-col cols="12" md="6">
                <v-select
                  v-model="form.document_type"
                  :items="documentTypes"
                  :label="t('case_documents.document_type')"
                  :error-messages="errors.document_type"
                  data-testid="case-document-input-type"
                  required
                >
                  <template #item="{ props: itemProps, item }">
                    <v-list-item v-bind="itemProps" :title="t(`case_documents.document_types.${item.raw}`)">
                    </v-list-item>
                  </template>
                  <template #selection="{ item }">
                    {{ t(`case_documents.document_types.${item.raw}`) }}
                  </template>
                </v-select>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="form.name"
                  :label="t('case_documents.name')"
                  :error-messages="errors.name"
                  data-testid="case-document-input-name"
                  required
                />
              </v-col>
            </v-row>

            <v-textarea
              v-model="form.description"
              :label="t('case_documents.description')"
              :error-messages="errors.description"
              data-testid="case-document-input-description"
              rows="2"
              class="mt-2"
            />

            <v-row class="mt-2">
              <v-col cols="6" md="3">
                <v-text-field
                  v-model.number="form.folio_start"
                  :label="t('case_documents.folio_start')"
                  :error-messages="errors.folio_start"
                  data-testid="case-document-input-folio-start"
                  type="number"
                  min="1"
                />
              </v-col>
              <v-col cols="6" md="3">
                <v-text-field
                  v-model.number="form.folio_end"
                  :label="t('case_documents.folio_end')"
                  :error-messages="errors.folio_end"
                  data-testid="case-document-input-folio-end"
                  type="number"
                  min="1"
                />
              </v-col>
              <v-col cols="6" md="3">
                <v-text-field
                  v-model.number="form.page_count"
                  :label="t('case_documents.page_count')"
                  :error-messages="errors.page_count"
                  data-testid="case-document-input-page-count"
                  type="number"
                  min="1"
                />
              </v-col>
              <v-col cols="6" md="3">
                <v-text-field
                  v-model="form.document_date"
                  :label="t('case_documents.document_date')"
                  :error-messages="errors.document_date"
                  data-testid="case-document-input-date"
                  type="date"
                />
              </v-col>
            </v-row>

            <v-text-field
              v-model="form.issuer"
              :label="t('case_documents.issuer')"
              :error-messages="errors.issuer"
              data-testid="case-document-input-issuer"
              :hint="t('case_documents.issuer_hint')"
              class="mt-2"
            />
          </v-form>
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn
            variant="text"
            :disabled="saving"
            data-testid="case-document-btn-cancel"
            @click="showDocumentForm = false"
          >
            {{ t('common.cancel') }}
          </v-btn>
          <v-btn
            color="primary"
            :loading="saving"
            data-testid="case-document-btn-submit"
            @click="submitDocumentForm"
          >
            {{ t('common.create') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Delete Confirmation -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('case_documents.delete_title')"
      :text="t('case_documents.delete_message')"
      :confirm-label="t('common.delete')"
      :confirm-color="'error'"
      :loading="deleting"
      @confirm="deleteDocument"
    />
  </v-container>
</template>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}
</style>
