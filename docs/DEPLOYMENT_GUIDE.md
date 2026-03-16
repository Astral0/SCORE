# SCORE - Guide de deploiement complet

Guide autonome pour deployer SCORE sur un serveur Linux (Debian/Ubuntu) avec Conda.
Ce document est concu pour etre suivi pas a pas par un humain ou une IA.

---

## Architecture deployee

```
SCORE (Django 5.1 / Python 3.12)
├── Django          : serveur web (port 8000)
├── Celery worker   : taches async (ingestion, analyses)
├── Redis           : broker Celery
├── SQLite          : base de donnees (data/db.sqlite3)
└── LLM externe     : chat + embeddings via API OpenAI-compatible
```

---

## Etape 1 : Prerequis systeme

```bash
sudo apt-get install -y pkg-config libcairo2-dev screen libreoffice-core libreoffice-writer libreoffice-impress libreoffice-calc
```

| Paquet | Raison |
|--------|--------|
| `pkg-config`, `libcairo2-dev` | Compilation de `pycairo` (dependance de `xhtml2pdf`) |
| `screen` | Session multi-onglets pour Django + Celery |
| `libreoffice-*` | Conversion de fichiers `.doc`, `.ppt`, `.xlsx` (voir etape 11) |

---

## Etape 2 : Creer le venv Conda

```bash
conda create -n score python=3.12 -y
conda activate score
```

> Python 3.12 requis (`requires-python = ">=3.12"`). Rester sur 3.12 plutot que 3.13 pour la compatibilite avec `faiss-cpu` et `hdbscan`.

---

## Etape 3 : Configurer les registries (reseau d'entreprise)

Si le reseau utilise un miroir interne pour pip/npm (ex: EDF), lancer :

```bash
./switch-env.sh edf
```

Ce script configure `~/.pip/pip.conf`, `.npmrc` et `.yarnrc.yml` pour utiliser le miroir interne. Pour revenir aux registries publics : `./switch-env.sh public`.

> Si `switch-env.sh` n'existe pas, creer manuellement `~/.pip/pip.conf` :
> ```ini
> [global]
> index-url = https://votre-miroir/repository/pypi/simple
> trusted-host = votre-miroir
> ```

---

## Etape 4 : Installer le projet

```bash
cd /chemin/vers/SCORE
pip install -e ".[dev]"
```

### Dependances optionnelles

```bash
pip install -e ".[sharepoint]"              # Connecteur SharePoint
pip install -e ".[confluence]"              # Connecteur Confluence
pip install -e ".[dev,sharepoint,confluence]"  # Tout
```

### Erreur "Multiple top-level packages"

Si `pip install -e .` echoue avec cette erreur, verifier que `pyproject.toml` contient la section :

```toml
[tool.setuptools.packages.find]
include = [
    "score*", "analysis*", "chat*", "connectors*", "dashboard*",
    "ingestion*", "llm*", "nsg*", "reports*", "tenants*", "vectorstore*",
]
```

---

## Etape 5 : Installer Redis

Redis sert de broker pour les taches Celery (ingestion de documents, analyses).

```bash
conda install -n score redis-server -y
```

Verification :
```bash
redis-server --daemonize yes
redis-cli ping    # doit repondre PONG
```

> **Alternative sans Redis** : mettre `CELERY_BROKER_BACKEND=database` dans `.env`.
> Celery utilisera alors la base Django comme broker (plus lent, acceptable en dev).

---

## Etape 6 : Telecharger les modeles NLP

```bash
python -m spacy download fr_core_news_sm

python -c "import nltk; nltk.download('punkt'); nltk.download('punkt_tab'); nltk.download('stopwords')"
```

---

## Etape 7 : Certificats SSL (reseau d'entreprise)

Si le reseau utilise un proxy HTTPS avec CA interne, les appels Python (openai, httpx, requests) echoueront avec `CERTIFICATE_VERIFY_FAILED`.

### 7a. Installer les CA dans le store systeme

```bash
# Copier les certificats CA internes
sudo cp /chemin/vers/certificats/*.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

> **LXC/Container** : copier d'abord les certs depuis le host dans le rootfs du container :
> ```bash
> # Depuis le host
> cp /usr/local/share/ca-certificates/*.crt /var/lib/lxc/<nom>/rootfs/usr/local/share/ca-certificates/
> # Puis dans le container
> sudo update-ca-certificates
> ```

### 7b. Forcer Python a utiliser le bundle systeme

Le Python Conda utilise son propre bundle `certifi`, pas celui du systeme. Ajouter dans `~/.bashrc` :

```bash
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
```

Puis : `source ~/.bashrc`

### 7c. Verification

```bash
python -c "
from openai import OpenAI
c = OpenAI(api_key='test', base_url='https://votre-serveur-llm/v1')
c.models.list()
" 2>&1 | head -5
# Doit retourner des donnees, pas une erreur SSL
```

---

## Etape 8 : Configurer l'environnement

```bash
cp .env.example .env
```

### 8a. Generer la SECRET_KEY

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

Coller le resultat dans `.env` a la ligne `SECRET_KEY=`.

### 8b. Configuration minimale du `.env`

```ini
# Django
SECRET_KEY=<cle generee>
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# LLM Provider
LLM_PROVIDER=openai

# OpenAI ou serveur compatible (LiteLLM, vLLM, Ollama, etc.)
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://votre-serveur-llm/v1    # laisser vide pour api.openai.com

# Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_BROKER_BACKEND=redis
```

### 8c. Configuration des modeles (`config.yaml`)

Le fichier `config.yaml` definit les modeles LLM et embedding. Adapter a votre serveur :

```yaml
llm:
  provider: openai
  chat_model: gpt-4o                      # votre modele de chat
  embedding_model: text-embedding-3-small  # votre modele d'embedding
  embedding_dimensions: 1536               # adapter selon le modele
  fallback_models:
    - gpt-4o-mini                          # modele de secours sur 429
```

> **IMPORTANT** : Le parametre `embedding_dimensions` n'est envoye a l'API que pour les
> modeles `text-embedding-*` d'OpenAI. Pour les autres modeles (bge, Gemini, etc.),
> il sert uniquement a dimensionner le stockage vectoriel cote SCORE.

### 8d. Decouvrir les modeles disponibles (LiteLLM)

```bash
curl -sk -H "Authorization: Bearer $OPENAI_API_KEY" $OPENAI_BASE_URL/models | python -m json.tool
```

Chercher un modele de **chat** (ex: gemini, mistral, gpt) et un modele d'**embedding** (ex: bge, text-embedding, gemini-embedding).

Pour verifier les dimensions d'un modele d'embedding :

```bash
curl -sk -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  $OPENAI_BASE_URL/embeddings \
  -d '{"model":"nom-du-modele","input":"test"}' \
  | python -c "import sys,json; d=json.load(sys.stdin); print(f'dimensions: {len(d[\"data\"][0][\"embedding\"])}')"
```

---

## Etape 9 : Initialiser la base de donnees

```bash
python manage.py migrate
```

### Creer le compte administrateur

```bash
python manage.py createsuperuser
```

Ou en non-interactif :

```bash
DJANGO_SUPERUSER_PASSWORD=motdepasse python manage.py createsuperuser --noinput --username admin --email admin@localhost
```

---

## Etape 10 : Lancer le serveur

### Avec start.sh (recommande)

```bash
./start.sh
```

Demarre dans une session `screen` :
- Redis (si pas deja lance)
- Django sur `0.0.0.0:8000`
- Worker Celery (taches async)

```bash
screen -r score          # Se connecter a la session
# Ctrl+A puis n          # Onglet suivant (Django <-> Celery)
# Ctrl+A puis d          # Detacher la session
screen -S score -X quit  # Arreter tout
```

### Manuellement (3 terminaux)

```bash
# Terminal 1 : Redis
redis-server

# Terminal 2 : Django
python manage.py runserver 0.0.0.0:8000

# Terminal 3 : Celery worker
celery -A score worker -l info --pool threads
```

---

## Etape 11 : Preparer les documents

### 11a. Creer le repertoire

```bash
mkdir -p data/documents
```

Deposer les fichiers dans ce repertoire. Les sous-repertoires sont supportes (scan recursif).

### 11b. Formats supportes

SCORE supporte nativement : `.pdf`, `.docx`, `.pptx`, `.md`, `.html`, `.txt`, `.csv`, `.json`, `.xml`, `.rst`, `.yaml`

**Formats NON supportes** : `.doc`, `.ppt`, `.xls`, `.xlsx`, `.xlsm`

### 11c. Convertir les anciens formats Office

Les fichiers `.doc`, `.ppt` et Excel doivent etre convertis avant ingestion :

```bash
python << 'PYEOF'
import subprocess, os

base = "data/documents"  # adapter le chemin
converted = {"doc": 0, "ppt": 0, "excel": 0, "errors": []}

for root, dirs, files in os.walk(base):
    for f in files:
        fp = os.path.join(root, f)
        ext = os.path.splitext(f)[1].lower()

        if ext == ".doc":
            fmt, key = "docx", "doc"
        elif ext == ".ppt":
            fmt, key = "pptx", "ppt"
        elif ext in (".xlsx", ".xlsm", ".xls"):
            fmt, key = "pdf", "excel"
        else:
            continue

        result = subprocess.run(
            ["libreoffice", "--headless", "--convert-to", fmt, "--outdir", root, fp],
            capture_output=True, text=True, timeout=60
        )
        if result.returncode == 0:
            converted[key] += 1
            os.remove(fp)  # supprimer l'original
        else:
            converted["errors"].append(f"{f}: {result.stderr.strip()}")

print(f".doc  -> .docx : {converted['doc']}")
print(f".ppt  -> .pptx : {converted['ppt']}")
print(f".xlsx -> .pdf  : {converted['excel']}")
if converted["errors"]:
    print(f"\nErreurs ({len(converted['errors'])}):")
    for e in converted["errors"]:
        print(f"  - {e}")
PYEOF
```

### 11d. Corriger les noms de fichiers avec accents casses

Les fichiers copies depuis Windows/SharePoint/NTFS peuvent avoir des accents corrompus (surrogates UTF-8). Symptome : erreur `surrogates not allowed` dans les logs Celery.

```bash
python << 'PYEOF'
import os

base = "data/documents"  # adapter le chemin
fixed = 0
for root, dirs, files in os.walk(base):
    for f in files:
        try:
            f.encode('utf-8')
        except UnicodeEncodeError:
            raw = f.encode('utf-8', 'surrogateescape')
            try:
                new_name = raw.decode('latin-1')
            except Exception:
                new_name = raw.decode('utf-8', 'replace')
            old_path = os.path.join(root, f)
            new_path = os.path.join(root, new_name)
            if old_path != new_path and not os.path.exists(new_path):
                os.rename(old_path, new_path)
                fixed += 1

print(f"{fixed} fichiers renommes")
PYEOF
```

---

## Etape 12 : Premier lancement

1. Ouvrir http://localhost:8000
2. Se connecter avec le compte admin
3. Creer un **espace de travail** (ex: "Mon equipe")
4. Creer un **projet** (ex: "Referentiel documentaire")
5. Aller dans **Connecteurs** > **Ajouter**
6. Choisir le type **Generic**
7. Configurer `base_path` = chemin absolu du dossier (ex: `/chemin/vers/SCORE/data/documents`)
8. Lancer la **synchronisation**

### Suivi de l'ingestion

- L'interface affiche la progression en temps reel
- Logs detailles : `logs/celery.log`
- En cas d'erreurs, consulter les logs pour identifier le probleme (voir section Troubleshooting)

---

## Etape 13 : Connecteur SharePoint (optionnel)

Prerequis : une **App Registration Azure AD** avec la permission Microsoft Graph `Sites.Read.All` (type Application).

### 13a. Variables d'environnement

Ajouter dans `.env` :

```ini
SHAREPOINT_CLIENT_ID=<Azure AD Application ID>
SHAREPOINT_TENANT_ID=<Azure AD Tenant ID>
SHAREPOINT_CLIENT_SECRET=<secret>
```

### 13b. Extraire les infos depuis une URL SharePoint

A partir d'une URL SharePoint du type :
```
https://monorg.sharepoint.com/sites/MonSite/Documents/Forms/AllItems.aspx?id=/sites/MonSite/Documents/MonDossier
```

Extraire :
- **Site URL** : `monorg.sharepoint.com/sites/MonSite`
- **Folder path** : `/Documents/MonDossier` (le parametre `id=` decode)

### 13c. Configuration dans l'interface

1. Ajouter un connecteur de type **SharePoint**
2. Renseigner :
   - **Site URL** : `monorg.sharepoint.com/sites/MonSite`
   - **Folder path** : `/Documents/MonDossier`
   - **Credential ref** : `SHAREPOINT_CLIENT_SECRET`
3. Lancer la synchronisation

---

## Troubleshooting

### Erreur SSL `CERTIFICATE_VERIFY_FAILED`

Le CA interne n'est pas reconnu par Python. Voir etape 7.

### Erreur Celery `Connection refused` port 6379

Redis n'est pas lance. Soit :
- Lancer Redis : `redis-server --daemonize yes`
- Ou passer en mode database : `CELERY_BROKER_BACKEND=database` dans `.env`

### Erreur embedding `UnsupportedParamsError: Setting dimensions is not supported`

Le serveur LLM (LiteLLM) refuse le parametre `dimensions` pour ce modele d'embedding. SCORE n'envoie `dimensions` que pour les modeles `text-embedding-*`. Si le probleme persiste, verifier que `llm/client.py` contient bien le filtre `self._embed_model.startswith("text-embedding-")`.

### Erreur `surrogates not allowed`

Des noms de fichiers ont des accents corrompus. Voir etape 11d.

### Erreur `UNIQUE constraint failed` a la synchronisation

Des documents ont deja ete ingeres lors d'un sync precedent. Solutions :
1. Supprimer le connecteur et le recreer (reset complet)
2. Ou laisser faire : SCORE ignore les doublons, seuls les nouveaux documents sont ajoutes

### Erreur `NullObject` sur un PDF

Le PDF est corrompu ou a une structure non standard. Regenerer le PDF depuis la source.

### `pip install -e .` echoue avec "Multiple top-level packages"

Voir la note a l'etape 4.

---

## Resume des ports et services

| Service | Port | Description |
|---------|------|-------------|
| Django | 8000 | Interface web |
| Redis | 6379 | Broker Celery |
| Admin Django | 8000/admin | Administration |

## Resume des fichiers de configuration

| Fichier | Role |
|---------|------|
| `.env` | Secrets, cles API, provider LLM |
| `config.yaml` | Modeles LLM, parametres d'analyse, chunking |
| `start.sh` | Script de demarrage (Redis + Django + Celery) |
| `switch-env.sh` | Bascule miroirs pip/npm (EDF/public) |
