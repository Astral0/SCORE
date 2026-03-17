# SCORE - Discovery Report

> **Generated**: 2026-03-17
> **Project**: SCORE (SCORE Curates Organizational Repository for Embeddings)
> **Version**: Current state (branch: fix/setuptools-packages)

---

## Executive Summary

**SCORE** est une plateforme enterprise d'analyse documentaire intelligente. Elle ingere des documents multi-sources (SharePoint, Confluence, fichiers locaux), extrait des claims structurees, detecte les contradictions et doublons, realise du clustering semantique, identifie les lacunes documentaires, et produit un audit qualite RAG selon 6 axes avec notation A-E (Nutri-Score style).

### Chiffres cles

| Metrique | Valeur |
|----------|--------|
| Stack backend | Django 5.1 + Python 3.12+ |
| Stack frontend | Django Templates + Bootstrap + HTMX + D3.js |
| Async | Celery 5.4 + Redis |
| LLM providers | OpenAI / Azure OpenAI / Azure Mistral |
| Vector store | sqlite-vec + FAISS |
| Modeles Django | 20+ |
| Apps Django | 9 (tenants, connectors, ingestion, vectorstore, analysis, reports, dashboard, chat) |
| Endpoints HTTP | 50+ |
| Phases d'analyse | 14 (8 analysis + 6 audit) |
| Axes d'audit RAG | 6 (hygiene, structure, coverage, coherence, retrievability, governance) |

---

## Table of Contents

1. [Architecture Overview](./architecture.md)
2. [Data Model](./data_model.md)
3. [LLM Integration](./llm_integration.md)
4. [Ingestion Pipeline](./ingestion_pipeline.md)
5. [Analysis Engine](./analysis_engine.md)
6. [RAG Audit System](./audit_system.md)
7. [Frontend & UI](./frontend.md)
8. [Multi-Tenant Architecture](./multi_tenant.md)
9. [External Connectors](./connectors.md)
10. [Chat Assistant](./chat_assistant.md)
11. [Configuration & Deployment](./configuration.md)
12. [Dependencies](./dependencies.md)
13. [Test Coverage](./test_coverage.md)
14. [Recommendations](./recommendations/)
    - [Architecture](./recommendations/architecture.md)
    - [Performance](./recommendations/performance.md)
    - [Security](./recommendations/security.md)

---

## Quick Navigation

### By Role

| Role | Start Here |
|------|------------|
| Developpeur backend | [Architecture](./architecture.md) → [Data Model](./data_model.md) → [Analysis Engine](./analysis_engine.md) |
| Developpeur frontend | [Frontend & UI](./frontend.md) |
| DevOps / SRE | [Configuration & Deployment](./configuration.md) |
| Product Owner | [Executive Summary](#executive-summary) → [Recommendations](./recommendations/) |
| Data Scientist | [LLM Integration](./llm_integration.md) → [Analysis Engine](./analysis_engine.md) |

### By Feature

| Feature | Documentation |
|---------|---------------|
| Ingestion documents | [Ingestion Pipeline](./ingestion_pipeline.md) |
| Detection doublons | [Analysis Engine](./analysis_engine.md#phase-1-duplicates) |
| Detection contradictions | [Analysis Engine](./analysis_engine.md#phase-7-contradictions) |
| Clustering semantique | [Analysis Engine](./analysis_engine.md#phase-4-clustering) |
| Audit qualite RAG | [RAG Audit System](./audit_system.md) |
| Chat assistant | [Chat Assistant](./chat_assistant.md) |
| Multi-tenant | [Multi-Tenant Architecture](./multi_tenant.md) |
