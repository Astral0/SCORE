# ADR-007: Celery pour traitement asynchrone

## Status
Accepted

## Context
Les pipelines d'ingestion et d'analyse sont des operations longues (minutes a heures) qui ne peuvent pas bloquer les requetes HTTP. Un systeme de task queue est necessaire.

## Decision
Utiliser Celery avec Redis comme broker et django-celery-results comme backend de resultats. django-celery-beat pour les taches planifiees.

## Consequences

### Positif
- Ecosystem mature et bien integre a Django
- Redis comme broker : rapide, fiable
- Scalabilite horizontale des workers
- django-celery-beat : scheduling cron natif
- Retry automatique configurable

### Negatif
- Redis est un service supplementaire a gerer
- Celery avec SQLite peut causer des contention en ecriture
- Monitoring Celery necessite des outils supplementaires (Flower, etc.)
- Pool "threads" (pas "prefork") a cause de SQLite

### Risques
- Si le nombre de taches concurrentes augmente, la contention SQLite peut devenir problematique
- Le pool "threads" limite le parallelisme reel (GIL Python)

## Alternatives
- **Django-Q2** : plus leger mais moins mature
- **Dramatiq** : API plus moderne mais moins integre a Django
- **Huey** : minimaliste, adapte a SQLite mais moins de features
