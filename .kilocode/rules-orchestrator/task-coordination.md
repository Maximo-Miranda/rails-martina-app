# Coordinación de Tareas

## Dividir Tareas Complejas en Subtareas

### Principios de División
- Dividir tareas complejas en subtareas manejables
- Cada subtarea debe tener un objetivo claro
- Establecer dependencias entre subtareas cuando sea necesario
- Mantener subtareas independientes cuando sea posible

### Ejemplo de División de Tareas
```
Tarea Principal: Implementar sistema de documentos

Subtareas:
- [ ] Crear modelo Document
- [ ] Crear migration de documentos
- [ ] Crear controller DocumentsController
- [ ] Crear página Documents/Index
- [ ] Crear página Documents/Show
- [ ] Crear página Documents/Form
- [ ] Implementar upload de documentos
- [ ] Implementar validaciones
- [ ] Crear tests
```

## Uso de update_todo_list

### Para Tareas Complejas
- Usar `update_todo_list` para seguimiento de progreso
- Crear una lista de tareas clara y accionable
- Marcar tareas como [ ] (pending), [x] (completed), [-] (in progress)
- Actualizar la lista después de completar cada tarea

### Ejemplo de Uso de update_todo_list
```markdown
[ ] Crear modelo Document
[ ] Crear migration de documentos
[-] Crear controller DocumentsController
[ ] Crear página Documents/Index
[ ] Crear página Documents/Show
[ ] Crear página Documents/Form
[ ] Implementar upload de documentos
[ ] Implementar validaciones
[ ] Crear tests
```

## Coordinación entre Modos

### Cuándo Cambiar de Modo
- Usar `switch_mode` para cambiar de modo apropiadamente
- Cambiar a Architect mode para planificación
- Cambiar a Code mode para implementación
- Cambiar a Debug mode para troubleshooting
- Cambiar a Ask mode para preguntas de documentación

### Ejemplo de Coordinación entre Modos

**Situación**: Necesitas implementar una nueva funcionalidad compleja

**Flujo**:
1. Usar Architect mode para planificar la funcionalidad
2. Crear un plan detallado con consideraciones
3. Obtener aprobación del usuario
4. Cambiar a Code mode para implementar
5. Implementar siguiendo el plan
6. Si hay errores, cambiar a Debug mode
7. Una vez completado, cambiar a Architect mode para revisar

## Coordinación de Tareas Dependientes

### Identificar Dependencias
- Identificar tareas que dependen de otras
- Establecer el orden de ejecución correcto
- Documentar dependencias claramente
- Evitar bloqueos por dependencias circulares

### Ejemplo de Tareas Dependientes
```
Tarea A: Crear modelo Document
Tarea B: Crear migration de documentos (depende de A)
Tarea C: Crear controller DocumentsController (depende de A)
Tarea D: Crear página Documents/Index (depende de C)
Tarea E: Crear tests (depende de A, B, C, D)

Orden de ejecución: A → B → C → D → E
```

## Coordinación de Tareas Paralelas

### Tareas que Pueden Ejecutarse en Paralelo
- Identificar tareas independientes
- Ejecutar tareas paralelas cuando sea posible
- Reducir el tiempo total de ejecución
- Mantener seguimiento de progreso

### Ejemplo de Tareas Paralelas
```
Tareas Paralelas:
- [ ] Crear modelo User
- [ ] Crear modelo Document
- [ ] Crear modelo Project
- [ ] Crear modelo Tag

Estas tareas pueden ejecutarse en paralelo porque son independientes.

Tareas Secuenciales (dependen de las anteriores):
- [ ] Crear migration de users (depende de User)
- [ ] Crear migration de documents (depende de Document)
- [ ] Crear migration de projects (depende de Project)
```

## Coordinación de Testing y Desarrollo

### Integración de Testing en el Flujo de Desarrollo
- Escribir tests mientras se desarrolla la funcionalidad
- Ejecutar tests frecuentemente durante el desarrollo
- Corregir errores de testing inmediatamente
- Mantener tests actualizados con el código

### Ejemplo de Integración de Testing
```
Flujo de Desarrollo con Testing:

1. [ ] Crear modelo Document
2. [ ] Crear test de modelo Document
3. [ ] Crear controller DocumentsController
4. [ ] Crear test de controller DocumentsController
5. [ ] Crear página Documents/Index
6. [ ] Crear test E2E de Documents/Index
7. [ ] Implementar validaciones
8. [ ] Actualizar tests de validaciones
9. [ ] Ejecutar todos los tests
10. [ ] Corregir errores de tests
```

## Coordinación de Frontend y Backend

### Sincronización entre Frontend y Backend
- Coordinar el desarrollo de controllers y páginas
- Asegurar que las props de Inertia sean correctas
- Sincronizar validaciones entre frontend y backend
- Coordinar la implementación de traducciones

### Ejemplo de Coordinación Frontend-Backend
```
Tarea: Implementar página de documentos

Backend:
- [ ] Crear controller DocumentsController
- [ ] Implementar acción index
- [ ] Implementar acción show
- [ ] Implementar acción create
- [ ] Agregar traducciones en config/locales/frontend.es.yml

Frontend:
- [ ] Crear página Documents/Index.vue
- [ ] Crear página Documents/Show.vue
- [ ] Crear página Documents/Form.vue
- [ ] Implementar navegación con Inertia
- [ ] Agregar data-testid para testing

Coordinación:
- [ ] Verificar que las props de Inertia coincidan
- [ ] Probar integración entre frontend y backend
- [ ] Ejecutar tests E2E completos
```

## Coordinación de Event Sourcing

### Coordinación de Eventos y Handlers
- Coordinar la creación de eventos y handlers
- Asegurar que los eventos se publiquen en el momento correcto
- Verificar que los handlers reaccionen a los eventos correctos
- Coordinar la implementación de notificaciones

### Ejemplo de Coordinación de Event Sourcing
```
Tarea: Implementar upload de documentos con eventos

Eventos:
- [ ] Crear evento DocumentUploadRequested
- [ ] Crear evento DocumentUploaded
- [ ] Crear evento DocumentUploadFailed

Handlers:
- [ ] Crear handler OnUploadRequested
- [ ] Crear handler OnUploaded
- [ ] Crear handler OnUploadFailed

Jobs:
- [ ] Crear job UploadDocumentJob
- [ ] Implementar lógica de upload en el job
- [ ] Publicar evento DocumentUploadRequested
- [ ] Manejar evento DocumentUploaded en handler
- [ ] Manejar evento DocumentUploadFailed en handler

Notificaciones:
- [ ] Crear notifier DocumentUploadedNotifier
- [ ] Crear notifier DocumentUploadFailedNotifier
- [ ] Enviar notificación en handler OnUploaded
- [ ] Enviar notificación en handler OnUploadFailed
```

## Coordinación de Multi-tenancy

### Asegurar Aislamiento de Datos
- Coordinar la implementación de acts_as_tenant
- Verificar que las queries filtren por tenant
- Asegurar que las policies respeten el tenant actual
- Coordinar el manejo de tenant en jobs

### Ejemplo de Coordinación de Multi-tenancy
```
Tarea: Implementar documentos multi-tenant

Backend:
- [ ] Agregar acts_as_tenant al modelo Document
- [ ] Crear scope para filtrar por tenant
- [ ] Actualizar policy para respetar tenant
- [ ] Verificar que las queries filtren por tenant

Frontend:
- [ ] Actualizar página para mostrar documentos del tenant actual
- [ ] Implementar selector de tenant
- [ ] Agregar validaciones de tenant

Testing:
- [ ] Crear tests de aislamiento de tenant
- [ ] Verificar que no haya fuga de datos entre tenants
- [ ] Probar con múltiples tenants
```

## Coordinación de Deployment

### Preparación para Deployment
- Coordinar la preparación de ambiente de producción
- Verificar que todas las migrations estén ejecutadas
- Asegurar que los assets estén compilados
- Verificar que las configuraciones sean correctas

### Ejemplo de Coordinación de Deployment
```
Tarea: Deploy a producción

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

## Best Practices de Coordinación

### Principios Generales
- Mantener comunicación clara con el usuario
- Proporcionar actualizaciones de progreso regulares
- Ser flexible ante cambios en el plan
- Documentar decisiones y cambios
- Aprender de cada tarea completada

### Herramientas de Coordinación
- Usar `update_todo_list` para seguimiento
- Usar `switch_mode` para cambiar de modo apropiadamente
- Mantener registros de decisiones
- Documentar bloqueos y soluciones
- Compartir conocimiento con el equipo

### Comunicación con el Usuario
- Proporcionar actualizaciones de progreso
- Preguntar antes de hacer cambios significativos
- Ser transparente sobre bloqueos y desafíos
- Solicitar feedback regularmente
- Ajustar el plan según el feedback del usuario
