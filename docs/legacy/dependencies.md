# Dependencies

## Core Stack

| Package | Version | Purpose |
|---------|---------|---------|
| django | >=5.1,<5.2 | Web framework |
| django-environ | >=0.11 | .env file parsing |
| django-allauth | >=65.0 | Authentication (email, OAuth) |
| django-celery-results | >=2.5 | Celery result backend |
| django-celery-beat | >=2.6 | Celery periodic tasks |
| celery[redis] | >=5.4 | Task queue |
| sqlalchemy | >=2.0 | DB broker alternative (dev) |

## LLM & AI

| Package | Version | Purpose |
|---------|---------|---------|
| openai | >=1.40 | OpenAI / Azure OpenAI SDK |
| tiktoken | >=0.7 | Token counting |

## Vector Store & ML

| Package | Version | Purpose |
|---------|---------|---------|
| sqlite-vec | ==0.1.6 | SQLite vector extension (KNN) |
| numpy | >=1.26 | Numerical computing |
| scikit-learn | >=1.5 | Clustering, TF-IDF |
| hdbscan | >=0.8 | Hierarchical DBSCAN |
| datasketch | >=1.6 | MinHash (lexical similarity) |
| faiss-cpu | >=1.7 | Similarity search (semantic graph) |

## NLP

| Package | Version | Purpose |
|---------|---------|---------|
| spacy | >=3.5 | NLP (concept extraction, French) |
| langid | >=1.1 | Language detection |
| rank-bm25 | >=0.2 | BM25 full-text search |
| nltk | >=3.8 | Natural language toolkit |
| networkx | >=3.1 | Graph algorithms |

## Document Parsing

| Package | Version | Purpose |
|---------|---------|---------|
| beautifulsoup4 | >=4.12 | HTML/XML parsing |
| pypdf | >=4.0 | PDF extraction |
| python-docx | >=1.1 | DOCX parsing |
| python-pptx | >=0.6 | PPTX parsing |
| markdown | >=3.6 | Markdown to HTML |

## HTTP & Config

| Package | Version | Purpose |
|---------|---------|---------|
| httpx | >=0.27 | HTTP client (connectors) |
| pyyaml | >=6.0 | YAML config parsing |

## Export & Deployment

| Package | Version | Purpose |
|---------|---------|---------|
| xhtml2pdf | >=0.2.11 | HTML to PDF |
| whitenoise | >=6.7 | Static files |
| gunicorn | >=22.0 | Production WSGI |
| waitress | >=3.0 | Dev WSGI (Windows) |

## Optional (External Connectors)

| Package | Version | Purpose |
|---------|---------|---------|
| msal | >=1.28 | Microsoft auth (SharePoint) |
| office365-rest-python-client | >=2.5 | SharePoint API |
| atlassian-python-api | >=3.41 | Confluence API |

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| pytest | >=8.0 | Testing |
| pytest-django | >=4.8 | Django test integration |
| pytest-asyncio | >=0.23 | Async tests |
| factory-boy | >=3.3 | Test fixtures |
| faker | >=22.0 | Fake data |
| coverage | >=7.4 | Test coverage |
| ruff | >=0.5 | Linting & formatting |
