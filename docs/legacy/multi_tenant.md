# Multi-Tenant Architecture

## Model

```text
User (Django auth)
  │
  ├── TenantMembership ──> Tenant (workspace)
  │     role: ADMIN / EDITOR / VIEWER
  │
  └── ProjectMembership ──> Project (sub-workspace)
        role: ADMIN / EDITOR / VIEWER
```

## Isolation

### Data Isolation
- Tous les modeles heritent de `TenantScopedModel` (FK tenant obligatoire)
- Les modeles projet heritent de `ProjectScopedModel` (FK tenant + project)
- Querysets filtres automatiquement par tenant via `TenantScopedManager`

### Middleware
- `TenantMiddleware` : extrait le tenant du contexte utilisateur (session, URL, header)
- Injecte `request.tenant` pour toutes les vues
- Filtre automatique des querysets

### RBAC (Role-Based Access Control)

| Role | Permissions |
|------|------------|
| **ADMIN** | Full access : CRUD, user management, settings |
| **EDITOR** | Read/write : create/edit documents, run analysis |
| **VIEWER** | Read-only : view documents, analysis, reports |

### Audit Log
- Operations privilegiees tracees dans `AuditLog`
- Actions : USER_INVITED, ROLE_CHANGED, PROJECT_CREATED, ANALYSIS_DELETED, etc.
- Immutable : insert-only, jamais modifie
- Indexe sur (tenant, -created_at)

## Limites

| Limite | Configuration |
|--------|---------------|
| Max documents | `Tenant.max_documents` |
| Max connectors | `Tenant.max_connectors` |
