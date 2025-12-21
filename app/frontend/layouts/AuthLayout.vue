<script setup lang="ts">
import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

interface Flash {
  notice?: string
  alert?: string
}

const page = usePage()
const flash = computed(() => page.props.flash as Flash)
</script>

<template>
  <v-app>
    <!-- Header Material Design 3 para auth -->
    <v-app-bar
      elevation="2"
      color="primary"
      density="comfortable"
    >
      <v-container class="d-flex justify-center align-center py-0">
        <a href="/" class="text-decoration-none">
          <div class="d-flex align-center">
            <v-avatar color="white" size="32" class="mr-2">
              <v-icon color="primary" size="20">mdi-cube-outline</v-icon>
            </v-avatar>
            <span class="text-h6 font-weight-bold text-white">Martina</span>
          </div>
        </a>
      </v-container>
    </v-app-bar>

    <!-- Main Content -->
    <v-main class="bg-grey-lighten-4">
      <v-container class="fill-height py-6" fluid>
        <v-row align="center" justify="center" class="fill-height">
          <v-col cols="12" sm="10" md="6" lg="4" xl="3" class="px-4">
            <!-- Flash Messages - fuera del card para mejor visibilidad -->
            <v-slide-y-transition>
              <v-alert
                v-if="flash?.notice"
                type="success"
                variant="tonal"
                class="mb-4"
                density="compact"
                closable
                icon="mdi-check-circle-outline"
              >
                {{ flash.notice }}
              </v-alert>
            </v-slide-y-transition>

            <v-slide-y-transition>
              <v-alert
                v-if="flash?.alert"
                type="error"
                variant="tonal"
                class="mb-4"
                density="compact"
                closable
                icon="mdi-alert-circle-outline"
              >
                {{ flash.alert }}
              </v-alert>
            </v-slide-y-transition>

            <slot />
          </v-col>
        </v-row>
      </v-container>
    </v-main>

    <!-- Footer minimalista -->
    <v-footer color="transparent" class="text-center text-caption text-medium-emphasis pa-4">
      <v-row justify="center" no-gutters>
        <v-col cols="12">
          © {{ new Date().getFullYear() }} Martina. Todos los derechos reservados.
        </v-col>
      </v-row>
    </v-footer>
  </v-app>
</template>
