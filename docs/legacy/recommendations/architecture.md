# Recommendations - Architecture

## Forces actuelles

1. **Separation claire des apps Django** : chaque domaine metier a son app (ingestion, analysis, chat, etc.)
2. **Pipeline checkpoint/resume** : fault-tolerant, reprise par phase
3. **LLM abstraction** : multi-provider avec fallback et rate limiting
4. **Multi-tenant bien isole** : abstract base models + middleware
5. **HTMX pour l'interactivite** : complexite frontend minimale

## Points d'attention

### 1. Couplage Views ↔ Business Logic

Certaines vues contiennent de la logique metier directement. Extraire systmatiquement les services dans des modules dedies (`services.py`) pour faciliter le test unitaire et la reutilisation.

### 2. SQLite en production

SQLite est adapte pour des corpus < 100k documents mais presente des limites :
- Pas de connexions concurrentes en ecriture (WAL mode aide mais ne resout pas tout)
- Pas de replication / haute disponibilite
- Backup necessite un arret ou snapshot filesystem

**Recommandation** : Prevoir une migration PostgreSQL si le volume augmente ou si le multi-worker Celery pose des problemes de concurrence.

### 3. Vectorstore dual (sqlite-vec + FAISS)

Deux technologies vectorielles coexistent :
- `sqlite-vec` pour les embeddings principaux (KNN search)
- `FAISS` pour le graphe semantique (nsg/)

**Recommandation** : Evaluer la consolidation sur une seule technologie vectorielle pour simplifier la maintenance.

### 4. Configuration dispersee

La configuration est repartie entre `.env`, `config.yaml` et `score/settings.py` avec des overrides par env vars. Cela peut creer de la confusion.

**Recommandation** : Documenter clairement la priorite des sources de configuration et envisager de tout centraliser dans `config.yaml` avec `.env` uniquement pour les secrets.

### 5. Tests d'integration pipeline

Les tests couvrent bien les modeles et vues mais manquent de tests d'integration bout-en-bout sur les pipelines (ingestion, analysis).

**Recommandation** : Ajouter des tests d'integration avec fixtures representatifs pour les pipelines critiques.
