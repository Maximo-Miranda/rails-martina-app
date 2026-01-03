# Reglas Específicas de Vue/TypeScript

## Sintaxis Vue

### Uso de `<script setup>`
- Usar `<script setup lang="ts">` siempre
- Usar Composition API
- Preferir `<script setup>` sobre Options API

### Ejemplo Correcto
```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import { usePage } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'

const page = usePage()
const { t } = useTranslations()

const documents = ref(page.props.documents)
</script>

<template>
  <div>{{ t('documents.title') }}</div>
</template>
```

## Estructura de Archivos

### Pages
- Ubicación: `app/frontend/Pages/`
- Nomenclatura: PascalCase
- Cada página es un componente Vue

### Components
- Ubicación: `app/frontend/Components/`
- Nomenclatura: PascalCase
- Componentes reutilizables

### Composables
- Ubicación: `app/frontend/composables/`
- Nomenclatura: camelCase con prefijo `use`
- Lógica reutilizable

### Types
- Ubicación: `app/frontend/types/`
- Definir interfaces TypeScript
- Usar tipos estrictos

### Ejemplo de Estructura
```
app/frontend/
├── Pages/
│   ├── Documents/
│   │   ├── Index.vue
│   │   ├── Show.vue
│   │   └── Form.vue
│   └── Users/
│       ├── Index.vue
│       └── Show.vue
├── Components/
│   ├── PageHeader.vue
│   ├── FormActions.vue
│   └── ConfirmDialog.vue
├── composables/
│   ├── useTranslations.ts
│   ├── usePermissions.ts
│   └── useActionLoading.ts
└── types/
    ├── models/
    │   ├── document.ts
    │   └── user.ts
    └── shared.ts
```

## TypeScript

### Tipos Estrictos
- Usar tipos estrictos siempre
- Definir interfaces para props y emits
- Evitar `any` tanto como sea posible
- Usar tipos genéricos cuando sea apropiado

### Ejemplo de Tipos
```typescript
interface Document {
  id: number
  name: string
  content: string
  user: User
  project: Project
  created_at: string
  updated_at: string
}

interface User {
  id: number
  name: string
  email: string
}

interface Project {
  id: number
  name: string
  slug: string
}
```

### Props y Emits
```vue
<script setup lang="ts">
interface Props {
  document: Document
  onSave: () => void
  onCancel: () => void
}

const props = defineProps<Props>()

const emit = defineEmits<{
  save: []
  cancel: []
}>()
</script>
```

## Testing Attributes

### MANDATORIO
- **OBLIGATORIO**: Agregar `data-testid="kebab-case-identifier"` a todos los elementos interactivos Vuetify
- Usar identificadores descriptivos y únicos
- Seguir el formato kebab-case

### Ejemplos
```vue
<template>
  <v-text-field
    data-testid="documents-input-search"
    v-model="search"
    :label="t('documents.search')"
  />

  <v-btn
    data-testid="documents-button-create"
    @click="createDocument"
  >
    {{ t('documents.new') }}
  </v-btn>

  <v-data-table
    data-testid="documents-table"
    :items="documents"
  >
    <template #item.actions="{ item }">
      <v-btn
        data-testid="documents-button-edit-{{ item.id }}"
        @click="editDocument(item)"
      >
        {{ t('common.edit') }}
      </v-btn>

      <v-btn
        data-testid="documents-button-delete-{{ item.id }}"
        @click="deleteDocument(item)"
      >
        {{ t('common.delete') }}
      </v-btn>
    </template>
  </v-data-table>
</template>
```

### Reglas para data-testid
- Usar formato: `entity-action-identifier`
- Para elementos dinámicos: `entity-action-{{ id }}`
- Ser descriptivo y único
- No cambiar los data-testid existentes (rompe tests)

## Traducciones Frontend

### Uso de useTranslations()
- Usar el composable `useTranslations()` para todas las traducciones
- Notación de puntos: `t('auth.login.title')`
- Las traducciones se pasan desde Rails vía props de Inertia (`page.props.t`)
- Interpolación: `t('key', { name: 'John' })` → reemplaza `%{name}` en el YAML
- **Siempre usar traducciones en lugar de texto hardcodeado en el frontend**

### Ejemplo de Uso
```vue
<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const greeting = computed(() => t('dashboard.greeting', { name: userName.value }))
</script>

<template>
  <div>
    <h1>{{ greeting }}</h1>
    <p>{{ t('dashboard.summary') }}</p>
  </div>
</template>
```

### Interpolación de Variables
```vue
<script setup lang="ts">
const { t } = useTranslations()

const message = computed(() => t('activities.new_project', { name: projectName.value }))
</script>
```

### Archivo de Traducciones (Backend)
```yaml
# config/locales/frontend.es.yml
es:
  frontend:
    documents:
      title: 'Documentos'
      new: 'Nuevo Documento'
      edit: 'Editar Documento'
      delete: 'Eliminar Documento'
      confirm_delete: '¿Estás seguro de eliminar este documento?'
      name: 'Nombre'
      content: 'Contenido'
      save: 'Guardar'
      cancel: 'Cancelar'
      created_at: 'Creado el'
      updated_at: 'Actualizado el'
```

## Inertia

### Navegación
- Usar `router` de `@inertiajs/vue3` para navegación
- Usar `usePage()` para acceder a props
- Manejar errores con Inertia

### Ejemplo de Navegación
```vue
<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const goToDocuments = () => {
  router.get('/documents')
}

const goToDocument = (id: number) => {
  router.get(`/documents/${id}`)
}

const createDocument = () => {
  router.post('/documents', formData)
}
</script>
```

### Props de Inertia
```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'

const page = usePage()
const documents = page.props.documents as Document[]
const currentUser = page.props.auth.user as User
</script>
```

## Vuetify

### Convenciones
- Seguir las convenciones de Vuetify
- Usar componentes de Vuetify para UI
- Personalizar temas en `app/frontend/plugins/vuetify.ts`

### Componentes Comunes
```vue
<template>
  <!-- Text Field -->
  <v-text-field
    v-model="value"
    :label="t('common.name')"
    :error-messages="errors.name"
  />

  <!-- Select -->
  <v-select
    v-model="value"
    :items="options"
    :label="t('common.role')"
  />

  <!-- Button -->
  <v-btn
    color="primary"
    @click="onSubmit"
  >
    {{ t('common.save') }}
  </v-btn>

  <!-- Data Table -->
  <v-data-table
    :headers="headers"
    :items="items"
  />

  <!-- Dialog -->
  <v-dialog v-model="dialog">
    <v-card>
      <v-card-title>{{ t('common.confirm') }}</v-card-title>
      <v-card-actions>
        <v-btn @click="dialog = false">{{ t('common.cancel') }}</v-btn>
        <v-btn color="primary" @click="onConfirm">{{ t('common.confirm') }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>
```

## Package Manager

### Uso de bun
- Usar **bun** para instalar dependencias frontend
- Comandos:
  - `bun install` - Instalar dependencias
  - `bun run` - Ejecutar scripts
  - `bun add` - Agregar dependencias
  - `bun remove` - Eliminar dependencias

### Ejemplos
```bash
# Instalar dependencias
bun install

# Ejecutar servidor de desarrollo
bun run dev

# Agregar una nueva dependencia
bun add vue-router

# Agregar dependencia de desarrollo
bun add -D @types/node

# Eliminar dependencia
bun remove lodash
```

## Optimizaciones

### Lazy Loading
- Implementar lazy loading de componentes
- Usar `defineAsyncComponent` para componentes pesados
- Optimizar el bundle con code splitting

### Ejemplo de Lazy Loading
```vue
<script setup lang="ts">
import { defineAsyncComponent } from 'vue'

const HeavyComponent = defineAsyncComponent(() =>
  import('@/components/HeavyComponent.vue')
)
</script>
```

### Evitar Re-renders
- Usar `v-if` y `v-show` apropiadamente
- Usar `computed` para propiedades derivadas
- Usar `v-memo` para listas grandes

### Ejemplo de Optimización
```vue
<script setup lang="ts">
import { computed } from 'vue'

// MAL (re-render en cada cambio)
const filteredItems = items.value.filter(item => item.active)

// BIEN (computed se cachea)
const filteredItems = computed(() =>
  items.value.filter(item => item.active)
)
</script>

<template>
  <!-- v-if para elementos que no se renderizan frecuentemente -->
  <div v-if="showDetails">
    {{ details }}
  </div>

  <!-- v-show para elementos que se muestran/ocultan frecuentemente -->
  <div v-show="isVisible">
    {{ content }}
  </div>
</template>
```

## Seguridad

### Validación de Inputs
- Sanitizar inputs del usuario
- Usar validaciones en el frontend y backend
- No confiar solo en validaciones del frontend

### Ejemplo de Validación
```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const name = ref('')
const errors = ref<Record<string, string>>({})

const validate = () => {
  errors.value = {}

  if (!name.value) {
    errors.value.name = t('validation.required')
  } else if (name.value.length > 255) {
    errors.value.name = t('validation.too_long', { count: 255 })
  }

  return Object.keys(errors.value).length === 0
}
</script>

<template>
  <v-text-field
    v-model="name"
    :error-messages="errors.name"
    @blur="validate"
  />
</template>
```

## Testing

### Playwright Tests
- Usar `data-testid` para seleccionar elementos
- Probar flujos de usuario completos
- Mantener tests independientes y reproducibles

### Ejemplo de Test
```typescript
test('should create a document', async ({ page }) => {
  await page.goto('/documents/new')

  await page.fill('[data-testid="documents-input-name"]', 'Test Document')
  await page.fill('[data-testid="documents-input-content"]', 'Test Content')

  await page.click('[data-testid="documents-button-save"]')

  await expect(page).toHaveURL(/\/documents\/\d+/)
})
```

## Comentarios en Código

### Principio: Mínimo Posible
- El código debe ser expresivo y legible por sí mismo
- Nombres de variables, métodos y clases deben describir claramente su propósito
- Solo agregar comentarios cuando la lógica no sea explícita o evidente

### Excepciones Permitidas
- En tests para aclarar el propósito de cada caso de prueba
- Para explicar algoritmos complejos o no triviales
- Para documentar decisiones de arquitectura importantes
- Para explicar workarounds o soluciones temporales

### NO Usar Comentarios Para
- Explicar código obvio (ej: `// increment counter` antes de `counter += 1`)
- Documentar parámetros o métodos que ya son auto-explicativos
- Código comentado (eliminar en su lugar)
- Repetir lo que el código ya dice
