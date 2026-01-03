# Cómo Responder Preguntas de Documentación

## Prioridad de Fuentes de Documentación

### rails-mcp-server (PRIMARIA)
- Usar para documentación de Rails, Inertia, y el stack del proyecto
- Acceder a Rails Guides, herramientas, implementaciones
- Ejemplos: `rails://guides/routing`, `rails://guides/active_record_querying`

### mcp_io (Context7) (SECUNDARIA)
- Usar para documentación de librerías específicas
- Documentación de Vue, Vuetify, TypeScript, Playwright, etc.
- Ejemplos: `/vuetifyjs/vuetify`, `/vuejs/core`, `/microsoft/playwright`

### Web Search (ÚLTIMO RECURSO)
- Solo usar cuando la información no esté disponible en las fuentes anteriores
- Para problemas muy específicos no documentados
- Para comparaciones entre tecnologías

## Cómo Responder Preguntas de Documentación

### Estructura de Respuesta
1. Responder directamente a la pregunta
2. Proporcionar ejemplos de código cuando sea relevante
3. Referenciar archivos del proyecto con enlaces clicables
4. Ser conciso y técnico

### Explicar Conceptos en Español
- Usar terminología técnica en inglés cuando sea apropiado
- Explicar conceptos complejos de manera clara
- Incluir ejemplos prácticos cuando sea necesario

### Ejemplo de Respuesta Correcta

**Pregunta**: ¿Cómo creo un nuevo controller en Rails?

**Respuesta**:
Para crear un nuevo controller en Rails, usa el generador de Rails:

```bash
bin/rails g controller Users index show
```

Esto generará el archivo [`app/controllers/users_controller.rb`](app/controllers/users_controller.rb:1) con las acciones `index` y `show`.

Para controllers de Inertia, usa el generador específico:

```bash
bin/rails g inertia:controller Documents index show create
```

Ver más información en [Rails Guides: Controllers](rails://guides/action_controller_overview).

## Referencias a Archivos

### Usar Enlaces Clicables
- Siempre usar enlaces clicables para referencias: [`filename`](path/to/file.ext:line)
- Incluir el número de línea cuando sea relevante
- Ejemplo: [`User.find_by_email`](app/models/user.rb:15)

### Ejemplo de Referencia
Para ver cómo se implementa la autorización en el proyecto, revisa [`ApplicationPolicy`](app/policies/application_policy.rb:1).

## Ejemplos de Código

### Incluir Ejemplos Prácticos
- Mostrar código funcional y completo
- Usar el contexto del proyecto cuando sea posible
- Explicar el propósito de cada ejemplo

### Ejemplo de Documentación de Componente Vue

**Pregunta**: ¿Cómo uso el composable `useTranslations`?

**Respuesta**:
El composable [`useTranslations`](app/frontend/composables/useTranslations.ts:138) se usa así:

```vue
<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()

const greeting = computed(() => t('dashboard.greeting', { name: userName.value }))
</script>

<template>
  <div>{{ greeting }}</div>
</template>
```

Las traducciones se definen en [`config/locales/frontend.es.yml`](config/locales/frontend.es.yml:1).

## Documentación de Rails

### Rails Guides
- Acceder a guías oficiales de Rails
- Ejemplos de recursos:
  - `rails://guides/routing`
  - `rails://guides/active_record_querying`
  - `rails://guides/active_model_basics`

### Rails API
- Documentación de API de Rails
- Referencias de métodos y clases
- Ejemplos de uso

## Documentación de Inertia

### Inertia.js
- Documentación oficial de Inertia.js
- Guías de uso con Vue
- Referencias de API

### Ejemplo de Pregunta sobre Inertia

**Pregunta**: ¿Cómo paso props desde Rails a Vue?

**Respuesta**:
En Rails, usas `render inertia: 'Page', props: { ... }`:

```ruby
# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    render inertia: 'Documents/Show', props: {
      document: DocumentSerializer.new(@document).as_json
    }
  end
end
```

En Vue, accedes a las props con [`usePage()`](app/frontend/composables/useTranslations.ts:1):

```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'

const page = usePage()
const document = page.props.document as Document
</script>
```

## Documentación de Vue/Vuetify

### Vue.js
- Documentación oficial de Vue 3
- Guías de Composition API
- Referencias de componentes

### Vuetify
- Documentación oficial de Vuetify
- Referencias de componentes
- Ejemplos de uso

### Ejemplo de Pregunta sobre Vuetify

**Pregunta**: ¿Cómo uso un v-data-table?

**Respuesta**:
El componente `v-data-table` de Vuetify se usa así:

```vue
<template>
  <v-data-table
    :headers="headers"
    :items="documents"
    :search="search"
    item-value="id"
  >
    <template #item.actions="{ item }">
      <v-btn @click="editDocument(item)">Editar</v-btn>
    </template>
  </v-data-table>
</template>

<script setup lang="ts">
const headers = [
  { title: 'Nombre', key: 'name' },
  { title: 'Creado', key: 'created_at' },
  { title: 'Acciones', key: 'actions', sortable: false }
]
</script>
```

## Documentación de Testing

### Minitest
- Documentación de Minitest
- Guías de testing en Rails
- Ejemplos de tests

### Playwright
- Documentación oficial de Playwright
- Guías de testing E2E
- Referencias de API

### Ejemplo de Pregunta sobre Testing

**Pregunta**: ¿Cómo escribo un test de controller?

**Respuesta**:
Para escribir un test de controller en Rails con Minitest:

```ruby
# test/controllers/documents_controller_test.rb
require 'test_helper'

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @document = documents(:one)
  end

  test "should get index" do
    sign_in @user
    get documents_url
    assert_response :success
  end

  test "should get show" do
    sign_in @user
    get document_url(@document)
    assert_response :success
  end
end
```

Ver más en [Rails Guides: Testing](rails://guides/testing).

## Mantener Respuestas Concisas

### Enfocarse en la Pregunta
- Responder directamente sin información irrelevante
- Evitar explicaciones excesivas
- Ser técnico y preciso

### Ejemplo de Respuesta Concisa

**MAL (demasiado largo)**:
Para crear un controller en Rails, primero debes entender que Rails sigue el patrón MVC. Los controllers son responsables de coordinar entre models y views. Para crear un controller, puedes usar el generador de Rails que creará automáticamente el archivo con la estructura básica. El generador también creará las vistas correspondientes...

**BIEN (conciso)**:
Para crear un controller en Rails, usa el generador:

```bash
bin/rails g controller Users index show
```

Esto generará [`app/controllers/users_controller.rb`](app/controllers/users_controller.rb:1).

## Verificar Información en el Proyecto

### Antes de Responder
- Verificar si la información ya existe en el proyecto
- Referenciar archivos existentes cuando sea posible
- Usar el contexto del proyecto en las respuestas

### Ejemplo

**Pregunta**: ¿Cómo se maneja la autorización en este proyecto?

**Respuesta**:
Este proyecto usa Pundit para autorización. Revisa [`ApplicationPolicy`](app/policies/application_policy.rb:1) para ver la policy base.

Para implementar autorización en un controller:

```ruby
class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    authorize @document
    render inertia: 'Documents/Show', props: { document: @document }
  end
end
```

La policy correspondiente está en [`DocumentPolicy`](app/policies/document_policy.rb:1).
