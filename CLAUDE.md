# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Backend**: Rails 8.1 with PostgreSQL, Solid Queue/Cache/Cable
- **Frontend**: Vue 3 (Composition API, TypeScript), Inertia.js, Vuetify 3, Tailwind CSS 4
- **Package Manager**: Bun
- **Testing**: Minitest (unit/integration), Playwright (system/E2E)

## Commands

```bash
bin/setup              # Initial setup (bundle, bun install, db:prepare)
bin/dev                # Start dev server (Rails + Vite via Overmind/Foreman)
bin/rails test         # Run unit/integration tests
bin/rails test:system  # Run E2E tests with Playwright
bin/ci                 # Full CI suite
bin/rubocop            # Ruby linting
bin/brakeman           # Security scan
bun run check          # TypeScript type checking
```

## Architecture

### Inertia.js SSR Pattern
Rails handles routing and renders Vue components server-side via Inertia. Controllers use `render inertia: 'PageName', props: { ... }` instead of traditional views. Pages receive props directly from Rails controllers.

### Directory Structure
- `app/frontend/pages/` - Inertia page components (PascalCase directories)
- `app/frontend/components/` - Reusable Vue components
- `app/frontend/composables/` - Vue 3 composables (useTranslations, usePermissions, useUser)
- `app/frontend/types/` - TypeScript definitions
- `app/services/` - Business logic extracted from controllers
- `app/policies/` - Pundit authorization policies
- `app/jobs/` - Background jobs (Solid Queue)

### Authorization
Uses Pundit + Rolify for RBAC:
- Global roles: `super_admin`, `admin`, `blog_admin`, `blog_writer`
- Project roles: `owner`, `coworker`, `client`
- Each model has a corresponding policy in `app/policies/`

### Multi-tenancy
Uses `acts_as_tenant` gem. Projects serve as the tenant scope for most resources.

### Event Sourcing
Rails Event Store for audit trails. Browser UI at `/res` (super_admin only).

## Coding Conventions

### Backend
- Controllers should be skinny; extract logic to services/policies
- Use Rails generators: `bin/rails g inertia:controller`, `bin/rails g model`
- Migrations must include `null: false` and `unique: true` constraints where appropriate

### Frontend
- Use `<script setup lang="ts">` syntax
- Add `data-testid="kebab-case-identifier"` to all interactive Vuetify elements
- TypeScript path aliases: `@/*` and `~/*` for imports

### Localization
- Default locale: Spanish (es)
- Translation files: `config/locales/*.yml`
- Frontend translations: `config/locales/frontend.{es,en}.yml`
