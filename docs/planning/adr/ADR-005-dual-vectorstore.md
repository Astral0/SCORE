# ADR-005: sqlite-vec + FAISS dual vector store

## Status
Accepted

## Context
SCORE a deux besoins vectoriels distincts :
1. Stockage et recherche KNN des embeddings de chunks (ingestion, chat RAG)
2. Indexation de similarite pour le graphe semantique (concepts, relations)

## Decision
Utiliser sqlite-vec pour les embeddings principaux (KNN search) et FAISS pour le graphe semantique (nsg/).

## Consequences

### Positif
- sqlite-vec : zero config, integre a SQLite, persistant par defaut
- FAISS : tres performant pour la recherche de similarite, bien adapte au graphe
- Separation des concerns : embeddings documents vs concepts semantiques

### Negatif
- Deux technologies vectorielles a maintenir
- Duplication potentielle de certaines donnees
- FAISS necessite un chargement en memoire

### Risques
- Si une seule technologie peut couvrir les deux besoins, la duplication augmente la complexite inutilement
- FAISS en memoire peut poser des problemes sur gros corpus

## Alternatives
- **Tout en sqlite-vec** : plus simple mais moins performant pour le graphe
- **Tout en FAISS** : plus performant mais perte de la persistance native SQLite
- **Qdrant/Milvus** : plus robuste mais ajoute un service externe
