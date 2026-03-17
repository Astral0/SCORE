# Recommendations - Performance

## Points d'attention

### 1. Batch LLM Calls

Le pipeline d'analyse fait de nombreux appels LLM sequentiels (claims par chunk, contradictions par paire). L'utilisation du Batch API pour les phases avec > 10 prompts est deja implementee mais pourrait etre etendue.

**Recommandation** : S'assurer que toutes les phases a fort volume (claims, contradictions, gaps) utilisent systematiquement le batch API quand disponible.

### 2. Embedding Generation

L'embedding en batch de 500 est efficace mais la phase initiale d'ingestion d'un gros corpus peut etre lente.

**Recommandation** : Envisager le parallelisme des embeddings sur plusieurs workers Celery si le volume depasse 10k chunks.

### 3. HTMX Polling

Le polling HTMX toutes les 2-5s pour les mises a jour de progression peut generer de la charge sur des corpus longs.

**Recommandation** : Envisager Server-Sent Events (SSE) ou WebSocket pour les mises a jour en temps reel si la charge polling devient significative.

### 4. Clustering HDBSCAN

HDBSCAN sur de gros corpus (> 50k chunks) peut etre couteux en memoire et CPU.

**Recommandation** : Prevoir un sampling ou une approche incrementale pour les tres gros corpus.

### 5. Graphe Semantique (FAISS + NetworkX)

Le graphe semantique est charge en memoire (NetworkX) et peut devenir volumineux.

**Recommandation** : Surveiller la consommation memoire et prevoir une pagination ou lazy-loading si necessaire.
