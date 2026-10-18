# Taxi AM

A ride-hailing app for Armenia: riders book from the web, drivers use a React PWA, Rails runs
dispatch, pricing and payments. See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Development

```sh
bin/setup      # gems, databases (needs PostgreSQL with PostGIS)
bin/dev        # Rails + Tailwind watcher
bin/rspec      # test suite
bin/ci         # everything CI runs
```

Languages: Armenian (default), Russian, English. Switch with the links in the header or `?locale=ru`.

## Repository note

This app currently lives on the `taxi-main` branch of another repository. To move it to its own:

```sh
git push git@github.com:<owner>/taxi-am.git taxi-main:main
```

then change `taxi-main` to `main` in `.github/workflows/*.yml` and `CLAUDE.md`.

## Deployment

Same as Kamal's usual flow, gated by the repository variable `DEPLOY_ENABLED=true`:
variables `KAMAL_WEB_HOST`, `APP_HOST`; secrets `SSH_PRIVATE_KEY`, `SECRET_KEY_BASE`, `POSTGRES_PASSWORD`.
First time: `bin/kamal setup`.
