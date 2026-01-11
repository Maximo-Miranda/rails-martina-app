<script setup lang="ts">
import { ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import FormActions from '@/components/FormActions.vue'
import type { ChatStore } from '@/types'

const props = defineProps<{
  chat: { title: string | null }
  store: ChatStore | null
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const title = ref(props.chat.title || '')
const saving = ref(false)

function handleSubmit() {
  if (saving.value) return

  saving.value = true
  router.post(
    '/chats',
    { chat: { title: title.value.trim() || null } },
    {
      onFinish: () => {
        saving.value = false
      }
    }
  )
}

function handleCancel() {
  navigateTo('/chats')
}
</script>

<template>
  <v-container class="py-6">
    <PageHeader
      :title="t('chats.new_chat')"
      :subtitle="t('chats.subtitle')"
    >
      <template #actions>
        <v-btn
          variant="text"
          size="small"
          data-testid="chats-btn-back"
          @click="handleCancel"
        >
          {{ t('common.back') }}
        </v-btn>
      </template>
    </PageHeader>

    <!-- Store Info -->
    <v-card v-if="store" class="rounded-xl mb-4" elevation="0" border>
      <v-card-text class="pa-4">
        <div class="d-flex align-center justify-space-between">
          <div>
            <div class="text-subtitle-2 text-grey">{{ t('documents.current_store') }}</div>
            <div class="text-h6">{{ store.display_name }}</div>
          </div>
          <v-chip
            :color="store.status === 'synced' ? 'success' : 'warning'"
            size="small"
            variant="tonal"
          >
            {{ store.status }}
          </v-chip>
        </div>
      </v-card-text>
    </v-card>

    <!-- Form -->
    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-form @submit.prevent="handleSubmit">
          <v-text-field
            v-model="title"
            :label="t('chats.default_title')"
            :placeholder="t('chats.default_title')"
            variant="outlined"
            density="comfortable"
            clearable
            data-testid="chats-input-title"
          >
            <template #prepend-inner>
              <v-icon color="grey">mdi-chat</v-icon>
            </template>
          </v-text-field>

          <p class="text-body-2 text-grey mt-n2 mb-4">
            {{ t('chats.title_hint') }}
          </p>

          <FormActions
            :primary-loading="saving"
            :primary-label="t('chats.start_chat')"
            data-testid="chats-form-actions"
            @cancel="handleCancel"
          />
        </v-form>
      </v-card-text>
    </v-card>
  </v-container>
</template>
