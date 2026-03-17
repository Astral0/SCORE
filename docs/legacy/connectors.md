# External Connectors

## Architecture

```text
ConnectorConfig (ORM)
  ├── connector_type: SHAREPOINT / CONFLUENCE / GENERIC
  ├── config: JSON (site_url, space_key, paths...)
  └── credential_ref: env var name (never raw secrets)

BaseConnector (Abstract)
  ├── list_changed_documents() → [ChangedDocument]
  └── fetch_document(doc) → ExtractedDocument
```

## SharePoint Connector

**Auth** : OAuth2 via MSAL + office365-rest-python-client

**Configuration** :
```json
{
  "site_url": "https://company.sharepoint.com/sites/docs",
  "library": "Documents",
  "folder_path": "/General"
}
```

**Env Vars** :
- `SHAREPOINT_CLIENT_ID`
- `SHAREPOINT_CLIENT_SECRET`
- `SHAREPOINT_TENANT_ID`

**Dependencies** (optionnelles) : `msal`, `office365-rest-python-client`

## Confluence Connector

**Auth** : Basic (username + API token)

**Configuration** :
```json
{
  "space_key": "DOCS",
  "page_labels": ["architecture", "api"]
}
```

**Env Vars** :
- `CONFLUENCE_URL`
- `CONFLUENCE_USERNAME`
- `CONFLUENCE_API_TOKEN`

**Dependencies** (optionnelles) : `atlassian-python-api`

## Generic Connector

**Usage** : Fichiers locaux ou URLs HTTP

**Configuration** :
```json
{
  "base_path": "/data/documents/",
  "file_patterns": ["*.pdf", "*.docx"],
  "recursive": true
}
```

Supporte aussi l'upload manuel de fichiers via l'interface.

## Incremental Sync

- Chaque `list_changed_documents()` compare avec l'etat precedent
- Detection basee sur : content_hash, source_version, etag, modified timestamp
- Seuls les documents nouveaux/modifies sont re-ingeres
- Documents supprimes a la source marques DELETED (soft delete)

## Schedule

- `ConnectorConfig.schedule_cron` : expression cron optionnelle
- Execution via Celery Beat (django_celery_beat)
