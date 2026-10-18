# Spark

A dating + live-streaming social network (Topface-style dating with Bigo/Tango-style live streams), built on Rails 8.
The full roadmap, phases and architecture are in `docs/ROADMAP.md`. Work one phase per branch (`claude/<feature>`) and one PR.

## Stack
- Rails 8.1, Ruby (see `.ruby-version`), PostgreSQL (PostGIS image in CI and production)
- Hotwire (Turbo + Stimulus), importmap, Tailwind (`tailwindcss-rails`)
- Solid Queue / Solid Cache / Solid Cable — no Redis
- Auth: the Rails 8 authentication generator (`app/controllers/concerns/authentication.rb`) plus `RegistrationsController`
- Tests: RSpec, FactoryBot, shoulda-matchers, Capybara (`spec/`). No Minitest.
- Deploy: Kamal (`config/deploy.yml`) via `.github/workflows/deploy.yml`

## Architecture rules
- Rails is the control plane; video is handled by MediaMTX (added in Phase 4). Rails never proxies media.
- Coins are an append-only ledger (`LedgerEntry`); never update balances in place without a ledger row.
- Controllers require authentication by default; opt out with `allow_unauthenticated_access`.

## Before every push
Run `bin/ci` (RuboCop, gem + importmap audits, Brakeman, RSpec). It must pass; CI (`.github/workflows/ci.yml`) runs the same checks plus a Docker build.

## Local setup
`bin/setup` (or the SessionStart hook in cloud sessions), then `bin/dev`.
