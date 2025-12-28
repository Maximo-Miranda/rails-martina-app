<script setup lang="ts">
import { useForm } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'

interface GeminiStore {
  id?: number
  display_name: string
  gemini_store_name?: string | null
  status?: string
}

const props = defineProps<{
  store: Partial<GeminiStore>
  errors?: Record<string, string[]>
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()

const isEditing = !!props.store.id

const form = useForm({
  display_name: props.store.display_name || ''
})

const submit = () => {
  if (isEditing) {
    form.put(`/gemini_file_search_stores/${props.store.id}`)
  } else {
    form.post('/gemini_file_search_stores')
  }
}
</script>

<template>
  <v-container class="py-6" style="max-width: 600px;">
    <PageHeader
      :title="isEditing ? t('gemini_stores.edit') : t('gemini_stores.new')"
      :subtitle="isEditing ? t('gemini_stores.edit_description') : t('gemini_stores.new_description')"
    />

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form @submit.prevent="submit" data-testid="gemini-store-form">
          <v-text-field
            v-model="form.display_name"
            data-testid="gemini-store-input-display-name"
            :label="t('gemini_stores.display_name')"
            :error-messages="form.errors.display_name || errors?.display_name"
            :disabled="form.processing"
            variant="outlined"
            class="mb-4"
            required
          />

          <v-alert
            v-if="isEditing && props.store.status === 'pending'"
            type="info"
            variant="tonal"
            class="mb-4"
            data-testid="gemini-store-pending-alert"
          >
            {{ t('gemini_stores.pending_message') }}
          </v-alert>

          <v-alert
            v-if="isEditing && props.store.status === 'failed'"
            type="error"
            variant="tonal"
            class="mb-4"
            data-testid="gemini-store-failed-alert"
          >
            {{ t('gemini_stores.failed_message') }}
          </v-alert>

          <v-text-field
            v-if="isEditing && props.store.gemini_store_name"
            :model-value="props.store.gemini_store_name"
            data-testid="gemini-store-input-gemini-name"
            :label="t('gemini_stores.gemini_name')"
            variant="outlined"
            class="mb-4"
            readonly
            disabled
          />

          <FormActions
            data-test-id="gemini-store-form"
            :primary-label="isEditing ? t('common.save') : t('common.create')"
            :primary-loading="form.processing"
            :primary-disabled="form.processing || isNavigating"
            :cancel-label="t('common.cancel')"
            :cancel-disabled="form.processing || isNavigating"
            @cancel="navigateTo('/gemini_file_search_stores')"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
