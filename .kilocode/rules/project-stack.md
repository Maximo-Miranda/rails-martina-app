# Stack Tecnológico del Proyecto

## Backend

### Framework
- **Rails 8** (API mode + Inertia)
- Ruby 3.x+
- PostgreSQL como base de datos

### Infraestructura
- **Solid Queue**: Para jobs asíncronos
- **Solid Cache**: Para caching
- **Solid Cable**: Para ActionCable (WebSockets)

### Gems Principales
- `inertia_rails` (~> 3.15) - Integración con Inertia.js
- `vite_rails` (~> 3.0) - Integración con Vite
- `devise` (~> 4.9) - Autenticación
- `devise-i18n` - Internacionalización de Devise
- `devise_invitable` (~> 2.0) - Invitaciones de usuarios
- `pundit` (~> 2.5) - Authorization
- `rolify` (~> 6.0) - Gestión de roles
- `acts_as_tenant` (~> 1.0) - Multi-tenancy
- `discard` (~> 1.4) - Soft deletion
- `friendly_id` (~> 5.5) - URLs amigables
- `data_migrate` (~> 11.3) - Migraciones de datos
- `pagy` (~> 43.2) - Paginación
- `ransack` (~> 4.4) - Búsqueda
- `rails_event_store` (~> 2.18) - Event Sourcing
- `faraday` (~> 2.14) - Cliente HTTP
- `noticed` (~> 3.0) - Notificaciones

## Frontend

### Framework
- **Vue.js 3** (Composition API)
- **TypeScript** (~5.6.2)
- **Inertia.js** (@inertiajs/vue3 ~2.3.3)

### UI Framework
- **Vuetify** (~> 3.11.4)
- **Material Design Icons** (@mdi/font ~7.4.47)

### Build Tool
- **Vite** (~> 7.3.0)
- **vite-plugin-ruby** (~> 5.1.1)
- **vite-plugin-vuetify** (~> 2.1.2)

### Integración con Rails
- **@rails/actioncable** (~> 8.1.100) - WebSockets

## Testing

### Backend
- **Minitest** (~> 5.27) - Unit/Integration tests
- **database_cleaner-active_record** - Limpieza de DB en tests
- **VCR** (~> 6.4) - HTTP mocking
- **WebMock** (~> 3.26) - HTTP stubbing

### Frontend/E2E
- **Playwright** (~> 1.57.0) - System/E2E tests
- **Capybara** - Browser automation
- **capybara-playwright-driver** - Playwright driver for Capybara

## Development Tools

### Linting/Quality
- **RuboCop** (rubocop-rails-omakase) - Linter de Ruby
- **Brakeman** - Análisis de seguridad
- **bundler-audit** - Auditoría de gems

### Deployment
- **Kamal** - Deploy a Docker containers
- **Docker** - Contenedores
- **Thruster** - HTTP asset caching/compression

## Package Manager

### Frontend
- **bun** - Package manager para dependencias frontend
  - `bun install` - Instalar dependencias
  - `bun run` - Ejecutar scripts
  - `bun add` - Agregar dependencias
  - `bun remove` - Eliminar dependencias

### Backend
- **Bundler** - Package manager para gems

## Key Commands

### Desarrollo
- `bin/dev` - Iniciar servidor de desarrollo
- `bin/rails server` - Iniciar servidor Rails
- `bun run dev` - Iniciar Vite dev server

### Testing
- `bin/ci` - Ejecutar todos los tests
- `bin/rails test` - Ejecutar tests de Rails
- `bun run check` - Verificar TypeScript

### Generadores
- `bin/rails g model` - Generar modelo
- `bin/rails g controller` - Generar controller
- `bin/rails g inertia:controller` - Generar controller Inertia
