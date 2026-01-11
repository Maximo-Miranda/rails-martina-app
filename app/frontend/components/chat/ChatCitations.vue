<script setup lang="ts">
import { ref, computed } from 'vue'
import { useTranslations } from '@/composables/useTranslations'
import type { MessageCitation } from '@/types'

const props = defineProps<{
  citations: MessageCitation[]
}>()

const { t } = useTranslations()

const expanded = ref(false)

const citationsCount = computed(() => props.citations.length)

function formatPages(pages: number[] | null): string {
  if (!pages || pages.length === 0) return ''
  return pages.join(', ')
}

function formatConfidence(score: number | null): string {
  if (score === null) return ''
  return `${Math.round(score * 100)}%`
}

function viewDocument(documentId: number) {
  // Open document in new tab
  window.open(`/documents/${documentId}`, '_blank')
}
</script>

<template>
  <v-card
    variant="outlined"
    class="citations-card rounded-lg"
    density="compact"
  >
    <v-card-title
      class="d-flex align-center cursor-pointer py-2 px-3"
      @click="expanded = !expanded"
    >
      <v-icon start size="small" color="primary">mdi-file-document-multiple</v-icon>
      <span class="text-body-2 font-weight-medium">
        {{ t('chats.chat_detail.citations') }}
      </span>
      <v-chip size="x-small" class="ml-2" color="primary" variant="tonal">
        {{ citationsCount }}
      </v-chip>
      <v-spacer />
      <v-icon size="small">
        {{ expanded ? 'mdi-chevron-up' : 'mdi-chevron-down' }}
      </v-icon>
    </v-card-title>

    <v-expand-transition>
      <div v-show="expanded">
        <v-divider />
        <v-list density="compact" class="py-0">
          <v-list-item
            v-for="citation in citations"
            :key="citation.id"
            class="px-3"
            data-testid="chat-citation-item"
          >
            <template #prepend>
              <v-icon size="small" color="grey">mdi-file-document</v-icon>
            </template>

            <v-list-item-title class="text-body-2">
              {{ citation.document_name || `Documento ${citation.document_id}` }}
            </v-list-item-title>

            <v-list-item-subtitle class="text-caption">
              <span v-if="citation.pages?.length">
                {{ t('chats.chat_detail.pages') }}: {{ formatPages(citation.pages) }}
              </span>
              <span v-if="citation.confidence_score" class="ml-2">
                {{ t('chats.chat_detail.confidence') }}: {{ formatConfidence(citation.confidence_score) }}
              </span>
            </v-list-item-subtitle>

            <!-- Text snippet preview -->
            <div
              v-if="citation.text_snippet"
              class="text-caption text-grey mt-1 citation-snippet"
            >
              "{{ citation.text_snippet }}"
            </div>

            <template #append>
              <v-btn
                icon
                variant="text"
                size="x-small"
                :title="t('chats.chat_detail.view_document')"
                data-testid="chat-btn-view-document"
                @click.stop="viewDocument(citation.document_id)"
              >
                <v-icon size="small">mdi-open-in-new</v-icon>
              </v-btn>
            </template>
          </v-list-item>
        </v-list>
      </div>
    </v-expand-transition>
  </v-card>
</template>

<style scoped>
.citations-card {
  background-color: rgba(var(--v-theme-surface-variant), 0.5);
}

.citation-snippet {
  font-style: italic;
  max-height: 60px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.cursor-pointer {
  cursor: pointer;
}
</style>
