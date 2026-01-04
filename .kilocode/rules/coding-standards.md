# Estándares de Código

## Principios Generales

### Framework First
- Siempre priorizar las convenciones de Rails/Inertia sobre soluciones personalizadas
- Usar las funcionalidades built-in del framework antes de crear soluciones propias
- Seguir los patrones establecidos por la comunidad de Rails y Vue

### Code Quality
- Escribir código legible y auto-documentado
- Mantener el código simple y claro
- Usar nombres descriptivos para variables, métodos y clases
- Evitar la complejidad innecesaria

### DRY (Don't Repeat Yourself)
- Extraer lógica reutilizable en métodos, módulos, services o composables
- Evitar duplicación de código
- Usar herencia y composición apropiadamente

## Backend (Ruby/Rails)

### Ruby Style
- Usar Ruby 3.x+ con características modernas:
  - Pattern matching donde sea apropiado
  - Endless methods para métodos de una línea
  - Argumentos keyword por defecto
- Seguir las guías de RuboCop/StandardRB
- Usar 2 espacios de indentación
- Preferir `&&` y `||` sobre `and` y `or`

### Rails Conventions
- **Controllers**:
  - Mantener controllers delgados (skinny controllers)
  - Solo renderizar Inertia o redirigir
  - Usar `render inertia: 'Page', props: { ... }`
  - Usar `redirect_to` (Inertia maneja 303)

- **Models**:
  - Incluir validaciones en el modelo
  - Usar `null: false`, `unique: true` en migrations
  - Usar callbacks solo cuando sea necesario
  - Implementar scopes para consultas comunes

- **Migrations**:
  - Siempre usar `bin/rails g` para generar
  - Reversible cuando sea posible
  - Incluir índices para optimizar consultas

- **Generadores**:
  - Siempre usar `bin/rails g` (ej: `inertia:controller`, `model`)
  - Revisar los archivos generados antes de commitear

### Lógica de Negocio
- Extraer lógica compleja a:
  - `app/services/` - Servicios de dominio
  - `app/forms/` - Form objects
  - `app/policies/` - Authorization policies
  - `app/event_handlers/` - Event handlers

### Event Sourcing
- Definir eventos en `app/events/`
- Implementar handlers en `app/event_handlers/`
- Usar `rails_event_store` para gestión de eventos

### Jobs
- Crear jobs en `app/jobs/`
- Usar `Solid Queue` para jobs asíncronos
- Implementar reintentos con backoff exponencial
- Incluir logging detallado

### Traducciones Backend
- Archivos YAML en `config/locales/`
- Estructura: `es:`, `en:` con claves anidadas
- Para traducciones frontend: usar `es: frontend: ...`
- Interpolación con `%{variable}`

## Frontend (Vue/TypeScript)

### Sintaxis Vue
- Usar `<script setup lang="ts">` siempre
- Usar Composition API
- Preferir `<script setup>` sobre Options API

### Estructura de Archivos
- **Pages** en `app/frontend/Pages/` (PascalCase)
- **Components** en `app/frontend/Components/`
- **Composables** en `app/frontend/composables/`
- **Types** en `app/frontend/types/`

### TypeScript
- Usar tipos estrictos
- Definir interfaces para props y emits
- Evitar `any` tanto como sea posible
- Usar tipos genéricos cuando sea apropiado

### Testing Attributes
- **MANDATORIO**: Agregar `data-testid="kebab-case-identifier"` a todos los elementos interactivos Vuetify
- Ejemplo: `<v-text-field data-testid="users-input-search" />`
- Usar identificadores descriptivos y únicos

### Traducciones Frontend
- Usar el composable `useTranslations()`
- Notación de puntos: `t('auth.login.title')`
- Las traducciones se pasan desde Rails vía props de Inertia (`page.props.t`)
- Interpolación: `t('key', { name: 'John' })` → reemplaza `%{name}` en el YAML
- **Siempre usar traducciones en lugar de texto hardcodeado en el frontend**

### Inertia
- Usar `router` de `@inertiajs/vue3` para navegación
- Pasar props desde controllers de Rails
- Usar `usePage()` para acceder a props
- Manejar errores con Inertia

### Vuetify
- Seguir las convenciones de Vuetify
- Usar componentes de Vuetify para UI
- Personalizar temas en `app/frontend/plugins/vuetify.ts`

### Package Manager
- Usar **bun** para instalar dependencias frontend:
  - `bun install` - Instalar dependencias
  - `bun run` - Ejecutar scripts
  - `bun add` - Agregar dependencias
  - `bun remove` - Eliminar dependencias

## Comentarios en Código

### Principio: Mínimo Posible
El código debe ser expresivo y legible por sí mismo. Los nombres de variables, métodos y clases deben describir claramente su propósito.

### Solo Agregar Comentarios Cuando:
- La lógica no sea explícita o evidente
- Se implementan algoritmos complejos o no triviales
- Se documentan decisiones de arquitectura importantes
- Se implementan workarounds o soluciones temporales

### Excepciones Permitidas:
- **En tests**: Para aclarar el propósito de cada caso de prueba
- **Para algoritmos complejos**: Explicar el "por qué" de la implementación
- **Para decisiones de arquitectura**: Documentar el razonamiento detrás de decisiones importantes
- **Para workarounds**: Explicar por qué se necesita una solución temporal

### NO Usar Comentarios Para:
- Explicar código obvio (ej: `# increment counter` antes de `counter += 1`)
- Documentar parámetros o métodos que ya son auto-explicativos
- Código comentado (eliminar en su lugar)
- Repetir lo que el código ya dice

### Ejemplos:

**MAL (comentario innecesario):**
```ruby
# Increment the counter
counter += 1
```

**BIEN (código auto-explicativo):**
```ruby
active_users_count += 1
```

**BIEN (comentario útil):**
```ruby
# Using exponential backoff to prevent overwhelming the API
# during rate limit errors
retry_after: (2**attempt_count).seconds
```

## Seguridad

### Validación y Sanitización
- Siempre validar y sanitizar inputs del usuario
- Usar strong parameters en controllers
- Sanitizar datos antes de guardar en la base de datos
- Proteger contra SQL injection, XSS, CSRF

### Authorization
- Usar `pundit` para authorization
- Verificar permisos en cada acción que modifique datos
- Implementar policies apropiadas

### Autenticación
- Usar `devise` para autenticación
- Implementar autenticación en todas las rutas protegidas
- Manejar sesiones de forma segura

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

## Testing

### Backend
- Escribir tests unitarios para models, services, forms
- Escribir tests de integración para controllers
- Usar fixtures para datos de prueba
- Mantener tests independientes y rápidos

### Frontend
- Escribir tests E2E con Playwright
- Usar `data-testid` para seleccionar elementos
- Mantener tests independientes y reproducibles
- Probar flujos de usuario completos
