# ADR-003: Abstraction LLM multi-provider

## Status
Accepted

## Context
SCORE depend fortement des LLM pour l'analyse documentaire. Les organisations peuvent avoir des contraintes de provider (OpenAI, Azure, Mistral) et les APIs evoluent rapidement.

## Decision
Implementer un `LLMClient` unifie dans `llm/client.py` qui abstrait les differences entre providers et fournit rate limiting, fallback, et batch API.

## Consequences

### Positif
- Changement de provider transparent pour le code metier
- Rate limiting et fallback integres
- Batch API pour optimiser les couts sur gros volumes
- Pipeline tracing pour debugger les appels LLM
- Temperature handling automatique pour modeles incompatibles

### Negatif
- Couche d'abstraction a maintenir lors de nouvelles APIs
- Certaines features provider-specifiques ne sont pas exposees
- Complexite du fallback chain

### Risques
- Si un provider change son API de facon majeure, l'abstraction doit etre mise a jour
- Le batch API n'est pas supporte par tous les providers
