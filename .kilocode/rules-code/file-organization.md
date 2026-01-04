# Organización de Archivos

## Backend

### Controllers
- Ubicación: `app/controllers/`
- Responsabilidades: Delgados, solo renderizan Inertia o redirigen
- Convención: PascalCase, plural (ej: `UsersController`)
- Namespaces: Para recursos anidados (ej: `app/controllers/projects/documents_controller.rb`)

### Models
- Ubicación: `app/models/`
- Responsabilidades: Datos, validaciones, scopes, asociaciones
- Convención: PascalCase, singular (ej: `User`)
- Incluir `acts_as_tenant` cuando aplique

### Services
- Ubicación: `app/services/`
- Responsabilidades: Lógica de negocio compleja
- Convención: PascalCase, terminan en `Service` (ej: `UserRegistrationService`)
- Stateless cuando sea posible

### Forms
- Ubicación: `app/forms/`
- Responsabilidades: Validaciones complejas, lógica de presentación
- Convención: PascalCase, terminan en `Form` (ej: `DocumentForm`)

### Policies
- Ubicación: `app/policies/`
- Responsabilidades: Authorization con Pundit
- Convención: PascalCase, singular + `Policy` (ej: `DocumentPolicy`)
- Cada model debe tener su policy

### Events
- Ubicación: `app/events/`
- Responsabilidades: Definición de eventos de dominio
- Convención: Módulos anidados, PascalCase (ej: `Events::Documents::Created`)
- Inmutables

### Event Handlers
- Ubicación: `app/event_handlers/`
- Responsabilidades: Reaccionar a eventos
- Convención: Módulos anidados, PascalCase (ej: `EventHandlers::Documents::OnCreated`)
- Idempotentes cuando sea posible

### Jobs
- Ubicación: `app/jobs/`
- Responsabilidades: Tareas asíncronas
- Convención: PascalCase, terminan en `Job` (ej: `ProcessDocumentJob`)
- Heredan de `ApplicationJob`

### Notifiers
- Ubicación: `app/notifiers/`
- Responsabilidades: Notificaciones con `noticed`
- Convención: PascalCase, terminan en `Notifier` (ej: `DocumentUploadedNotifier`)
- Heredan de `ApplicationNotifier`

### Helpers
- Ubicación: `app/helpers/`
- Responsabilidades: Métodos helper para views
- Convención: PascalCase, terminan en `Helper` (ej: `DocumentsHelper`)

### Channels
- Ubicación: `app/channels/`
- Responsabilidades: WebSockets con ActionCable
- Convención: PascalCase, terminan en `Channel` (ej: `NotificationsChannel`)

### Mailers
- Ubicación: `app/mailers/`
- Responsabilidades: Envío de emails
- Convención: PascalCase, terminan en `Mailer` (ej: `UserMailer`)

## Frontend

### Pages
- Ubicación: `app/frontend/Pages/`
- Responsabilidades: Páginas Inertia
- Convención: PascalCase, organizados por recurso (ej: `Documents/Index.vue`)
- Usar `<script setup lang="ts">`

### Components
- Ubicación: `app/frontend/Components/`
- Responsabilidades: Componentes Vue reutilizables
- Convención: PascalCase (ej: `PageHeader.vue`, `FormActions.vue`)
- Usar `<script setup lang="ts">`

### Composables
- Ubicación: `app/frontend/composables/`
- Responsabilidades: Lógica reutilizable (Composition API)
- Convención: camelCase con prefijo `use` (ej: `useTranslations.ts`)
- Retornar funciones reactivas y estado

### Types
- Ubicación: `app/frontend/types/`
- Responsabilidades: Definiciones TypeScript
- Convención: camelCase (ej: `document.ts`, `user.ts`)
- Organizar por dominio (ej: `types/models/`)

### Layouts
- Ubicación: `app/frontend/layouts/`
- Responsabilidades: Layouts de páginas
- Convención: PascalCase (ej: `AppLayout.vue`, `AuthLayout.vue`)

### Plugins
- Ubicación: `app/frontend/plugins/`
- Responsabilidades: Plugins de Vue/Vuetify
- Convención: camelCase (ej: `vuetify.ts`)

### Utils
- Ubicación: `app/frontend/utils/`
- Responsabilidades: Funciones utilitarias
- Convención: camelCase (ej: `validation.ts`)

## Configuración

### Locales
- Ubicación: `config/locales/`
- Responsabilidades: Traducciones
- Convención: `es.yml`, `en.yml`, `frontend.es.yml`, `devise.*.yml`
- Estructura: `es:`, `en:` con claves anidadas

### Initializers
- Ubicación: `config/initializers/`
- Responsabilidades: Configuración inicial de Rails
- Convención: camelCase (ej: `inertia.rb`, `vite.rb`)

## Database

### Migrations
- Ubicación: `db/migrate/`
- Responsabilidades: Cambios en schema
- Convención: Timestamp + descripción (ej: `20240103120000_create_documents.rb`)
- Reversibles cuando sea posible

### Seeds
- Ubicación: `db/seeds.rb`
- Responsabilidades: Datos iniciales
- Organizar por contexto si es complejo

## Testing

### Unit Tests
- Ubicación: `test/models/`, `test/services/`, `test/forms/`
- Responsabilidades: Tests unitarios de backend
- Convención: `*_test.rb` (ej: `user_test.rb`)

### Integration Tests
- Ubicación: `test/controllers/`, `test/integration/`
- Responsabilidades: Tests de integración
- Convención: `*_test.rb` (ej: `users_controller_test.rb`)

### System Tests
- Ubicación: `test/system/` o `test/playwright/`
- Responsabilidades: Tests E2E con Playwright
- Convención: `*_test.rb` (ej: `documents_test.rb`)

### Fixtures
- Ubicación: `test/fixtures/`
- Responsabilidades: Datos de prueba
- Convención: `*.yml` (ej: `users.yml`)

### VCR Cassettes
- Ubicación: `test/vcr_cassettes/`
- Responsabilidades: Grabaciones HTTP
- Convención: Organizar por endpoint

## Assets

### Images
- Ubicación: `app/assets/images/`
- Responsabilidades: Imágenes estáticas
- Convención: Organizar por tipo

### Stylesheets
- Ubicación: `app/assets/stylesheets/`
- Responsabilidades: CSS global
- Convención: `application.css`

## Public
- Ubicación: `public/`
- Responsabilidades: Archivos públicos
- Convención: Organizar por tipo (ej: `public/404.html`)

## Ejemplo de Estructura Completa

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── documents_controller.rb
│   ├── projects_controller.rb
│   └── projects/
│       └── documents_controller.rb
├── models/
│   ├── application_record.rb
│   ├── document.rb
│   ├── project.rb
│   └── user.rb
├── services/
│   └── user_registration_service.rb
├── forms/
│   └── document_form.rb
├── policies/
│   ├── application_policy.rb
│   ├── document_policy.rb
│   └── project_policy.rb
├── events/
│   └── documents/
│       └── created.rb
├── event_handlers/
│   └── documents/
│       └── on_created.rb
├── jobs/
│   └── process_document_job.rb
├── notifiers/
│   └── document_uploaded_notifier.rb
├── helpers/
│   └── documents_helper.rb
├── channels/
│   ├── application_cable/
│   │   ├── channel.rb
│   │   └── connection.rb
│   └── notifications_channel.rb
└── mailers/
    └── user_mailer.rb

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
├── types/
│   ├── models/
│   │   ├── document.ts
│   │   └── user.ts
│   └── shared.ts
├── layouts/
│   ├── AppLayout.vue
│   └── AuthLayout.vue
├── plugins/
│   └── vuetify.ts
└── utils/
    └── validation.ts

config/
├── locales/
│   ├── es.yml
│   ├── en.yml
│   ├── frontend.es.yml
│   ├── devise.es.yml
│   └── devise.en.yml
└── initializers/
    ├── inertia.rb
    └── vite.rb

db/
├── migrate/
│   └── 20240103120000_create_documents.rb
└── seeds.rb

test/
├── models/
│   └── user_test.rb
├── services/
│   └── user_registration_service_test.rb
├── controllers/
│   └── documents_controller_test.rb
├── integration/
│   └── document_flow_test.rb
├── system/
│   └── documents_test.rb
├── fixtures/
│   └── users.yml
└── vcr_cassettes/
    └── external_service/
        └── upload_document.yml
```

## Reglas de Organización

### Principios
- Separar responsabilidades claramente
- Usar convenciones de nombres consistentes
- Organizar por dominio funcional
- Mantener estructura predecible

### Cuándo Crear Nuevos Directorios
- Cuando hay múltiples archivos del mismo tipo
- Cuando la lógica puede agruparse por dominio
- Cuando mejora la mantenibilidad del código

### Cuándo Usar Namespaces
- Para recursos anidados (ej: `Projects::DocumentsController`)
- Para módulos relacionados (ej: `Events::Documents`)
- Para organizar código complejo

### Buenas Prácticas
- Mantener archivos pequeños y enfocados
- Evitar profundidad excesiva en directorios
- Usar índices cuando sea apropiado
- Documentar directorios complejos con README
