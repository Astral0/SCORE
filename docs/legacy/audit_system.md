# RAG Audit System

## Overview

Systeme d'evaluation de la qualite d'un corpus documentaire pour usage RAG (Retrieval-Augmented Generation). Notation A-E style Nutri-Score sur 6 axes independants.

## 6 Axes d'Audit

```text
┌─────────────────────────────────────────────────────┐
│                   AUDIT SCORE (A-E)                  │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ HYGIENE  │ │STRUCTURE │ │COVERAGE  │            │
│  │  (0-100) │ │  (0-100) │ │  (0-100) │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │COHERENCE │ │RETRIEV.  │ │GOVERNANCE│            │
│  │  (0-100) │ │  (0-100) │ │  (0-100) │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                      │
│  Overall = Weighted average → Grade A/B/C/D/E       │
└─────────────────────────────────────────────────────┘
```

### Axe 1 : Hygiene (60-67%)

**Objectif** : Qualite de base du corpus (doublons, boilerplate).

**Metriques** :
- Taux de deduplication (MinHash)
- Frequence de contenu boilerplate
- Qualite de l'extraction texte

### Axe 2 : Structure (67-73%)

**Objectif** : Qualite du decoupage en chunks.

**Metriques** :
- Distribution taille tokens par chunk (optimal : 80-1024)
- Chunks trop petits / trop grands
- Coherence heading_path

### Axe 3 : Coverage (73-80%)

**Objectif** : Couverture thematique du corpus.

**Metriques** :
- Diversite TF-IDF
- Decomposition SVD / topic modeling
- Lacunes identifiees

### Axe 4 : Coherence (80-87%)

**Objectif** : Consistance terminologique.

**Metriques** :
- Frequence termes
- Similarite Levenshtein (variantes orthographiques)
- Contradictions terminologiques

### Axe 5 : Retrievability (87-93%)

**Objectif** : Capacite de retrouver l'information pertinente.

**Metriques** :
- BM25 recall sur queries de test
- Taux de reponse aux questions generees
- Qualite des embeddings

### Axe 6 : Governance (93-100%)

**Objectif** : Gouvernance documentaire.

**Metriques** :
- Completude des metadonnees (auteur, date, source)
- Fraicheur des documents (staleness_days)
- Champs obligatoires presents

## Grading

| Grade | Score | Signification |
|-------|-------|---------------|
| A | 80-100 | Excellent - corpus pret pour RAG |
| B | 60-79 | Bon - ameliorations mineures |
| C | 40-59 | Moyen - ameliorations significatives necessaires |
| D | 20-39 | Insuffisant - problemes majeurs |
| E | 0-19 | Critique - corpus inadapte au RAG |

## Data Model

```text
AuditJob
  ├── status: QUEUED → RUNNING → COMPLETED/FAILED
  ├── current_axis: hygiene → ... → governance → done
  ├── overall_score: 0-100
  ├── overall_grade: A-E
  └── AuditAxisResult (×6)
        ├── axis: hygiene/structure/coverage/coherence/retrievability/governance
        ├── score: 0-100
        ├── metrics: JSON
        ├── chart_data: JSON (pre-computed pour D3.js)
        └── details: JSON
```

## UI

- Dashboard avec radar chart (6 axes)
- Detail par axe avec metriques et graphiques D3.js
- Comparaison entre audits successifs
