# ADR-001: SQLite comme base de donnees principale

## Status
Accepted

## Context
SCORE a besoin d'une base de donnees relationnelle pour stocker les metadonnees documentaires, les resultats d'analyse, et les configurations multi-tenant. Le deploiement doit rester simple (pas de service de base de donnees separe).

## Decision
Utiliser SQLite3 comme base de donnees principale via Django ORM.

## Consequences

### Positif
- Zero configuration : pas de service externe a gerer
- Deploiement simplifie : un seul fichier `db.sqlite3`
- Performance excellente en lecture
- ACID compliance native
- Backup simple (copie de fichier)

### Negatif
- Un seul writer simultane (WAL mode aide partiellement)
- Pas de replication / haute disponibilite
- Limite pratique ~100k documents pour la performance
- Contention potentielle avec multi-worker Celery

### Risques
- Si le volume depasse 100k documents, migration vers PostgreSQL necessaire
- Si multi-worker Celery cause des erreurs "database is locked", reduction de la concurrence ou migration necessaire

## Alternatives considerees
- **PostgreSQL** : plus robuste mais ajoute un service a gerer
- **MySQL** : meme complexite que PostgreSQL sans avantages pour ce cas
