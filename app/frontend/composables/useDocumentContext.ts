import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'
import type { SharedProps } from '@/types/shared'

export interface Project {
  id: number
  name: string
  slug: string
}

export interface DocumentRoutes {
  index: (storeId?: number) => string
  show: (docId: number, storeId?: number) => string
  new: (storeId?: number) => string
  destroy: (docId: number) => string
}

export interface DocumentContext {
  isGlobal: boolean
  currentProject: Project | null
  routes: DocumentRoutes
  testIdPrefix: string
}

/** Handles document context detection (global vs project scope). */
export function useDocumentContext(): DocumentContext {
  const page = usePage()

  const isGlobal = computed(() => {
    const url = new URL(window.location.href)
    return url.searchParams.get('scope') === 'global'
  })

  const currentProject = computed(() => (page.props as SharedProps).current_project as Project | null)

  const buildUrl = (path: string, storeId?: number): string => {
    const params = new URLSearchParams()
    if (isGlobal.value) {
      params.set('scope', 'global')
      // Only include store_id for global scope - project scope uses tenant's store
      if (storeId) params.set('store_id', String(storeId))
    }
    const query = params.toString()
    return query ? `${path}?${query}` : path
  }

  const routes = computed<DocumentRoutes>(() => ({
    index: (storeId) => buildUrl('/documents', storeId),
    show: (docId, storeId) => buildUrl(`/documents/${docId}`, storeId),
    new: (storeId) => buildUrl('/documents/new', storeId),
    destroy: (docId) => buildUrl(`/documents/${docId}`),
  }))

  const testIdPrefix = computed(() => isGlobal.value ? 'global-documents' : 'project-documents')

  return {
    isGlobal: isGlobal.value,
    currentProject: currentProject.value,
    routes: routes.value,
    testIdPrefix: testIdPrefix.value,
  }
}
