<script setup lang="ts">
import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

interface User {
  id: number
  email: string
  full_name: string
}

const page = usePage()
const currentUser = computed(() => page.props.current_user as User | null)

// Stats cards mock data
const stats = [
  { title: 'Proyectos activos', value: '12', icon: 'mdi-folder-outline', color: 'primary' },
  { title: 'Tareas pendientes', value: '28', icon: 'mdi-checkbox-marked-outline', color: 'warning' },
  { title: 'Completadas hoy', value: '5', icon: 'mdi-check-circle-outline', color: 'success' },
  { title: 'En revisión', value: '3', icon: 'mdi-eye-outline', color: 'info' },
]

// Recent activities mock data
const recentActivities = [
  { title: 'Nuevo proyecto creado', description: 'Proyecto Alpha', time: 'Hace 2 horas', icon: 'mdi-folder-plus', color: 'primary' },
  { title: 'Tarea completada', description: 'Diseño de interfaz', time: 'Hace 4 horas', icon: 'mdi-check', color: 'success' },
  { title: 'Comentario agregado', description: 'En tarea de backend', time: 'Hace 5 horas', icon: 'mdi-comment-outline', color: 'info' },
  { title: 'Archivo subido', description: 'documento.pdf', time: 'Ayer', icon: 'mdi-file-upload-outline', color: 'warning' },
]
</script>

<template>
  <v-container class="py-6">
    <!-- Welcome Header -->
    <div class="mb-6">
      <h1 class="text-h4 font-weight-bold mb-1">
        ¡Hola, {{ currentUser?.full_name?.split(' ')[0] || 'Usuario' }}!
      </h1>
      <p class="text-body-1 text-medium-emphasis">
        Aquí tienes un resumen de tu actividad reciente.
      </p>
    </div>

    <!-- Stats Cards -->
    <v-row class="mb-6">
      <v-col v-for="stat in stats" :key="stat.title" cols="12" sm="6" lg="3">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-text class="pa-4">
            <div class="d-flex align-center justify-space-between">
              <div>
                <div class="text-caption text-medium-emphasis text-uppercase tracking-wide mb-1">
                  {{ stat.title }}
                </div>
                <div class="text-h4 font-weight-bold">{{ stat.value }}</div>
              </div>
              <v-avatar :color="stat.color" size="48" variant="tonal">
                <v-icon :icon="stat.icon" size="24" />
              </v-avatar>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <v-row>
      <!-- Recent Activity -->
      <v-col cols="12" md="8">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="d-flex align-center justify-space-between pa-4">
            <span class="text-h6 font-weight-bold">Actividad reciente</span>
            <v-btn variant="text" color="primary" size="small" class="text-none">
              Ver todo
            </v-btn>
          </v-card-title>
          <v-divider />
          <v-list lines="two">
            <v-list-item
              v-for="(activity, index) in recentActivities"
              :key="index"
            >
              <template v-slot:prepend>
                <v-avatar :color="activity.color" size="40" variant="tonal">
                  <v-icon :icon="activity.icon" size="20" />
                </v-avatar>
              </template>
              <v-list-item-title class="font-weight-medium">
                {{ activity.title }}
              </v-list-item-title>
              <v-list-item-subtitle>
                {{ activity.description }}
              </v-list-item-subtitle>
              <template v-slot:append>
                <span class="text-caption text-medium-emphasis">{{ activity.time }}</span>
              </template>
            </v-list-item>
          </v-list>
        </v-card>
      </v-col>

      <!-- Quick Actions -->
      <v-col cols="12" md="4">
        <v-card class="rounded-xl" elevation="0" border>
          <v-card-title class="pa-4">
            <span class="text-h6 font-weight-bold">Acciones rápidas</span>
          </v-card-title>
          <v-divider />
          <v-card-text class="pa-4">
            <v-btn
              block
              color="primary"
              class="text-none mb-3"
              prepend-icon="mdi-plus"
              rounded="lg"
            >
              Nuevo proyecto
            </v-btn>
            <v-btn
              block
              variant="tonal"
              color="primary"
              class="text-none mb-3"
              prepend-icon="mdi-checkbox-marked-outline"
              rounded="lg"
            >
              Crear tarea
            </v-btn>
            <v-btn
              block
              variant="outlined"
              color="primary"
              class="text-none"
              prepend-icon="mdi-account-multiple-plus-outline"
              rounded="lg"
            >
              Invitar equipo
            </v-btn>
          </v-card-text>
        </v-card>

        <!-- Tip Card -->
        <v-card class="rounded-xl mt-4 bg-primary" elevation="0">
          <v-card-text class="pa-4">
            <div class="d-flex align-start">
              <v-icon icon="mdi-lightbulb-outline" color="white" class="mr-3 mt-1" />
              <div>
                <div class="text-body-2 font-weight-bold text-white mb-1">
                  Consejo del día
                </div>
                <div class="text-caption text-white" style="opacity: 0.9;">
                  Organiza tus tareas por prioridad para ser más productivo. ¡Empieza por las más importantes!
                </div>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<style scoped>
.tracking-wide {
  letter-spacing: 0.05em;
}
</style>