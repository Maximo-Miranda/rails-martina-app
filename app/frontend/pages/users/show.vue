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
    <div class="mb-6">
      <v-btn icon="mdi-arrow-left" variant="text" @click="navigateTo('/users')" class="mr-2" />
      <span class="text-h4 font-weight-bold">{{ user.full_name }}</span>
    </div>

    <v-card class="rounded-xl" elevation="0" border>
      <v-card-text class="pa-6">
        <v-list>
          <v-list-item>
            <template #prepend>
              <v-avatar color="primary" size="64">
                <span class="text-h5">{{ user.full_name?.charAt(0)?.toUpperCase() }}</span>
              </v-avatar>
            </template>
            <v-list-item-title class="text-h6">{{ user.full_name }}</v-list-item-title>
            <v-list-item-subtitle>{{ user.email }}</v-list-item-subtitle>
          </v-list-item>
        </v-list>

        <v-divider class="my-4" />

        <div class="mb-4">
          <div class="text-overline text-medium-emphasis mb-2">{{ t('users.roles_in_project') }}</div>
          <v-chip-group>
            <v-chip v-for="role in user.roles" :key="role" color="primary" variant="tonal">
              {{ t(`roles.${role}`) }}
            </v-chip>
            <v-chip v-if="!user.roles?.length" color="grey" variant="tonal">
              {{ t('users.no_roles') }}
            </v-chip>
          </v-chip-group>
        </div>

        <div>
          <div class="text-overline text-medium-emphasis mb-2">{{ t('users.joined') }}</div>
          <p>{{ user.created_at ? new Date(user.created_at).toLocaleDateString() : '-' }}</p>
        </div>
      </v-card-text>
    </v-card>
  </v-container>
</template>
