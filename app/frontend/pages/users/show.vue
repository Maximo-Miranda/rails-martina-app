<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
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
    <!-- Back button -->
    <v-btn
      variant="text"
      prepend-icon="mdi-arrow-left"
      class="mb-4 px-0"
      data-testid="users-btn-back"
      @click="navigateTo('/users')"
    >
      {{ t('common.back') }}
    </v-btn>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <!-- User header with avatar -->
        <div class="d-flex align-center mb-6">
          <v-avatar color="primary" size="56" class="mr-4">
            <span class="text-h6">{{ user.full_name?.charAt(0)?.toUpperCase() }}</span>
          </v-avatar>
          <div>
            <div class="text-h6">{{ user.full_name }}</div>
            <div class="text-body-2 text-medium-emphasis">{{ user.email }}</div>
          </div>
        </div>

        <v-divider class="my-4" />

        <!-- Joined date -->
        <div class="mb-6">
          <div class="text-overline text-medium-emphasis mb-2">{{ t('users.joined') }}</div>
          <div class="text-body-1">
            {{ user.created_at ? new Date(user.created_at).toLocaleDateString() : '-' }}
          </div>
        </div>

        <!-- Roles -->
        <div>
          <div class="text-overline text-medium-emphasis mb-2">{{ t('users.roles_in_project') }}</div>
          <div data-testid="users-roles-chips">
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
        </div>
      </v-card-text>
    </v-card>
  </v-container>
</template>
