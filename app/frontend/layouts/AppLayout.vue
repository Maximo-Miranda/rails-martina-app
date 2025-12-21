<script setup lang="ts">
import { ref, computed } from 'vue'
import { usePage, router, Link } from '@inertiajs/vue3'

interface User {
  id: number
  email: string
  full_name: string
}

const page = usePage()
const currentUser = computed(() => page.props.current_user as User | null)
const isAuthenticated = computed(() => !!currentUser.value)

// Navigation drawer state
const drawer = ref(false)

// User menu state
const userMenu = ref(false)

// Navigation items for authenticated users
const navigationItems = [
  { title: 'Dashboard', icon: 'mdi-view-dashboard', href: '/dashboard' },
  { title: 'Proyectos', icon: 'mdi-folder-outline', href: '/projects' },
  { title: 'Tareas', icon: 'mdi-checkbox-marked-outline', href: '/tasks' },
  { title: 'Reportes', icon: 'mdi-chart-bar', href: '/reports' },
  { title: 'Configuración', icon: 'mdi-cog-outline', href: '/settings' },
]

const logout = () => {
  router.delete('/users/sign_out')
}

const navigateTo = (href: string) => {
  userMenu.value = false
  drawer.value = false
  router.visit(href)
}

// Get user initials for avatar
const userInitials = computed(() => {
  if (!currentUser.value?.full_name) return 'U'
  const names = currentUser.value.full_name.split(' ')
  if (names.length >= 2) {
    return `${names[0][0]}${names[1][0]}`.toUpperCase()
  }
  return names[0].substring(0, 2).toUpperCase()
})
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
                  title="Mi perfil"
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
                Cerrar sesión
              </v-btn>
            </v-card-text>
          </v-card>
        </v-menu>
      </template>

      <!-- Botones de login/registro (cuando NO está autenticado) -->
      <template v-else>
        <Link href="/users/sign_in">
          <v-btn variant="text" class="text-none text-white mr-1">
            Iniciar sesión
          </v-btn>
        </Link>
        <Link href="/users/sign_up">
          <v-btn variant="flat" color="white" class="text-none text-primary">
            Registrarse
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
            Cerrar sesión
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
