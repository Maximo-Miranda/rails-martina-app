# Manejo de Errores

## Errores de Inertia

### InertiaFailureApp
- Usar [`app/lib/inertia_failure_app.rb`](app/lib/inertia_failure_app.rb:1) para errores de Inertia
- Manejar errores de forma centralizada
- Proporcionar mensajes de error útiles al usuario
- Redirigir a páginas de error apropiadas

### Ejemplo de InertiaFailureApp
```ruby
class InertiaFailureApp
  def call(env)
    request = ActionDispatch::Request.new(env)
    exception = request.env['action_dispatch.exception']

    if exception.is_a?(ActionController::InvalidAuthenticityToken)
      redirect_to root_path, alert: 'Error de autenticación'
    elsif exception.is_a?(Pundit::NotAuthorizedError)
      redirect_to root_path, alert: 'No tienes permiso para realizar esta acción'
    else
      redirect_to root_path, alert: 'Ha ocurrido un error inesperado'
    end
  end
end
```

## Validaciones en Models y Forms

### Models
- Incluir validaciones en el model
- Usar mensajes de error traducidos
- Proporcionar mensajes claros y útiles
- Validar antes de guardar en la base de datos

### Ejemplo de Validaciones en Model
```ruby
class Document < ApplicationRecord
  validates :name, presence: { message: I18n.t('errors.blank') }
  validates :name, length: {
    maximum: 255,
    message: I18n.t('errors.too_long', count: 255)
  }
  validates :content, presence: { message: I18n.t('errors.blank') }
end
```

### Forms
- Usar form objects para validaciones complejas
- Incluir validaciones personalizadas con mensajes traducidos
- Manejar errores de validación apropiadamente

### Ejemplo de Form
```ruby
class DocumentForm
  include ActiveModel::Model

  attr_accessor :name, :content, :project_id

  validates :name, presence: true
  validates :content, presence: true
  validates :project_id, presence: true

  def save
    return false unless valid?

    document = Document.new(
      name:,
      content:,
      project_id:
    )

    if document.save
      @document = document
      true
    else
      document.errors.each do |attribute, message|
        errors.add(attribute, message)
      end
      false
    end
  end
end
```

## Eventos de Error

### Definición de Eventos de Error
- Crear eventos de error en [`app/events/`](app/events/)
- Los eventos deben incluir información relevante del error
- Usar nombres descriptivos (ej: `DocumentUploadFailed`)

### Ejemplo de Evento de Error
```ruby
module Events
  module Documents
    class UploadFailed
      attr_reader :document_id, :error_message, :failed_at

      def initialize(document_id:, error_message:, failed_at: Time.current)
        @document_id = document_id
        @error_message = error_message
        @failed_at = failed_at
      end
    end
  end
end
```

## Notificaciones de Error con noticed

### Notifiers de Error
- Crear notifiers en [`app/notifiers/`](app/notifiers/)
- Usar `noticed` para notificaciones de error
- Enviar notificaciones apropiadas según el tipo de error
- Incluir información relevante en la notificación

### Ejemplo de Notifier de Error
```ruby
class DocumentUploadFailedNotifier < ApplicationNotifier
  deliver_by :database
  deliver_by :email, mailer: 'UserMailer'

  param :document
  param :error_message

  def title
    "Error al subir documento: #{document.name}"
  end

  def url
    document_url(document)
  end

  def message
    "El documento no pudo ser subido: #{error_message}"
  end
end
```

## Logging Apropiado en Jobs y Services

### Logging en Jobs
- Incluir logging detallado en todos los jobs
- Loguar el inicio y fin de la ejecución
- Loguar errores con contexto completo
- Usar niveles de logging apropiados (info, warn, error)

### Ejemplo de Logging en Job
```ruby
class ProcessDocumentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(document_id)
    Rails.logger.info("Starting document processing: #{document_id}")

    document = Document.find(document_id)

    result = ExternalService.process(document.content)

    if result.success?
      document.update!(status: :processed)
      Rails.logger.info("Document processed successfully: #{document_id}")
    else
      document.update!(status: :failed, error_message: result.error)
      Rails.logger.error("Document processing failed: #{document_id} - #{result.error}")
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Document not found: #{document_id} - #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Failed to process document #{document_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
```

### Logging en Services
- Loguar el inicio y fin de la operación
- Loguar errores con contexto completo
- Usar niveles de logging apropiados
- Incluir información relevante para debugging

### Ejemplo de Logging en Service
```ruby
class DocumentProcessingService
  def call(document)
    Rails.logger.info("Processing document: #{document.id}")

    result = ExternalService.process(document.content)

    if result.success?
      Rails.logger.info("Document processed successfully: #{document.id}")
      { success: true, document: }
    else
      Rails.logger.error("Document processing failed: #{document.id} - #{result.error}")
      { success: false, error: result.error }
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process document #{document.id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { success: false, error: e.message }
  end
end
```

## Manejo de Errores en Controllers

### Errores de Validación
- Retornar errores de validación al frontend
- Usar mensajes traducidos
- Incluir información de contexto cuando sea necesario

### Ejemplo de Manejo de Errores de Validación
```ruby
class DocumentsController < ApplicationController
  def create
    @document = Document.new(document_params)
    authorize @document

    if @document.save
      redirect_to @document, notice: t('documents.create.success')
    else
      render inertia: 'Documents/New', props: {
        document: @document,
        errors: @document.errors
      }
    end
  end
end
```

### Errores de Autorización
- Manejar errores de Pundit apropiadamente
- Proporcionar mensajes claros al usuario
- Redirigir a páginas apropiadas

### Ejemplo de Manejo de Errores de Autorización
```ruby
class ApplicationController < ActionController::Base
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    message = t("pundit.#{policy_name}.#{exception.query}")

    redirect_to root_path, alert: message
  end
end
```

## Manejo de Errores en Frontend

### Errores de Inertia
- Manejar errores de Inertia en el frontend
- Mostrar mensajes de error al usuario
- Proporcionar opciones para recuperar del error

### Ejemplo de Manejo de Errores en Vue
```vue
<script setup lang="ts">
import { usePage } from '@inertiajs/vue3'
import { useTranslations } from '@/composables/useTranslations'

const page = usePage()
const { t } = useTranslations()

const errors = computed(() => page.props.errors || {})
</script>

<template>
  <v-alert
    v-if="errors.unexpected"
    type="error"
    :text="t('errors.unexpected')"
  />
</template>
```

### Errores de Validación
- Mostrar errores de validación en los campos correspondientes
- Usar mensajes traducidos
- Proporcionar feedback visual claro

### Ejemplo de Errores de Validación en Vue
```vue
<template>
  <v-text-field
    v-model="name"
    :label="t('documents.name')"
    :error-messages="errors.name"
  />
</template>
```

## Manejo de Errores de API Externa

### Errores de HTTP
- Manejar errores de respuestas HTTP
- Reintentar con backoff exponencial
- Loguar errores con contexto completo
- Notificar al usuario apropiadamente

### Ejemplo de Manejo de Errores de API
```ruby
class ExternalService
  MAX_RETRIES = 3
  BASE_DELAY = 2

  def self.process(content)
    retry_count = 0

    begin
      response = HTTP.post(endpoint, body: content)

      if response.success?
        return SuccessResponse.new(data: response.body)
      else
        raise ExternalServiceError.new(response.status, response.body)
      end
    rescue ExternalServiceError => e
      if retry_count < MAX_RETRIES
        delay = BASE_DELAY ** retry_count
        Rails.logger.warn("Retrying in #{delay}s: #{e.message}")
        sleep(delay)
        retry_count += 1
        retry
      else
        Rails.logger.error("Max retries reached: #{e.message}")
        raise
      end
    end
  end
end
```

## Manejo de Errores de Database

### Errores de Conexión
- Manejar errores de conexión a la base de datos
- Reintentar con backoff exponencial
- Loguar errores con contexto completo
- Notificar al usuario apropiadamente

### Errores de Query
- Manejar errores de query de forma apropiada
- Verificar que las queries sean válidas
- Loguar errores con contexto completo
- Proporcionar mensajes útiles al usuario

### Ejemplo de Manejo de Errores de Database
```ruby
class DocumentRepository
  def self.find_with_retry(id)
    retry_count = 0
    MAX_RETRIES = 3

    begin
      return Document.find(id)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("Document not found: #{id}")
      raise
    rescue ActiveRecord::StatementInvalid => e
      if retry_count < MAX_RETRIES
        Rails.logger.warn("Retrying query: #{e.message}")
        retry_count += 1
        sleep(2 ** retry_count)
        retry
      else
        Rails.logger.error("Max retries reached: #{e.message}")
        raise
      end
    end
  end
end
```

## Manejo de Errores de Jobs

### Errores de Ejecución
- Manejar errores de ejecución de jobs
- Reintentar con backoff exponencial
- Loguar errores con contexto completo
- Notificar al usuario apropiadamente

### Ejemplo de Manejo de Errores en Job
```ruby
class ProcessDocumentJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(document_id)
    document = Document.find(document_id)
    Rails.logger.info("Processing document: #{document.id}")

    result = ExternalService.process(document.content)

    if result.success?
      document.update!(status: :processed)
      Rails.logger.info("Document processed successfully: #{document.id}")
    else
      document.update!(status: :failed, error_message: result.error)
      Rails.logger.error("Document processing failed: #{document.id} - #{result.error}")
      DocumentUploadFailedNotifier.with(
        document:,
        error_message: result.error
      ).deliver_later(document.user)
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Document not found: #{document_id} - #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Failed to process document #{document_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
```

## Best Practices de Manejo de Errores

### Principios Generales
- Manejar errores de forma consistente en toda la aplicación
- Proporcionar mensajes de error claros y útiles al usuario
- Loguar errores con contexto completo para debugging
- Usar notificaciones apropiadas según el tipo de error
- Reintentar operaciones fallidas con backoff exponencial
- Documentar patrones de errores recurrentes

### Seguridad
- No exponer información sensible en mensajes de error
- No revelar detalles de implementación interna
- Usar mensajes genéricos para errores de seguridad
- Loguar información detallada internamente pero no al usuario

### Experiencia de Usuario
- Proporcionar feedback visual claro de errores
- Ofrecer opciones para recuperar del error
- Usar mensajes amigables y traducidos
- Mantener la interfaz funcional incluso con errores
