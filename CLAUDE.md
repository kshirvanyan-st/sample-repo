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
- Auth is phone + SMS code only (no passwords): `SessionsController` (number) then
  `VerificationsController` (code). Codes are `PhoneVerification` rows (HMAC digest, 5 min, 5 tries,
  single use). Controllers require sign-in by default; opt out with `allow_unauthenticated_access`.
- Phone numbers are stored as E.164 via `User.normalize_phone` (phonelib, Armenia by default).
- Send SMS only through `SmsSender.deliver` (Twilio in production, log in dev, `SmsSender::TestAdapter`
  in specs). Never log or persist a plain code.
- Roles: `User#role` (rider, driver, dispatcher, admin). Guard staff pages with `require_role`
  (404 for everyone else). Staff actions go through `Moderation`, which writes the `ModerationAction`
  audit log. Admin controllers live in `app/controllers/admin/`. The first admin:
  `bin/rails taxi:make_admin PHONE=+374...`.
- Drivers: `DriverProfile` (status draft → submitted → approved / needs_changes / rejected / suspended)
  with one `Vehicle`. Decisions go through `Moderation.approve_driver!` etc. (status guards, audit row,
  SMS). Only `approved` drivers will be dispatched. `DocumentExpiryJob` (daily, `config/recurring.yml`)
  sends 30- and 7-day reminders once each (`ExpiryNotice`) and suspends on expiry.
- Uploaded documents: list them in the model's `DOCUMENTS` and include `DocumentAttachments` (type is
  sniffed from the bytes, max size). Serve them only through `DocumentsController` (owner or admin),
  never with public Active Storage URLs.
- Maps: `Routing.route` (OSRM; falls back to a straight-line estimate marked `approximate`) and
  `Geocoding.search/reverse` (Nominatim, Armenia only, cached). Never call the public OSM servers per
  keystroke. Points via `Geo.point(lat:, lon:)`. `ServiceZone.serves?` gates every trip.
- Prices: `Tariff#fare_for` (whole drams, rounded up to 10 ֏). A `FareQuote` stores the prices and a tariff
  snapshot, so a quote never changes after it is shown. Defaults live in `lib/map_defaults.rb` (seeds).
- MapLibre is served from `public/vendor/maplibre-gl-<version>/` (three ES modules that import each other
  by relative path). To upgrade: download the new `dist/*.mjs` and css there and update `config/importmap.rb`.
- Specs tagged `:osrm` run only in the CI `routing` job against a real OSRM (`bin/osrm-prepare`).
- Locale files: `config/locales/{hy,ru,en}.yml` plus feature files like `drivers.hy.yml`.
- Rate limits: sign-in per IP and per number; signed-in actions per user (`by: -> { Current.user.id }`).
- Geo: store points as PostGIS `geography(Point, 4326)` (longitude first); never compare raw lat/lng floats.

## Before every push
Run `bin/ci` (RuboCop, gem + importmap audits, Brakeman, RSpec). CI runs the same plus a Docker build.

## Local setup
`bin/setup` (or the SessionStart hook in cloud sessions, which also installs PostGIS), then `bin/dev`.
