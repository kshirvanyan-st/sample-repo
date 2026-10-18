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
- Rails is the control plane; video is handled by MediaMTX. Rails never proxies media.
  MediaMTX calls `Media::AuthController` for every publish/read/API request and
  `Media::HooksController` when a path starts/stops; `StreamReconcileJob` is the safety net.
  Viewers read with a signed token from `Stream#viewer_token_for`; broadcasters publish with `User#stream_key`.
- Coins are an append-only ledger (`LedgerEntry`); never update balances in place without a ledger row.
- Controllers require authentication by default; opt out with `allow_unauthenticated_access`.

## Before every push
Run `bin/ci` (RuboCop, gem + importmap audits, Brakeman, RSpec). It must pass; CI (`.github/workflows/ci.yml`) runs the same checks plus a Docker build.

## Local setup
`bin/setup` (or the SessionStart hook in cloud sessions), then `bin/dev`; `bin/media` for streaming.
Streaming changes: also run `script/media_smoke` (needs a `mediamtx` binary and ffmpeg). In cloud
sessions MediaMTX can't be downloaded from GitHub; build it with Go (see the `media` job in `.github/workflows/ci.yml`
for the version) or rely on the CI `media` job.
