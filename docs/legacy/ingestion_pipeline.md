# Ingestion Pipeline

## Pipeline Overview

```text
ConnectorConfig (source definition)
       │
       ▼
┌──────────────────┐
│  1. DETECTION    │ list_changed_documents()
│  (incremental)   │ Compare content_hash + source_version
└────────┬─────────┘
         │ new/updated docs
         ▼
┌──────────────────┐
│  2. EXTRACTION   │ PDF, DOCX, PPTX, HTML, Markdown
│  (text + meta)   │ → ExtractedDocument
└────────┬─────────┘
         │ raw text + heading hierarchy
         ▼
┌──────────────────┐
│  3. CHUNKING     │ heading_aware or token_fixed
│  (segments)      │ chunk_size=1024, overlap=32
└────────┬─────────┘
         │ DocumentChunk records
         ▼
┌──────────────────┐
│  4. HASHING      │ SHA-256 content hash
│  (dedup)         │ Skip unchanged documents
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  5. EMBEDDING    │ LLMClient.embed(texts)
│  (vectorize)     │ Batch size: 500
└────────┬─────────┘
         │ vectors
         ▼
┌──────────────────┐
│  6. STORAGE      │ ORM: Document, DocumentChunk
│  (persist)       │ sqlite-vec: embeddings
└──────────────────┘
```

## Extraction Formats

| Format | Library | Notes |
|--------|---------|-------|
| PDF | pypdf | Extraction texte, pas d'OCR |
| DOCX | python-docx | Preserves heading hierarchy |
| PPTX | python-pptx | Slide par slide |
| HTML | BeautifulSoup4 | Nettoyage balises |
| Markdown | markdown lib | Conversion vers texte |

## Chunking Strategies

### heading_aware (default)
- Respecte la hierarchie des titres (H1 > H2 > H3)
- `heading_path` : "Chapitre 1 > Section 2 > Sous-section A"
- Contexte preserve pour le RAG

### token_fixed
- Decoupage fixe par nombre de tokens
- `chunk_size: 1024`, `chunk_overlap: 32`
- `min_chunk_size: 80` (rejette les fragments trop petits)

## Document Status Lifecycle

```text
PENDING → INGESTED → EMBEDDING → READY
    │         │          │
    └─────────┴──────────┴──→ ERROR
                                │
                                └──→ (retry possible)

READY → DELETED (soft delete on source removal)
```

## Celery Task: run_ingestion

- **Trigger** : UI (bouton sync) ou cron (ConnectorConfig.schedule_cron)
- **Retries** : max 2, delai 60s
- **Progress** : IngestionJob.processed_documents incremente par document
- **Error handling** : Erreurs par document loggees, pipeline continue
- **Incremental** : Seuls les documents nouveaux/modifies sont traites
