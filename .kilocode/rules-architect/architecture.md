# Principios de Arquitectura

## Patrones de Rails

### MVC (Model-View-Controller)
- **Models**: Representan datos y lógica de negocio
- **Views**: Páginas Inertia (Vue components)
- **Controllers**: Delgados, solo coordinan entre models y views

### Services
- Extraer lógica de negocio compleja a `app/services/`
- Los services deben ser stateless
- Usar services para operaciones que involucran múltiples models
- Ejemplo: `app/services/user_registration_service.rb`

### Forms
- Usar form objects en `app/forms/` para validaciones complejas
- Los forms encapsulan validaciones y lógica de presentación
- Facilitan testing de validaciones independientes de controllers

### Policies
- Usar `pundit` para authorization en `app/policies/`
- Cada model debe tener su policy correspondiente
- Las policies definen quién puede hacer qué sobre qué recurso

### Event Handlers
- Definir eventos de dominio en `app/events/`
- Implementar handlers en `app/event_handlers/`
- Usar `rails_event_store` para publicar y suscribirse a eventos
- Los handlers reaccionan a eventos de forma asíncrona

## Controllers Delgados

### Responsabilidades
- Solo renderizar Inertia o redirigir
- Usar `render inertia: 'Page', props: { ... }`
- Usar `redirect_to` (Inertia maneja 303)
- NO incluir lógica de negocio en controllers

### Ejemplo Correcto
```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    render inertia: 'Users/Index', props: { users: @users }
  end
end
```

### Ejemplo Incorrecto
```ruby
class UsersController < ApplicationController
  def index
    # Lógica de negocio en controller - MAL
    @users = User.where(active: true).order(:created_at)
    @filtered_users = @users.select { |u| u.email.include?('@') }
    render inertia: 'Users/Index', props: { users: @filtered_users }
  end
end
```

## Lógica de Negocio

### Ubicación
- `app/services/` - Servicios de dominio
- `app/forms/` - Form objects
- `app/policies/` - Authorization policies
- `app/event_handlers/` - Event handlers

### Cuándo Usar Services
- Operaciones que involucran múltiples models
- Lógica compleja que no pertenece a un solo model
- Operaciones que requieren transacciones
- Interacciones con servicios externos

### Cuándo Usar Forms
- Validaciones complejas que involucran múltiples models
- Formularios con lógica de presentación
- Operaciones que requieren pasos intermedios

## Event Sourcing

### Definición de Eventos
- Crear eventos en `app/events/`
- Los eventos deben ser inmutables
- Usar nombres descriptivos en pasado (ej: `UserCreated`, `DocumentUploaded`)

### Implementación de Handlers
- Crear handlers en `app/event_handlers/`
- Los handlers deben ser idempotentes cuando sea posible
- Manejar errores apropiadamente con logging

### Ejemplo de Evento
```ruby
module Events
  module Documents
    class Uploaded
      attr_reader :document_id, :uploaded_by, :uploaded_at

      def initialize(document_id:, uploaded_by:, uploaded_at: Time.current)
        @document_id = document_id
        @uploaded_by = uploaded_by
        @uploaded_at = uploaded_at
      end
    end
  end
end
```

### Ejemplo de Handler
```ruby
module EventHandlers
  module Documents
    class OnUploaded
      def call(event)
        document = Document.find(event.document_id)
        Notifier.document_uploaded(document).deliver_later
      rescue StandardError => e
        Rails.logger.error("Failed to handle DocumentUploaded: #{e.message}")
      end
    end
  end
end
```

## Multi-tenancy

### acts_as_tenant
- Usar `acts_as_tenant` para aislar datos por tenant
- Los models deben incluir `acts_as_tenant :tenant`
- Los queries deben filtrar automáticamente por el tenant actual

### Consideraciones
- Todos los models que pertenecen a un tenant deben usar `acts_as_tenant`
- Los jobs deben manejar el tenant apropiadamente
- Los policies deben respetar el tenant actual

## Authorization

### Pundit
- Usar `pundit` para authorization
- Cada model debe tener su policy en `app/policies/`
- Los controllers deben usar `authorize` y `policy_scope`

### Ejemplo de Policy
```ruby
class DocumentPolicy < ApplicationPolicy
  def index?
    user.has_access_to?(tenant)
  end

  def show?
    user.has_access_to?(record.tenant)
  end

  def create?
    user.has_access_to?(tenant)
  end

  def update?
    user.has_access_to?(record.tenant) && user.can_edit?(record)
  end

  def destroy?
    user.has_access_to?(record.tenant) && user.can_delete?(record)
  end

  class Scope < Scope
    def resolve
      scope.where(tenant: user.tenant)
    end
  end
end
```

## Jobs Asíncronos

### Ubicación
- Crear jobs en `app/jobs/`
- Usar `Solid Queue` para ejecución asíncrona

### Best Practices
- Implementar reintentos con backoff exponencial
- Incluir logging detallado
- Manejar errores apropiadamente
- Usar `perform_later` para encolar jobs

### Ejemplo de Job
```ruby
class UploadDocumentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(document_id)
    document = Document.find(document_id)
    Rails.logger.info("Uploading document: #{document.id}")

    # Lógica de upload
    external_service.upload(document)

    Rails.logger.info("Document uploaded successfully: #{document.id}")
  rescue StandardError => e
    Rails.logger.error("Failed to upload document #{document_id}: #{e.message}")
    raise
  end
end
```

## Notificaciones

### noticed
- Usar `noticed` para notificaciones
- Crear notifiers en `app/notifiers/`
- Las notificaciones pueden ser enviadas vía email, database, etc.

### Ejemplo de Notifier
```ruby
class DocumentUploadedNotifier < ApplicationNotifier
  deliver_by :database
  deliver_by :email, mailer: 'UserMailer'

  param :document

  def title
    "Documento subido: #{document.name}"
  end

  def url
    document_url(document)
  end
end
```

## Inertia Integration

### Controllers
- Usar `render inertia: 'Page', props: { ... }`
- Pasar props serializables (no objetos complejos)
- Usar `redirect_to` para redirecciones (Inertia maneja 303)

### Props
- Las props deben ser serializables
- Usar `ActiveModel::Serializers` si es necesario
- Evitar pasar objetos complejos directamente

### Ejemplo
```ruby
class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    authorize @document

    render inertia: 'Documents/Show', props: {
      document: DocumentSerializer.new(@document).as_json
    }
  end
end
```

## Frontend Architecture

### Vue Components
- Pages en `app/frontend/Pages/` (PascalCase)
- Components reutilizables en `app/frontend/Components/`
- Usar `<script setup lang="ts">` siempre
- Usar Composition API

### Composables
- Extraer lógica reutilizable a `app/frontend/composables/`
- Los composables deben ser independientes y reutilizables
- Ejemplos: `useTranslations`, `usePermissions`, `useActionLoading`

### Types
- Definir tipos TypeScript en `app/frontend/types/`
- Usar interfaces para props y emits
- Evitar `any` tanto como sea posible

## Seguridad

### Validación de Inputs
- Siempre validar y sanitizar inputs del usuario
- Usar strong parameters en controllers
- Sanitizar datos antes de guardar en la base de datos

### Protección contra Ataques
- SQL injection: Usar parameterized queries (Rails lo hace automáticamente)
- XSS: Sanitizar inputs y usar `content_tag` o `sanitize`
- CSRF: Rails incluye protección automática con `protect_from_forgery`

### Authorization
- Verificar permisos en cada acción que modifique datos
- Usar `pundit` para authorization
- Implementar policies apropiadas

## Optimizaciones

### Backend
- Evitar N+1 queries con `includes` y `joins`
- Usar caching con `Solid Cache` para datos frecuentes
- Optimizar queries con índices apropiados
- Usar `counter_cache` para contar asociaciones

### Frontend
- Implementar lazy loading de componentes
- Optimizar el bundle con code splitting
- Usar `v-if` y `v-show` apropiadamente
- Evitar re-renders innecesarios
