# Load tests (k6)

1. Create test users on the target (never production): `bin/rails "load:users[50]"`
2. Browsing and swiping: `k6 run -e BASE_URL=http://localhost:3000 -e VUS=20 load/k6/browse.js`
3. A crowd on one live stream (Action Cable + HLS): start a stream (`bin/dev_stream`), then
   `k6 run -e BASE_URL=http://localhost:3000 -e STREAM_ID=<id> -e VUS=30 load/k6/live_viewers.js`

Sign-in is rate limited per IP (10 per 3 minutes), and every virtual user comes from the k6
machine's IP, so start the target with e.g. `SIGN_IN_RATE_LIMIT=1000`. Other limits (likes,
messages, gifts) are per user, so they behave as in production.

Tunables: `VUS`, `DURATION`, `USERS` (how many load-N accounts exist). Thresholds fail the run
when more than 1% of requests error or Discover/like p95 goes over 800 ms.

WebRTC (WHEP) viewers can't be simulated with k6; WebRTC capacity is MediaMTX's job and is
best measured on the media server itself (`metrics: yes`, port 9998).
