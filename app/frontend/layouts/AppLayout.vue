<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { router, Link, usePage } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useUser } from '@/composables/useUser'
import ProjectSwitcher from '@/components/ProjectSwitcher.vue'

interface Flash {
  notice?: string
  alert?: string
}

const { t } = useTranslations()
const { currentUser, isAuthenticated, userInitials, logout } = useUser()
const page = usePage()

const drawer = ref(false)
const userMenu = ref(false)
const snackbar = ref(false)
const snackbarMessage = ref('')
const snackbarColor = ref('success')

const permissions = computed(() => page.props.permissions as { can_manage_users: boolean } | null)
const flash = computed(() => page.props.flash as Flash)

// Mostrar snackbar cuando hay mensajes flash
watch(flash, (newFlash) => {
  if (newFlash?.notice) {
    snackbarMessage.value = newFlash.notice
    snackbarColor.value = 'success'
    snackbar.value = true
  } else if (newFlash?.alert) {
    snackbarMessage.value = newFlash.alert
    snackbarColor.value = 'error'
    snackbar.value = true
  }
}, { immediate: true })

const navigationItems = computed(() => {
  const items = [
    { title: t('navigation.dashboard'), icon: 'mdi-view-dashboard', href: '/dashboard' },
    { title: t('navigation.projects'), icon: 'mdi-folder-outline', href: '/projects' },
  ]

  // Solo mostrar Users si tiene permiso
  if (permissions.value?.can_manage_users) {
    items.push({ title: t('navigation.users'), icon: 'mdi-account-group-outline', href: '/users' })
  }

  return items
})

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

      <!-- Project Switcher -->
      <div class="ml-4" v-if="isAuthenticated">
        <ProjectSwitcher />
      </div>

      <v-spacer />

      <!-- User Menu (cuando está autenticado) -->
      <template v-if="isAuthenticated">
        <v-menu v-model="userMenu" :close-on-content-click="false" location="bottom end">
          <template v-slot:activator="{ props }">
            <v-btn
              v-bind="props"
              data-testid="user-menu-button"
              variant="text"
              class="text-none text-white px-1"
              rounded="pill"
              :ripple="false"
              style="min-width: auto;"
            >
              <v-avatar color="white" size="34" class="mr-2">
                <span class="text-primary text-body-2 font-weight-bold">{{ userInitials }}</span>
              </v-avatar>
              <span class="d-none d-sm-inline text-body-2">{{ currentUser?.full_name || currentUser?.email }}</span>
              <v-icon size="small" class="ml-1">mdi-chevron-down</v-icon>
            </v-btn>
          </template>

          <v-card data-testid="user-menu" min-width="280" class="rounded-xl mt-1" elevation="8">
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
                data-testid="btn-logout"
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

    <!-- Snackbar para mensajes flash -->
    <v-snackbar
      v-model="snackbar"
      :color="snackbarColor"
      :timeout="4000"
      location="top"
      class="mt-4"
    >
      <div class="d-flex align-center">
        <v-icon
          :icon="snackbarColor === 'success' ? 'mdi-check-circle' : 'mdi-alert-circle'"
          class="mr-2"
        />
        {{ snackbarMessage }}
      </div>
      <template v-slot:actions>
        <v-btn
          variant="text"
          @click="snackbar = false"
          icon="mdi-close"
          size="small"
        />
      </template>
    </v-snackbar>
  </v-app>
</template>
