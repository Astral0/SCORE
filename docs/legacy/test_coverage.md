# Test Coverage

## Test Framework

| Tool | Usage |
|------|-------|
| pytest | Test runner |
| pytest-django | Django integration |
| pytest-asyncio | Async test support |
| factory-boy | Model fixtures |
| faker | Test data generation |

## Test Files

| File | Coverage |
|------|----------|
| `tests/test_models.py` | Creation modeles, FK relationships |
| `tests/test_claims_extractor.py` | Extraction claims S-P-O |
| `tests/test_clustering_engine.py` | Clustering HDBSCAN |
| `tests/test_audit_views.py` | UI endpoints audit |
| `tests/test_analysis_views.py` | UI endpoints analysis |
| `tests/test_connectors_views.py` | UI endpoints connectors |
| `tests/test_reports_views.py` | Generation rapports |
| `tests/test_tenant_isolation.py` | Isolation multi-tenant |
| `tests/test_csp_middleware.py` | Headers CSP |
| `tests/nsg/test_*.py` | Semantic graph |

## Commands

```bash
# All tests
pytest tests/ -v

# Specific module
pytest tests/test_llm_client.py -v

# Coverage report
pytest tests/ --cov=. --cov-report=term-missing
pytest tests/ --cov=. --cov-report=html
```

## Areas Covered

- Model creation and relationships
- View endpoints (status codes, permissions)
- Business logic (claims extraction, clustering)
- Middleware (CSP, tenant)
- Multi-tenant isolation
- Report generation

## Areas to Improve

- Pipeline integration tests (ingestion end-to-end)
- LLM client mock tests (rate limiting, fallback)
- Celery task tests (async workflow)
- Connector tests (SharePoint, Confluence mocks)
- Chat assistant tests
- D3.js visualization tests (if applicable)
