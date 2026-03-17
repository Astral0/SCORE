# PRD Technique - SCORE Platform

> **Document**: Product Requirements Document - Technical
> **Project**: SCORE (SCORE Curates Organizational Repository for Embeddings)
> **Date**: 2026-03-17
> **Status**: Current state documentation (as-is)

---

## 1. System Architecture

### 1.1 High-Level Overview

```text
┌──────────────────────────────────────────────────────────────┐
│                    SCORE Application                          │
│                                                               │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │Dashboard│ │Connectors│ │Analysis │ │  Chat   │           │
│  │  App    │ │   App    │ │   App   │ │   App   │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
│       │           │           │            │                 │
│  ┌────▼───────────▼───────────▼────────────▼────┐           │
│  │           Django 5.1 (MVT Monolith)           │           │
│  │                                                │           │
│  │  Models ─── Views ─── Templates ─── Middleware│           │
│  │    │          │           │             │      │           │
│  │    │          │           │       ┌─────▼────┐│           │
│  │    │          │           │       │  Tenant  ││           │
│  │    │          │           │       │Isolation ││           │
│  │    │          │           │       └──────────┘│           │
│  └────┼──────────┼───────────┼───────────────────┘           │
│       │          │           │                                │
│  ┌────▼────┐ ┌───▼───┐ ┌────▼──────────┐                   │
│  │ SQLite3 │ │ Redis │ │ LLM Providers │                   │
│  │   ORM   │ │ Queue │ │ OpenAI/Azure  │                   │
│  └─────────┘ └───┬───┘ └───────────────┘                   │
│                   │                                          │
│  ┌────────────────▼─────────────────────┐                   │
│  │          Celery Workers              │                   │
│  │  ┌───────────┐ ┌──────────────────┐  │                   │
│  │  │ Ingestion │ │    Analysis      │  │                   │
│  │  │   Task    │ │ Pipeline (14ph)  │  │                   │
│  │  └───────────┘ └──────────────────┘  │                   │
│  └──────────────────────────────────────┘                   │
│                                                               │
│  ┌──────────────────────────────────────┐                   │
│  │         Vector Storage               │                   │
│  │  sqlite-vec (KNN) + FAISS (graph)   │                   │
│  └──────────────────────────────────────┘                   │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 Django Apps

| App | Models | Views | Tasks | Purpose |
|-----|--------|-------|-------|---------|
| `tenants` | 5 | - | - | Multi-tenant, RBAC, audit log |
| `connectors` | 1 | 8 | - | Source configuration |
| `ingestion` | 3 | - | 1 | Document pipeline |
| `analysis` | 12 | 30+ | 2 | Analysis + audit |
| `vectorstore` | 0 | - | - | Embedding storage (sqlite-vec) |
| `chat` | 3 | 4 | - | RAG assistant |
| `reports` | 1 | 2+ | - | Export generation |
| `dashboard` | 1 | 2 | - | UI, feedback |

### 1.3 Data Flow

```text
Source (SharePoint/Confluence/Files)
    │
    ▼ [Celery: run_ingestion]
  INGESTION PIPELINE
    │ 1. Detect changes (incremental)
    │ 2. Extract text (PDF/DOCX/PPTX/HTML/MD)
    │ 3. Chunk (heading-aware, 1024 tokens)
    │ 4. Hash (SHA-256, skip unchanged)
    │ 5. Embed (LLM batch, 500/batch)
    │ 6. Store (ORM + sqlite-vec)
    ▼
  DOCUMENTS + CHUNKS + EMBEDDINGS
    │
    ▼ [Celery: run_unified_pipeline]
  ANALYSIS PIPELINE (14 phases, checkpoint/resume)
    │ Ph 1: Duplicates (semantic+lexical+metadata → LLM verify)
    │ Ph 2: Claims (S-P-O extraction via LLM)
    │ Ph 3: Semantic Graph (spaCy+NetworkX+FAISS)
    │ Ph 4: Clustering (HDBSCAN hierarchical → LLM labels)
    │ Ph 5: Gaps (LLM coverage questions → evaluation)
    │ Ph 6: Tree (document taxonomy)
    │ Ph 7: Contradictions (KNN claims → LLM classify)
    │ Ph 8: Hallucination risks (acronyms, jargon, hedging)
    │ Ph 9-14: Audit 6 axes (hygiene→governance)
    ▼
  ANALYSIS RESULTS + AUDIT SCORE (A-E)
    │
    ├──▶ Dashboard (HTMX live updates)
    ├──▶ D3.js Visualizations (clusters, tree, graph)
    ├──▶ Reports (HTML/CSV/JSON/PDF)
    └──▶ Chat Assistant (RAG Q&A)
```

---

## 2. Component Specifications

### 2.1 LLM Client (`llm/client.py`)

**Interface** :
```python
class LLMClient:
    def chat(messages: list[dict], model: str, temperature: float) -> str
    def embed(texts: list[str]) -> list[list[float]]
    def batch_submit(prompts: list[str]) -> list[str]
```

**Features** :
- Multi-provider : OpenAI, Azure OpenAI, Azure Mistral
- Rate limiting : token bucket, configurable RPM
- Fallback chain : liste de modeles alternatifs
- Batch API : soumission asynchrone pour gros volumes
- Temperature handling : detection modeles incompatibles (o1, o3, GPT-5)
- Pipeline tracing : logging optionnel des appels

**Configuration** : `config.yaml` → section `llm`

### 2.2 Ingestion Pipeline (`ingestion/pipeline.py`)

**Etapes** :
1. `list_changed_documents()` → detection incrementale
2. `extract_text()` → PDF/DOCX/PPTX/HTML/MD
3. `chunk_text()` → heading-aware (1024 tokens, 32 overlap)
4. `hash_content()` → SHA-256 (skip unchanged)
5. `generate_embeddings()` → LLM batch (500/batch)
6. `store()` → ORM (Document, DocumentChunk) + sqlite-vec

**Error handling** : per-document, pipeline continue
**Retry** : Celery max_retries=2, delay=60s
**Tracking** : IngestionJob.processed_documents

### 2.3 Analysis Pipeline (`analysis/pipeline.py`)

**14 phases** avec checkpoint/resume :
- Chaque phase lit `AnalysisJob.current_phase`
- Cleanup des resultats partiels avant re-execution
- Recovery automatique au demarrage worker (RUNNING → QUEUED → re-dispatch)

**Phases critiques** :
| Phase | Algorithme | Complexite |
|-------|-----------|-----------|
| Duplicates | Cosine + MinHash + LLM | O(n²) attenuation par seuil |
| Claims | LLM per chunk | O(n_chunks) |
| Clustering | HDBSCAN | O(n log n) |
| Contradictions | KNN + LLM per pair | O(n_claims × k) |

### 2.4 Vector Store (`vectorstore/store.py`)

**Technology** : sqlite-vec (SQLite extension)
- Virtual table `vec0` pour KNN
- Dimensions configurables (1024 ou 1536)
- Fichier : `data/vec.sqlite3`

**Operations** :
- `add_embeddings()` : batch insert
- `semantic_search()` : KNN top-k
- `clear_project()` : cleanup

### 2.5 Semantic Graph (`nsg/`)

**Stack** : spaCy + NetworkX + FAISS
- `concepts.py` : extraction concepts (NER + noun chunks)
- `graph.py` : construction graphe (nodes = concepts, edges = co-occurrence)
- FAISS index pour recherche similarite

**Persistence** : fichiers dans `data/graph_dir/<project_id>/`

---

## 3. Database Schema

### 3.1 Tables principales (SQLite3)

| Table | App | Records typiques (1000 docs) |
|-------|-----|------------------------------|
| tenants_tenant | tenants | ~5 |
| tenants_project | tenants | ~20 |
| ingestion_document | ingestion | ~1000 |
| ingestion_documentchunk | ingestion | ~10000 |
| analysis_claim | analysis | ~50000 |
| analysis_duplicatepair | analysis | ~100-500 |
| analysis_contradictionpair | analysis | ~50-200 |
| analysis_topiccluster | analysis | ~20-100 |
| analysis_gapreport | analysis | ~10-50 |
| analysis_hallucinationreport | analysis | ~20-100 |
| analysis_auditaxisresult | analysis | 6 per audit |

### 3.2 Indexes critiques

| Table | Index | Purpose |
|-------|-------|---------|
| document | (tenant, project, connector, source_id) | Lookup unique |
| documentchunk | (document, chunk_index) | Ordering |
| claim | (document, chunk) | Lookup per chunk |
| auditlog | (tenant, -created_at) | Recent logs |
| auditlog | (action) | Filter by action |

---

## 4. API Endpoints

### 4.1 Endpoints count by app

| App | GET | POST | Total |
|-----|-----|------|-------|
| dashboard | 1 | 0 | 1 |
| connectors | 5 | 3 | 8 |
| analysis | 20 | 8 | 28 |
| audit | 8 | 3 | 11 |
| chat | 2 | 3 | 5 |
| reports | 2 | 0 | 2 |
| **Total** | **38** | **17** | **55** |

### 4.2 HTMX Partials

| Endpoint | Pattern | Polling |
|----------|---------|---------|
| `_progress/` | Analysis progress | 2s |
| `_progress_full/` | Full progress with phase detail | 2s |
| `_results/` | Analysis results partial | on-demand |
| `_jobs/` | Ingestion job list | 5s |
| `_live/` | Connector live status | 5s |

### 4.3 JSON API (D3.js)

| Endpoint | Usage |
|----------|-------|
| `api/clusters/` | D3 bubble chart data |
| `api/tree/` | D3 hierarchical tree data |
| `api/concept-graph/` | D3 force graph data |
| `api/concept-graph/query/` | Interactive graph query |
| `api/<axis>/` | Audit axis chart data |

---

## 5. Async Processing

### 5.1 Celery Configuration

| Setting | Value |
|---------|-------|
| Broker | Redis (redis://localhost:6379/0) |
| Result backend | django-celery-results |
| Scheduler | django-celery-beat (DatabaseScheduler) |
| Pool | threads |
| Concurrency | 4 |

### 5.2 Tasks

| Task | Queue | Retry | Description |
|------|-------|-------|-------------|
| `run_ingestion` | default | 2× (60s delay) | Pipeline ingestion complet |
| `run_unified_pipeline` | default | 0 (checkpoint) | Pipeline analysis+audit 14 phases |
| `run_analysis` | default | 0 (checkpoint) | Legacy: analysis seul |

### 5.3 Recovery

Au demarrage worker (`worker_ready` signal) :
1. Query AnalysisJob RUNNING/QUEUED
2. Revoke ancien Celery task_id
3. Reset → QUEUED
4. Re-dispatch `.delay()`

---

## 6. Security Architecture

### 6.1 Authentication
- django-allauth (email + OAuth)
- Session-based auth (Django middleware)
- Admin interface : Django admin

### 6.2 Authorization
- Tenant isolation via TenantScopedModel + middleware
- RBAC : Admin/Editor/Viewer per tenant et per project
- Audit log : operations privilegiees

### 6.3 Data Protection
- Credentials by reference (env var names, pas de secrets en DB)
- CSP headers (middleware)
- HSTS en production
- `.env` gitignored

---

## 7. Deployment

### 7.1 Docker Compose

| Service | Resources | Scaling |
|---------|-----------|---------|
| web | gunicorn 4W×4T | Vertical (workers/threads) |
| celery | threads pool, 4 concurrency | Horizontal (replicas) |
| celery-beat | 1 instance | Non-scalable (singleton) |
| redis | Standard | Standard |

### 7.2 Volumes

| Volume | Content | Backup |
|--------|---------|--------|
| db-data | SQLite databases | File copy |
| vec-data | Vector embeddings | File copy |
| media-data | Uploaded files | File copy |

### 7.3 Health Check

- `/healthz/` endpoint
- 30s interval, 10s timeout, 3 retries
- Monitored par Docker healthcheck

---

## 8. Configuration Reference

### 8.1 config.yaml sections

| Section | Parameters | Description |
|---------|-----------|-------------|
| `llm` | provider, models, rate limits, batch | LLM configuration |
| `chunking` | strategy, size, overlap, min_size | Chunking parameters |
| `analysis.duplicates` | thresholds, weights, verification | Duplicate detection |
| `analysis.contradictions` | confidence, similarity, staleness | Contradiction detection |
| `analysis.clustering` | algorithm, min_size, subclustering | Clustering |
| `analysis.gaps` | questions per cluster, confidence | Gap detection |
| `analysis.hallucination` | acronym freq, jargon TF-IDF, hedging | Hallucination risks |
| `audit` | 6 axis configs, weights | RAG audit |
| `semantic_graph` | spaCy model, top_k, hops, max_nodes | Concept graph |
| `authority_rules` | source weights, recency bias | Conflict resolution |

### 8.2 Environment variable overrides

Les variables `.env` surchargent `config.yaml` pour les parametres sensibles (API keys) et les seuils ajustables en production sans redeployer.
