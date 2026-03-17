# Frontend & UI

## Stack Technique

| Technologie | Usage |
|-------------|-------|
| **Django Templates** | Server-side rendering (Jinja2-style) |
| **Bootstrap** | Framework CSS responsive |
| **HTMX** | Interactivite sans SPA (polling, modals, partials) |
| **D3.js** | Visualisations interactives (clusters, tree, graphe) |
| **CSS custom** | `dashboard/static/css/style.css` |

## Architecture Frontend

```text
┌─────────────────────────────────────────┐
│              base.html                   │
│  ┌─────────┐ ┌────────────────────────┐ │
│  │ Navbar  │ │     Content Area       │ │
│  │         │ │                        │ │
│  │ Sidebar │ │  ┌──────────────────┐  │ │
│  │ (nav)   │ │  │  Page Template   │  │ │
│  │         │ │  │                  │  │ │
│  │         │ │  │  HTMX Partials   │  │ │
│  │         │ │  │  D3.js Canvases  │  │ │
│  │         │ │  └──────────────────┘  │ │
│  └─────────┘ └────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Pages Principales

| Page | Template | Features |
|------|----------|----------|
| Dashboard | `dashboard/index.html` | Vue d'ensemble, metriques |
| Connectors | `connectors/list.html` | Liste, creation, sync |
| Connector Detail | `connectors/detail.html` | Documents, jobs, live status |
| Analysis List | `analysis/list.html` | Jobs, lancement, progress |
| Analysis Detail | `analysis/detail.html` | Resultats multi-onglets |
| Duplicates | `analysis/duplicates.html` | Paires, scores, resolution |
| Contradictions | `analysis/contradictions.html` | Claims, severity, batch resolve |
| Clusters | `analysis/clusters.html` | D3.js bubble chart |
| Gaps | `analysis/gaps.html` | Coverage, severity |
| Hallucinations | `analysis/hallucinations.html` | Risques, termes |
| Tree | `analysis/tree.html` | D3.js hierarchical tree |
| Knowledge Map | `analysis/knowledge_map.html` | D3.js concept graph |
| Audit List | `audit/list.html` | Jobs, grades A-E |
| Audit Detail | `audit/detail.html` | Radar chart 6 axes |
| Chat | `chat/home.html` | Assistant RAG, conversations |

## Patterns HTMX

### Live Progress
```html
<!-- Polling toutes les 2s pour mise a jour progression -->
<div hx-get="/analysis/{pk}/_progress/" hx-trigger="every 2s" hx-swap="innerHTML">
  <!-- Progress bar -->
</div>
```

### Modal Dialogs
```html
<!-- Modal de configuration -->
<button hx-get="/connectors/create/" hx-target="#modal-container">
  Nouveau connecteur
</button>
```

### Partial Updates
```html
<!-- Mise a jour partielle de la liste des jobs -->
<div hx-get="/connectors/{pk}/_jobs/" hx-trigger="every 5s">
  <!-- Job list partial -->
</div>
```

## Visualisations D3.js

| Visualisation | Page | Description |
|---------------|------|-------------|
| Bubble Chart | Clusters | Cercles proportionnels par cluster |
| Hierarchical Tree | Tree | Taxonomie documents/clusters |
| Force-directed Graph | Knowledge Map | Graphe conceptuel interactif |
| Radar Chart | Audit Detail | 6 axes d'audit |
| Bar Charts | Audit Axes | Metriques par axe |

## Internationalization

- Default : **Francais (fr)**
- Support : Anglais (en)
- Fichiers : `locale/fr/LC_MESSAGES/django.po`
- Middleware : `LocaleMiddleware` dans settings
