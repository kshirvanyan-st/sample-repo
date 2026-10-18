# Plan: "Spark" — a dating and live-streaming social network on Rails 8 (Topface + Bigo/Tango style)

## Context
`kshirvanyan-st/sample-repo` is empty. The goal is a general-audience social app that combines:
- Topface-style dating: profiles, a swipe card game, matches and chat
- live streaming: go live, watch, live chat, gifts paid with coins, follows

It is built on generated Rails 8 code and changed to fit, developed with Claude Code in the cloud, and
shipped through GitHub Actions CI/CD.

Choices confirmed with the user:
- Base: Rails 8 plus its generators
- Deploy: Kamal to a VPS
- Audience: general (no adult content)
- Video: self-hosted **MediaMTX**
- Scope: keep dating **and** add streaming

### What changes compared with the dating-only plan
- **Media plane:** Rails can't carry video. MediaMTX does that work:
  - broadcasters send video in through WebRTC (WHIP) from the browser, or RTMP from OBS
  - viewers watch over WebRTC (WHEP) for under 1 s latency, or LL-HLS for large audiences
  - coturn handles NAT traversal
- **Rails is the control plane.** It handles:
  - MediaMTX's HTTP auth callback, which allows or denies each publish and read
  - stream keys
  - stream state, through MediaMTX's `runOnReady`/`runOnNotReady` hooks and its HTTP API
  - viewer counts
  - live chat over Solid Cable
- **Money moves into the MVP.** Gifts need coins:
  - coin packs sold through Stripe Checkout
  - an append-only ledger
  - creator earnings (Stripe Connect payouts come later)
- **Moderation is stricter for live video.** Stream reports, an admin "kill stream" (MediaMTX API kick),
  per-stream chat moderators, an 18+ minimum age for broadcasters, and an option to save recordings for
  review.
- **Infrastructure:** MediaMTX and coturn run as extra Kamal accessories. They need UDP ports, host
  networking, and more bandwidth. A dedicated media VPS is advisable.

## Stack
- Ruby 3.4 and Rails 8.x
- PostgreSQL 17 + PostGIS
- Hotwire and Tailwind
- Active Storage + libvips
- Solid Queue, Solid Cable and Solid Cache
- Pundit, pagy, rack-attack
- RSpec, FactoryBot, Capybara
- Stripe (`stripe` gem)
- Media: MediaMTX (Docker `bluenviron/mediamtx`), coturn, and `hls.js` plus a small WHIP/WHEP client
  in Stimulus

## Phases (one Claude cloud session → one PR each)

### Phase 0 — Bootstrap (PR #1)
- Run `rails new . -d postgresql --css=tailwind -T`.
- Add RSpec.
- Run `g authentication` and add a registrations controller.
- Add `CLAUDE.md`, and a `.claude/hooks/session-start.sh` SessionStart hook that runs bundle, starts
  Postgres, and runs `db:prepare`.
- Expand `ci.yml`.

### Phase 1 — Profiles and photos (PR #2)
- `Profile` model: name, birthdate (18+), gender, looking_for, city, bio, `lonlat:st_point`.
- `has_many_attached :photos` with variants, at most 9 photos, and moderation status.
- An onboarding wizard.
- `Follow(follower, followee)` is added here, because both dating and streaming use it.

### Phase 2 — Dating: swipe and matches (PR #3)
- `Like(liker, likee, kind)` with a unique index on the pair; a mutual like creates a `Match`.
- `Discovery::Feed` query object (PostGIS distance, filters, excludes users already rated or blocked).
- Stimulus `swipe_controller`, plus "Who liked me" and "Matches" pages.
- `Block` and `Report` models, and rate limits.

### Phase 3 — Direct chat (PR #4)
- `Conversation` and `Message`.
- Turbo Stream broadcasts over Solid Cable, read receipts, and a Pundit policy.

### Phase 4 — Live streaming core (PR #5)
**Models**
- `Stream(user, title, category, status: scheduled|live|ended, stream_key (encrypted), started_at,
  ended_at, peak_viewers)`
- `StreamViewer` (presence)

**MediaMTX config** in `config/mediamtx.yml`:
- `authMethod: http`, pointing at `POST /media/auth`
- paths `live/<stream_key>` for publishing and `watch/<stream_id>` for viewing (aliased with
  `source: rtsp://localhost/live/...`), or a single path that Rails authorizes for both
- `runOnReady` and `runOnNotReady` call `POST /media/hooks/ready` and `/notready` with a shared secret

**Rails controllers**
- `Media::AuthController`:
  - publishing requires a valid stream key, an owner who is 18+ and in good standing, and no other live
    stream already running
  - reading requires a stream that is live and a viewer who isn't blocked
  - returns 200 or 401
- `Media::HooksController`: moves `Stream` to `live` or `ended` and broadcasts a "now live" Turbo Stream
  to followers

**UI**
- "Go Live" page: a Stimulus `whip_controller` captures `getUserMedia` and publishes over WHIP; OBS
  instructions show the RTMP URL and key.
- Watch page: a `whep_controller` plays over WebRTC and falls back to `hls.js` LL-HLS.
- Live chat: `StreamChannel` (Action Cable), with rate limiting and moderator roles.
- Viewer count comes from Action Cable presence.

**Discovery**
- "Live now" grid by category or nearby; followed broadcasters first.
- Swipe cards show a "LIVE" badge that opens the stream.

### Phase 5 — Coins and gifts (PR #6)
**Models**
- `CoinPack`
- `Wallet`, with balance cached on the user
- `LedgerEntry(user, amount, kind: purchase|gift_sent|gift_received|refund, ref)`: append-only, and the
  balance is the sum of entries, written inside a DB transaction with a row lock
- `Gift` catalog
- `GiftTransaction(stream, sender, recipient, gift, coins)`

**Purchase and gifting**
- Stripe Checkout for coin packs; a `StripeWebhooksController` credits coins idempotently, keyed on
  `event.id`.
- Gift animations play over the stream through the Turbo Stream / Action Cable overlay, with a top
  gifters leaderboard.
- Creator earnings view. Payouts (Stripe Connect) and VIP subscriptions go in the backlog.

### Phase 6 — Moderation and hardening (PR #7)
- Admin area with:
  - a live streams dashboard
  - kill stream, which calls the MediaMTX API `/v3/paths/kick` and suspends the broadcaster's key
  - reports queue, photo review, and user bans
- Optional recording (`record: yes` in MediaMTX for flagged streams), kept for N days.
- Load test: k6 for HTTP and Action Cable, and a WHEP viewer swarm for MediaMTX.
- Seed data: fake profiles plus a looping test stream (an ffmpeg pusher in dev).

### Phase 7 — Revenue monitoring and growth analytics (PR #8)
This phase shows where money comes from and what to change to earn more.

**Tools (free, they run inside the Rails app, no extra service bill)**
- `ahoy_matey`: records visits and product events, for example `signup`, `profile_completed`,
  `swipe`, `match`, `stream_started`, `stream_watched`, `coins_checkout_opened`, `coins_purchased`,
  `gift_sent`.
- `blazer`: SQL dashboards and scheduled **checks**, alerts that email or Slack you, mounted at
  `/admin/blazer`.
- `field_test`: A/B tests, for example coin pack prices or first-purchase bonus size.
- Stripe Dashboard: the source of truth for payments, refunds and chargebacks. Rails also stores every
  purchase in `ledger_entries`, so revenue can be joined with user behavior.
- Prometheus + Grafana, run as Kamal accessories on the media VPS:
  - MediaMTX metrics (`metrics: yes`, port 9998): viewers, bytes sent, streams
  - node_exporter: server bandwidth and CPU

  This gives **infrastructure cost per viewer-hour**.
- Optional: PostHog Cloud (free up to about 1M events per month) for funnels, session replays and
  retention charts, if Blazer isn't enough.

**Revenue dashboard (`/admin/revenue`) KPIs, refreshed by a daily Solid Queue job into
`daily_metrics`**

| KPI | Why it matters |
|---|---|
| Revenue per day/week, split by coin pack | Shows which packs sell |
| Payer conversion (payers ÷ DAU) | Tells you whether to make the first purchase easier |
| ARPU and ARPPU | Average revenue per user and per paying user |
| LTV by signup cohort compared with CAC (ad spend ÷ signups) | Is it worth buying users? |
| D1/D7/D30 retention (dating users vs. stream viewers) | Which feature keeps people |
| Gifts per stream-hour and top broadcasters by gifts received | Which creators to promote or feature |
| Coins purchased vs. coins spent (unspent balance) | Unspent coins mean the catalog is weak |
| Funnel: signup → profile → first match/first stream view → checkout opened → purchase | Where users drop off |
| Gross margin = revenue − Stripe fees − creator payouts − infrastructure cost (from Grafana bandwidth × price per TB) | Real profit |
| Refund and chargeback rate | Stripe risk; keep it under 0.75% |

**Alerts (Blazer checks)**
- revenue today is more than 30% below the 7-day average
- payment failure spike
- chargeback rate above 0.5%
- media bandwidth above budget
- a broadcaster earning unusually fast (fraud)

**Levers to test with `field_test`**
- coin pack pricing and a "best value" badge
- first-purchase 2× bonus
- daily login rewards
- paid profile boosts in the swipe deck
- "super like" costing coins
- featured "Live now" placement
- VIP subscription (no ads, see who liked you, more swipes), sold through Stripe Billing in the backlog

## Infrastructure and Kamal (`config/deploy.yml`)
- **web:** the Rails app on app VPS #1, with `kamal-proxy` and Let's Encrypt.
- **job:** Solid Queue running `bin/jobs`.
- **accessories:**
  - `db`: `postgis/postgis:17`
  - `mediamtx`: on media VPS #2
    - host network
    - ports 8889 (WHEP/WHIP HTTPS), 8189/udp (WebRTC), 1935 (RTMP), 8888 (HLS)
    - `config/mediamtx.yml` mounted into the container
  - `coturn`: on the media VPS
    - ports 3478 TCP/UDP and a relay UDP range
- Put a CDN (for example Bunny or Cloudflare) in front of HLS for large audiences.
- Expose `media.<domain>` for WebRTC endpoints, with TLS from certbot or Caddy on the media VPS.
- Rails generates short-lived TURN credentials (the coturn REST API shared-secret scheme) and passes
  them to the browser.

## CI/CD with GitHub Actions
**`ci.yml`** runs on PRs and on push to `main`:
- **Security and lint:** Brakeman, `bundle audit`, `importmap audit`, RuboCop.
- **Tests:**
  - services: `postgis/postgis:17`
  - steps: `db:prepare`, then RSpec (models, request and system specs)
  - uploads screenshots when a test fails
- **Media integration job:**
  - starts `bluenviron/mediamtx` as a service with the test config pointing at the Rails test server
  - pushes a test pattern over RTMP with `ffmpeg`
  - checks that `/media/auth` allowed it and that the `Stream` became `live`
  - checks that a reader with a bad key is rejected
- **Docker build check:** `docker build` of the app image.

**`deploy.yml`** runs on push to `main` after CI passes:
- deploys to the `production` GitHub Environment, which requires manual approval
- runs `kamal deploy`, plus `kamal accessory reboot mediamtx` when `config/mediamtx.yml` changed
  (path filter)
- Secrets:
  - `RAILS_MASTER_KEY`
  - `KAMAL_REGISTRY_PASSWORD`, for GHCR
  - `SSH_PRIVATE_KEY`
  - `POSTGRES_PASSWORD`
  - `MEDIAMTX_HOOK_SECRET`
  - `TURN_SECRET`
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
- **Smoke test after deploy:** curl `/up` and the MediaMTX API health endpoint.

**Branch protection on `main`:** all CI checks must pass, plus one review.

## Working with Claude in the cloud
- Each phase is one Claude Code cloud session on a `claude/<feature>` branch.
- In each session Claude writes specs first, implements the feature, and runs RuboCop, Brakeman and
  RSpec. Phase 4 and later sessions also run MediaMTX locally through Docker, or as a binary, with an
  ffmpeg test source.
- Claude then pushes and opens a PR, subscribes with `subscribe_pr_activity`, and fixes CI and review
  comments until the PR is green.
- Merging triggers `deploy.yml`.
- `CLAUDE.md` documents the architecture: Rails is the control plane and MediaMTX is the media plane.
  It also lists the commands to run, so every session starts with the same context.

## Key files
- `Gemfile`
- `config/database.yml` (postgis)
- `config/deploy.yml`
- `.kamal/secrets`
- `config/mediamtx.yml`
- `config/coturn/turnserver.conf`
- `.github/workflows/{ci,deploy}.yml`
- `CLAUDE.md`
- `.claude/hooks/session-start.sh`
- Models: `app/models/{user,profile,follow,like,match,conversation,message,block,report,stream,
  stream_viewer,wallet,ledger_entry,coin_pack,gift,gift_transaction}.rb`
- Controllers: `app/controllers/media/{auth,hooks}_controller.rb` and
  `app/controllers/stripe_webhooks_controller.rb`
- Query objects: `app/queries/discovery/{feed,live_now}.rb`
- Channels: `app/channels/stream_channel.rb`
- Stimulus controllers: `app/javascript/controllers/{swipe,whip,whep,gift}_controller.js`
- Specs: `spec/**`, with `spec/media/` for the MediaMTX integration tests

## Verification
- **Dev:** `bin/dev` together with `docker run bluenviron/mediamtx` using the dev config. Then:
  - sign up users A and B
  - A goes live from the browser over WHIP; B sees "Live now" and watches over WHEP with under 1 s delay
  - B chats and sends a gift bought with Stripe test-mode coins; A's earnings increase
  - an admin kills the stream and B's player stops
- **Dating flow:** a mutual like creates a match, and the DM chat works in real time.
- **Tests:** `bundle exec rspec` passes. The CI media integration job passes: an ffmpeg RTMP push is
  authorized and the stream goes live.
- **Production:** after merge, `deploy.yml` succeeds and `/up` returns 200. A test broadcast from OBS to
  `rtmp://media.<domain>/live/<key>` plays on the watch page; check this from a mobile network to confirm
  TURN works.

## Estimated monthly cost (rough, USD; prices change, so check them before buying)
Bandwidth is the main cost. One viewer at about 2.5 Mbps uses about 1.1 GB per hour.
MediaMTX passes video through without transcoding, so it needs little CPU.

| Item | MVP / beta (≤50 concurrent viewers) | Growth (~150 average, 500 peak viewers) | Scale (~1,500 average viewers) |
|---|---|---|---|
| App VPS (Rails, jobs) | $10–15 (1× Hetzner 4 vCPU/8 GB) | $40–60 (2× + load balancer) | $150–300 |
| Postgres (accessory + backups) | $0–5 (same box) | $30–50 (dedicated box) | $100–200 |
| Media VPS (MediaMTX + coturn) | $15–30 (1× dedicated vCPU, 20 TB included) | $150–250 (2–3 boxes, ~120 TB/month) | $1,500–3,000 (dedicated 1 Gbit servers, ~1.2 PB/month) |
| Photo storage (S3-compatible) | $5 | $10–20 | $50–100 |
| Email (Postmark/SES) | $0–15 | $15–50 | $50–100 |
| Error monitoring (Sentry) | $0 | $26 | $80 |
| Domain + DNS | $1–2 | $1–2 | $1–20 |
| GitHub (repo, Actions, GHCR) | $0–4 | $4–20 | $20–50 |
| **Infrastructure total** | **≈ $35–75** | **≈ $300–500** | **≈ $2,000–4,000** |
| Claude for development | $20 Pro, or $100–200 Max for daily cloud sessions | same | same, per developer |

Variable costs:
- Stripe takes about 2.9% + $0.30 per coin purchase, so sell larger coin packs.
- App store in-app purchases take 15–30% if the app is later released as a mobile app.

Cost levers:
- Serve HLS through a CDN only for very popular streams.
- Cap bitrate at 720p / 2 Mbps.
- Add ABR transcoding only when needed; it means more CPU.

## First step after approval
Phase 0 bootstrap PR: the Rails 8 app, RSpec, authentication, CLAUDE.md, the SessionStart hook and CI.
