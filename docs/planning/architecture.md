# Architecture Technique - SCORE Platform

> **Date**: 2026-03-17
> **Status**: Documentation de l'etat actuel (as-is)

---

## 1. Vue d'ensemble

### 1.1 Style architectural

**Django MVT Monolith** avec traitement asynchrone Celery.

Le systeme suit un pattern classique Django avec separation claire :
- **Models** : ORM, structure donnees, contraintes d'integrite
- **Views** : HTTP handling, authentification, validation, rendering
- **Templates** : Rendu HTML server-side avec interactivite HTMX
- **Services/Pipelines** : Logique metier complexe (ingestion, analysis)
- **Tasks** : Execution asynchrone des operations longues

### 1.2 Principes de design

| Principe | Implementation |
|----------|---------------|
| **Separation of concerns** | Apps Django par domaine metier |
| **Fault tolerance** | Checkpoint/resume pipeline, worker recovery |
| **Multi-provider** | LLM abstraction avec fallback chain |
| **Tenant isolation** | Abstract base models + middleware |
| **Incremental processing** | Sync differentiels, skip unchanged |
| **Observability** | Pipeline tracing, audit log, progress tracking |

---

## 2. Architecture des composants

### 2.1 Layer diagram

```text
┌─────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                         │
│  Django Templates + Bootstrap + HTMX + D3.js                │
│  (Server-side rendering avec interactivite ciblee)          │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   APPLICATION LAYER                          │
│  Views (HTTP) + URL Routing + Middleware                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │dashboard/│ │connectors│ │analysis/ │ │  chat/   │      │
│  │views.py  │ │/views.py │ │views.py  │ │views.py  │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   DOMAIN LAYER                               │
│  Business Logic + Pipelines + Algorithms                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │  ingestion/  │ │  analysis/   │ │    llm/      │        │
│  │  pipeline.py │ │  pipeline.py │ │  client.py   │        │
│  │  extraction  │ │  duplicates  │ │  (multi-     │        │
│  │  chunking    │ │  claims      │ │   provider)  │        │
│  │  hashing     │ │  clustering  │ │              │        │
│  └──────────────┘ │  etc. (14ph) │ └──────────────┘        │
│                    └──────────────┘                          │
│  ┌──────────────┐ ┌──────────────┐                          │
│  │    nsg/      │ │ vectorstore/ │                          │
│  │  graph.py    │ │  store.py    │                          │
│  │  concepts.py │ │  (sqlite-vec)│                          │
│  └──────────────┘ └──────────────┘                          │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   INFRASTRUCTURE LAYER                        │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌───────────────┐   │
│  │ SQLite3 │ │sqlite-vec│ │  Redis  │ │ LLM APIs      │   │
│  │  (ORM)  │ │ (vectors)│ │ (queue) │ │ (OpenAI/Azure)│   │
│  └─────────┘ └──────────┘ └─────────┘ └───────────────┘   │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐                     │
│  │  FAISS  │ │Filesystem│ │ Celery  │                     │
│  │ (graph) │ │ (media)  │ │(workers)│                     │
│  └─────────┘ └──────────┘ └─────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Communication entre composants

| Source | Destination | Protocole | Pattern |
|--------|------------|-----------|---------|
| Browser → Django | HTTP/HTMX | Request/Response + polling |
| Django → Celery | Redis (AMQP) | Fire-and-forget (.delay()) |
| Celery → LLM | HTTPS | Request/Response + retry |
| Celery → SQLite | File I/O | ORM queries |
| Celery → sqlite-vec | File I/O | Virtual table queries |
| Django → sqlite-vec | File I/O | KNN search (chat) |

---

## 3. Module Decomposition

### 3.1 Ingestion Module

```text
ingestion/
├── pipeline.py        # Orchestration (detect → extract → chunk → embed → store)
├── extraction.py      # Text extraction (PDF, DOCX, PPTX, HTML, MD)
├── chunking.py        # Heading-aware chunking (1024 tokens)
├── hashing.py         # SHA-256 content hashing
├── models.py          # Document, DocumentChunk, IngestionJob
├── tasks.py           # Celery: run_ingestion
└── views.py           # HTTP endpoints (N/A - via connectors)
```

**Responsabilites** :
- Extraction texte multi-format
- Decoupage intelligent preservant le contexte (heading_path)
- Detection incrementale des changements
- Generation embeddings vectoriels en batch

### 3.2 Analysis Module

```text
analysis/
├── pipeline.py        # Phase orchestration + checkpoint/resume
├── duplicates.py      # Phase 1: semantic + lexical + metadata
├── claims.py          # Phase 2: S-P-O triple extraction
├── semantic_graph.py  # Phase 3: spaCy + NetworkX + FAISS
├── clustering.py      # Phase 4: HDBSCAN hierarchical
├── gaps.py            # Phase 5: coverage questions
├── tree.py            # Phase 6: document taxonomy
├── contradictions.py  # Phase 7: KNN + LLM classify
├── hallucination.py   # Phase 8: risk detection
├── audit/             # Phases 9-14: 6 audit axes
│   ├── hygiene.py
│   ├── structure.py
│   ├── coverage.py
│   ├── coherence.py
│   ├── retrievability.py
│   └── governance.py
├── trace.py           # Pipeline tracing
├── models.py          # 12 models
├── tasks.py           # Celery: run_unified_pipeline, run_analysis
└── views.py           # 30+ endpoints
```

**Responsabilites** :
- 14 phases d'analyse sequentielles avec checkpoint
- Detection doublons multi-signal
- Extraction et analyse de claims structurees
- Clustering semantique hierarchique
- Audit qualite RAG 6 axes
- Tracabilite complete

### 3.3 LLM Module

```text
llm/
└── client.py          # LLMClient unified interface
```

**Responsabilites** :
- Abstraction multi-provider (OpenAI, Azure, Mistral)
- Rate limiting avec backoff exponentiel
- Fallback chain de modeles
- Batch API pour gros volumes
- Token counting (tiktoken)

---

## 4. Data Architecture

### 4.1 Storage strategy

| Donnee | Technology | Justification |
|--------|-----------|---------------|
| Metadonnees, modeles Django | SQLite3 | Simplicite deploiement, ACID |
| Embeddings vectoriels | sqlite-vec | KNN natif, pas de service externe |
| Graphe semantique | FAISS + NetworkX (fichiers) | Recherche similarite + graph algorithms |
| Files uploadees | Filesystem | Standard Django media |
| Queue messages | Redis | Standard Celery broker |

### 4.2 Data lifecycle

```text
Document lifecycle:
  CREATED (source detected)
    → PENDING (queued for processing)
    → INGESTED (text extracted + chunked)
    → EMBEDDING (vectors being generated)
    → READY (fully processed, searchable)
    → ERROR (processing failed, retryable)
    → DELETED (soft delete, source removed)

Analysis lifecycle:
  QUEUED → RUNNING (phase by phase) → COMPLETED / FAILED / CANCELLED

Audit lifecycle:
  QUEUED → RUNNING (axis by axis) → COMPLETED / FAILED
```

---

## 5. Infrastructure

### 5.1 Deployment topology

```text
┌─────────────────────────────────────────┐
│              Docker Compose              │
│                                          │
│  ┌──────────────┐  ┌──────────────┐    │
│  │     web      │  │    redis     │    │
│  │  gunicorn    │  │   :6379      │    │
│  │  4W × 4T     │  │              │    │
│  │  :8000       │  │              │    │
│  └──────┬───────┘  └──────┬───────┘    │
│         │                  │            │
│  ┌──────▼───────┐  ┌──────▼───────┐    │
│  │   celery     │  │ celery-beat  │    │
│  │   worker     │  │  scheduler   │    │
│  │  threads:4   │  │  (singleton) │    │
│  └──────────────┘  └──────────────┘    │
│                                          │
│  Volumes: db-data, vec-data, media-data │
└─────────────────────────────────────────┘
```

### 5.2 Scaling considerations

| Composant | Scaling | Limite |
|-----------|---------|--------|
| Web (gunicorn) | Vertical (workers × threads) | CPU/RAM |
| Celery workers | Horizontal (replicas) | SQLite write contention |
| Redis | Standard | Rarement le bottleneck |
| SQLite | Non-scalable | ~100k docs max |

### 5.3 Bottlenecks identifies

1. **SQLite write lock** : Un seul writer simultane → contention si multi-worker Celery
2. **LLM API rate limits** : 500 RPM configurable, backoff sur 429
3. **Memory (HDBSCAN/FAISS)** : Corpus > 50k chunks = usage memoire significatif
4. **Embedding generation** : Phase la plus longue de l'ingestion

---

## 6. Cross-Cutting Concerns

### 6.1 Authentication & Authorization

```text
Browser → allauth (login/signup/OAuth)
    → Session cookie
    → TenantMiddleware (inject request.tenant)
    → View (check permissions via membership)
```

### 6.2 Error Handling

| Couche | Strategy |
|--------|----------|
| Views | Django error pages (400, 403, 404, 500) |
| Pipelines | Per-item error logging, pipeline continues |
| Celery tasks | Retry (ingestion), checkpoint (analysis) |
| LLM calls | Backoff + fallback models |

### 6.3 Observability

| Type | Implementation |
|------|---------------|
| Logging | Python logging → `logs/score.log` |
| Progress | IngestionJob/AnalysisJob.progress_pct + HTMX |
| Tracing | analysis/trace.py (LLM call details) |
| Audit | AuditLog (privileged operations) |
| Health | `/healthz/` endpoint |

### 6.4 Configuration Management

```text
Priority (highest → lowest):
1. Environment variables (.env)
2. config.yaml (application config)
3. Django settings.py (framework config)
4. Defaults in code
```

---

## 7. ADR Reference

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](adr/ADR-001-sqlite.md) | SQLite comme base principale | Accepted |
| [ADR-002](adr/ADR-002-htmx.md) | HTMX plutot que SPA | Accepted |
| [ADR-003](adr/ADR-003-llm-abstraction.md) | Abstraction LLM multi-provider | Accepted |
| [ADR-004](adr/ADR-004-checkpoint-resume.md) | Checkpoint/resume pipeline | Accepted |
| [ADR-005](adr/ADR-005-dual-vectorstore.md) | sqlite-vec + FAISS dual store | Accepted |
| [ADR-006](adr/ADR-006-multi-tenant.md) | Multi-tenant via abstract models | Accepted |
| [ADR-007](adr/ADR-007-celery.md) | Celery pour traitement asynchrone | Accepted |
