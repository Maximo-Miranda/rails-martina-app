<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useDocumentPreview, type PreviewMode } from '@/composables/useDocumentPreview'
import { useActionLoading } from '@/composables/useActionLoading'
import PageHeader from '@/components/PageHeader.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import type { CaseDocumentDetail, CaseDocumentType } from '@/types'

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
  document: CaseDocumentDetail
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()
const { getPreviewMode, isPreviewable, needsContentFetch, parseCSV } = useDocumentPreview()
const { isActionLoading, isAnyLoadingGlobal, startLoading, stopLoading } = useActionLoading()

const deleteDialog = ref(false)
const previewDialog = ref(false)
const previewUrl = ref<string | null>(null)
const previewLoading = ref(false)
const previewMode = ref<PreviewMode>('none')
const previewContent = ref<string | null>(null)
const parsedCSV = ref<string[][]>([])

// Edit state
const showEditDialog = ref(false)
const saving = ref(false)
const editErrors = ref<Record<string, string[]>>({})

const documentTypes: CaseDocumentType[] = [
  'demanda', 'contestacion', 'auto', 'sentencia', 'recurso',
  'memorial', 'prueba', 'notificacion', 'poder', 'dictamen', 'acta', 'otro'
]

const editForm = ref({
  document_type: props.document.documentType || 'otro',
  name: props.document.name || '',
  description: props.document.description || '',
  folio_start: props.document.folioStart,
  folio_end: props.document.folioEnd,
  page_count: props.document.pageCount,
  document_date: props.document.documentDate,
  issuer: props.document.issuer || '',
})

const canPreview = computed(() => isPreviewable(props.document.contentType))

const formatDate = (dateString: string | null) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString()
}

const documentPath = computed(() =>
  `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents/${props.document.id}`
)

const confirmDelete = () => {
  deleteDialog.value = true
}

const deleteDocument = () => {
  startLoading('delete', props.document.id)
  router.delete(documentPath.value, {
    onFinish: () => {
      stopLoading('delete', props.document.id)
      deleteDialog.value = false
    },
  })
}

const toggleAi = () => {
  startLoading('toggleAi', props.document.id)
  const action = props.document.aiEnabled ? 'disable_ai' : 'enable_ai'

  router.post(`${documentPath.value}/${action}`, {}, {
    onFinish: () => {
      stopLoading('toggleAi', props.document.id)
    },
  })
}

const openPreview = async () => {
  if (!props.document.hasFile) return

  const mode = getPreviewMode(props.document.contentType)
  if (mode === 'none') {
    triggerDownload()
    return
  }

  previewLoading.value = true
  previewDialog.value = true
  previewMode.value = mode

  try {
    if (mode === 'iframe') {
      const response = await fetch(`${documentPath.value}/file_url`)
      const data = await response.json()
      if (data.url) {
        previewUrl.value = data.url
      }
    } else if (needsContentFetch(props.document.contentType)) {
      const response = await fetch(`${documentPath.value}/file_content`)
      const data = await response.json()
      if (data.content) {
        previewContent.value = data.content
        if (mode === 'csv') {
          parsedCSV.value = parseCSV(data.content)
        }
      }
    }
  } catch (err) {
    console.error('Error loading file:', err)
  } finally {
    previewLoading.value = false
  }
}

const triggerDownload = async () => {
  if (!props.document.hasFile) return

  try {
    const response = await fetch(`${documentPath.value}/file_url`)
    const data = await response.json()
    if (data.url) {
      window.open(data.url, '_blank')
    }
  } catch (err) {
    console.error('Error getting download URL:', err)
  }
}

const downloadFile = () => {
  if (previewUrl.value) {
    window.open(previewUrl.value, '_blank')
  }
}

const goBack = () => {
  navigateTo(`/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}`)
}

// Edit functions
const openEditDialog = () => {
  editForm.value = {
    document_type: props.document.documentType || 'otro',
    name: props.document.name || '',
    description: props.document.description || '',
    folio_start: props.document.folioStart,
    folio_end: props.document.folioEnd,
    page_count: props.document.pageCount,
    document_date: props.document.documentDate,
    issuer: props.document.issuer || '',
  }
  editErrors.value = {}
  showEditDialog.value = true
}

const submitEditForm = () => {
  saving.value = true

  router.put(documentPath.value, { case_document: editForm.value }, {
    onSuccess: () => {
      showEditDialog.value = false
      saving.value = false
    },
    onError: (e) => {
      editErrors.value = e as Record<string, string[]>
      saving.value = false
    },
  })
}

// Check for edit query param on mount
onMounted(() => {
  const url = new URL(window.location.href)
  if (url.searchParams.get('edit') === 'true') {
    openEditDialog()
    // Clean up the URL
    url.searchParams.delete('edit')
    window.history.replaceState({}, '', url.toString())
  }
})
</script>

<template>
  <v-container class="py-6" style="max-width: 1200px;">
    <PageHeader
      :title="document.name"
      :subtitle="`${notebook.code} - ${legalCase.caseNumber}`"
    >
      <template #actions>
        <v-btn
          variant="outlined"
          size="small"
          prepend-icon="mdi-arrow-left"
          :disabled="isAnyLoadingGlobal"
          data-testid="case-document-btn-back"
          @click="goBack"
        >
          {{ t('common.back') }}
        </v-btn>
        <v-btn
          color="primary"
          size="small"
          prepend-icon="mdi-pencil"
          :disabled="isAnyLoadingGlobal"
          data-testid="case-document-btn-edit"
          @click="openEditDialog"
        >
          {{ t('common.edit') }}
        </v-btn>
        <v-btn
          v-if="document.hasFile && canPreview"
          color="secondary"
          variant="outlined"
          size="small"
          prepend-icon="mdi-eye"
          :disabled="isAnyLoadingGlobal"
          data-testid="case-document-btn-preview"
          @click="openPreview"
        >
          {{ t('common.preview') }}
        </v-btn>
        <v-btn
          v-else-if="document.hasFile && !canPreview"
          color="secondary"
          variant="outlined"
          size="small"
          prepend-icon="mdi-download"
          :disabled="isAnyLoadingGlobal"
          data-testid="case-document-btn-download"
          @click="triggerDownload"
        >
          {{ t('common.download') }}
        </v-btn>
        <v-btn
          color="error"
          variant="outlined"
          size="small"
          prepend-icon="mdi-delete"
          :disabled="isAnyLoadingGlobal"
          data-testid="case-document-btn-delete"
          @click="confirmDelete"
        >
          {{ t('common.delete') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-row>
      <v-col cols="12" md="8">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-file-document</v-icon>
            {{ t('case_documents.title') }}
          </v-card-title>

          <v-divider />

          <v-card-text>
            <v-list density="compact">
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-tag</v-icon>
                </template>
                <v-list-item-title>{{ t('case_documents.document_type') }}</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip size="small" variant="tonal">
                    {{ document.documentType ? t(`case_documents.document_types.${document.documentType}`) : t('case_documents.document_types.sin_tipo') }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-format-list-numbered</v-icon>
                </template>
                <v-list-item-title>{{ t('case_documents.foliation') }}</v-list-item-title>
                <v-list-item-subtitle>
                  {{ document.foliation || '-' }}
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-file-multiple</v-icon>
                </template>
                <v-list-item-title>{{ t('case_documents.page_count') }}</v-list-item-title>
                <v-list-item-subtitle>
                  {{ document.pageCount || '-' }}
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-calendar</v-icon>
                </template>
                <v-list-item-title>{{ t('case_documents.document_date') }}</v-list-item-title>
                <v-list-item-subtitle>
                  {{ formatDate(document.documentDate) }}
                </v-list-item-subtitle>
              </v-list-item>

              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-account</v-icon>
                </template>
                <v-list-item-title>{{ t('case_documents.issuer') }}</v-list-item-title>
                <v-list-item-subtitle>
                  {{ document.issuer || '-' }}
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>

            <template v-if="document.description">
              <v-divider class="my-4" />
              <h4 class="text-subtitle-2 mb-2">{{ t('case_documents.description') }}</h4>
              <p class="text-body-2" style="white-space: pre-wrap;">{{ document.description }}</p>
            </template>
          </v-card-text>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center">
            <v-icon class="mr-2">mdi-brain</v-icon>
            {{ t('case_documents.ai') }}
          </v-card-title>

          <v-divider />

          <v-card-text class="text-center py-6">
            <v-icon
              :color="document.aiEnabled ? 'success' : 'grey'"
              size="64"
              class="mb-4"
            >
              mdi-brain
            </v-icon>
            <p class="text-body-1">
              {{ document.aiEnabled ? t('case_documents.ai_enabled') : t('case_documents.ai_disabled') }}
            </p>
            <p class="text-caption text-grey mt-2">
              {{ document.aiEnabled
                ? 'Este documento está indexado para consultas con IA'
                : 'Habilita la IA para poder consultar este documento'
              }}
            </p>
            <v-btn
              :color="document.aiEnabled ? 'warning' : 'success'"
              size="small"
              class="mt-4"
              :prepend-icon="document.aiEnabled ? 'mdi-brain-off' : 'mdi-brain'"
              :loading="isActionLoading('toggleAi', document.id)"
              :disabled="isAnyLoadingGlobal"
              data-testid="case-document-btn-toggle-ai"
              @click="toggleAi"
            >
              {{ document.aiEnabled ? t('case_documents.disable_ai') : t('case_documents.enable_ai') }}
            </v-btn>
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
                <v-list-item-title class="text-caption">Ítem #</v-list-item-title>
                <v-list-item-subtitle>{{ document.itemNumber }}</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title class="text-caption">Creado</v-list-item-title>
                <v-list-item-subtitle>{{ formatDate(document.createdAt) }}</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <v-list-item-title class="text-caption">Archivo</v-list-item-title>
                <v-list-item-subtitle>
                  <v-chip :color="document.hasFile ? 'success' : 'grey'" size="small" variant="tonal">
                    {{ document.hasFile ? 'Adjunto' : 'Sin archivo' }}
                  </v-chip>
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Preview Dialog -->
    <v-dialog v-model="previewDialog" max-width="900" scrollable>
      <v-card>
        <v-card-title class="d-flex align-center justify-space-between">
          <span>{{ document.name }}</span>
          <div>
            <v-btn
              icon
              variant="text"
              size="small"
              @click="downloadFile"
            >
              <v-icon>mdi-download</v-icon>
            </v-btn>
            <v-btn
              icon
              variant="text"
              size="small"
              @click="previewDialog = false"
            >
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </div>
        </v-card-title>

        <v-divider />

        <v-card-text class="pa-0" style="height: 70vh; overflow: auto;">
          <div v-if="previewLoading" class="d-flex align-center justify-center" style="height: 100%;">
            <v-progress-circular indeterminate color="primary" />
          </div>

          <iframe
            v-else-if="previewMode === 'iframe' && previewUrl"
            :src="previewUrl"
            style="width: 100%; height: 100%; border: none;"
          />

          <pre
            v-else-if="(previewMode === 'text' || previewMode === 'markdown') && previewContent"
            class="pa-4 text-body-2"
            style="white-space: pre-wrap; word-break: break-word; margin: 0;"
          >{{ previewContent }}</pre>

          <div
            v-else-if="previewMode === 'csv' && parsedCSV.length > 0"
            class="pa-4"
          >
            <v-table density="compact">
              <thead v-if="parsedCSV.length > 0">
                <tr>
                  <th v-for="(cell, index) in parsedCSV[0]" :key="index" class="text-left">
                    {{ cell }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, rowIndex) in parsedCSV.slice(1)" :key="rowIndex">
                  <td v-for="(cell, cellIndex) in row" :key="cellIndex">
                    {{ cell }}
                  </td>
                </tr>
              </tbody>
            </v-table>
          </div>
        </v-card-text>
      </v-card>
    </v-dialog>

    <!-- Delete Confirmation -->
    <ConfirmDialog
      v-model="deleteDialog"
      :title="t('case_documents.delete_title')"
      :text="t('case_documents.delete_message')"
      :confirm-label="t('common.delete')"
      confirm-color="error"
      :loading="isActionLoading('delete', document.id)"
      @confirm="deleteDocument"
    />

    <!-- Edit Dialog -->
    <v-dialog v-model="showEditDialog" max-width="700" persistent>
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-file-document-edit</v-icon>
          {{ t('case_documents.edit') }}
        </v-card-title>

        <v-card-text>
          <v-form @submit.prevent="submitEditForm">
            <v-row>
              <v-col cols="12" md="6">
                <v-select
                  v-model="editForm.document_type"
                  :items="documentTypes"
                  :label="t('case_documents.document_type') + ' *'"
                  :error-messages="editErrors.document_type"
                  data-testid="case-document-edit-input-type"
                  required
                >
                  <template #item="{ props: itemProps, item }">
                    <v-list-item
                      v-bind="itemProps"
                      :title="t(`case_documents.document_types.${item.raw}`)"
                    />
                  </template>
                  <template #selection="{ item }">
                    {{ t(`case_documents.document_types.${item.raw}`) }}
                  </template>
                </v-select>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="editForm.name"
                  :label="t('case_documents.name') + ' *'"
                  :error-messages="editErrors.name"
                  data-testid="case-document-edit-input-name"
                  required
                />
              </v-col>
            </v-row>

            <v-textarea
              v-model="editForm.description"
              :label="t('case_documents.description') + ' *'"
              :error-messages="editErrors.description"
              data-testid="case-document-edit-input-description"
              rows="2"
              class="mt-2"
              required
            />

            <v-row class="mt-2">
              <v-col cols="4">
                <v-text-field
                  v-model.number="editForm.folio_start"
                  :label="t('case_documents.folio_start') + ' *'"
                  :error-messages="editErrors.folio_start"
                  data-testid="case-document-edit-input-folio-start"
                  type="number"
                  min="1"
                  required
                />
              </v-col>
              <v-col cols="4">
                <v-text-field
                  v-model.number="editForm.folio_end"
                  :label="t('case_documents.folio_end') + ' *'"
                  :error-messages="editErrors.folio_end"
                  data-testid="case-document-edit-input-folio-end"
                  type="number"
                  min="1"
                  required
                />
              </v-col>
              <v-col cols="4">
                <v-text-field
                  v-model.number="editForm.page_count"
                  :label="t('case_documents.page_count') + ' *'"
                  :error-messages="editErrors.page_count"
                  data-testid="case-document-edit-input-page-count"
                  type="number"
                  min="1"
                  required
                />
              </v-col>
            </v-row>

            <v-row class="mt-2">
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="editForm.document_date"
                  :label="t('case_documents.document_date') + ' *'"
                  :error-messages="editErrors.document_date"
                  data-testid="case-document-edit-input-date"
                  type="date"
                  required
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="editForm.issuer"
                  :label="t('case_documents.issuer') + ' *'"
                  :error-messages="editErrors.issuer"
                  data-testid="case-document-edit-input-issuer"
                  :hint="t('case_documents.issuer_hint')"
                  required
                />
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn
            variant="text"
            :disabled="saving"
            data-testid="case-document-edit-btn-cancel"
            @click="showEditDialog = false"
          >
            {{ t('common.cancel') }}
          </v-btn>
          <v-btn
            color="primary"
            :loading="saving"
            data-testid="case-document-edit-btn-submit"
            @click="submitEditForm"
          >
            {{ t('common.save') }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>
