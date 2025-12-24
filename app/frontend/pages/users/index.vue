<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import type { User } from '@/types'

const props = defineProps<{
  users: User[]
  can_invite: boolean
}>()

const { t } = useTranslations()
const { navigateTo } = useNavigation()

const deleteUser = (id: number) => {
  if (confirm(t('users.confirm_delete'))) {
    router.delete(`/users/${id}`)
  }
}
</script>

<template>
  <v-container class="py-6">
    <div class="d-flex align-center justify-space-between mb-6">
      <div>
        <h1 class="text-h4 font-weight-bold mb-1">{{ t('users.title') }}</h1>
        <p class="text-body-1 text-medium-emphasis">{{ t('users.subtitle') }}</p>
      </div>
      <v-btn v-if="can_invite" color="primary" prepend-icon="mdi-account-plus" @click="navigateTo('/users/new_invitation')">
        {{ t('users.invite') }}
      </v-btn>
    </div>

    <v-card class="rounded-xl" elevation="0" border>
      <v-table>
        <thead>
          <tr>
            <th>{{ t('users.name') }}</th>
            <th>{{ t('users.email') }}</th>
            <th>{{ t('users.joined') }}</th>
            <th class="text-right">{{ t('common.actions') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user.id">
            <td>
              <div class="d-flex align-center py-2">
                <v-avatar color="primary" size="32" class="mr-3">
                  <span class="text-caption">{{ user.full_name?.charAt(0)?.toUpperCase() }}</span>
                </v-avatar>
                {{ user.full_name }}
              </div>
            </td>
            <td>{{ user.email }}</td>
            <td class="text-medium-emphasis">{{ new Date(user.created_at!).toLocaleDateString() }}</td>
            <td class="text-right">
              <v-btn icon="mdi-eye" variant="text" size="small" @click="navigateTo(`/users/${user.id}`)" />
              <v-btn icon="mdi-delete" variant="text" size="small" color="error" @click="deleteUser(user.id)" />
            </td>
          </tr>
        </tbody>
      </v-table>

      <v-card-text v-if="!users.length" class="text-center pa-8">
        <v-icon size="48" color="grey-lighten-1" class="mb-4">mdi-account-group-outline</v-icon>
        <p class="text-body-1 text-medium-emphasis">{{ t('users.empty') }}</p>
      </v-card-text>
    </v-card>
  </v-container>
</template>
