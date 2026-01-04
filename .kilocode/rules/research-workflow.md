# Flujo de Investigación con MCP

## Prioridad Estricta para Resolver Consultas o Encontrar Herramientas

Cuando necesites investigar documentación, encontrar herramientas o resolver dudas técnicas, sigue este orden de prioridad estricta:

### 1. rails-mcp-server (PRIMARIA)
Esta es la fuente principal para cualquier pregunta relacionada con Rails, Inertia o el stack del proyecto.

**Usar para:**
- Documentación de Rails (guías, API, convenciones)
- Documentación de Inertia.js
- Herramientas específicas de Rails (generadores, comandos)
- Implementación de patrones Rails
- Verificar convenciones del framework
- Encontrar herramientas MCP disponibles para Rails

**Cómo usar:**
```ruby
# Buscar herramientas disponibles
mcp--rails--search_tools

# Ejecutar una herramienta específica
mcp--rails--execute_tool

# Acceder a recursos de documentación
access_mcp_resource
```

**Recursos disponibles:**
- Rails Guides: `rails://guides/{guide_name}`
- Stimulus Guides: `stimulus://guides/{guide_name}`
- Turbo Guides: `turbo://guides/{guide_name}`
- Custom Guides: `custom://guides/{guide_name}`
- Kamal Guides: `kamal://guides/{guide_name}`

### 2. mcp_io (Context7) (SECUNDARIA)
Usar esta fuente para documentación de librerías específicas que no estén disponibles en rails-mcp-server.

**Usar para:**
- Documentación de librerías JavaScript/TypeScript (Vue, Vuetify, etc.)
- Documentación de gems de Ruby específicas
- Documentación de herramientas de testing (Playwright, etc.)
- Referencias de APIs externas
- Ejemplos de código de librerías específicas

**Cómo usar:**
```ruby
# Primero resolver el ID de la librería
mcp--context7--resolve-library-id

# Luego obtener la documentación
mcp--context7--get-library-docs
```

**Parámetros importantes:**
- `mode`: 'code' para referencias de API y ejemplos, 'info' para guías conceptuales
- `topic`: Enfocar la documentación en un tema específico
- `page`: Paginar si la respuesta no es suficiente

### 3. Web Search (ÚLTIMO RECURSO)
Solo usar cuando la información no esté disponible en rails-mcp-server o Context7.

**Usar para:**
- Problemas muy específicos no documentados
- Soluciones a bugs o issues recientes
- Comparaciones entre tecnologías
- Tendencias o buenas prácticas muy recientes
- Información sobre proyectos o herramientas muy nuevas

**Cuándo NO usar:**
- Para documentación estándar de Rails/Inertia (usar rails-mcp-server)
- Para documentación de librerías conocidas (usar Context7)
- Para preguntas que pueden responderse con las herramientas MCP disponibles

## Ejemplos de Flujo de Investigación

### Ejemplo 1: Implementar un nuevo controller en Rails
```
1. Usar rails-mcp-server → buscar herramientas de controller
2. Usar rails-mcp-server → acceder a Rails Guides sobre controllers
3. NO usar web search (documentación disponible en MCP)
```

### Ejemplo 2: Usar un componente específico de Vuetify
```
1. Intentar rails-mcp-server → buscar si hay documentación de Vuetify
2. Si no hay, usar Context7 → buscar documentación de Vuetify
3. NO usar web search (documentación disponible en Context7)
```

### Ejemplo 3: Resolver un error muy específico y reciente
```
1. Usar rails-mcp-server → buscar en Rails Guides
2. Usar Context7 → buscar en documentación de librerías
3. Si no se encuentra, usar web search
```

## Reglas de Oro

1. **Siempre empezar con rails-mcp-server** para cualquier pregunta Rails/Inertia
2. **Usar Context7** para librerías específicas no cubiertas por rails-mcp-server
3. **Web search es el último recurso**, solo cuando las fuentes anteriores fallen
4. **No mezclar fuentes** en una sola respuesta si una de las fuentes primarias tiene la información
5. **Documentar la fuente** cuando se use información de MCP o Context7

## Comandos Útiles

### Rails MCP
```bash
# Buscar herramientas disponibles
mcp--rails--search_tools(query: "controller", category: "controllers", detail_level: "summary")

# Ejecutar herramienta
mcp--rails--execute_tool(tool_name: "get_routes", params: {})

# Acceder a guía de Rails
access_mcp_resource(server_name: "rails", uri: "rails://guides/routing")
```

### Context7
```bash
# Resolver ID de librería
mcp--context7--resolve-library-id(libraryName: "vuetify")

# Obtener documentación
mcp--context7--get-library-docs(
  context7CompatibleLibraryID: "/vuetifyjs/vuetify",
  mode: "code",
  topic: "components",
  page: 1
)
```

## Errores Comunes a Evitar

- ❌ Usar web search para documentación básica de Rails
- ❌ No verificar rails-mcp-server antes de usar Context7
- ❌ No especificar el modo correcto en Context7 ('code' vs 'info')
- ❌ No paginar resultados cuando la información no es suficiente
- ❌ Mezclar información de múltiples fuentes sin verificar consistencia
