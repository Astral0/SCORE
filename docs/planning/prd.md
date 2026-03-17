# PRD - SCORE Platform

> **Document**: Product Requirements Document
> **Project**: SCORE (SCORE Curates Organizational Repository for Embeddings)
> **Date**: 2026-03-17
> **Status**: Current state documentation (as-is)

---

## 1. Vision & Objectives

### 1.1 Vision

SCORE est une plateforme enterprise d'analyse documentaire intelligente qui permet aux organisations d'evaluer, structurer et optimiser leurs corpus documentaires pour un usage RAG (Retrieval-Augmented Generation).

### 1.2 Problem Statement

Les organisations accumulent des documents provenant de sources multiples (SharePoint, Confluence, fichiers locaux) sans visibilite sur :
- La qualite globale du corpus (doublons, contradictions, lacunes)
- Les risques pour un systeme RAG (hallucinations, incoherences)
- La structure semantique des connaissances
- L'evolution dans le temps de la qualite documentaire

### 1.3 Target Users

| Persona | Role | Besoin principal |
|---------|------|-----------------|
| **Knowledge Manager** | Gestion base documentaire | Vue d'ensemble qualite, actions correctives |
| **RAG Engineer** | Construction systeme RAG | Evaluation corpus, optimisation chunks |
| **Compliance Officer** | Conformite reglementaire | Audit trail, contradictions, gouvernance |
| **Data Scientist** | Analyse donnees | Clustering, graphe semantique, metriques |
| **Team Lead** | Gestion equipe | Multi-tenant, roles, projets |

---

## 2. Functional Requirements

### 2.1 Document Ingestion (F-ING)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-ING-001 | Ingestion multi-sources (SharePoint, Confluence, fichiers) | P0 | Implemented |
| F-ING-002 | Extraction texte PDF, DOCX, PPTX, HTML, Markdown | P0 | Implemented |
| F-ING-003 | Chunking heading-aware avec preservation contexte | P0 | Implemented |
| F-ING-004 | Sync incrementale (detection changements) | P0 | Implemented |
| F-ING-005 | Generation embeddings vectoriels | P0 | Implemented |
| F-ING-006 | Tracking progression ingestion (jobs) | P1 | Implemented |
| F-ING-007 | Gestion versions documents | P1 | Implemented |
| F-ING-008 | Upload manuel de fichiers | P1 | Implemented |
| F-ING-009 | Scheduled sync (cron) | P2 | Implemented |

### 2.2 Analysis Pipeline (F-ANA)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-ANA-001 | Detection doublons (semantique + lexicale + metadata) | P0 | Implemented |
| F-ANA-002 | Extraction claims structurees (S-P-O) | P0 | Implemented |
| F-ANA-003 | Detection contradictions entre claims | P0 | Implemented |
| F-ANA-004 | Clustering semantique hierarchique (HDBSCAN) | P0 | Implemented |
| F-ANA-005 | Detection lacunes documentaires | P0 | Implemented |
| F-ANA-006 | Taxonomie hierarchique documents | P1 | Implemented |
| F-ANA-007 | Detection risques hallucination | P1 | Implemented |
| F-ANA-008 | Graphe semantique (concepts + relations) | P1 | Implemented |
| F-ANA-009 | Checkpoint/resume pipeline (fault-tolerant) | P0 | Implemented |
| F-ANA-010 | Tracabilite pipeline (debugging) | P2 | Implemented |
| F-ANA-011 | Configuration seuils analysis (config.yaml) | P1 | Implemented |

### 2.3 RAG Audit (F-AUD)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-AUD-001 | Audit 6 axes (hygiene, structure, coverage, coherence, retrievability, governance) | P0 | Implemented |
| F-AUD-002 | Notation Nutri-Score A-E | P0 | Implemented |
| F-AUD-003 | Metriques detaillees par axe | P0 | Implemented |
| F-AUD-004 | Chart data pre-computed pour visualisation | P1 | Implemented |
| F-AUD-005 | Audit standalone ou combine avec analysis | P1 | Implemented |

### 2.4 Chat Assistant (F-CHT)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-CHT-001 | Chat RAG avec attribution sources | P1 | Implemented |
| F-CHT-002 | System prompt personnalisable par user/projet | P1 | Implemented |
| F-CHT-003 | Historique conversations persistant | P1 | Implemented |
| F-CHT-004 | Suggestions de questions de suivi | P2 | Implemented |

### 2.5 Reports & Export (F-RPT)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-RPT-001 | Reports par type (duplicates, contradictions, gaps, full) | P1 | Implemented |
| F-RPT-002 | Export HTML, CSV, JSON | P1 | Implemented |
| F-RPT-003 | Export PDF (xhtml2pdf) | P2 | Implemented |

### 2.6 Multi-Tenant (F-TNT)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-TNT-001 | Isolation par workspace (tenant) | P0 | Implemented |
| F-TNT-002 | Sous-projets par tenant | P0 | Implemented |
| F-TNT-003 | RBAC roles (Admin/Editor/Viewer) | P0 | Implemented |
| F-TNT-004 | Audit log operations privilegiees | P1 | Implemented |
| F-TNT-005 | Limites par tenant (max documents, connectors) | P2 | Implemented |

### 2.7 UI & Dashboard (F-UI)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| F-UI-001 | Dashboard principal avec metriques | P0 | Implemented |
| F-UI-002 | Progress live ingestion/analysis (HTMX) | P0 | Implemented |
| F-UI-003 | Visualisation clusters (D3.js bubble chart) | P1 | Implemented |
| F-UI-004 | Visualisation taxonomie (D3.js tree) | P1 | Implemented |
| F-UI-005 | Visualisation graphe conceptuel (D3.js force) | P1 | Implemented |
| F-UI-006 | Radar chart audit 6 axes | P1 | Implemented |
| F-UI-007 | Resolution batch (contradictions, gaps, hallucinations) | P1 | Implemented |
| F-UI-008 | Interface feedback utilisateur | P2 | Implemented |
| F-UI-009 | Internationalisation FR/EN | P2 | Implemented |

---

## 3. Non-Functional Requirements

### 3.1 Performance (NFR-PERF)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-PERF-001 | Temps ingestion 1000 documents (PDF ~10 pages) | < 30 minutes |
| NFR-PERF-002 | Temps analysis pipeline complet 1000 docs | < 2 heures |
| NFR-PERF-003 | Temps reponse chat | < 5 secondes |
| NFR-PERF-004 | UI page load time | < 2 secondes |
| NFR-PERF-005 | Corpus maximum supporte | 100k documents (SQLite limit) |

### 3.2 Reliability (NFR-REL)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-REL-001 | Pipeline checkpoint/resume | Resume apres crash |
| NFR-REL-002 | Worker recovery au demarrage | Auto-recovery jobs stale |
| NFR-REL-003 | LLM fallback models | Degradation gracieuse |
| NFR-REL-004 | Rate limiting avec backoff | Pas de perte de donnees |

### 3.3 Security (NFR-SEC)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-SEC-001 | Auth email + OAuth | allauth |
| NFR-SEC-002 | Tenant isolation | Pas de fuite de donnees cross-tenant |
| NFR-SEC-003 | Credentials by reference | Pas de secrets en base |
| NFR-SEC-004 | CSP + HSTS headers | En production |
| NFR-SEC-005 | Audit trail | Operations privilegiees loggees |

### 3.4 Scalability (NFR-SCA)

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-SCA-001 | Multi-worker Celery | Scalabilite horizontale workers |
| NFR-SCA-002 | Batch API LLM | Optimisation couts pour gros volumes |
| NFR-SCA-003 | Embedding batch | Parallelisme generation embeddings |

---

## 4. Architecture Decision Records

Voir `docs/planning/adr/` pour les ADR detaillees :
- ADR-001: SQLite comme base de donnees principale
- ADR-002: HTMX vs SPA framework
- ADR-003: Multi-provider LLM abstraction
- ADR-004: Checkpoint/resume pipeline
- ADR-005: sqlite-vec + FAISS dual vector store
- ADR-006: Multi-tenant via abstract base models
- ADR-007: Celery pour traitement asynchrone

---

## 5. Feature Map

```text
SCORE Platform
├── Document Management
│   ├── Multi-source ingestion (SharePoint, Confluence, Generic)
│   ├── Text extraction (PDF, DOCX, PPTX, HTML, MD)
│   ├── Heading-aware chunking
│   ├── Incremental sync
│   └── Version tracking
├── Analysis Engine
│   ├── Duplicate detection (semantic + lexical + metadata)
│   ├── Claim extraction (S-P-O triples)
│   ├── Contradiction detection
│   ├── Semantic clustering (HDBSCAN hierarchical)
│   ├── Gap detection
│   ├── Hallucination risk detection
│   ├── Document taxonomy
│   └── Semantic concept graph
├── RAG Audit
│   ├── 6-axis evaluation
│   ├── Nutri-Score grading (A-E)
│   ├── Detailed metrics per axis
│   └── Chart data for visualization
├── Chat Assistant
│   ├── RAG-based Q&A
│   ├── Source attribution
│   ├── Custom system prompts
│   └── Conversation history
├── Reporting
│   ├── Multi-format export (HTML, CSV, JSON, PDF)
│   └── Per-analysis reports
├── Multi-Tenant
│   ├── Workspace isolation
│   ├── RBAC (Admin/Editor/Viewer)
│   ├── Projects per tenant
│   └── Audit logging
└── UI
    ├── Bootstrap + HTMX
    ├── D3.js visualizations
    ├── Live progress tracking
    └── i18n (FR/EN)
```

---

## 6. Technical Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Backend | Django | 5.1 |
| Language | Python | 3.12+ |
| Database | SQLite3 | - |
| Vector Store | sqlite-vec + FAISS | 0.1.6 |
| Task Queue | Celery + Redis | 5.4 |
| LLM | OpenAI / Azure / Mistral | - |
| Frontend | Django Templates + HTMX + D3.js | - |
| Auth | django-allauth | 65.0+ |
| NLP | spaCy + NLTK + scikit-learn | - |
| Deployment | Docker + gunicorn | - |
