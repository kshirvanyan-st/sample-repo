# Taxi AM

A ride-hailing app for Armenia (Yerevan first), built on Rails 8. Roadmap, phases and architecture:
`docs/ROADMAP.md`. One phase per branch (`claude/taxi-<phase>`) and one PR **into `taxi-main`**.

## Branches (important)
This project lives on the orphan branch **`taxi-main`** inside the Spark repository until it moves to
its own repo. Never merge into or branch from Spark's `main`; PRs target `taxi-main`. CI runs on PRs
and on pushes to `taxi-main`.

## Stack
- Rails 8.1, Ruby (see `.ruby-version`), PostgreSQL + **PostGIS** (`activerecord-postgis-adapter`,
  `postgis/postgis:17` in CI and production)
- Hotwire + Tailwind for the rider web app; the driver app will be a React PWA built with Vite
  (`app/frontend/driver`, Phase 4/8)
- Solid Queue / Solid Cache / Solid Cable, no Redis
- Tests: RSpec, FactoryBot, shoulda-matchers, Capybara (`spec/`). No Minitest.
- Deploy: Kamal (`config/deploy.yml`) via `.github/workflows/deploy.yml` (off until `DEPLOY_ENABLED`)

## Rules
- **Every user-facing string goes through I18n** and must exist in `hy`, `ru` and `en`
  (`spec/i18n_spec.rb` enforces matching keys; missing translations raise in dev/test).
  Armenian is the default locale. Have native speakers review new copy.
- Money is in AMD, stored as integers (drams). Balances only change through an append-only ledger
  (the Wallet pattern from Spark) once payments arrive.
- Geo: store points as PostGIS `geography(Point, 4326)` (longitude first); never compare raw lat/lng floats.

## Before every push
Run `bin/ci` (RuboCop, gem + importmap audits, Brakeman, RSpec). CI runs the same plus a Docker build.

## Local setup
`bin/setup` (or the SessionStart hook in cloud sessions, which also installs PostGIS), then `bin/dev`.
