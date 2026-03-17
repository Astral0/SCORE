# Chat Assistant

## Architecture

```text
User Question
     │
     ▼
┌────────────────┐
│ chat/views.py  │ chat_ask()
│  chat_ask()    │
└────┬───────────┘
     │
     ▼
┌────────────────┐
│ RAG Pipeline   │
│ 1. Embed query │ LLMClient.embed()
│ 2. KNN search  │ VectorStore.semantic_search()
│ 3. Get chunks  │ DocumentChunk + heading_path
│ 4. Build ctx   │ System prompt + context + history
│ 5. LLM call    │ LLMClient.chat()
└────┬───────────┘
     │
     ▼
┌────────────────┐
│   Response     │
│ + sources      │ Which documents answered
│ + suggestions  │ Follow-up questions
└────────────────┘
```

## Data Model

| Model | Purpose |
|-------|---------|
| **ChatConfig** | System prompt per user per project |
| **Conversation** | Thread de messages (par utilisateur) |
| **Message** | Message individuel (user/assistant) avec sources JSON |

## Workflow

1. Utilisateur envoie question via POST `/chat/ask/`
2. Chargement historique conversation (contexte)
3. Chargement `ChatConfig.system_prompt` (personnalise par user/project)
4. Embedding de la question → recherche semantique KNN
5. Construction du contexte : system prompt + chunks pertinents + historique
6. Appel LLM (chat completion)
7. Response + sources (documents ayant repondu) + suggestions
8. Stockage comme `Message` dans la `Conversation`

## Features

- **Source attribution** : chaque reponse cite les documents sources
- **System prompt personnalise** : par utilisateur et par projet
- **Historique** : conversations persistantes
- **Suggestions** : questions de suivi proposees
