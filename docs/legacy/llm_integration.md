# LLM Integration

## Architecture

```text
┌─────────────────────────────────────────┐
│             LLMClient                    │
│  (llm/client.py)                        │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
│  │ OpenAI  │ │  Azure  │ │  Azure    │ │
│  │  API    │ │ OpenAI  │ │  Mistral  │ │
│  └────┬────┘ └────┬────┘ └─────┬─────┘ │
│       └───────────┼────────────┘        │
│              Unified API                 │
│  - chat(messages, model, temperature)   │
│  - embed(texts) → vectors              │
│  - batch_submit(prompts) → results     │
└─────────────────────────────────────────┘
```

## Providers

| Provider | Chat | Embeddings | Config Env Vars |
|----------|------|-----------|-----------------|
| **openai** | OpenAI API | OpenAI API | `OPENAI_API_KEY` |
| **azure** | Azure OpenAI | Azure OpenAI | `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT`, deployment names |
| **azure_mistral** | Azure AI Foundry (Mistral) | Azure OpenAI | `AZURE_MISTRAL_ENDPOINT/API_KEY` + Azure embedding vars |

## Key Features

### Rate Limiting & Retry
- `requests_per_minute` configurable (default 500)
- Exponential backoff on HTTP 429
- Token bucket pattern

### Fallback Models
- Chain de modeles de fallback sur rate-limit
- Configuration : `fallback_models: [model_a, model_b]`
- `fallback_retries_per_model: 1` retries par modele

### Batch API
- Pour operations couteuses (>= 10 prompts)
- Soumission asynchrone via OpenAI Batch API
- Polling avec `batch_poll_interval_seconds` et `batch_max_wait_seconds`

### Temperature Handling
- Detection automatique des modeles incompatibles (o1, o3, GPT-5)
- Fallback silencieux si temperature non supportee

### Pipeline Tracing
- Collecteur optionnel pour logging des appels LLM
- Tracabilite complete : prompt, response, tokens, duree

## Configuration (config.yaml)

```yaml
llm:
  provider: openai
  chat_model: C2-Cloud-Gemini-2.5-Pro
  embedding_model: bge-m3-custom-fr
  embedding_dimensions: 1024
  requests_per_minute: 500
  embedding_batch_size: 500
  fallback_models: [C2-Cloud-Gemini-2.5-Flash]
  fallback_retries_per_model: 1
  batch_model: ""
  batch_poll_interval_seconds: 1
  batch_max_wait_seconds: 1800
```

## Usage in Codebase

| Module | Usage LLM |
|--------|-----------|
| `analysis/claims.py` | Extraction claims S-P-O (chat) |
| `analysis/contradictions.py` | Classification contradiction/outdated (chat) |
| `analysis/duplicates.py` | Verification cross-encoder (chat) |
| `analysis/clustering.py` | Generation labels/summaries clusters (chat) |
| `analysis/gaps.py` | Generation questions + evaluation couverture (chat) |
| `analysis/hallucination.py` | Detection risques (chat) |
| `analysis/audit/*.py` | Evaluation axes RAG (chat) |
| `ingestion/pipeline.py` | Generation embeddings (embed) |
| `chat/views.py` | Chat assistant RAG (chat + embed pour search) |
| `nsg/concepts.py` | Extraction concepts (spaCy, pas LLM) |
