# Spark

Dating + live-streaming social network on Rails 8. See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the plan.

## Development

```sh
bin/setup      # installs gems, prepares the database, starts the server
bin/dev        # Rails + Tailwind watcher
bin/media      # MediaMTX for live streaming (binary on PATH or Docker), talks to bin/dev
bin/rails db:seed   # demo profiles; sign in as demo@example.com / password123
bin/rspec      # test suite
script/media_smoke  # end-to-end streaming check with real MediaMTX + ffmpeg
bin/dev_stream      # keep a test-pattern stream live as a seeded user (needs bin/media)
```

### Moderation

- Make someone staff: `bin/rails "users:grant[email@example.com,admin]"` (or `moderator`).
  In production: `bin/kamal app exec 'bin/rails "users:grant[you@example.com,admin]"'`.
- Staff see **Admin** in the nav (`/admin`): reports queue, photo review, live streams
  (end, or end + suspend streaming), user search with ban/unban and roles, and an audit log
  of every action. Non-staff get a 404.
- Banning signs the user out everywhere, ends their stream, closes reports against them and
  hides them from discovery, profiles, Liked me and Live now.
- `PHOTO_MODERATION=manual` keeps new photos pending (visible only to their owner) until
  approved in `/admin/photos`; the default approves them automatically.

### Load tests

k6 scripts for browsing/swiping and for a crowd on a live stream are in [`load/`](load/README.md).

### Live streaming

Rails is the control plane; [MediaMTX](https://github.com/bluenviron/mediamtx) moves the video.

- **Broadcasters** go live from the browser (WebRTC/WHIP) or OBS (WHIP on OBS 30+, or RTMP).
  MediaMTX asks Rails (`POST /media/auth`) whether the stream key is valid, and tells Rails
  when video starts/stops (`/media/hooks/ready|not_ready`). `StreamReconcileJob` catches missed hooks.
- **Viewers** get a short-lived signed token from Rails and play over WebRTC (WHEP, <1 s) or
  low-latency HLS (RTMP sources, whose AAC audio WebRTC can't carry).
- Config: `config/media/mediamtx.yml` (shared), `config/initializers/media.rb` (Rails side).

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

### Coin payments (Stripe)

1. In the Stripe dashboard, add a webhook endpoint `https://<APP_HOST>/stripe/webhooks` for
   `checkout.session.completed`, `checkout.session.async_payment_succeeded`, `checkout.session.expired`
   and `charge.refunded`.
2. Add the **secrets** `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` (the endpoint's signing secret).
3. Create the coin packs and gifts once: `bin/kamal app exec "bin/rails db:seed"`.

Coins are credited only by the signed webhook, never by the redirect back from Checkout. Every coin
movement is a row in the append-only `ledger_entries` table (`Wallet` is the only writer). Locally,
without Stripe keys, buying a pack adds the coins directly (development only); with test keys, use
`stripe listen --forward-to localhost:3000/stripe/webhooks`.

### Live streaming server (optional)

Streaming runs on a second VPS (Caddy needs ports 80/443, which kamal-proxy holds on the web host):

1. Point a domain such as `media.example.com` at the media VPS. Open TCP 80, 443, 1935 and UDP 8189.
2. Add **variables** `MEDIA_HOST=<media VPS IP>`, `MEDIA_DOMAIN=media.example.com` and the **secret**
   `MEDIA_HOOK_SECRET` (`openssl rand -hex 32`).
3. First time only: `bin/kamal accessory boot mediamtx && bin/kamal accessory boot caddy`.
   Later deploys restart them when `config/media/` changes.

Optional TURN for viewers behind strict NATs: run coturn with `use-auth-secret` and set `TURN_URLS`
and `TURN_SECRET` for the app; Rails hands out time-limited TURN credentials.
