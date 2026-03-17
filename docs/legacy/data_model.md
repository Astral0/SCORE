# Data Model

## Entity Relationship Overview

```text
Tenant (workspace)
  ├── TenantMembership ──> User (role: ADMIN/EDITOR/VIEWER)
  ├── Project (sub-workspace)
  │     ├── ProjectMembership ──> User
  │     ├── ConnectorConfig (source: SharePoint/Confluence/Generic)
  │     │     └── Document (ingested file)
  │     │           └── DocumentChunk (text segment + embedding)
  │     │                 └── Claim (S-P-O triple)
  │     ├── IngestionJob (pipeline run)
  │     ├── AnalysisJob (14-phase pipeline)
  │     │     ├── DuplicateGroup → DuplicatePair (doc_a ↔ doc_b)
  │     │     ├── ContradictionPair (claim_a ↔ claim_b)
  │     │     ├── TopicCluster → ClusterMembership (chunk/doc)
  │     │     ├── GapReport
  │     │     ├── TreeNode (hierarchical taxonomy)
  │     │     └── HallucinationReport
  │     ├── AuditJob → AuditAxisResult (×6 axes)
  │     ├── ChatConfig → Conversation → Message
  │     └── Report
  ├── AuditLog (immutable operations log)
  └── Feedback (user feedback)
```

## Models by App

### tenants/

| Model | Key Fields | Constraints |
|-------|-----------|-------------|
| **Tenant** | id (UUID), name, slug, max_documents, max_connectors | Primary workspace |
| **TenantMembership** | tenant, user, role, language | unique_together=(tenant, user) |
| **Project** | tenant, name, slug, description | unique_together=(tenant, slug) |
| **ProjectMembership** | project, user, role | unique_together=(project, user) |
| **AuditLog** | tenant, user, action, target_type, target_id, detail | Immutable, indexed |

**Abstract bases** :
- `TenantScopedModel` : ajoute FK `tenant` a tous les modeles de donnees
- `ProjectScopedModel` : ajoute FK `tenant` + `project`

### ingestion/

| Model | Key Fields | Status Values |
|-------|-----------|---------------|
| **Document** | tenant, project, connector, source_id, title, content_hash, status, word_count, chunk_count | PENDING → INGESTED → EMBEDDING → READY → ERROR → DELETED |
| **DocumentChunk** | document, chunk_index, content, token_count, heading_path, has_embedding | unique_together=(document, chunk_index) |
| **IngestionJob** | tenant, project, connector, status, total/processed/new/updated/deleted documents, celery_task_id | QUEUED → RUNNING → COMPLETED → FAILED |

### analysis/

| Model | Key Fields | Notes |
|-------|-----------|-------|
| **AnalysisJob** | project, status, current_phase (14 phases), progress_pct, config_overrides (JSON) | Checkpoint/resume par phase |
| **DuplicateGroup** | analysis_job, recommended_action | MERGE/DELETE_OLDER/REVIEW/KEEP |
| **DuplicatePair** | group, doc_a, doc_b, semantic_score, lexical_score, metadata_score, combined_score, verified | Scores ponderes + verification LLM |
| **Claim** | document, chunk, subject, predicate, object_value, qualifiers (JSON), claim_date | Triple S-P-O structure |
| **ContradictionPair** | analysis_job, claim_a, claim_b, classification, severity, confidence, resolution | CONTRADICTION/OUTDATED/ENTAILMENT/UNRELATED |
| **TopicCluster** | analysis_job, parent (self-FK), label, summary, key_concepts (JSON), level, doc_count | Hierarchique via parent |
| **ClusterMembership** | cluster, chunk, document, similarity_to_centroid | unique_together=(cluster, chunk) |
| **GapReport** | analysis_job, gap_type, title, severity, coverage_score, evidence (JSON) | 6 types de gaps |
| **TreeNode** | analysis_job, parent (self-FK), label, node_type, document, cluster, level | Taxonomie hierarchique |
| **HallucinationReport** | analysis_job, risk_type, term, expansions (JSON), severity | 6 types de risques |
| **AuditJob** | project, analysis_job (nullable), status, current_axis, overall_score, overall_grade (A-E) | 6 axes sequentiels |
| **AuditAxisResult** | audit_job, axis, score (0-100), metrics (JSON), chart_data (JSON) | unique_together=(audit_job, axis) |

### connectors/

| Model | Key Fields | Notes |
|-------|-----------|-------|
| **ConnectorConfig** | tenant, project, name, connector_type, enabled, config (JSON), credential_ref, schedule_cron | SHAREPOINT/CONFLUENCE/GENERIC |

### chat/

| Model | Key Fields | Notes |
|-------|-----------|-------|
| **ChatConfig** | project, user, system_prompt | unique_together=(project, user) |
| **Conversation** | project, user, title, tools (JSON) | Thread de messages |
| **Message** | conversation, role, content, sources (JSON), suggestions (JSON) | user/assistant |

### reports/

| Model | Key Fields | Notes |
|-------|-----------|-------|
| **Report** | project, analysis_job, report_type, format, title, summary, data (JSON) | DUPLICATES/CONTRADICTIONS/GAPS/FULL |

### dashboard/

| Model | Key Fields | Notes |
|-------|-----------|-------|
| **Feedback** | tenant, user, feedback_type, area, subject, description | FEEDBACK/ISSUE |

## Storage Strategy

| Type | Technology | File |
|------|-----------|------|
| Relational (ORM) | SQLite3 | `data/db.sqlite3` |
| Vector embeddings | sqlite-vec | `data/vec.sqlite3` |
| Semantic graph | FAISS + NetworkX (files) | `data/graph_dir/<project>/` |
| Media (uploads) | Filesystem | `media/` |
