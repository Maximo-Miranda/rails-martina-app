<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { router, usePage } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'
import { useNavigation } from '@/composables/useNavigation'
import { useGlobalLoading } from '@/composables/useGlobalLoading'
import type { Project } from '@/types'

const { t } = useTranslations()
const { navigateTo: navigate, isNavigating } = useNavigation()
const { isLoading } = useGlobalLoading()
const page = usePage()

const menu = ref(false)
const search = ref('')
const loading = ref(false)
const projects = ref<Project[]>([])

// Computed property ensures reactivity when current_project changes
const currentProject = computed(() => page.props.current_project as Project | null)

const fetchProjects = async (query: string = '') => {
  loading.value = true
  try {
    const params = new URLSearchParams()
    if (query) params.append('q[name_or_slug_cont]', query)
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
  if (isLoading.value) return
  menu.value = false
  router.post(`/projects/${slug}/switch`)
}

const navigateTo = (path: string) => {
  menu.value = false
  navigate(path)
}

// Debounced search to reduce API calls
let searchTimeout: ReturnType<typeof setTimeout>
watch(search, (value) => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => fetchProjects(value), 300)
})

// Fetch projects when menu opens
watch(menu, (isOpen) => {
  if (isOpen) {
    search.value = ''
    fetchProjects()
  }
})
</script>

<template>
  <v-menu v-model="menu" :close-on-content-click="false" location="bottom start" min-width="320">
    <template v-slot:activator="{ props }">
      <v-tooltip location="bottom" :disabled="!currentProject || currentProject.name.length < 30">
        <template v-slot:activator="{ props: tooltipProps }">
          <v-btn
            v-bind="{ ...props, ...tooltipProps }"
            data-testid="switcher-btn"
            variant="tonal"
            color="white"
            class="text-none switcher-btn"
            rounded="lg"
            size="small"
          >
            <v-icon start size="small">mdi-folder-outline</v-icon>
            <span class="d-none d-sm-inline switcher-btn-text">{{ currentProject?.name || t('projects.select') }}</span>
            <v-icon end size="small">mdi-chevron-down</v-icon>
          </v-btn>
        </template>
        <span>{{ currentProject?.name }}</span>
      </v-tooltip>
    </template>

    <v-card class="rounded-xl" elevation="8" data-testid="switcher-menu">
      <v-card-text class="pa-3">
        <v-text-field
          v-model="search"
          data-testid="switcher-input-search"
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
              :active="currentProject?.id === project.id"
              :disabled="isLoading"
              :data-testid="`switcher-project-${project.slug}`"
              @click="switchProject(project.slug)"
              rounded="lg"
              color="primary"
              class="py-2"
            >
              <template v-slot:prepend>
                <v-avatar color="primary" size="32" variant="tonal" class="mr-3">
                  <v-icon size="small">mdi-folder-outline</v-icon>
                </v-avatar>
              </template>
              <v-list-item-title class="project-item-title">{{ project.name }}</v-list-item-title>
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
          data-testid="switcher-btn-new"
          :disabled="isLoading || isNavigating"
          @click="navigateTo('/projects/new')"
          class="text-none"
        >
          {{ t('projects.new') }}
        </v-btn>
      </v-card-text>
    </v-card>
  </v-menu>
</template>

<style scoped>
.switcher-btn {
  max-width: 320px;
}

.switcher-btn-text {
  max-width: 250px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.project-item-title {
  font-size: 0.875rem;
  line-height: 1.3;
  white-space: normal;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
