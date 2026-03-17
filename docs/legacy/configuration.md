# Configuration & Deployment

## Configuration Files

| Fichier | Usage |
|---------|-------|
| `.env` | Variables d'environnement (secrets, API keys) |
| `config.yaml` | Configuration applicative (chunking, analysis, audit) |
| `score/settings.py` | Django settings |
| `docker-compose.yml` | Orchestration multi-conteneurs |
| `Dockerfile` | Image de production |

## Environment Variables (.env)

### Django
| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | - | **REQUIRED** Django secret key |
| `DEBUG` | False | Mode debug |
| `ALLOWED_HOSTS` | localhost,127.0.0.1 | Hosts autorises |

### LLM Provider
| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_PROVIDER` | openai | openai / azure / azure_mistral |
| `OPENAI_API_KEY` | - | Cle API OpenAI |
| `OPENAI_CHAT_MODEL` | - | Override config.yaml |
| `OPENAI_EMBEDDING_MODEL` | - | Override config.yaml |

### Azure OpenAI
| Variable | Description |
|----------|-------------|
| `AZURE_OPENAI_API_KEY` | Cle API |
| `AZURE_OPENAI_ENDPOINT` | URL endpoint |
| `AZURE_OPENAI_API_VERSION` | Version API (default: 2024-06-01) |
| `AZURE_OPENAI_CHAT_DEPLOYMENT` | Deployment chat |
| `AZURE_OPENAI_EMBEDDING_DEPLOYMENT` | Deployment embedding |

### Celery
| Variable | Default | Description |
|----------|---------|-------------|
| `CELERY_BROKER_URL` | redis://localhost:6379/0 | URL du broker |
| `CELERY_BROKER_BACKEND` | redis | redis / database (dev) |

### Analysis Thresholds
| Variable | Default | Description |
|----------|---------|-------------|
| `DUPLICATE_SEMANTIC_THRESHOLD` | 0.92 | Seuil similarite semantique |
| `DUPLICATE_COMBINED_THRESHOLD` | 0.80 | Seuil combinaison ponderee |
| `CONTRADICTION_CONFIDENCE_THRESHOLD` | 0.75 | Confiance minimum |

## Docker Deployment

### Services

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| web | Dockerfile | 8000 | Django + gunicorn |
| celery | Dockerfile | - | Worker (threads, concurrency 4) |
| celery-beat | Dockerfile | - | Scheduler (DatabaseScheduler) |
| redis | redis:7-alpine | 6379 | Message broker |

### Volumes

| Volume | Mount | Description |
|--------|-------|-------------|
| db-data | /app/data/ | SQLite databases |
| vec-data | /app/data/ | Vector store |
| media-data | /app/media/ | Uploaded files |
| redis-data | /data | Redis persistence |

### Production

```bash
# Build and start
docker-compose up -d

# Migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Health check
curl http://localhost:8000/healthz/
```

## URLs

| URL | Description |
|-----|-------------|
| `/` | Redirect vers /dashboard/ |
| `/dashboard/` | Dashboard principal |
| `/admin/` | Django admin |
| `/healthz/` | Health check (monitoring) |
| `/auth/login/` | Authentification |
