# ADR-002: HTMX plutot que SPA framework

## Status
Accepted

## Context
L'interface utilisateur de SCORE necessite de l'interactivite (progress live, modals, mises a jour partielles) sans la complexite d'un SPA complet (React, Vue, Angular).

## Decision
Utiliser Django Templates + Bootstrap pour le rendu server-side, avec HTMX pour l'interactivite et D3.js pour les visualisations.

## Consequences

### Positif
- Complexite frontend minimale (pas de build pipeline, pas de state management)
- SEO-friendly (server-side rendering)
- Performance initiale excellente (HTML complet au premier chargement)
- HTMX couvre les besoins : polling, partials, modals
- D3.js pour les visualisations complexes (clusters, tree, graphe)

### Negatif
- Moins d'interactivite riche qu'un SPA
- Chaque interaction necessite un round-trip serveur
- Pas de mode offline
- D3.js require de pre-computer les donnees cote serveur (chart_data JSON)

### Risques
- Si les besoins d'interactivite augmentent significativement, migration vers un SPA partiel (ex: React pour certaines pages) pourrait etre necessaire
