<script setup lang="ts">
import { ref, computed } from 'vue'
import { useForm } from '@inertiajs/vue3'
import type { VForm } from 'vuetify/components'
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
}>()

const { t } = useTranslations()
const { navigateTo, isNavigating } = useNavigation()

const formRef = ref<VForm | null>(null)
const isEditing = computed(() => !!props.store.id)

const form = useForm({
  display_name: props.store.display_name ?? ''
})

const rules = {
  required: (v: string | number | null | undefined) => !!v || t('validation.required'),
}

const submit = async () => {
  const { valid } = await formRef.value!.validate()
  if (!valid) return

  if (isEditing.value) {
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
        <v-form ref="formRef" @submit.prevent="submit" data-testid="gemini-store-form">
          <v-text-field
            v-model="form.display_name"
            data-testid="gemini-store-input-display-name"
            :label="t('gemini_stores.display_name') + ' *'"
            :rules="[rules.required]"
            :error-messages="form.errors.display_name"
            :disabled="form.processing"
            variant="outlined"
            class="mb-4"
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
