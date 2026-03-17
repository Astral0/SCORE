# Analyse concurrentielle de SCORE — Mars 2026

## Positionnement unique de SCORE

SCORE occupe une **niche actuellement non contestee** : l'audit qualite d'un corpus documentaire **en amont** du RAG. Le marche est structure en 3 couches, et SCORE est seul sur la premiere :

```
┌─────────────────────────────────────────────────────┐
│  1. QUALITE DU CORPUS (pre-ingestion)               │  ← SCORE est ICI, seul
│     Doublons, contradictions, lacunes, clustering,   │
│     note globale A-E                                 │
├─────────────────────────────────────────────────────┤
│  2. TRAITEMENT / INGESTION                           │  ← Unstructured, Docling, LlamaParse
│     Parsing, chunking, extraction, ETL               │
├─────────────────────────────────────────────────────┤
│  3. EVALUATION DU PIPELINE RAG (post-deploiement)   │  ← Ragas, DeepEval, LangSmith, etc.
│     Faithfulness, relevance, hallucination runtime   │
└─────────────────────────────────────────────────────┘
```

**Aucun outil** ne combine detection de doublons semantiques + extraction de claims + detection de contradictions + analyse de lacunes + clustering + score qualite global. C'est le differenciateur fondamental de SCORE.

---

## Table des matieres

- [A. Outils d'evaluation RAG (couche 3)](#a-outils-devaluation-rag-couche-3--post-deploiement)
- [B. Outils de traitement documentaire (couche 2)](#b-outils-de-traitement-documentaire-couche-2--ingestion)
- [C. Outils les plus proches de SCORE](#c-outils-les-plus-proches-de-score-chevauchement-partiel)
- [D. Initiatives francaises / secteur public](#d-initiatives-francaises--secteur-public)
- [Synthese : forces et faiblesses de SCORE](#synthese--forces-et-faiblesses-de-score)
- [Recommandations pour le positionnement](#recommandations-pour-le-positionnement)
- [Sources](#sources)

---

## A. Outils d'evaluation RAG (couche 3 — post-deploiement)

Ces outils evaluent la **sortie** du pipeline RAG, pas la qualite des documents sources. Ils repondent a "mon pipeline RAG fonctionne-t-il bien ?". SCORE repond a "mes documents sont-ils fiables **avant** d'alimenter un RAG ?".

### Langfuse

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 23.2k |
| **Licence** | MIT |
| **Prix** | Gratuit / Pro 59$/mo |
| **Fonde** | 2023 (YC W23), Series A |
| **Ce que ca fait** | Plateforme d'observabilite LLM open source la plus populaire. Tracing OpenTelemetry, evaluateurs LLM-as-judge, gestion de prompts, datasets & experiences. Framework-agnostic. |
| **Forces** | Le + populaire en OSS, UI soignee, tarification a l'unite |
| **Faiblesses** | Pas de HITL natif, pas de workflows RGPD |
| **Audit corpus ?** | Non — observabilite pipeline uniquement |

### Opik (Comet)

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 18.3k |
| **Licence** | Apache 2.0 |
| **Prix** | 100% gratuit OSS |
| **Fonde** | 2024 (Comet, 70M$ de financement) |
| **Ce que ca fait** | Framework d'evaluation LLM veritablement open source. LLM-as-judge, detection d'hallucinations, evaluation RAG, integration pytest. |
| **Forces** | Vrai OSS sans feature-gate, fonctionnalites completes |
| **Faiblesses** | Plus jeune entrant, ecosysteme plus petit |
| **Audit corpus ?** | Non |

### DeepEval (Confident AI)

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 14.1k |
| **Licence** | Apache 2.0 |
| **Prix** | Gratuit / Cloud 30-80$/user/mo |
| **Fonde** | 2023 (YC), 2.2M$ seed |
| **Ce que ca fait** | Framework d'evaluation LLM pytest-compatible avec 50+ metriques (RAG triad, G-Eval, hallucination, toxicite, biais, agentic, conversationnel). Red-teaming, generation de datasets synthetiques, CI/CD. |
| **Forces** | 50+ metriques, pytest-natif, scores auto-explicatifs, 3M+ telechargements/mois. Utilise par BCG, AstraZeneca, Mercedes-Benz |
| **Faiblesses** | Dashboard cloud moins mature que LangSmith |
| **Audit corpus ?** | Non — evalue la sortie du pipeline RAG |

### Ragas

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 13k |
| **Licence** | Apache 2.0 |
| **Prix** | Gratuit (OSS uniquement) |
| **Fonde** | 2023 (YC), papier arXiv, presente a EACL 2024 |
| **Ce que ca fait** | Framework de reference pour l'evaluation RAG. Metriques : faithfulness, answer relevancy, context precision, context recall. Generation de donnees de test synthetiques par knowledge-graph. |
| **Forces** | Reference academique, 4.7M+ evaluations/mois, utilise par AWS, Microsoft, Databricks |
| **Faiblesses** | NaN frequents (JSON invalide du LLM juge), peu de metriques hors RAG, difficile a debugger |
| **Audit corpus ?** | Non |

### Arize Phoenix

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 8.9k |
| **Licence** | Elastic License 2.0 (ELv2) |
| **Prix** | Gratuit / Pro 50$/mo |
| **Fonde** | 2020, 131M$ (Series C fev 2025, avec Microsoft M12, Datadog) |
| **Ce que ca fait** | Plateforme d'observabilite IA. Tracing OpenTelemetry, visualisations d'embeddings pour debugger le retrieval, evaluateurs LLM-as-judge, gestion de prompts. |
| **Forces** | Visualisations d'embeddings uniques, deploiement single-container, partenaire officiel Google ADK |
| **Faiblesses** | Licence ELv2 (pas MIT/Apache — interdit de proposer en SaaS), UI moins polie |
| **Audit corpus ?** | Non — observabilite runtime |

### Evidently AI

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 7.3k |
| **Licence** | Apache 2.0 |
| **Prix** | Gratuit + Cloud |
| **Fonde** | 2020 (YC), 1.1M$ seed |
| **Ce que ca fait** | Monitoring ML+LLM. 100+ metriques couvrant data drift, evaluation LLM, evaluation RAG (context relevance, faithfulness). Test Suites pour CI/CD via GitHub Actions. |
| **Forces** | Couvre ML classique ET LLM, integration CI/CD |
| **Faiblesses** | Plus monitoring que plateforme d'evaluation |
| **Audit corpus ?** | Non |

### TruLens (Snowflake)

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | 3.2k |
| **Licence** | MIT |
| **Prix** | Gratuit |
| **Fonde** | 2019 (CMU), racheté par Snowflake mai 2024 (42.3M$ leves au total) |
| **Ce que ca fait** | Framework d'evaluation et tracing pour apps LLM. "Feedback functions" pour evaluation programmatique. RAG Triad (context relevance, groundedness, answer relevance). Traces OpenTelemetry. |
| **Forces** | Transparent, auditable, integration Snowflake |
| **Faiblesses** | Croissance ralentie post-acquisition, moins de features qu'DeepEval |
| **Audit corpus ?** | Non |

### LangSmith (LangChain)

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | Ferme (proprietaire) |
| **Licence** | Proprietaire |
| **Prix** | Gratuit / Plus 39$/user/mo / Enterprise custom |
| **Fonde** | 2022, 160M$ leves, valorisation 1.25Md$, CA 16M$ en 2025 |
| **Ce que ca fait** | Plateforme complete d'observabilite, evaluation et experimentation LLM. Tracing hierarchique, annotation humaine, LLM-as-judge, datasets & experiments, gestion de prompts, dashboards custom. |
| **Forces** | UI la plus polie du marche, leader par adoption, BYOC et self-hosted |
| **Faiblesses** | Perception de vendor lock-in LangChain, 2 vulnerabilites securite en 2025 (AgentSmith, CVE-2026-25750 — corrigees) |
| **Audit corpus ?** | Non |

### Braintrust

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | Ferme (proprietaire) |
| **Licence** | Proprietaire |
| **Prix** | Gratuit / Pro 249$/mo / Enterprise custom |
| **Fonde** | 2023, 121M$ (Series B fev 2026), valorisation 800M$ |
| **Ce que ca fait** | Plateforme d'observabilite IA production. Inspection de traces, gestion d'experiences, comparaison de prompts cote-a-cote, scoring par revue humaine, detection de regressions CI. |
| **Forces** | Clients premium (Notion, Stripe, Vercel, Airtable, Instacart), A/B testing |
| **Faiblesses** | Cher (249$/mo), pas open source |
| **Audit corpus ?** | Non |

### Galileo

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | Ferme (SDK uniquement) |
| **Licence** | Proprietaire |
| **Prix** | Gratuit (5k traces/mo) / Enterprise (non public) |
| **Fonde** | 2021, 68M$ (Series B oct 2024), 834% croissance CA en 2024 |
| **Ce que ca fait** | Plateforme enterprise d'evaluation GenAI. Modeles d'evaluation proprietaires (EFMs / Luna-2) — petits modeles specialises pour l'evaluation. Couvre RAG, agents, guardrails, hallucinations. |
| **Forces** | EFMs moins cher que GPT-4-as-judge, clients Fortune 50 (HP, Twilio, Reddit) |
| **Faiblesses** | Pricing opaque, peu d'engagement OSS |
| **Audit corpus ?** | Non |

### Patronus AI

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | Ferme (proprietaire) |
| **Licence** | Proprietaire |
| **Prix** | Enterprise |
| **Fonde** | 2023, 20M$ (Series A mai 2024, Lightspeed, Datadog) |
| **Ce que ca fait** | Plateforme d'evaluation IA orientee recherche. Modeles d'evaluation custom, benchmarks sectoriels (FinanceBench, EnterpriseBench), detection d'hallucinations. |
| **Forces** | Approche recherche, benchmarks specialises finance/sante |
| **Faiblesses** | Niche enterprise, peu de donnees publiques d'adoption |
| **Audit corpus ?** | Non |

### Quotient AI (Databricks)

| Attribut | Detail |
|----------|--------|
| **Stars GitHub** | N/A (rachete) |
| **Licence** | Proprietaire → integre Databricks/MLflow |
| **Prix** | Integration Databricks |
| **Fonde** | 2023, bootstrappe, rachete par Databricks mars 2026 |
| **Ce que ca fait** | Evaluation d'agents IA sur traces de production completes. Detecte hallucinations, erreurs de raisonnement, mauvaise utilisation d'outils. Clustering des signaux en datasets d'evaluation. |
| **Forces** | Equipe ex-GitHub Copilot eval, analyse de trajectoires d'agents completes |
| **Faiblesses** | Futur incertain en standalone, integration MLflow en cours |
| **Audit corpus ?** | Non |

---

## B. Outils de traitement documentaire (couche 2 — ingestion)

Ces outils convertissent et preparent les documents. Ils sont **complementaires** a SCORE, pas concurrents.

| Outil | Stars GitHub | Licence | Prix | Ce que ca fait | Pertinence vs SCORE |
|-------|:-----------:|---------|------|----------------|:-------------------:|
| **RAGFlow** (InfiniFlow) | ~70k | OSS | Gratuit | Moteur RAG avec DeepDoc pour preprocessing, chunking semantique. Philosophie "Quality In, Quality Out". | Complementaire (ingestion RAG) |
| **Docling** (IBM) | ~55k | MIT (LF AI) | Gratuit | Conversion PDF/DOCX/PPTX/HTML vers formats structures. Modele vision Granite-Docling-258M. Integre avec LangChain, LlamaIndex, spaCy. | Complementaire (parsing) |
| **LlamaIndex** | ~42.5k | MIT | Gratuit / LlamaCloud credits | Framework RAG complet, 20+ formats. Deduplication basique par doc_id. LlamaParse pour PDF avances. | Complementaire (framework). Dedup triviale vs SCORE |
| **Haystack** (deepset) | ~24k | Apache 2.0 | Gratuit / Cloud | Framework RAG modulaire, integration RAGAS pour evaluation. Pipeline retrieval/indexing/evaluation. | Complementaire (framework) |
| **Unstructured.io** | ~14k | Apache 2.0 | Gratuit / Pay-as-you-go | Standard industriel pour ETL documentaire. 25+ formats. Partitioning, cleaning, chunking. | Complementaire (ETL). Ne fait aucun audit qualite |
| **LlamaParse** | Cloud | Proprietaire | Credits | Parsing PDF avance (tableaux imbriques, images, skew detection). | Complementaire (parsing) |

**Verdict** : SCORE audite → ces outils ingerent. Enchainement naturel.

---

## C. Outils les plus proches de SCORE (chevauchement partiel)

### Matrice de fonctionnalites

| Outil | Doublons | Contradictions | Lacunes | Clustering | Score global | OSS | Prix |
|-------|:--------:|:--------------:|:-------:|:----------:|:------------:|:---:|------|
| **SCORE** | Oui (semantique + MinHash + LLM) | Oui (claims + LLM) | Oui (QG/RAG + orphelins) | Oui (HDBSCAN) | Oui (A-E) | Oui (Apache 2.0) | Gratuit |
| **Microsoft Purview** | Oui (near-duplicate) | Non | Non | Non | Non (pass/fail regles) | Non | 30$/user/mo + Azure |
| **Glean** | Oui (semantique) | Non | Non | Non | Non | Non | Enterprise (valo 4.6Md$) |
| **Cleanlab** | Oui (data-level) | Non | Non | Non | Par datapoint | Oui (MIT) | Gratuit + Enterprise (rachete jan 2026) |
| **Vectara** (HHEM) | Non | Non | Non | Non | Par reponse | Partiel | Des 100k$/an |
| **Contextual AI** (GLM) | Non | Non | Non | Non | Par reponse (factualite) | Non | Custom |
| **RagScore** (HZYAI) | Non | Non | Non | Non | Score pipeline | Oui | Gratuit |
| **RAG Corpus Profiler** | Oui (semantique) | Non | Oui (basique) | Non | Non | Oui | Gratuit |

### Analyses detaillees des plus proches

#### Microsoft Purview / SharePoint Document Processing

Le concurrent le plus credible sur le papier :
- **Detection near-duplicate** de documents dans SharePoint
- **Classification IA** et tagging automatique
- **Regles de qualite** personnalisables
- **Gouvernance** : retention, records management, eDiscovery

Mais des differences fondamentales :
- Focus **gouvernance/compliance**, pas RAG-readiness
- **Pas de detection de contradictions** ni d'analyse de lacunes
- **Pas de score qualite holistique** (pass/fail par regle, pas de note A-E)
- Proprietaire, couteux, ecosysteme Microsoft obligatoire
- Ne comprend pas les concepts de claims, clustering thematique ou graphe semantique

#### Glean

- Plateforme de recherche enterprise IA (valorisee 4.6Md$)
- **Detection de doublons semantiques** et fuzzy matching cross-plateformes
- Mais : pas open source, pas de score qualite, pas de contradictions, pas d'analyse de lacunes
- Inaccessible pour la plupart des organisations (prix enterprise)

#### Cleanlab

- Detection de doublons, outliers et problemes de qualite dans les datasets
- **Rachete par Handshake en janvier 2026** (talent acquisition) — futur incertain
- Cible la qualite des **donnees d'entrainement ML** (labels, annotations), pas les corpus documentaires
- Pas de contradictions, pas de lacunes, pas de clustering documentaire

#### RAG Corpus Profiler

- Le plus proche conceptuellement : scan PII, doublons semantiques, bruit, lacunes de couverture
- Mais : script CLI minimaliste, pas de UI, pas de multi-tenant, pas de contradictions, pas de scoring, pas de connecteurs (SharePoint, Confluence)
- Projet individuel avec traction limitee

#### Vectara

- HHEM (Hallucination Evaluation Model) pour detecter les sorties infideles du LLM
- Mockingbird LLM optimise pour la generation ancree avec citations
- Detecte les hallucinations dans les **sorties RAG** (post-generation), pas dans le corpus source
- Tres cher (des 100k$/an)

#### Contextual AI

- Grounded Language Model (GLM) : 88% de factualite sur FACTS benchmark
- Fonde par les pionniers du RAG (ex-FAIR/HuggingFace), 100M$ leves
- Optimise la **generation** RAG, pas la qualite du corpus en amont
- Pas de fonctionnalites d'audit documentaire

---

## D. Initiatives francaises / secteur public

| Initiative | Organisme | Description | Pertinence vs SCORE |
|-----------|-----------|-------------|:-------------------:|
| **Albert** | DINUM / Etalab | Agent conversationnel souverain (Mistral/LLaMA) pour l'administration | Different (chatbot, pas audit qualite) |
| **La Suite Numerique** | DINUM | Suite bureautique souveraine avec IA (Mistral), SecNumCloud | Different (bureautique) |
| **Banque des Territoires x HuggingFace** | CDC groupe | RAG souverain pour EduRenov (renovation ecoles) | Different (use-case specifique) |
| **Numspot** | BdT + Docaposte + Dassault | Cloud souverain (infra) | Different (infrastructure) |
| **Panorama IA DINUM** (AMI 2025) | DINUM | ~100 solutions IA selectionnees pour les administrations | Aucune ne couvre l'audit qualite de corpus |

**Aucune initiative publique francaise** ne couvre le creneau de SCORE. C'est un avantage strategique pour le positionner comme brique souveraine de reference.

---

## Synthese : forces et faiblesses de SCORE

### Forces

| Force | Detail |
|-------|--------|
| **Niche incontestee** | Seul outil combinant les 5 dimensions d'audit corpus (doublons, contradictions, lacunes, clustering, score) |
| **Open source Apache 2.0** | Aucune restriction, deployable partout, pas de feature-gate |
| **Stack pragmatique** | Django + SQLite + sqlite-vec = deploiement simple, pas de dependance lourde (pas de Postgres, pas d'Elastic) |
| **Algorithmes solides** | MinHash LSH, HDBSCAN, BM25, FAISS, graphe semantique NetworkX, TF-IDF/SVD/NMF |
| **Multi-connecteurs** | SharePoint, Confluence, fichiers locaux, HTTP |
| **Metaphore Nutri-Score** | Communication efficace aupres des decideurs non-techniques |
| **Souverainete** | Origine service public francais, hebergeable on-premise |
| **Audit RAG sans LLM** | Les 6 axes d'audit sont 100% deterministes (pas de cout LLM pour l'audit) |
| **Multi-tenant** | Isolation par organisation native |
| **Chat RAG integre** | Permet de tester directement la qualite du referentiel |

### Faiblesses / risques

| Point | Detail |
|-------|--------|
| **Maturite** | 5 jours d'existence publique, v0.1.0, 1 contributeur, 1 star |
| **Communaute** | Zero traction externe, pas de blog post d'annonce, pas de Discussions GitHub activees |
| **Dependance LLM** | L'analyse (claims, contradictions, clustering labels) necessite OpenAI/Azure — cout et latence |
| **SQLite en prod** | Limites de concurrence pour de gros deploiements multi-utilisateurs |
| **Pas de release** | Aucun tag de version publie sur GitHub |
| **Documentation mixte** | README en anglais mais docs techniques en francais — peut limiter l'adoption internationale |
| **CI historique** | Les 6 premiers runs CI ont echoue (corrige depuis, mais visible) |
| **Pas de modeles locaux** | Pas de support Ollama/vLLM pour un deploiement 100% souverain sans API externe |

---

## Recommandations pour le positionnement

### Actions immediates

1. **Publier une GitHub Release v0.1.0** avec changelog
2. **Activer GitHub Discussions** pour creer une communaute
3. **Ajouter des topics GitHub** : `rag`, `document-quality`, `knowledge-base`, `audit`, `nutri-score`, `llm`, `django`
4. **Publier un blog post technique** detaillant l'architecture et les algorithmes
5. **Soumettre a Hacker News** (Show HN) et Reddit r/MachineLearning, r/LocalLLaMA

### Actions strategiques

6. **Benchmarker publiquement** : publier des resultats sur des corpus publics (Wikipedia FR, documentation technique open source) pour demontrer la valeur
7. **Integrer avec l'ecosysteme** : proposer des plugins/connecteurs pour LlamaIndex, Haystack, LangChain comme etape pre-ingestion
8. **Ajouter le support de modeles locaux** (Ollama, vLLM) pour un deploiement 100% souverain — argument decisif pour le secteur public
9. **Positionner le narratif** : "Ragas evalue votre pipeline RAG. SCORE evalue vos documents **avant** qu'ils n'entrent dans le pipeline."
10. **Viser le panorama DINUM** : candidater a l'AMI solutions IA pour les administrations publiques

---

## Sources

### Outils d'evaluation RAG
- [Ragas GitHub](https://github.com/explodinggradients/ragas) — [ragas.io](https://www.ragas.io/)
- [DeepEval GitHub](https://github.com/confident-ai/deepeval) — [deepeval.com](https://deepeval.com/)
- [TruLens GitHub](https://github.com/truera/trulens) — [trulens.org](https://www.trulens.org/)
- [Arize Phoenix GitHub](https://github.com/Arize-ai/phoenix) — [phoenix.arize.com](https://phoenix.arize.com/)
- [Langfuse GitHub](https://github.com/langfuse/langfuse) — [langfuse.com](https://langfuse.com/)
- [Opik GitHub](https://github.com/comet-ml/opik) — [comet.com/opik](https://www.comet.com/site/products/opik/)
- [Evidently AI GitHub](https://github.com/evidentlyai/evidently) — [evidentlyai.com](https://www.evidentlyai.com/)
- [LangSmith](https://www.langchain.com/langsmith) — [Pricing](https://www.langchain.com/pricing)
- [Braintrust](https://www.braintrust.dev/) — [Pricing](https://www.braintrust.dev/pricing)
- [Galileo](https://galileo.ai/) — [Pricing](https://galileo.ai/pricing)
- [Patronus AI](https://www.patronus.ai/)

### Outils de traitement documentaire
- [RAGFlow GitHub](https://github.com/infiniflow/ragflow)
- [Docling GitHub](https://github.com/docling-project/docling)
- [LlamaIndex GitHub](https://github.com/run-llama/llama_index)
- [Haystack GitHub](https://github.com/deepset-ai/haystack)
- [Unstructured.io GitHub](https://github.com/Unstructured-IO/unstructured)

### Concurrents proches
- [Microsoft Purview](https://learn.microsoft.com/en-us/purview/)
- [Glean](https://www.glean.com/)
- [Cleanlab GitHub](https://github.com/cleanlab/cleanlab)
- [Vectara](https://www.vectara.com/) — [HHEM](https://github.com/vectara/hallucination-leaderboard)
- [Contextual AI](https://contextual.ai/)
- [RAG Corpus Profiler GitHub](https://github.com/aashirpersonal/rag-corpus-profiler)
- [RagScore GitHub](https://github.com/HZYAI/RagScore)

### Initiatives francaises
- [Albert (DINUM/Etalab) GitHub](https://github.com/etalab-ia/albert)
- [La Suite Numerique](https://lasuite.numerique.gouv.fr/)
- [Panorama IA DINUM](https://alliance.numerique.gouv.fr/cartographie/panorama-des-solutions-ia-sur-etagere-pour-les-administrations-publiques/)
- [Numspot](https://numspot.com/)

### Articles et comparatifs
- [Top RAG Evaluation Tools 2026 (Maxim AI)](https://www.getmaxim.ai/articles/the-5-best-rag-evaluation-tools-you-should-know-in-2026/)
- [RAG Evaluation Tools (AIMultiple)](https://research.aimultiple.com/rag-evaluation-tools/)
- [Best LLM Observability Tools 2026 (Firecrawl)](https://www.firecrawl.dev/blog/best-llm-observability-tools)
- [DeepEval vs Ragas](https://deepeval.com/blog/deepeval-vs-ragas)
- [Evidently RAG Evaluation](https://www.evidentlyai.com/blog/open-source-rag-evaluation-tool)

### SCORE
- [SCORE GitHub](https://github.com/informatique-cdc/SCORE)
- [CDC Informatique](https://www.icdc.caissedesdepots.fr/)

---

*Analyse realisee le 16 mars 2026. Donnees verifiees par recherche web multi-sources.*
