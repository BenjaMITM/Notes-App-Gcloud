# Cloud Run Deployment (Notes App)

This deploys two services:
- `notes-api` (Phoenix GraphQL API)
- `notes-web` (SvelteKit UI)

## Prereqs
- gcloud CLI authenticated
- Cloud SQL instance already created: `newest-project-485620:us-central1:cloud-codex-notes`
- Artifact Registry repo: `us-central1-docker.pkg.dev/newest-project-485620/notes`
- Secret Manager secrets:
  - `notes-db-password` (Cloud SQL password)
  - `notes-secret-key-base` (Phoenix secret key)

## Create secrets

Create the secrets once and paste the values when prompted:

```sh
gcloud secrets create notes-db-password --data-file=-
# paste your DB password, then press Ctrl-D

gcloud secrets create notes-secret-key-base --data-file=-
# generate with `mix phx.gen.secret`, paste it, then press Ctrl-D
```

## Build + push images

```sh
gcloud config set project newest-project-485620

gcloud builds submit --tag us-central1-docker.pkg.dev/newest-project-485620/notes/notes-api:latest .

gcloud builds submit --tag us-central1-docker.pkg.dev/newest-project-485620/notes/notes-web:latest ./web
```

## Deploy

```sh
gcloud run services replace deploy/cloudrun/api-service.yaml --region us-central1

gcloud run services replace deploy/cloudrun/web-service.yaml --region us-central1
```
