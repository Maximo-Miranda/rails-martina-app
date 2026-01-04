# Guías de Testing

## Backend Testing (Minitest)

### Unit Tests
- Ubicación: `test/models/`, `test/services/`, `test/forms/`
- Usar fixtures para datos de prueba
- Probar cada método y comportamiento individualmente
- Mantener tests independientes y rápidos

### Integration Tests
- Ubicación: `test/controllers/`, `test/integration/`
- Probar flujos completos de usuario
- Verificar interacciones entre componentes
- Usar fixtures para configurar datos

### Model Tests
- Probar validaciones
- Probar asociaciones
- Probar scopes y métodos de clase
- Probar callbacks y observadores

### Service Tests
- Probar lógica de negocio compleja
- Verificar interacciones con modelos externos
- Probar manejo de errores
- Verificar efectos secundarios

### Controller Tests
- Probar respuestas HTTP
- Verificar que se rendericen las páginas de Inertia correctas
- Probar autorización con Pundit
- Verificar redirecciones apropiadas

## Frontend/E2E Testing (Playwright)

### System Tests
- Ubicación: `test/system/` o `test/playwright/`
- Probar flujos de usuario completos
- Usar `data-testid` para seleccionar elementos
- Mantener tests independientes y reproducibles

### Testing Attributes
- **MANDATORIO**: Agregar `data-testid="kebab-case-identifier"` a todos los elementos interactivos Vuetify
- Ejemplo: `<v-text-field data-testid="users-input-search" />`
- Usar identificadores descriptivos y únicos

### Component Tests
- Probar componentes Vue individuales
- Verificar comportamiento de props y emits
- Probar interacciones de usuario
- Verificar manejo de errores

### E2E Tests
- Probar flujos completos de usuario
- Verificar integración entre frontend y backend
- Probar navegación entre páginas
- Verificar manejo de errores

## Testing Commands

### Ejecutar Todos los Tests
```bash
bin/ci
```

### Ejecutar Tests de Rails
```bash
bin/rails test
```

### Ejecutar Tests Específicos
```bash
bin/rails test test/models/user_test.rb
bin/rails test test/controllers/users_controller_test.rb
```

### Ejecutar Tests con Coverage
```bash
COVERAGE=true bin/rails test
```

## Best Practices

### General
- Todo nuevo código debe tener tests correspondientes
- Mantener tests independientes entre sí
- Usar nombres descriptivos para tests
- Probar casos normales y casos borde
- Probar manejo de errores

### Backend
- Usar fixtures para datos de prueba
- Evitar acoplamiento entre tests
- Limpiar la base de datos después de cada test
- Usar mocks/stubs para dependencias externas

### Frontend
- Usar `data-testid` para seleccionar elementos
- Probar interacciones de usuario
- Verificar estado de la aplicación
- Probar manejo de errores y notificaciones

## Testing con Database Cleaner

### Configuración
- Usar `database_cleaner-active_record` para limpieza de DB
- Configurar estrategia apropiada (truncation vs transaction)
- Asegurar limpieza entre tests

### Estrategias
- **Transaction**: Rápida, pero puede causar problemas con ciertas características
- **Truncation**: Más lenta, pero más confiable
- Usar transaction para la mayoría de tests
- Usar truncation para tests que requieran características especiales

## Testing con VCR y WebMock

### VCR (HTTP Recording)
- Usar VCR para grabar respuestas HTTP
- Mantener cassettes en `test/vcr_cassettes/`
- Re-grabar cassettes cuando cambien las APIs externas
- Usar cassettes para tests de integración con servicios externos

### WebMock (HTTP Stubbing)
- Usar WebMock para stubbing de HTTP
- Configurar stubs para endpoints externos
- Verificar que se hagan las llamadas HTTP correctas
- Usar en lugar de VCR para casos simples

## Testing de Event Sourcing

### Event Tests
- Probar que se publiquen los eventos correctos
- Verificar que los eventos tengan los datos correctos
- Probar que los eventos se publiquen en el momento correcto

### Event Handler Tests
- Probar que los handlers reaccionen a los eventos correctos
- Verificar que los handlers ejecuten las acciones correctas
- Probar manejo de errores en handlers
- Verificar efectos secundarios de handlers

## Testing de Jobs

### Job Tests
- Ubicación: `test/jobs/`
- Probar que los jobs ejecuten las acciones correctas
- Verificar que los jobs manejen errores apropiadamente
- Probar reintentos con backoff exponencial
- Verificar logging en jobs

### Async Job Testing
- Usar `perform_enqueued_jobs` para probar jobs encolados
- Usar `perform_later` para probar ejecución asíncrona
- Verificar que los jobs se encolen con los parámetros correctos

## Testing de Authorization

### Pundit Policy Tests
- Ubicación: `test/policies/`
- Probar que las policies verifiquen permisos correctos
- Verificar que las policies manejen todos los casos
- Probar que las policies sean consistentes

### Authorization Integration
- Probar que los controllers usen policies correctamente
- Verificar que se denieguen acciones no autorizadas
- Probar que se permitan acciones autorizadas

## Testing de Multi-tenancy

### Tenant Tests
- Probar que cada tenant tenga sus datos aislados
- Verificar que no haya fuga de datos entre tenants
- Probar que los scopes de tenant funcionen correctamente
- Verificar que las policies respeten el tenant actual

## Testing de Traducciones

### Backend Translation Tests
- Probar que las traducciones existan para todas las claves
- Verificar que las traducciones tengan el formato correcto
- Probar interpolación de variables

### Frontend Translation Tests
- Probar que el composable `useTranslations()` funcione
- Verificar que las traducciones se pasen correctamente vía Inertia
- Probar interpolación de variables en frontend

## Testing de Performance

### Backend Performance
- Probar que las queries sean eficientes
- Verificar que no haya N+1 queries
- Usar herramientas de profiling cuando sea necesario
- Probar que el caching funcione correctamente

### Frontend Performance
- Probar que no haya re-renders innecesarios
- Verificar que el lazy loading funcione
- Probar que el code splitting funcione
- Usar herramientas de profiling cuando sea necesario
