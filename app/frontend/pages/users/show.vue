<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import PageHeader from '@/components/PageHeader.vue'
import type { User } from '@/types'

const props = defineProps<{
  user: User & { roles?: string[] }
  errors?: Record<string, string[]>
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()
</script>

<template>
  <v-container class="py-6" style="max-width: 600px;">
    <PageHeader :title="user.full_name" :subtitle="user.email">
      <template #actions>
        <v-btn variant="text" prepend-icon="mdi-arrow-left" @click="navigateTo('/users')">
          {{ t('common.back') }}
        </v-btn>
      </template>
    </PageHeader>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <div class="d-flex align-center mb-6">
          <v-avatar color="primary" size="56" class="mr-4">
            <span class="text-h6">{{ user.full_name?.charAt(0)?.toUpperCase() }}</span>
          </v-avatar>
          <div>
            <div class="text-h6">{{ user.full_name }}</div>
            <div class="text-body-2 text-medium-emphasis">{{ user.email }}</div>
          </div>
        </div>

        <v-divider class="my-6" />

        <v-row>
          <v-col cols="12" sm="6">
            <div class="text-overline text-medium-emphasis mb-2">{{ t('users.joined') }}</div>
            <div class="text-body-1">
              {{ user.created_at ? new Date(user.created_at).toLocaleDateString() : '-' }}
            </div>
          </v-col>
          <v-col cols="12" sm="6">
            <div class="text-overline text-medium-emphasis mb-2">{{ t('users.roles_in_project') }}</div>
            <div>
              <v-chip
                v-for="role in user.roles"
                :key="role"
                color="primary"
                variant="tonal"
                class="mr-2 mb-2"
              >
                {{ t(`roles.${role}`) }}
              </v-chip>
              <v-chip v-if="!user.roles?.length" color="grey" variant="tonal">
                {{ t('users.no_roles') }}
              </v-chip>
            </div>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-container>
</template>
