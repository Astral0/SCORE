# Analysis Engine

## Pipeline Overview (14 Phases)

```text
Phase  Progress  Module                 Output
─────  ────────  ─────────────────────  ─────────────────────
  1     0-10%    duplicates.py          DuplicateGroup, DuplicatePair
  2    10-16%    claims.py              Claim (S-P-O triples)
  3    16-22%    semantic_graph.py      FAISS index + NetworkX graph
  4    22-32%    clustering.py          TopicCluster, ClusterMembership
  5    32-40%    gaps.py                GapReport
  6    40-48%    tree.py                TreeNode (taxonomy)
  7    48-55%    contradictions.py      ContradictionPair
  8    55-60%    hallucination.py       HallucinationReport
  9    60-67%    audit/hygiene.py       AuditAxisResult (hygiene)
 10    67-73%    audit/structure.py     AuditAxisResult (structure)
 11    73-80%    audit/coverage.py      AuditAxisResult (coverage)
 12    80-87%    audit/coherence.py     AuditAxisResult (coherence)
 13    87-93%    audit/retrievability.py AuditAxisResult (retrievability)
 14    93-100%   audit/governance.py    AuditAxisResult (governance)
```

## Phase 1: Duplicates (0-10%)

**Objectif** : Detecter les documents en double ou quasi-identiques.

**Algorithme** :
1. Similarite semantique : cosine distance sur embeddings
2. Similarite lexicale : MinHash Jaccard (datasketch)
3. Similarite metadata : correspondance titre/auteur/path
4. Combinaison ponderee → candidats au-dessus du seuil
5. Verification LLM : cross-encoder sur top candidats

**Seuils** (config.yaml) :
- `semantic_threshold: 0.92`
- `combined_threshold: 0.80`

**Output** : DuplicateGroup + DuplicatePair avec scores et evidence

## Phase 2: Claims (10-16%)

**Objectif** : Extraire des assertions structurees de chaque chunk.

**Format** : Triple Subject-Predicate-Object + qualifiers + date
- Exemple : "Le serveur [sujet] supporte [predicat] 1000 connexions simultanees [objet]"

**Methode** : Prompt LLM sur chaque chunk → parsing JSON
**Idempotent** : Skip les chunks deja traites

## Phase 3: Semantic Graph (16-22%)

**Objectif** : Construire un graphe de concepts interconnectes.

**Stack** :
- spaCy (fr_core_news_sm) : extraction concepts
- NetworkX : construction graphe
- FAISS : indexation similarite

**Persistence** : Fichiers dans `data/graph_dir/<project_id>/`

## Phase 4: Clustering (22-32%)

**Objectif** : Regrouper documents et chunks par theme.

**Algorithme** :
1. HDBSCAN sur embeddings chunks (ou k-means)
2. Subclustering hierarchique si cluster >= 10 elements
3. LLM genere label + summary + key_concepts par cluster

**Output** : TopicCluster (hierarchique via parent FK) + ClusterMembership

## Phase 5: Gaps (32-40%)

**Objectif** : Identifier les lacunes documentaires.

**Types de gaps** :
| Type | Description |
|------|-------------|
| MISSING_TOPIC | Sujet non couvert |
| LOW_COVERAGE | Couverture insuffisante |
| STALE_AREA | Zone obsolete |
| ORPHAN_TOPIC | Topic isole |
| WEAK_BRIDGE | Lien faible entre topics |
| CONCEPT_ISLAND | Concept isole sans contexte |

**Methode** : LLM genere des questions de couverture par cluster → evalue si reponses existent

## Phase 6: Tree (40-48%)

**Objectif** : Construire une taxonomie hierarchique documents/clusters.

**Structure** : Root → Categories → Clusters → Documents → Sections
**Output** : TreeNode avec self-FK parent

## Phase 7: Contradictions (48-55%)

**Objectif** : Detecter les claims contradictoires.

**Algorithme** :
1. KNN search sur embeddings claims (claims similaires)
2. LLM evalue chaque paire : CONTRADICTION / OUTDATED / ENTAILMENT / UNRELATED
3. Severity : HIGH / MEDIUM / LOW + score de confiance

**Seuils** :
- `confidence_threshold: 0.75`
- `staleness_bias: true` (prefere les docs recents)

## Phase 8: Hallucination (55-60%)

**Objectif** : Identifier les risques d'hallucination pour un systeme RAG.

**Types de risques** :
| Type | Description |
|------|-------------|
| UNDEFINED_ACRONYM | Acronyme jamais defini |
| AMBIGUOUS_ACRONYM | Acronyme avec plusieurs significations |
| CONFLICTING_ACRONYM | Definitions contradictoires |
| JARGON_NO_CONTEXT | Jargon technique sans explication |
| HEDGING_LANGUAGE | Langage incertain ("peut-etre", "environ") |
| IMPLICIT_KNOWLEDGE | Connaissances implicites non documentees |

## Checkpoint/Resume

- `AnalysisJob.current_phase` : phase courante pour reprise
- Cleanup des resultats partiels avant re-execution d'une phase
- Recovery automatique au demarrage worker (jobs RUNNING → QUEUED → re-dispatch)

## Celery Tasks

| Task | Description |
|------|-------------|
| `run_unified_pipeline` | Pipeline complet (14 phases) avec checkpoint |
| `run_analysis` | Legacy : phases analysis seules (sans audit) |
