<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { router, usePage } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import type { Project } from '@/types'

const { t } = useTranslations()
const { navigateTo: navigate } = useNavigation()
const page = usePage()

const menu = ref(false)
const search = ref('')
const loading = ref(false)
const projects = ref<Project[]>([])

// User computed so it's reactive to prop changes
const currentProject = computed(() => page.props.current_project as Project | null)

const fetchProjects = async (query: string = '') => {
  loading.value = true
  try {
    const params = new URLSearchParams()
    if (query) params.append('q[name_cont]', query)
    params.append('limit', '5')

    const response = await fetch(`/projects/search?${params}`)
    const data = await response.json()
    projects.value = data.projects
  } catch (error) {
    console.error('Error fetching projects:', error)
  } finally {
    loading.value = false
  }
}

const switchProject = (slug: string) => {
  menu.value = false
  router.post(`/projects/${slug}/switch`)
}

const navigateTo = (path: string) => {
  menu.value = false
  navigate(path)
}

// Debounce search
let searchTimeout: ReturnType<typeof setTimeout>
watch(search, (value) => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => fetchProjects(value), 300)
})

// Load projects when menu opens
watch(menu, (isOpen) => {
  if (isOpen) {
    search.value = ''
    fetchProjects()
  }
})
</script>

<template>
  <v-menu v-model="menu" :close-on-content-click="false" location="bottom start" min-width="300">
    <template v-slot:activator="{ props }">
      <v-btn
        v-bind="props"
        variant="tonal"
        color="white"
        class="text-none"
        rounded="lg"
        size="small"
      >
        <v-icon start size="small">mdi-folder-outline</v-icon>
        <span class="d-none d-sm-inline">{{ currentProject?.name || t('projects.select') }}</span>
        <v-icon end size="small">mdi-chevron-down</v-icon>
      </v-btn>
    </template>

    <v-card class="rounded-xl" elevation="8">
      <v-card-text class="pa-3">
        <v-text-field
          v-model="search"
          :placeholder="t('projects.search')"
          prepend-inner-icon="mdi-magnify"
          variant="outlined"
          density="compact"
          hide-details
          class="mb-2"
          autofocus
        />

        <v-list density="compact" nav class="pa-0" max-height="240" style="overflow-y: auto;">
          <template v-if="loading">
            <v-list-item class="text-center">
              <v-progress-circular indeterminate size="24" color="primary" />
            </v-list-item>
          </template>

          <template v-else-if="projects.length">
            <v-list-item
              v-for="project in projects"
              :key="project.id"
              :title="project.name"
              :subtitle="'/' + project.slug"
              :active="currentProject?.id === project.id"
              @click="switchProject(project.slug)"
              rounded="lg"
              color="primary"
            >
              <template v-slot:prepend>
                <v-avatar color="primary" size="32" variant="tonal">
                  <v-icon size="small">mdi-folder-outline</v-icon>
                </v-avatar>
              </template>
            </v-list-item>
          </template>

          <template v-else>
            <v-list-item class="text-center text-medium-emphasis">
              {{ t('projects.no_results') }}
            </v-list-item>
          </template>
        </v-list>

        <v-divider class="my-2" />

        <v-btn
          block
          variant="text"
          color="primary"
          prepend-icon="mdi-plus"
          size="small"
          @click="navigateTo('/projects/new')"
          class="text-none"
        >
          {{ t('projects.new') }}
        </v-btn>
      </v-card-text>
    </v-card>
  </v-menu>
</template>
