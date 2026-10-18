# Plan: a taxi app for Armenia (Rails 8), on its own branch, ready to move to its own repo

## Context
The Spark repo stays as it is. The user wants a ride-hailing app for the Armenian market, built the
same way as Spark:
- generated Rails 8 code, reshaped phase by phase
- one PR per phase, GitHub Actions CI/CD, Kamal deploy, Claude Code cloud sessions

It lives on a **separate branch that will later move to its own repository**. The working name is
**"Taxi AM"**, and it's easy to rename.

Market facts that shape the design:
- **Yandex Go dominates**, and local players (gg, Bolt-style apps) compete on price and driver
  commission.
- **Cash is still a large share of rides,** so cash-first payments are needed, with commission owed
  by drivers tracked in a ledger.
- **Drivers are mostly on Android.**
- **Hayeren, Russian and English are all needed** from day one.
- **Taxi permits and personal-data law** must be checked before launch.

## Branch and repo strategy
- Create an **orphan branch `taxi-main`**: no Spark history; `rails new` from an empty tree. It acts as
  the taxi project's `main`.
- **Feature work** happens on `claude/taxi-<phase>` branches cut from `taxi-main`. **PRs target
  `taxi-main`**, never Spark's `main`.
- **CI:** the taxi `ci.yml` triggers on `pull_request` and on pushes to `taxi-main`, so it runs here
  and keeps working after the move.
- **Deploy:** `deploy.yml` ships disabled (`DEPLOY_ENABLED`) until the move.
- **Moving later** is lossless:
  ```
  git push git@github.com:<owner>/taxi-am.git taxi-main:main
  ```
  Then rename the workflow branch filters from `taxi-main` to `main`.

## Reused from Spark
These are copied and adapted, not shared code:
- **Wallet + append-only `LedgerEntry`** (row lock, cached balance, DB check constraints): drivers'
  commission balance and cash settlements
- **`Moderation` + `ModerationAction` audit log + `Admin::BaseController`:** driver approval, bans,
  complaints
- **Per-user `rate_limit`**, the session-cookie-aware Action Cable connection, `AdminConstraint`
- **Ahoy server-side events, `DailyMetric` job, `Analytics::*` service, `ChartsHelper`
  (validated palette):** ops and revenue dashboards
- **CI and dev tooling:** the CI layout (lint, scans, RSpec on PostGIS, Docker build, plus an
  integration job like `media_smoke`), the Kamal accessory pattern, the SessionStart hook,
  `CLAUDE.md`, the k6 load-test layout

## Stack
- Rails 8.1, PostgreSQL 17 + **PostGIS**. This time real geo queries justify it: nearest drivers,
  service zones, pickup areas. Use `activerecord-postgis-adapter`, with the PostGIS image already
  used in CI.
- Hotwire, Tailwind, Solid Queue/Cache/Cable (no Redis), RSpec.
- **Maps:**
  - **Map display:** MapLibre GL in the browser, with vector tiles from MapTiler (free tier) or
    self-hosted later.
  - **Routing and ETA:** **OSRM** as a Kamal accessory with the Armenia OpenStreetMap extract (small,
    quick to build).
  - **Geocoding and search:** Nominatim self-hosted for Armenia, with a pluggable `Geocoder` adapter so
    Yandex or 2GIS can be swapped in if their address quality is better.
- **SMS one-time codes** for sign-in, behind an `SmsSender` adapter: Twilio to start, with a local
  Armenian SMS gateway as an option.
- **Rider app:** Hotwire (Rails views), installable as a PWA.
- **Driver app: a React PWA** (the user's choice: simple, one codebase, no app store).
  - **Code and build:** lives in the same repo (`app/frontend/driver`), built with **Vite**
    (`vite_rails` gem), and served from the same domain at `/driver`.
  - **Server connection:** JSON API under `/api/v1/driver/*` plus Action Cable
    (`@rails/actioncable`). The same-origin session cookie handles auth, so there are no tokens to
    manage.
  - **Offline and install:** a service worker caches the app shell for flaky mobile data and makes
    it installable to the home screen.
  - **Push:** Web Push (VAPID, `web-push` gem) for ride offers. It works on Android Chrome and on iOS
    16.4+ when the app is installed.
  - **Known PWA limit:** browsers pause GPS and timers when the app is in the background or the screen
    is off. Mitigations:
    - the **Screen Wake Lock** keeps the screen on while the driver is online
    - the online toggle warns when the app goes to the background, and the server sets drivers
      offline after 60 s without a location update, so dispatch never offers rides to a stale
      position
    - navigation opens Google Maps, Yandex or 2GIS in another app and returns, and the driver
      re-confirms on return
  - If drivers complain about these limits, a thin native wrapper around the same React app can be
    added later.

## Phases (one Claude cloud session and one PR each, PRs into `taxi-main`)
0. **Bootstrap**
   - orphan `taxi-main` with `rails new` (PostgreSQL + PostGIS adapter, Tailwind) and RSpec
   - CI, Kamal skeleton, SessionStart hook, `CLAUDE.md`, `docs/ROADMAP.md`
   - I18n set up for hy/ru/en from the first view
1. **Phone sign-in and roles** (done: Twilio SMS behind `SmsSender`)
   - phone plus SMS code login (rate-limited per phone and per IP, codes hashed and expiring)
   - `User` roles: rider, driver, dispatcher, admin
   - rider profile and saved places (home, work)
2. **Drivers and vehicles** (done)
   - driver application: license, ID, car registration, photos via Active Storage; vehicle make,
     model, color, plate
   - admin review queue (approve, reject, ask for more) through `Moderation` with the audit log
   - document expiry reminders
3. **Maps, places and pricing**
   - **map and places:** MapLibre map, address search, map pin, reverse geocoding
   - **OSRM:** routes, distance and ETA, run as a Kamal accessory, plus a CI job that runs OSRM on a
     tiny extract (same idea as `media_smoke`)
   - **tariffs in AMD:** Economy and Comfort, with base, per-km, per-minute and minimum fare, set by
     admin
   - **fare estimate before booking,** and **service zones** (Yerevan first) as PostGIS polygons
4. **Booking, dispatch and live tracking (the core)**
   - **Trip state machine:** requested → offered → accepted → driver_arriving → arrived → in_progress
     → completed, or cancelled (by rider, driver or system), with a reason
   - **Dispatcher:**
     - online drivers that are nearest by route ETA (PostGIS shortlist, then OSRM table)
     - one driver offered at a time with a 15 s timeout, then the next driver (Solid Queue job)
     - no double booking (row lock on the driver)
   - **Driver location:** sent every 3–5 s over Action Cable while online. The latest position goes
     in an indexed `driver_locations` table; trip breadcrumbs are kept for disputes.
   - **Live tracking:** the rider sees the car approach (Turbo Streams / cable broadcasts) and gets
     the driver's name, car, plate and ETA.
   - **Cancellations:** fees and rules set by admin.
5. **Payments and driver money**
   - **Cash first.** On completion, the driver's commission (for example 10–15%, set by admin) is
     debited from their **driver balance** with `Wallet`-style ledger entries.
   - **Driver top-ups:** drivers top up by card or at a kiosk. A driver below the minimum balance
     can't go online.
   - **Card payments:** through a local provider adapter (Ameriabank vPOS/ArCa, Idram, Telcell),
     using the same signed-callback-credits-only, idempotent pattern as Spark's Stripe webhook.
   - **Receipts** by SMS and email, plus daily driver earnings statements.
6. **Ratings, safety and support**
   - two-way 5-star ratings with reasons, which feed dispatch priority and automatic driver review
   - share-trip link
   - SOS button (sends the trip, location and driver to the support queue and to a contact)
   - lost items, and a complaints queue in admin
7. **Operations dashboard**
   - live map of online, busy and offline drivers and open requests
   - trips list with replay of the breadcrumb route
   - dispatcher tools: manual assign, cancel, call masking through the SMS/voice provider (later)
8. **Driver React PWA.** A first slim version lands with Phase 4, because dispatch needs a driver
   client. This phase makes it production-ready:
   - **Screens:** go online/offline, the incoming offer with a countdown and sound, the trip screen
     (navigate, arrived, start, complete with the fare), earnings and balance, top-up, documents and
     profile. Hy/ru/en via i18next, using strings exported from Rails I18n.
   - **Device features:** the Wake Lock and stale-location safeguards, a service worker (app-shell
     cache, Web Push offers), an install prompt, and a large-touch-target UI for phones mounted in
     the car.
   - **Tests:**
     - Vitest + React Testing Library for components and the trip flow
     - Playwright end-to-end with mocked geolocation against the Rails test server
9. **Analytics and growth** (from Spark's Phase 7):
   - **KPIs:** trips, GMV, take rate, completed vs cancelled, request-to-accept time, pickup ETA,
     driver utilization and online hours, rider retention
   - **supply/demand heatmap by hour:** where to recruit drivers
   - promo codes and referral rides (ledger-backed), and A/B tests on pricing display

## CI/CD (same shape as Spark)
- **`ci.yml`:**
  - scans, RuboCop, RSpec on `postgis/postgis:17`, Docker build
  - **driver-app jobs:** `npm ci`, ESLint, Vitest and a Vite production build. The Docker image builds
    it too, through vite_ruby's assets:precompile hook.
  - a **`routing` job:** OSRM on a tiny OSM extract, checking that fare estimates come from real
    routes
  - a **`dispatch` job:** concurrent booking simulation, checking that no driver gets double-booked
- **`deploy.yml`:** Kamal to a VPS, gated on `DEPLOY_ENABLED`. Accessories: PostGIS DB, OSRM,
  Nominatim (and tiles later).
- **k6 load tests:** 300 drivers sending location every 4 s plus booking bursts.

## Rough monthly running cost at launch (Yerevan)
| Item | Cost |
|---|---|
| App VPS | $20–40 |
| Routing/geocoding VPS: OSRM + Nominatim for Armenia (8 GB RAM is enough) | $20–30 |
| Map tiles (MapTiler free tier, then about $25) | $0–25 |
| SMS codes (about $0.03–0.08 each) | $20–60 |
| **Total** | **≈ $60–150 a month** |

## Verification (each phase)
- `bin/ci` green locally and in CI on PRs into `taxi-main`.
- Browser end-to-end test from Phase 4 on: two Chromium windows (rider and driver) with simulated GPS
  (Playwright geolocation):
  - book, offer, accept, approaching car on the map, trip, completion
  - commission ledger entry, ratings
  - screenshots sent to you
- Dispatch race test: 20 simultaneous requests and 5 drivers; no driver is double-booked and every
  request gets a final status.

## First step after approval
Phase 0:
- create orphan `taxi-main`
- `rails new` with PostGIS, RSpec, I18n hy/ru/en, CI, Kamal skeleton, `CLAUDE.md` and
  `docs/ROADMAP.md` (this plan)
- push `taxi-main`, then open the Phase 1 branch from it

Spark's `main` is not touched.
