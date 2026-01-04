# Gestión de Workflows

## Patrones de Event Sourcing del Proyecto

### Flujo de Event Sourcing
- Definir eventos de dominio en [`app/events/`](app/events/)
- Implementar handlers en [`app/event_handlers/`](app/event_handlers/)
- Usar `rails_event_store` para publicar y suscribirse a eventos
- Los handlers deben ser idempotentes cuando sea posible

### Ejemplo de Flujo de Event Sourcing
```
1. Usuario sube documento
2. Controller crea evento DocumentUploadRequested
3. Evento se publica en RailsEventStore
4. Handler OnUploadRequested se suscribe al evento
5. Handler encola job UploadDocumentJob
6. Job procesa el upload
7. Si exitoso, se publica evento DocumentUploaded
8. Handler OnUploaded se suscribe al evento
9. Handler envía notificación al usuario
```

## Coordinación de Jobs Asíncronos

### Flujo de Jobs
- Crear jobs en [`app/jobs/`](app/jobs/)
- Usar `Solid Queue` para ejecución asíncrona
- Implementar reintentos con backoff exponencial
- Coordinar jobs con eventos y handlers

### Ejemplo de Coordinación de Jobs
```
1. Controller crea evento DocumentUploadRequested
2. Handler OnUploadRequested se suscribe al evento
3. Handler encola job UploadDocumentJob
4. Job se ejecuta en background
5. Si falla, se reintenta con backoff exponencial
6. Si falla definitivamente, se publica evento DocumentUploadFailed
7. Handler OnUploadFailed se suscribe al evento
8. Handler envía notificación de error al usuario
```

## Gestión de Notificaciones en Tiempo Real (ActionCable)

### Flujo de Notificaciones
- Crear channels en [`app/channels/`](app/channels/)
- Usar ActionCable para WebSockets
- Coordinar notificaciones con eventos del sistema
- Manejar suscripciones y desuscripciones

### Ejemplo de Flujo de Notificaciones
```
1. Evento DocumentUploaded se publica
2. Handler OnUploaded se suscribe al evento
3. Handler crea notificación con `noticed`
4. Notificación se guarda en base de datos
5. ActionCable detecta nueva notificación
6. Channel NotificationsChannel transmite notificación al cliente
7. Cliente Vue recibe notificación en tiempo real
8. UI muestra notificación al usuario
```

### Ejemplo de Channel
```ruby
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    # Lógica de limpieza si es necesaria
  end
end
```

## Asegurar Consistencia en Multi-tenancy

### Flujo Multi-tenant
- Usar `acts_as_tenant` para aislar datos por tenant
- Coordinar el tenant actual entre frontend y backend
- Asegurar que las queries filtren por tenant
- Verificar que las policies respeten el tenant actual

### Ejemplo de Flujo Multi-tenant
```
1. Usuario selecciona tenant en frontend
2. Frontend envía tenant_id al backend
3. Backend establece tenant con acts_as_tenant
4. Todas las queries siguientes filtran por tenant
5. Policies verifican permisos dentro del tenant
6. Jobs se ejecutan en contexto del tenant
7. Notificaciones se envían solo a usuarios del tenant
8. Frontend muestra solo datos del tenant actual
```

## Coordinación de Frontend y Backend

### Flujo de Integración
- Coordinar controllers y páginas de Inertia
- Sincronizar props de Inertia entre Rails y Vue
- Coordinar validaciones entre frontend y backend
- Asegurar que las traducciones estén sincronizadas

### Ejemplo de Coordinación Frontend-Backend
```
Backend:
1. Controller define props para página Inertia
2. Controller renderiza página con props
3. Rails serializa props y las envía al frontend

Frontend:
1. Vue recibe props vía Inertia
2. Vue usa props para renderizar UI
3. Vue usa composables para lógica reutilizable
4. Vue usa traducciones desde props
5. Vue navega usando router de Inertia
```

## Gestión de Workflows Complejos

### Descomposición de Workflows
- Dividir workflows complejos en pasos manejables
- Coordinar la ejecución de cada paso
- Manejar errores en cada paso apropiadamente
- Permitir reanudar workflows desde puntos intermedios

### Ejemplo de Workflow Complejo
```
Workflow: Procesamiento de Documentos

Pasos:
1. Upload de documento
   - Controller crea evento DocumentUploadRequested
   - Handler encola job UploadDocumentJob
   - Job sube documento a servicio externo

2. Procesamiento de documento
   - Job crea evento DocumentProcessingStarted
   - Handler inicia procesamiento en servicio externo
   - Servicio externo procesa documento

3. Indexación de documento
   - Servicio externo crea evento DocumentProcessingCompleted
   - Handler crea índices de búsqueda
   - Handler actualiza estado del documento

4. Notificación de usuario
   - Handler crea evento DocumentReady
   - Handler envía notificación al usuario
   - Frontend muestra notificación en tiempo real
```

## Coordinación de Testing en Workflows

### Integración de Testing
- Coordinar tests unitarios, de integración y E2E
- Asegurar que los tests cubran todos los pasos del workflow
- Coordinar fixtures y datos de prueba
- Mantener tests independientes y reproducibles

### Ejemplo de Coordinación de Testing
```
Workflow: Creación de Documentos

Tests Unitarios:
- [ ] Test de modelo Document
- [ ] Test de validaciones
- [ ] Test de scopes
- [ ] Test de asociaciones

Tests de Integración:
- [ ] Test de controller DocumentsController
- [ ] Test de acción create
- [ ] Test de autorización con Pundit
- [ ] Test de evento DocumentUploadRequested

Tests E2E:
- [ ] Test de flujo completo de creación de documento
- [ ] Test de navegación entre páginas
- [ ] Test de validaciones en frontend
- [ ] Test de notificaciones

Coordinación:
- [ ] Ejecutar tests unitarios antes de tests de integración
- [ ] Ejecutar tests de integración antes de tests E2E
- [ ] Mantener fixtures actualizados
- [ ] Corregir errores de tests inmediatamente
```

## Gestión de Errores en Workflows

### Manejo de Errores por Paso
- Manejar errores en cada paso del workflow apropiadamente
- Publicar eventos de error cuando sea necesario
- Enviar notificaciones de error al usuario
- Permitir reanudar workflows desde puntos de error

### Ejemplo de Manejo de Errores en Workflow
```
Workflow: Upload de Documentos

Paso 1: Upload
- Error: Documento demasiado grande
- Acción: Mostrar error al usuario
- Evento: DocumentUploadFailed

Paso 2: Procesamiento
- Error: Servicio externo no disponible
- Acción: Reintentar con backoff
- Evento: DocumentProcessingFailed

Paso 3: Notificación
- Error: No se pudo enviar notificación
- Acción: Loguar error, continuar workflow
- Evento: NotificationFailed
```

## Coordinación de Deployment en Workflows

### Flujo de Deployment
- Coordinar la preparación de ambiente de producción
- Verificar que todos los componentes estén listos
- Coordinar el deployment con Kamal
- Monitorear el deployment en tiempo real

### Ejemplo de Coordinación de Deployment
```
Workflow: Deploy a Producción

Pre-deployment:
- [ ] Ejecutar todas las migrations
- [ ] Compilar assets
- [ ] Ejecutar tests completos
- [ ] Verificar configuraciones de producción
- [ ] Crear backup de base de datos

Deployment:
- [ ] Usar Kamal para deploy
- [ ] Verificar que el deploy sea exitoso
- [ ] Monitorear logs de producción
- [ ] Verificar que la aplicación funcione correctamente

Post-deployment:
- [ ] Verificar funcionalidades críticas
- [ ] Monitorear performance
- [ ] Verificar que no haya errores
- [ ] Actualizar documentación si es necesario
```

## Best Practices de Gestión de Workflows

### Principios Generales
- Documentar workflows claramente
- Usar eventos para desacoplar componentes
- Mantener workflows predecibles y reproducibles
- Coordinar todos los componentes del workflow
- Manejar errores apropiadamente en cada paso
- Proporcionar visibilidad del progreso al usuario
- Permitir reanudar workflows desde puntos intermedios

### Coordinación entre Componentes
- Usar eventos para comunicación entre componentes
- Coordinar la ejecución de jobs asíncronos
- Sincronizar estado entre frontend y backend
- Mantener consistencia de datos en multi-tenancy
- Coordinar notificaciones en tiempo real

### Documentación y Comunicación
- Documentar workflows con diagramas
- Explicar el propósito de cada paso
- Proporcionar actualizaciones de progreso
- Comunicar errores y bloqueos claramente
- Solicitar feedback del usuario regularmente

### Monitoreo y Métricas
- Monitorear el rendimiento de workflows
- Medir el tiempo de ejecución de cada paso
- Identificar cuellos de botella en workflows
- Optimizar workflows basado en métricas
- Alertar sobre workflows lentos o fallidos
