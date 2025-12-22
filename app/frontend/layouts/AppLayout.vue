<script setup lang="ts">
import { ref, computed } from 'vue'
import { router, Link } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useUser } from '@/composables/useUser'

const { t } = useTranslations()
const { currentUser, isAuthenticated, userInitials, logout } = useUser()

const drawer = ref(false)
const userMenu = ref(false)

const navigationItems = computed(() => [
  { title: t('navigation.dashboard'), icon: 'mdi-view-dashboard', href: '/dashboard' },
  //{ title: t('navigation.projects'), icon: 'mdi-folder-outline', href: '#' },
  //{ title: t('navigation.tasks'), icon: 'mdi-checkbox-marked-outline', href: '#' },
  //{ title: t('navigation.reports'), icon: 'mdi-chart-bar', href: '#' },
  //{ title: t('navigation.settings'), icon: 'mdi-cog-outline', href: '#' },
])

const navigateTo = (href: string) => {
  userMenu.value = false
  drawer.value = false
  router.visit(href)
}
</script>

<template>
  <v-app>
    <!-- App Bar - Material Design 3 style -->
    <v-app-bar
      elevation="2"
      color="primary"
      density="comfortable"
    >
      <!-- Hamburger menu (solo visible si está autenticado) -->
      <v-app-bar-nav-icon
        v-if="isAuthenticated"
        @click="drawer = !drawer"
        variant="text"
      />

      <!-- Logo / Brand - ir al dashboard -->
      <Link href="/dashboard" class="text-decoration-none">
        <div class="d-flex align-center ml-2">
          <v-avatar color="white" size="32" class="mr-2">
            <v-icon color="primary" size="20">mdi-cube-outline</v-icon>
          </v-avatar>
          <span class="text-h6 font-weight-bold text-white">Martina</span>
        </div>
      </Link>

      <v-spacer />

      <!-- User Menu (cuando está autenticado) -->
      <template v-if="isAuthenticated">
        <v-menu v-model="userMenu" :close-on-content-click="false" location="bottom end">
          <template v-slot:activator="{ props }">
            <v-btn
              v-bind="props"
              variant="text"
              class="text-none text-white"
              rounded="pill"
            >
              <v-avatar color="white" size="34" class="mr-2">
                <span class="text-primary text-body-2 font-weight-bold">{{ userInitials }}</span>
              </v-avatar>
              <span class="d-none d-sm-inline text-body-2">{{ currentUser?.full_name || currentUser?.email }}</span>
              <v-icon size="small" class="ml-1">mdi-chevron-down</v-icon>
            </v-btn>
          </template>

          <v-card min-width="280" class="rounded-xl mt-1" elevation="8">
            <v-card-text class="pa-4">
              <div class="d-flex align-center mb-3">
                <v-avatar color="primary" size="52" class="mr-3">
                  <span class="text-white text-h5 font-weight-medium">{{ userInitials }}</span>
                </v-avatar>
                <div>
                  <div class="text-body-1 font-weight-bold">{{ currentUser?.full_name }}</div>
                  <div class="text-body-2 text-medium-emphasis">{{ currentUser?.email }}</div>
                </div>
              </div>

              <v-divider class="my-3" />

              <v-list density="compact" nav class="pa-0">
                <v-list-item
                  prepend-icon="mdi-account-outline"
                  :title="t('navigation.user_menu.profile')"
                  value="profile"
                  @click="navigateTo('/users/edit')"
                  rounded="lg"
                />
              </v-list>

              <v-divider class="my-3" />

              <v-btn
                block
                variant="tonal"
                color="error"
                prepend-icon="mdi-logout"
                @click="logout"
                rounded="lg"
              >
                {{ t('navigation.user_menu.logout') }}
              </v-btn>
            </v-card-text>
          </v-card>
        </v-menu>
      </template>

      <!-- Botones de login/registro (cuando NO está autenticado) -->
      <template v-else>
        <Link href="/users/sign_in">
          <v-btn variant="text" class="text-none text-white mr-1">
            {{ t('navigation.auth.login') }}
          </v-btn>
        </Link>
        <Link href="/users/sign_up">
          <v-btn variant="flat" color="white" class="text-none text-primary">
            {{ t('navigation.auth.register') }}
          </v-btn>
        </Link>
      </template>
    </v-app-bar>

    <!-- Navigation Drawer (Temporary - solo para usuarios autenticados) -->
    <v-navigation-drawer
      v-if="isAuthenticated"
      v-model="drawer"
      temporary
      class="elevation-0"
    >
      <!-- Drawer Header -->
      <div class="pa-4 bg-primary">
        <div class="d-flex align-center">
          <v-avatar color="white" size="48" class="mr-3">
            <span class="text-primary text-h6 font-weight-bold">{{ userInitials }}</span>
          </v-avatar>
          <div>
            <div class="text-body-1 font-weight-medium text-white">{{ currentUser?.full_name }}</div>
            <div class="text-body-2 text-white" style="opacity: 0.8;">{{ currentUser?.email }}</div>
          </div>
        </div>
      </div>

      <v-divider />

      <!-- Navigation Items -->
      <v-list nav class="pa-2">
        <v-list-item
          v-for="item in navigationItems"
          :key="item.href"
          :prepend-icon="item.icon"
          :title="item.title"
          :value="item.href"
          @click="navigateTo(item.href)"
          rounded="lg"
          class="mb-1"
          color="primary"
        />
      </v-list>

      <template v-slot:append>
        <div class="pa-4">
          <v-btn
            block
            variant="outlined"
            color="error"
            prepend-icon="mdi-logout"
            @click="logout"
            class="text-none"
          >
            {{ t('navigation.user_menu.logout') }}
          </v-btn>
        </div>
      </template>
    </v-navigation-drawer>

    <!-- Main Content -->
    <v-main class="bg-grey-lighten-4">
      <slot />
    </v-main>
  </v-app>
</template>
