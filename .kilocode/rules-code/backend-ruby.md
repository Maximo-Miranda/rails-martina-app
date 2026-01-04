# Reglas Específicas de Ruby/Rails

## Ruby Style

### Ruby 3.x+ Características Modernas
- Usar pattern matching donde sea apropiado
- Usar endless methods para métodos de una línea
- Usar argumentos keyword por defecto

### Ejemplos de Ruby Moderno

#### Pattern Matching
```ruby
# Ruby 3.x+ pattern matching
case user
in { role: :admin }
  grant_admin_access(user)
in { role: :editor }
  grant_editor_access(user)
in { role: :viewer }
  grant_viewer_access(user)
end
```

#### Endless Methods
```ruby
# Método de una línea con endless method
def total_price = price * quantity + tax

# Equivalente a:
def total_price
  price * quantity + tax
end
```

#### Keyword Arguments
```ruby
# Usar argumentos keyword por defecto
def create_user(name:, email:, role: :viewer)
  User.create(name:, email:, role:)
end

# Llamada con keyword arguments
create_user(name: "John", email: "john@example.com")
create_user(name: "Jane", email: "jane@example.com", role: :admin)
```

### RuboCop/StandardRB
- Seguir las guías de RuboCop/StandardRB
- Usar 2 espacios de indentación
- Preferir `&&` y `||` sobre `and` y `or`
- Usar comas al final de líneas en arrays y hashes multilinea

### Ejemplo de Formato Correcto
```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    render inertia: 'Users/Index', props: { users: @users }
  end

  def show
    @user = User.find(params[:id])
    render inertia: 'Users/Show', props: { user: @user }
  end
end
```

## Rails Conventions

### Generadores
- **SIEMPRE** usar `bin/rails g` para generar archivos
- Revisar los archivos generados antes de commitear
- Ejemplos:
  - `bin/rails g model User name:string email:string`
  - `bin/rails g controller Users index show`
  - `bin/rails g inertia:controller Documents index show create`

### Migrations
- Usar `null: false`, `unique: true` siempre que sea posible
- Incluir índices para optimizar consultas
- Hacer migrations reversibles cuando sea posible

### Ejemplo de Migration Correcta
```ruby
class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents, comment: 'Documentos del sistema' do |t|
      t.string :name, null: false, comment: 'Nombre del documento'
      t.text :content, null: false, comment: 'Contenido del documento'
      t.references :user, null: false, foreign_key: true, index: true, comment: 'Usuario creador'
      t.references :project, null: false, foreign_key: true, index: true, comment: 'Proyecto asociado'
      t.timestamps null: false
    end

    add_index :documents, [:user_id, :project_id], name: 'idx_documents_user_project'
    add_index :documents, :created_at
  end
end
```

### Controllers
- Mantener controllers delgados (skinny controllers)
- Solo renderizar Inertia o redirigir
- Usar `render inertia: 'Page', props: { ... }`
- Usar `redirect_to` (Inertia maneja 303)

### Ejemplo de Controller Correcto
```ruby
class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy]

  def index
    @documents = Document.all
    authorize @documents
    render inertia: 'Documents/Index', props: { documents: @documents }
  end

  def show
    authorize @document
    render inertia: 'Documents/Show', props: { document: @document }
  end

  def create
    @document = Document.new(document_params)
    authorize @document

    if @document.save
      redirect_to @document, notice: 'Documento creado exitosamente'
    else
      render inertia: 'Documents/New', props: { document: @document, errors: @document.errors }
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :content, :project_id)
  end
end
```

### Models
- Incluir validaciones en el modelo
- Usar callbacks solo cuando sea necesario
- Implementar scopes para consultas comunes
- Usar `acts_as_tenant` para multi-tenancy

### Ejemplo de Model Correcto
```ruby
class Document < ApplicationRecord
  belongs_to :user
  belongs_to :project
  has_many :document_tags, dependent: :destroy
  has_many :tags, through: :document_tags

  acts_as_tenant :project

  validates :name, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :user, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user:) }

  def display_name
    "#{name} (#{created_at.strftime('%d/%m/%Y')})"
  end
end
```

## Eventos y Event Handlers

### Definición de Eventos
- Crear eventos en `app/events/`
- Los eventos deben ser inmutables
- Usar nombres descriptivos en pasado

### Ejemplo de Evento
```ruby
module Events
  module Documents
    class Created
      attr_reader :document_id, :created_by, :created_at

      def initialize(document_id:, created_by:, created_at: Time.current)
        @document_id = document_id
        @created_by = created_by
        @created_at = created_at
      end
    end
  end
end
```

### Implementación de Handlers
- Crear handlers en `app/event_handlers/`
- Los handlers deben ser idempotentes cuando sea posible
- Manejar errores apropiadamente con logging

### Ejemplo de Handler
```ruby
module EventHandlers
  module Documents
    class OnCreated
      def call(event)
        document = Document.find(event.document_id)
        Rails.logger.info("Document created: #{document.id}")

        # Notificar al usuario
        DocumentCreatedNotifier.with(document:).deliver_later(document.user)

        # Publicar evento de análisis
        RailsEventStore.publish(
          Events::Documents::AnalysisRequested.new(document_id: document.id)
        )
      rescue StandardError => e
        Rails.logger.error("Failed to handle DocumentCreated: #{e.message}")
        raise
      end
    end
  end
end
```

## Jobs

### Creación de Jobs
- Crear jobs en `app/jobs/`
- Usar `Solid Queue` para ejecución asíncrona
- Implementar reintentos con backoff exponencial
- Incluir logging detallado

### Ejemplo de Job Correcto
```ruby
class ProcessDocumentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(document_id)
    document = Document.find(document_id)
    Rails.logger.info("Processing document: #{document.id}")

    # Procesar documento
    result = ExternalService.process(document.content)

    if result.success?
      document.update!(status: :processed, processed_at: Time.current)
      Rails.logger.info("Document processed successfully: #{document.id}")
    else
      document.update!(status: :failed, error_message: result.error)
      Rails.logger.error("Document processing failed: #{document.id} - #{result.error}")
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Document not found: #{document_id}")
  rescue StandardError => e
    Rails.logger.error("Failed to process document #{document_id}: #{e.message}")
    raise
  end
end
```

## Package Manager Frontend

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

## Traducciones Backend

### Archivos YAML
- Archivos YAML en `config/locales/`
- Estructura: `es:`, `en:` con claves anidadas
- Para traducciones frontend: usar `es: frontend: ...`
- Interpolación con `%{variable}`

### Ejemplo de Archivo de Traducciones
```yaml
# config/locales/es.yml
es:
  activerecord:
    attributes:
      document:
        name: 'Nombre'
        content: 'Contenido'
        user: 'Usuario'
        project: 'Proyecto'
    errors:
      models:
        document:
          attributes:
            name:
              blank: 'no puede estar en blanco'
              too_long: 'es demasiado largo (máximo %{count} caracteres)'
            content:
              blank: 'no puede estar en blanco'

  documents:
    create:
      success: 'Documento creado exitosamente'
      error: 'Error al crear el documento'
    update:
      success: 'Documento actualizado exitosamente'
      error: 'Error al actualizar el documento'
    destroy:
      success: 'Documento eliminado exitosamente'
      error: 'Error al eliminar el documento'
```

### Ejemplo de Archivo de Traducciones Frontend
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

## Seguridad

### Validación y Sanitización
- Siempre validar y sanitizar inputs del usuario
- Usar strong parameters en controllers
- Sanitizar datos antes de guardar en la base de datos

### Ejemplo de Strong Parameters
```ruby
class DocumentsController < ApplicationController
  private

  def document_params
    params.require(:document).permit(
      :name,
      :content,
      :project_id,
      tags_attributes: [:id, :name, :_destroy]
    )
  end
end
```

### Protección contra Ataques
- SQL injection: Rails lo maneja automáticamente con parameterized queries
- XSS: Sanitizar inputs y usar `sanitize` helper
- CSRF: Rails incluye protección automática con `protect_from_forgery`

## Optimizaciones

### Evitar N+1 Queries
- Usar `includes` y `joins` para cargar asociaciones
- Usar `counter_cache` para contar asociaciones

### Ejemplo de Optimización
```ruby
# MAL (N+1 query)
@documents = Document.all
@documents.each do |document|
  puts document.user.name # Genera una query por cada documento
end

# BIEN (evita N+1)
@documents = Document.includes(:user).all
@documents.each do |document|
  puts document.user.name # No genera queries adicionales
end
```

### Caching
- Usar `Solid Cache` para datos frecuentes
- Cachear resultados de queries costosas
- Invalidar cache apropiadamente

### Ejemplo de Caching
```ruby
class DocumentsController < ApplicationController
  def index
    @documents = Rails.cache.fetch(['documents', current_user.id], expires_in: 5.minutes) do
      Document.includes(:user).where(user: current_user).recent
    end
    render inertia: 'Documents/Index', props: { documents: @documents }
  end
end
```
