# Architecture Overview

## High-Level Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS (Browser)                        │
│              Django Templates + Bootstrap + HTMX + D3.js        │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTP (port 8000)
┌───────────────────────────▼─────────────────────────────────────┐
│                     DJANGO 5.1 (WSGI)                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │dashboard │ │connectors│ │ analysis │ │   chat   │          │
│  │ (views)  │ │ (views)  │ │ (views)  │ │ (views)  │          │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘          │
│       │             │            │             │                │
│  ┌────▼─────────────▼────────────▼─────────────▼────┐          │
│  │              BUSINESS LOGIC LAYER                 │          │
│  │  ingestion/pipeline.py  analysis/pipeline.py      │          │
│  │  llm/client.py          nsg/graph.py              │          │
│  │  vectorstore/store.py   reports/                  │          │
│  └────┬─────────────┬────────────┬──────────────────┘          │
│       │             │            │                              │
│  ┌────▼─────┐ ┌─────▼────┐ ┌────▼──────┐                      │
│  │ Django   │ │sqlite-vec│ │   LLM     │                      │
│  │   ORM    │ │ (vectors)│ │ Providers │                      │
│  │ SQLite3  │ │vec.sqlite│ │ OpenAI/   │                      │
│  │ db.sqlite│ │          │ │ Azure/    │                      │
│  │          │ │          │ │ Mistral   │                      │
│  └──────────┘ └──────────┘ └───────────┘                      │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   Celery     │◄── Redis (port 6379)
                    │   Workers    │
                    │              │
                    │ - ingestion  │
                    │ - analysis   │
                    │ - audit      │
                    └──────────────┘
```

## Pattern Architecture

**Django MVT Monolith** avec traitement asynchrone Celery.

```text
Request Flow:
  HTTP Request → Middleware (Tenant, CSP, Auth) → View → Service/Pipeline → Model → Response

Async Flow:
  View → Celery Task (.delay()) → Worker → Pipeline → Model → Status Update
  View → HTMX Poll → Progress Partial → UI Update
```

### Separation des responsabilites

| Couche | Responsabilite | Fichiers |
|--------|---------------|----------|
| **Views** | HTTP, auth, validation, rendering | `*/views.py` |
| **Services/Pipelines** | Logique metier, orchestration | `*/pipeline.py`, `llm/client.py` |
| **Models** | ORM, structure donnees, contraintes | `*/models.py` |
| **Tasks** | Execution asynchrone | `*/tasks.py` |
| **Templates** | Rendu HTML, composants UI | `dashboard/templates/` |

## Project Structure

```
SCORE/
├── analysis/          # Moteur d'analyse (14 phases)
│   ├── audit/         # 6 axes d'audit RAG
│   ├── pipeline.py    # Orchestration phases
│   ├── duplicates.py  # Detection doublons
│   ├── claims.py      # Extraction claims S-P-O
│   ├── contradictions.py  # Detection contradictions
│   ├── clustering.py  # Clustering HDBSCAN
│   ├── gaps.py        # Detection lacunes
│   ├── hallucination.py   # Risques hallucination
│   ├── tree.py        # Taxonomie hierarchique
│   ├── semantic_graph.py  # Graphe conceptuel
│   └── trace.py       # Tracabilite pipeline
├── chat/              # Assistant chat RAG
├── connectors/        # Integrations (SharePoint, Confluence)
├── dashboard/         # Interface web (templates, static)
├── ingestion/         # Pipeline d'ingestion
│   ├── pipeline.py    # Orchestration ingestion
│   ├── extraction.py  # Extraction texte (PDF, DOCX, PPTX)
│   └── chunking.py    # Decoupage heading-aware
├── llm/               # Abstraction LLM
│   └── client.py      # Client unifie multi-provider
├── nsg/               # Graphe semantique (spaCy, NetworkX, FAISS)
├── reports/           # Generation rapports (HTML, CSV, JSON, PDF)
├── score/             # Configuration Django
│   ├── settings.py    # Settings
│   ├── urls.py        # URL routing
│   ├── celery.py      # Configuration Celery
│   └── middleware.py   # Middleware (Tenant, CSP)
├── tenants/           # Multi-tenant (workspaces, projets, roles)
├── vectorstore/       # Stockage embeddings (sqlite-vec)
└── tests/             # Suite de tests pytest
```

## Communication Patterns

### Synchrone (HTTP)

```text
Browser ──HTMX──> View ──ORM──> Model
                    │
                    └──render──> Template Partial
```

### Asynchrone (Celery)

```text
View ──.delay()──> Redis Queue ──> Celery Worker ──> Pipeline
  │                                                      │
  └──HTMX poll──> View ──> Job.status ──> Progress UI    └──> Model Update
```

### HTMX Live Updates

Les pages d'analyse et d'ingestion utilisent HTMX polling pour afficher la progression en temps reel sans WebSocket.

## Key Design Decisions

1. **SQLite + sqlite-vec** : Simplifie le deploiement (pas de PostgreSQL/Pinecone), suffisant pour des corpus < 100k documents
2. **Django Templates + HTMX** : Pas de SPA, server-side rendering avec interactivite ciblee
3. **Celery + Redis** : Traitement asynchrone des pipelines longs (ingestion, analyse)
4. **LLM abstraction multi-provider** : Flexibilite provider sans changer le code metier
5. **Checkpoint/Resume** : Les pipelines d'analyse sont fault-tolerant avec reprise par phase
6. **Multi-tenant** : Isolation par workspace avec roles RBAC
