# Recommendations - Security

## Forces actuelles

1. **Credentials by reference** : ConnectorConfig stocke des references (env vars) et non des secrets bruts
2. **CSP Middleware** : Headers Content-Security-Policy en place
3. **HSTS** : Active en production (DEBUG=False)
4. **Auth via allauth** : Framework mature avec email verification
5. **RBAC** : Roles ADMIN/EDITOR/VIEWER avec isolation tenant

## Points d'attention

### 1. API Keys LLM

Les cles API LLM sont dans `.env` et chargees via `django-environ`. C'est correct mais :

**Recommandation** : En production, utiliser un secret manager (Vault, AWS Secrets Manager) plutot que des fichiers `.env` sur le serveur.

### 2. SQLite File Access

Les fichiers SQLite (`db.sqlite3`, `vec.sqlite3`) sont accessibles en lecture/ecriture par le process Django et Celery.

**Recommandation** : S'assurer que les permissions filesystem limitent l'acces a l'utilisateur applicatif uniquement.

### 3. Upload de Fichiers

Le connecteur generic permet l'upload de fichiers (PDF, DOCX, etc.).

**Recommandation** :
- Valider les types MIME cote serveur (pas seulement l'extension)
- Limiter la taille des fichiers
- Scanner les fichiers avec un antivirus si deploye en entreprise

### 4. Injection Prompt LLM

Les contenus documentaires sont envoyes au LLM dans les prompts d'analyse.

**Recommandation** :
- Sanitiser les contenus avant injection dans les prompts
- Implementer des guardrails sur les reponses LLM
- Logger les appels LLM suspects

### 5. Audit Log

L'AuditLog est bien concu (immutable) mais limiter les operations tracees aux actions privilegiees.

**Recommandation** : S'assurer que toutes les operations destructives (delete, role change) sont systematiquement loggees.
