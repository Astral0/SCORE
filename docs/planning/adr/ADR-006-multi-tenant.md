# ADR-006: Multi-tenant via abstract base models

## Status
Accepted

## Context
SCORE doit supporter plusieurs organisations (tenants) sur une meme instance, avec isolation complete des donnees.

## Decision
Implementer le multi-tenant via des abstract base models Django (`TenantScopedModel`, `ProjectScopedModel`) qui ajoutent automatiquement une FK `tenant` a tous les modeles de donnees, combine avec un middleware qui injecte le tenant courant.

## Consequences

### Positif
- Isolation au niveau applicatif (pas de schema separation)
- Simple a implementer et a maintenir
- Compatible avec SQLite (pas de schemas multiples)
- RBAC granulaire (Admin/Editor/Viewer par tenant et projet)
- Audit log immutable pour tracabilite

### Negatif
- Pas d'isolation physique des donnees (meme base, meme tables)
- Un bug dans le filtrage peut causer une fuite de donnees cross-tenant
- Performance : tous les tenants dans les memes tables (index necessaires)

### Risques
- Oubli de filtrage tenant dans un nouveau endpoint = fuite de donnees
- Tests d'isolation necessaires et reguliers
