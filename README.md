# Spark

Dating + live-streaming social network on Rails 8. See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the plan.

## Development

```sh
bin/setup      # installs gems, prepares the database, starts the server
bin/dev        # Rails + Tailwind watcher
bin/rspec      # test suite
```

## Deployment (Kamal + GitHub Actions)

`.github/workflows/deploy.yml` deploys `main` after CI passes. It is off until you configure it:

1. Create a VPS (Ubuntu, Docker not required — Kamal installs it) and point your domain's A record at it.
2. In GitHub → Settings → Environments, create `production` (add required reviewers if you want manual approval).
3. Add **variables**: `DEPLOY_ENABLED=true`, `KAMAL_WEB_HOST=<server IP>`, `APP_HOST=<domain>`.
4. Add **secrets**: `SSH_PRIVATE_KEY` (root key for the VPS), `SECRET_KEY_BASE` (`bin/rails secret`),
   `POSTGRES_PASSWORD` (any strong password).
5. First time only, from your machine or a workflow run: `bin/kamal setup` (boots Postgres and the app).
   After that, every merge to `main` runs `bin/kamal deploy`.

Images are pushed to GitHub Container Registry using the workflow's `GITHUB_TOKEN`.
