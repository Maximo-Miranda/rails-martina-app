<script setup lang="ts">
import { ref, computed, reactive } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useDocumentContext } from '@/composables/useDocumentContext'
import { useFileFormat } from '@/composables/useFileFormat'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'
import type { GeminiStore, DocumentMetadata } from '@/types'
import type { Project } from '@/composables/useDocumentContext'

const props = defineProps<{
  project?: Project | null
  document: {
    gemini_file_search_store_id: number
    project_id?: number
    display_name?: string
    custom_metadata?: DocumentMetadata
  }
  store: GeminiStore
  errors?: Record<string, string[]>
  supportedContentTypes: string[]
  maxFileSize: number
  metadataKeys: string[]
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()
const { routes, testIdPrefix } = useDocumentContext()
const { formatBytes, getContentTypeIcon } = useFileFormat()

const fileInput = ref<HTMLInputElement | null>(null)
const selectedFile = ref<File | null>(null)
const fileError = ref<string | null>(null)
const dragOver = ref(false)
const processing = ref(false)

const formData = reactive({
  display_name: props.document.display_name || '',
  file: null as File | null,
  custom_metadata: {
    chat_correlation_id: props.document.custom_metadata?.chat_correlation_id || '',
    context_tags: props.document.custom_metadata?.context_tags || [] as string[],
    source_url: props.document.custom_metadata?.source_url || ''
  }
})

const canUpload = computed(() => {
  return selectedFile.value !== null && formData.display_name.trim() !== ''
})

const validateFile = (file: File): boolean => {
  fileError.value = null

  if (!props.supportedContentTypes.includes(file.type)) {
    fileError.value = t('documents.error_unsupported_type')
    return false
  }

  if (file.size > props.maxFileSize) {
    fileError.value = t('documents.error_file_too_large', { max: formatBytes(props.maxFileSize) })
    return false
  }

  if (file.size > props.store.available_bytes) {
    fileError.value = t('documents.error_store_capacity')
    return false
  }

  return true
}

const handleFileSelect = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    const file = input.files[0]
    if (validateFile(file)) {
      selectedFile.value = file
      formData.file = file
      if (!formData.display_name) {
        formData.display_name = file.name
      }
    }
  }
}

const handleDrop = (event: DragEvent) => {
  event.preventDefault()
  dragOver.value = false

  if (event.dataTransfer?.files && event.dataTransfer.files[0]) {
    const file = event.dataTransfer.files[0]
    if (validateFile(file)) {
      selectedFile.value = file
      formData.file = file
      if (!formData.display_name) {
        formData.display_name = file.name
      }
    }
  }
}

const handleDragOver = (event: DragEvent) => {
  event.preventDefault()
  dragOver.value = true
}

const handleDragLeave = () => {
  dragOver.value = false
}

const removeFile = () => {
  selectedFile.value = null
  formData.file = null
  fileError.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

const tagsInput = ref('')
const addTag = () => {
  const tag = tagsInput.value.trim()
  if (tag && !formData.custom_metadata.context_tags.includes(tag)) {
    formData.custom_metadata.context_tags.push(tag)
    tagsInput.value = ''
  }
}

const removeTag = (index: number) => {
  formData.custom_metadata.context_tags.splice(index, 1)
}

const submit = () => {
  processing.value = true
  const params = new URLSearchParams()
  if (props.project === null) {
    params.set('scope', 'global')
    params.set('store_id', String(props.store.id))
  }

  const queryString = params.toString()
  const url = queryString ? `/documents?${queryString}` : '/documents'

  router.post(url, {
    document: {
      display_name: formData.display_name,
      file: formData.file,
      custom_metadata: formData.custom_metadata
    }
  }, {
    forceFormData: true,
    onFinish: () => {
      processing.value = false
    }
  })
}
</script>

<template>
  <v-container class="py-6" style="max-width: 700px;">
    <PageHeader
      :title="t('documents.upload_new')"
      :subtitle="project ? t('documents.upload_description_project', { name: project.name }) : t('documents.upload_description')"
    />

    <!-- Store Info -->
    <v-alert type="info" variant="tonal" class="mb-4" :data-testid="`${testIdPrefix}-store-info`">
      <div class="d-flex justify-space-between align-center">
        <span>{{ t('documents.uploading_to') }}: <strong>{{ store.display_name }}</strong></span>
        <span class="text-caption">
          {{ t('documents.available_space') }}: {{ formatBytes(store.available_bytes) }}
        </span>
      </div>
    </v-alert>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form @submit.prevent="submit" :data-testid="`${testIdPrefix}-form`">
          <!-- File Upload Zone -->
          <div class="mb-6">
            <div class="text-subtitle-2 mb-2">{{ t('documents.select_file') }} *</div>

            <div
              class="upload-zone pa-8 text-center rounded-lg"
              :class="{ 'drag-over': dragOver, 'has-error': fileError }"
              :data-testid="`${testIdPrefix}-upload-zone`"
              @drop="handleDrop"
              @dragover="handleDragOver"
              @dragleave="handleDragLeave"
              @click="triggerFileInput"
            >
              <input
                ref="fileInput"
                type="file"
                :accept="supportedContentTypes.join(',')"
                style="display: none"
                :data-testid="`${testIdPrefix}-file-input`"
                @change="handleFileSelect"
              />

              <template v-if="!selectedFile">
                <v-icon icon="mdi-cloud-upload" size="48" color="grey-lighten-1" class="mb-2" />
                <p class="text-body-1 mb-1">{{ t('documents.drag_drop') }}</p>
                <p class="text-caption text-grey">{{ t('documents.click_to_select') }}</p>
                <p class="text-caption text-grey mt-2">
                  {{ t('documents.max_file_size') }}: {{ formatBytes(maxFileSize) }}
                </p>
              </template>

              <template v-else>
                <div class="d-flex align-center justify-center">
                  <v-icon :icon="getContentTypeIcon(selectedFile.type)" size="32" class="mr-3" />
                  <div class="text-left">
                    <div class="font-weight-medium">{{ selectedFile.name }}</div>
                    <div class="text-caption text-grey">{{ formatBytes(selectedFile.size) }}</div>
                  </div>
                  <v-btn
                    icon="mdi-close"
                    size="small"
                    variant="text"
                    class="ml-4"
                    :data-testid="`${testIdPrefix}-remove-file`"
                    @click.stop="removeFile"
                  />
                </div>
              </template>
            </div>

            <v-alert
              v-if="fileError"
              type="error"
              variant="tonal"
              class="mt-2"
              :data-testid="`${testIdPrefix}-file-error`"
              density="compact"
            >
              {{ fileError }}
            </v-alert>
          </div>

          <!-- Display Name -->
          <v-text-field
            v-model="formData.display_name"
            :data-testid="`${testIdPrefix}-input-display-name`"
            :label="t('documents.display_name')"
            :error-messages="errors?.display_name"
            :disabled="processing"
            variant="outlined"
            class="mb-4"
            required
          />

          <!-- Custom Metadata Section -->
          <v-expansion-panels class="mb-4">
            <v-expansion-panel>
              <v-expansion-panel-title :data-testid="`${testIdPrefix}-metadata-toggle`">
                <v-icon icon="mdi-tag-multiple" class="mr-2" />
                {{ t('documents.custom_metadata') }}
              </v-expansion-panel-title>
              <v-expansion-panel-text>
                <!-- Chat Correlation ID -->
                <v-text-field
                  v-model="formData.custom_metadata.chat_correlation_id"
                  :data-testid="`${testIdPrefix}-input-correlation-id`"
                  :label="t('documents.metadata_correlation_id')"
                  :hint="t('documents.metadata_correlation_id_hint')"
                  persistent-hint
                  variant="outlined"
                  class="mb-4"
                />

                <!-- Source URL -->
                <v-text-field
                  v-model="formData.custom_metadata.source_url"
                  :data-testid="`${testIdPrefix}-input-source-url`"
                  :label="t('documents.metadata_source_url')"
                  :hint="t('documents.metadata_source_url_hint')"
                  persistent-hint
                  variant="outlined"
                  class="mb-4"
                />

                <!-- Context Tags -->
                <div class="mb-2">
                  <div class="d-flex align-center">
                    <v-text-field
                      v-model="tagsInput"
                      :data-testid="`${testIdPrefix}-input-tags`"
                      :label="t('documents.metadata_tags')"
                      variant="outlined"
                      density="comfortable"
                      hide-details
                      @keyup.enter="addTag"
                    />
                    <v-btn
                      icon="mdi-plus"
                      size="small"
                      variant="text"
                      class="ml-2"
                      :data-testid="`${testIdPrefix}-btn-add-tag`"
                      @click="addTag"
                    />
                  </div>
                  <div v-if="formData.custom_metadata.context_tags.length" class="mt-2">
                    <v-chip
                      v-for="(tag, index) in formData.custom_metadata.context_tags"
                      :key="index"
                      size="small"
                      closable
                      class="ma-1"
                      :data-testid="`${testIdPrefix}-tag-${index}`"
                      @click:close="removeTag(index)"
                    >
                      {{ tag }}
                    </v-chip>
                  </div>
                </div>
              </v-expansion-panel-text>
            </v-expansion-panel>
          </v-expansion-panels>

          <FormActions
            :data-test-id="testIdPrefix"
            :primary-label="t('documents.upload')"
            :primary-loading="processing"
            :primary-disabled="!canUpload || processing || isNavigating"
            :cancel-label="t('common.cancel')"
            :cancel-disabled="processing || isNavigating"
            @cancel="navigateTo(routes.index(store.id))"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<style scoped>
.upload-zone {
  border: 2px dashed #e0e0e0;
  cursor: pointer;
  transition: all 0.2s ease;
}

.upload-zone:hover {
  border-color: #1976d2;
  background-color: rgba(25, 118, 210, 0.04);
}

.upload-zone.drag-over {
  border-color: #1976d2;
  background-color: rgba(25, 118, 210, 0.08);
}

.upload-zone.has-error {
  border-color: #d32f2f;
}
</style>
