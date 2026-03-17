# PLAN : Support multi-modele LLM dans le chat

> Genere par `/ai-plan-interview` le 2026-03-17

## 1. Contexte et objectif

L'application SCORE utilise actuellement un seul modele LLM (`C2-Cloud-Gemini-2.5-Pro`) pour toutes les conversations chat. Le selecteur de modele dans l'UI est en lecture seule apres nettoyage du branding Mistral hardcode.

**Objectif** : Permettre a chaque utilisateur de choisir un modele LLM parmi une liste configuree dans `config.yaml`. Le choix est effectif pour la generation de reponses, persiste par conversation, et trace par message.

## 2. Approche architecturale

**Approche choisie** : Clean (kwarg model override explicite)

**Justification** : Le pattern kwarg est thread-safe, explicite, et s'appuie sur `_call_with_fallback()` qui supporte deja les overrides de modele via kwargs. Le pattern `tools` existant fournit le blueprint exact pour la persistance (Conversation) et la synchronisation UI.

**Alternatives rejetees** :
- Context-variable (ContextVar) : Couplage implicite, difficile a tester, risque avec Celery
- Instances LLM separees : Sur-ingenierie, le singleton est bien ancre dans le code

## 3. Criteres d'acceptation

- [ ] L'utilisateur peut choisir un modele dans un dropdown interactif dans la toolbar du chat
- [ ] Le modele choisi est utilise pour generer la reponse (pas les techniques RAG intermediaires)
- [ ] Le modele choisi est utilise par agentic_rag quand il est active
- [ ] Le modele est persiste par Conversation (restaure au rechargement)
- [ ] Le modele effectivement utilise est stocke par Message (tracabilite)
- [ ] Un endpoint GET /chat/config/models/ renvoie la whitelist
- [ ] Le backend valide le model_id contre la whitelist (400 si invalide)
- [ ] L'embedding model n'est jamais affecte par la selection
- [ ] La generation de titre utilise toujours le modele par defaut
- [ ] Si `chat_models` est absent de config.yaml, degradation gracieuse (modele unique)

## 4. Analyse technique

### Fichiers a creer
| Fichier | Description |
|---------|-------------|
| `chat/migrations/XXXX_add_model_fields.py` | Migration : `Conversation.model` + `Message.model_used` |

### Fichiers a modifier
| Fichier | Modification |
|---------|-------------|
| `config.yaml` | Ajouter section `chat_models` sous `llm:` |
| `score/settings.py` | Exposer `chat_models` dans `LLM_CONFIG` |
| `llm/client.py` | Ajouter param `model` a `chat()` et `chat_messages()`, fix `_supports_temperature` |
| `chat/models.py` | Ajouter `model` a Conversation, `model_used` a Message |
| `chat/urls.py` | Ajouter route `config/models/` |
| `chat/views.py` | Endpoint `available_models`, validation model dans `chat_ask`, persistance, response |
| `chat/rag.py` | Param `model` dans `ask_documents()`, `_generate_answer()` |
| `chat/rag_techniques.py` | Param `model` dans `agentic_rag()`, `synthesize_sub_results()` |
| `chat/templates/chat/home.html` | Dropdown interactif, JS selectedModel, model dans fetch |
| `tests/test_chat_views.py` | Tests endpoint, validation, forwarding, persistance |

### Migration DB
Oui - 2 nouveaux champs CharField :
- `Conversation.model` : CharField(max_length=100, default="", blank=True)
- `Message.model_used` : CharField(max_length=100, default="", blank=True)

Non-destructif, valeur par defaut vide = "utiliser le defaut".

## 5. Plan d'implementation

### Phase 1 : Configuration et LLM client

- [ ] Ajouter `chat_models` dans `config.yaml` avec id/name/category pour chaque modele disponible
- [ ] Exposer `chat_models` dans `LLM_CONFIG` via `settings.py` (`_llm_yaml.get("chat_models", [])`)
- [ ] Ajouter param `model: str | None = None` a `LLMClient.chat()` (ligne 228)
- [ ] Ajouter param `model: str | None = None` a `LLMClient.chat_messages()` (ligne 279)
- [ ] Dans les deux methodes : `actual_model = model or self._chat_model`, utiliser dans kwargs
- [ ] Fix bug `_supports_temperature` : verifier `actual_model` au lieu de `self._chat_model`

### Phase 2 : Modeles Django et migration

- [ ] Ajouter `model = CharField(max_length=100, default="", blank=True)` a `Conversation`
- [ ] Ajouter `model_used = CharField(max_length=100, default="", blank=True)` a `Message`
- [ ] Generer la migration : `python manage.py makemigrations chat`
- [ ] Appliquer : `python manage.py migrate`

### Phase 3 : Pipeline RAG

- [ ] Ajouter param `model: str | None = None` a `ask_documents()` dans `rag.py`
- [ ] Ajouter param `model: str | None = None` a `_generate_answer()` dans `rag.py`
- [ ] Passer `model=model` a `llm.chat_messages()` dans `_generate_answer()` (ligne 126)
- [ ] Passer `model=model` a `agentic_rag()` dans `ask_documents()` (ligne 225)
- [ ] Passer `model=model` a `synthesize_sub_results()` dans `ask_documents()` (ligne 235)
- [ ] Ajouter param `model: str | None = None` a `agentic_rag()` dans `rag_techniques.py`
- [ ] Passer `model=model` aux appels `llm.chat_messages()` et `llm.chat()` dans `agentic_rag()`
- [ ] Ajouter param `model: str | None = None` a `synthesize_sub_results()` dans `rag_techniques.py`
- [ ] Passer `model=model` a `llm.chat_messages()` dans `synthesize_sub_results()`
- [ ] NE PAS modifier : `rag_fusion`, `hyde`, `decompose_question`, `rerank_chunks`, `crag_evaluate`, `self_rag_filter`

### Phase 4 : Views et endpoint

- [ ] Ajouter endpoint `available_models()` dans `views.py` : retourne `LLM_CONFIG["chat_models"]`, avec fallback sur le modele par defaut si liste vide
- [ ] Ajouter route `config/models/` dans `urls.py`
- [ ] Dans `chat_ask()` : lire `model_id = body.get("model", "")`, valider contre whitelist, retourner 400 si invalide
- [ ] Passer `model=effective_model` a `ask_documents()`
- [ ] Persister `model` sur la Conversation (comme `tools`)
- [ ] Persister `model_used` (depuis `result`) sur le Message assistant
- [ ] Dans `conversation_messages()` : retourner `model` dans la reponse JSON
- [ ] Dans `chat_ask()` response : retourner `model_used` dans la reponse JSON

### Phase 5 : Frontend interactif

- [ ] Ajouter `<div class="model-dropdown"></div>` dans les deux model-dropdown-wrap (landing + conversation)
- [ ] Declarer `var selectedModel = ''` et `var availableModels = []`
- [ ] Fetch `GET /chat/config/models/` au chargement de la page
- [ ] Construire le dropdown dynamiquement (grouped by category, single-select, CSS deja pret)
- [ ] Handler click : mettre a jour `selectedModel`, sync tous les `.model-label` spans
- [ ] Fermer model dropdown quand tools dropdown s'ouvre (et vice-versa)
- [ ] Ajouter handler close-on-outside-click pour `.model-dropdown-wrap`
- [ ] Inclure `model: selectedModel` dans le body de `sendMessage()`
- [ ] Dans `loadConversation()` : restaurer `selectedModel` depuis `data.model`
- [ ] Dans new chat : reset `selectedModel` au defaut
- [ ] Dans delete conversation : reset `selectedModel` au defaut
- [ ] Degradation gracieuse : si 0 ou 1 modele, masquer le dropdown ou le rendre non-interactif

### Phase 6 : Tests

- [ ] `test_available_models_endpoint` : GET retourne la liste des modeles
- [ ] `test_available_models_requires_login` : 302 si non authentifie
- [ ] `test_chat_ask_with_valid_model` : model passe a ask_documents
- [ ] `test_chat_ask_with_invalid_model` : retourne 400
- [ ] `test_chat_ask_without_model` : backward compatible, utilise le defaut
- [ ] `test_conversation_model_persisted` : model sauvegarde sur Conversation
- [ ] `test_conversation_messages_returns_model` : response inclut model
- [ ] `test_message_model_used_stored` : model_used sauvegarde sur Message

## 6. Analyse des Gaps (Gap-Analyst)

### Edge Cases a gerer
| ID | Categorie | Description | Source | Strategie | Priorite |
|----|-----------|-------------|--------|-----------|----------|
| EC-1 | bug existant | `_supports_temperature` verifie `self._chat_model` au lieu du modele reel | `llm/client.py:248,293` | Corriger pour utiliser `actual_model` | Critique |
| EC-2 | config | `chat_models` absent de config.yaml | `config.yaml` | Fallback : generer une entree depuis `chat_model` | Haute |
| EC-3 | config | `chat_models` vide explicitement | `config.yaml` | Meme fallback, masquer dropdown | Moyenne |
| EC-4 | fallback | 429 sur modele choisi, fallback sur autre modele | `llm/client.py:189` | `Message.model_used` stocke le modele reel (LLMResponse.model) | Moyenne |
| EC-5 | stale data | Modele stocke dans Conversation supprime de config | `chat/models.py` | Afficher le label "Modele inconnu" ou fallback au defaut | Moyenne |
| EC-6 | UI | Close handler ne couvre que `.tools-dropdown-wrap` | `home.html:2031` | Ajouter handler pour `.model-dropdown-wrap` | Moyenne |
| EC-7 | UI | Dual chatbox : landing + conversation non synchronises | `home.html` | `syncModelUI()` comme `syncToolsUI()` | Haute |

### Failure Modes couverts
| Composant | Failure | Handling actuel | Handling prevu |
|-----------|---------|-----------------|----------------|
| LLM API | 429 rate limit | `_call_with_fallback` avec chain | Inchange, user model = primaire dans la chain |
| LLM API | Modele inconnu par l'API | Exception generique → 500 | Validation whitelist en amont (400) |
| Config | `chat_models` manquant | N/A | Fallback vers `chat_model` unique |

### Patterns reutilises du codebase
| Pattern | Source | Application |
|---------|--------|-------------|
| tools selection (multi-select) | `home.html:activeTools` | Adapter en single-select pour model |
| tools persistence | `chat/views.py:115-117` | Meme pattern pour `conversation.model` |
| tools restoration | `home.html:1715-1718` | Meme pattern pour `selectedModel = data.model` |
| ChatConfig endpoint | `chat/views.py:save_system_prompt` | Blueprint pour `available_models` |
| `_call_with_fallback` kwargs | `llm/client.py:189` | Deja pret pour model override |

## 7. Analyse Code Field

### Hypotheses techniques
| Hypothese | Source |
|-----------|--------|
| Tous les modeles dans `chat_models` partagent le meme endpoint API et la meme cle | inference |
| `_max_tokens_key` est identique pour tous les modeles (meme provider) | `llm/client.py:111` |
| Le format de reponse est identique quel que soit le modele | inference |
| `LLMResponse.model` contient toujours l'ID exact du modele utilise | OpenAI SDK spec |

### Edge cases (consolides)
| Edge case | Source | Strategie |
|-----------|--------|-----------|
| `_supports_temperature` bug pour modeles reasoning | `llm/client.py:248` (gap-analyst) | Fix avec `actual_model` |
| Config `chat_models` absent/vide | config.yaml (gap-analyst) | Fallback auto depuis `chat_model` |
| Fallback 429 change le modele reellement utilise | `llm/client.py:189` (gap-analyst) | `Message.model_used` = `LLMResponse.model` |
| Modele supprime de config mais present en DB | inference | Label "inconnu" + fallback |

### Limitations connues
- [ ] Pas de restriction par role (tous les utilisateurs voient tous les modeles)
- [ ] Pas de metriques de cout par modele
- [ ] Les techniques RAG intermediaires utilisent toujours le modele par defaut (par design)
- [ ] Pas de comparaison A/B integree (mais `model_used` sur Message le permet manuellement)

### Conditions de validite
- [ ] Tous les modeles dans `chat_models` sont accessibles via le meme endpoint/cle API
- [ ] Le provider (`openai`/`azure`/`azure_mistral`) est le meme pour tous les modeles
- [ ] Django dev server ou gunicorn en mode thread (pas fork) pour thread-safety du singleton

## 8. Tests prevus

### Tests Backend
- [ ] Endpoint `available_models` retourne la liste et necessite auth
- [ ] Validation model_id : invalide → 400, valide → passe a ask_documents
- [ ] Backward compat : pas de model dans le body → utilise le defaut
- [ ] Persistance model sur Conversation
- [ ] Persistance model_used sur Message
- [ ] conversation_messages retourne le model

### Tests Frontend (manuels)
- [ ] Dropdown affiche les modeles depuis l'endpoint
- [ ] Selection met a jour le label dans les deux chatboxes
- [ ] Rechargement d'une conversation restaure le modele
- [ ] Nouveau chat reset le modele au defaut
- [ ] Degradation : 1 seul modele → dropdown masque ou non-interactif

### data-testid prevus
| Element | data-testid |
|---------|-------------|
| Bouton model toolbar | `model-selector-btn` |
| Dropdown model | `model-dropdown` |
| Option model | `model-option-{id}` |
| Label model actif | `model-label` |

## 9. Documentation a mettre a jour

- [ ] `CHANGELOG.md` : nouvelle feature multi-modele
- [ ] `config.yaml` : commentaires explicatifs sur `chat_models`

## 10. Estimation d'effort

| Composant | Lignes | Notes |
|-----------|--------|-------|
| Config + Settings | ~10 | config.yaml + settings.py |
| LLM Client | ~15 | model param + bug fix |
| Models + Migration | ~5 | 2 champs + migration auto |
| RAG pipeline | ~20 | rag.py + rag_techniques.py |
| Views + URL | ~40 | endpoint + validation + persistance |
| Frontend JS/HTML | ~60 | dropdown interactif |
| Tests | ~50 | 8 tests |
| **Total** | **~200** | |

---

> **Prochaine etape** : `/ai-plan-check docs/planning/PLAN_MULTI_MODEL_LLM_CHAT.md`
