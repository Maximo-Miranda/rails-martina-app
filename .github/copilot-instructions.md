# Project: Rails 8 + Inertia (Vue+TS)

## Stack
- **Backend**: Rails 8 (API mode + Inertia), PostgreSQL, Solid Queue/Cache.
- **Frontend**: Vue.js 3 (Composition API, TypeScript), Inertia.js, Vuetify.
- **Testing**: Minitest (Unit/Integration), Playwright (System/E2E).

## Research & Documentation Workflow (MCP)
**Strict priority for resolving queries or finding tools:**
1. **`rails-mcp-server`**: PRIMARY source. Use for Rails/Inertia documentation, tool discovery, and checking framework implementation details.
2. **`mcp_io` (Context7)**: Secondary source. Search specific library docs here if not found in Rails MCP.
3. **Web Search**: Last resort.

## Coding Guidelines

### General Principles
- **Framework First**: Always prioritize Rails/Inertia conventions and built-in functionalities over custom solutions.
- **Code Quality**: Write legible, self-documenting code. Keep it simple.
- **DRY**: Strictly follow the Don't Repeat Yourself principle. Extract reusable logic.

### Backend (Ruby/Rails)
- **Style**: Modern Ruby 3.x+ (pattern matching, endless methods). Follow RuboCop/StandardRB.
- **Structure**:
  - **Controllers**: Skinny. Use `render inertia: 'Page', props: { ... }`. Use `redirect_to` (Inertia handles 303).
  - **Logic**: Extract to `app/services`, `app/forms`, `app/policies`.
  - **DB**: `null: false`, `unique: true` in migrations.
- **Generators**: Always use `bin/rails g` (e.g., `inertia:controller`, `model`).

### Frontend (Vue/Inertia)
- **Syntax**: `<script setup lang="ts">`.
- **Structure**: Pages in `app/frontend/Pages` (PascalCase), Components in `app/frontend/Components`.
- **Testing Attributes**: **MANDATORY**. Add `data-testid="kebab-case-identifier"` to all interactive Vuetify elements in new views (e.g., `data-testid="users-input-search"`).

### Testing
- **Unit/Integration**: Minitest (`test/models`, `test/services`, `test/controllers`). Use Fixtures.
- **System/E2E**: Playwright.

## Key Commands
- **Dev**: `bin/dev`
- **Test**: `bin/ci` or `bin/rails test`

## Communication
- **Language**: Always respond in Spanish.
