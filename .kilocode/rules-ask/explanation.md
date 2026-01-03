# Cómo Explicar Código

## Análisis de Código Existente

### Antes de Sugerir Cambios
- Leer y entender el código existente
- Identificar el propósito y contexto
- Considerar el impacto de los cambios propuestos
- Verificar compatibilidad con el stack del proyecto

### Ejemplo de Análisis

**Pregunta**: ¿Cómo mejoro este controller?

**Análisis**:
El controller [`DocumentsController`](app/controllers/documents_controller.rb:1) actual tiene las siguientes características:
- Usa `render inertia` correctamente
- Incluye autorización con Pundit
- Maneja errores de forma básica

Se puede mejorar agregando:
- Validaciones de seguridad adicionales
- Caching para optimizar performance
- Logging más detallado

## Explicar el "Por Qué"

### Razonamiento Detrás de las Decisiones
- Explicar el propósito de cada cambio
- Justificar por qué se usa cierto patrón
- Referenciar mejores prácticas o convenciones
- Considerar alternativas y por qué se rechazaron

### Ejemplo de Explicación

**MAL (sin explicación)**:
Cambia `User.all` por `User.includes(:profile)`.

**BIEN (con explicación)**:
Cambia [`User.all`](app/models/user.rb:15) por `User.includes(:profile)` para evitar el problema N+1. Esto precarga las asociaciones de perfil, reduciendo el número de queries de N+1 a 1, mejorando significativamente el performance cuando se listan múltiples usuarios.

## Usar Enlaces Clicables

### Referencias a Archivos
- Siempre usar enlaces clicables: [`Class.method()`](path/to/file.rb:line)
- Incluir el número de línea cuando sea relevante
- Ejemplo: [`Document.find`](app/models/document.rb:20)

### Ejemplo de Referencia

Para entender cómo se maneja la autorización, revisa [`ApplicationPolicy`](app/policies/application_policy.rb:1) que define la policy base para todos los recursos.

## Mantener Explicaciones Concisas y Técnicas

### Enfocarse en lo Importante
- Ir directo al punto clave
- Evitar información irrelevante
- Usar terminología técnica apropiada

### Ejemplo de Explicación Concisa

**MAL (demasiado largo)**:
Para mejorar el performance de esta query, primero debes entender que cuando usas `User.all` y luego iteras sobre cada usuario para acceder a su perfil, Rails genera una query separada para cada usuario. Esto se conoce como el problema N+1 y puede causar problemas de performance cuando tienes muchos usuarios. Para solucionar esto, puedes usar el método `includes` que precarga las asociaciones...

**BIEN (conciso)**:
Cambia [`User.all`](app/models/user.rb:15) por `User.includes(:profile)` para evitar el problema N+1. Esto precarga las asociaciones, reduciendo las queries de N+1 a 1.

## Enfocarse en Arquitectura y Patrones

### Patrones del Proyecto
- Explicar cómo el código sigue los patrones del proyecto
- Referenciar servicios, forms, policies existentes
- Mostrar cómo se integra con la arquitectura existente

### Ejemplo de Explicación de Arquitectura

**Pregunta**: ¿Cómo creo un nuevo service?

**Explicación**:
Los services en este proyecto siguen el patrón establecido en [`UserRegistrationService`](app/services/user_registration_service.rb:1). Los services deben:

1. Estar en [`app/services/`](app/services/)
2. Terminar en `Service` (ej: `DocumentProcessingService`)
3. Ser stateless cuando sea posible
4. Manejar errores apropiadamente con logging

Ejemplo de service:

```ruby
class DocumentProcessingService
  def initialize(document:)
    @document = document
  end

  def call
    Rails.logger.info("Processing document: #{@document.id}")

    # Lógica de procesamiento
    result = ExternalService.process(@document.content)

    if result.success?
      @document.update!(status: :processed)
      Rails.logger.info("Document processed: #{@document.id}")
    else
      @document.update!(status: :failed)
      Rails.logger.error("Document failed: #{@document.id}")
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process document: #{e.message}")
    raise
  end
end
```

## Explicar Patrones de Rails/Inertia

### Convenciones del Framework
- Explicar cómo el código sigue las convenciones de Rails
- Referenciar documentación oficial cuando sea relevante
- Mostrar ejemplos de uso correcto

### Ejemplo de Explicación de Rails

**Pregunta**: ¿Cómo uso strong parameters?

**Explicación**:
Los strong parameters en Rails previenen asignación masiva no autorizada. En [`DocumentsController`](app/controllers/documents_controller.rb:30), el método [`document_params`](app/controllers/documents_controller.rb:35) define qué parámetros son permitidos:

```ruby
def document_params
  params.require(:document).permit(:name, :content, :project_id)
end
```

Esto asegura que solo `name`, `content` y `project_id` puedan ser asignados al model, protegiendo contra asignación masiva de campos sensibles.

## Explicar Patrones de Vue/TypeScript

### Convenciones de Frontend
- Explicar cómo el código sigue las convenciones de Vue
- Referenciar composables y componentes existentes
- Mostrar ejemplos de uso correcto

### Ejemplo de Explicación de Vue

**Pregunta**: ¿Cómo uso el composable useTranslations?

**Explicación**:
El composable [`useTranslations`](app/frontend/composables/useTranslations.ts:138) proporciona acceso a las traducciones pasadas desde Rails vía Inertia. Se usa así:

```vue
<script setup lang="ts">
import { useTranslations } from '@/composables/useTranslations'

const { t } = useTranslations()
</script>

<template>
  <div>{{ t('documents.title') }}</div>
</template>
```

Las traducciones se definen en [`config/locales/frontend.es.yml`](config/locales/frontend.es.yml:1) y se pasan al frontend vía props de Inertia (`page.props.t`).

## Explicar Event Sourcing

### Patrón de Eventos
- Explicar cómo se usan eventos en el proyecto
- Referenciar eventos y handlers existentes
- Mostrar el flujo de publicación y suscripción

### Ejemplo de Explicación de Event Sourcing

**Pregunta**: ¿Cómo creo un nuevo evento?

**Explicación**:
Los eventos en este proyecto siguen el patrón establecido en [`Events::Documents::Created`](app/events/documents/created.rb:1). Los eventos deben:

1. Estar en [`app/events/`](app/events/)
2. Ser inmutables (solo lectura después de creación)
3. Usar nombres en pasado (ej: `Created`, `Uploaded`)
4. Incluir todos los datos necesarios en el constructor

Ejemplo de evento:

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

El handler correspondiente en [`EventHandlers::Documents::OnCreated`](app/event_handlers/documents/on_created.rb:1) reaccionará a este evento cuando se publique.

## Explicar Testing

### Patrones de Testing
- Explicar cómo se estructuran los tests en el proyecto
- Referenciar tests existentes como ejemplos
- Mostrar buenas prácticas de testing

### Ejemplo de Explicación de Testing

**Pregunta**: ¿Cómo escribo un test de controller?

**Explicación**:
Los tests de controller en este proyecto siguen el patrón establecido en [`DocumentsControllerTest`](test/controllers/documents_controller_test.rb:1). Los tests deben:

1. Estar en [`test/controllers/`](test/controllers/)
2. Heredar de `ActionDispatch::IntegrationTest`
3. Usar fixtures para datos de prueba
4. Verificar respuestas HTTP y comportamiento esperado

Ejemplo de test:

```ruby
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

## Mantener el Contexto del Proyecto

### Stack Específico
- Siempre considerar el stack del proyecto (Rails 8 + Inertia + Vue + TS)
- Referenciar gems y librerías específicas del proyecto
- Usar convenciones establecidas en el proyecto

### Ejemplo de Contexto

**Pregunta**: ¿Cómo implemento caching?

**Explicación**:
Este proyecto usa Solid Cache para caching. Para implementar caching en un controller:

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

Esto usa [`Rails.cache.fetch`](app/controllers/documents_controller.rb:10) con Solid Cache, cacheando la query por 5 minutos y invalidando automáticamente.
