// Members browsing and swiping: sign in, open Discover, rate the top card, check Liked me,
// Matches and Live now.   k6 run -e BASE_URL=https://staging.example.com load/k6/browse.js
import http from "k6/http";
import { check, sleep } from "k6";
import { BASE, signIn, csrf } from "./lib.js";

export const options = {
  scenarios: {
    members: { executor: "ramping-vus", stages: [ { duration: "10s", target: Number(__ENV.VUS || 20) }, { duration: __ENV.DURATION || "30s", target: Number(__ENV.VUS || 20) }, { duration: "5s", target: 0 } ] },
  },
  thresholds: {
    http_req_failed: [ "rate<0.01" ],
    "http_req_duration{page:discover}": [ "p(95)<800" ],
    "http_req_duration{page:like}": [ "p(95)<800" ],
  },
};

export default function () {
  // Each virtual user signs in once and keeps its cookie, like a real browser.
  if (__ITER === 0) signIn(((__VU - 1) % Number(__ENV.USERS || 50)) + 1);

  for (let i = 0; i < 5; i++) {
    const deck = http.get(`${BASE}/discover`, { tags: { page: "discover" } });
    check(deck, { "deck loaded": (r) => r.status === 200 });
    const form = deck.html().find("form[action$='/likes']").first();
    const profileId = form.find("input[name=profile_id]").attr("value");
    if (profileId) {
      const like = http.post(`${BASE}/likes`, { profile_id: profileId, kind: Math.random() < 0.6 ? "like" : "skip", source: "deck" },
        { headers: { "X-CSRF-Token": csrf(deck), Accept: "text/vnd.turbo-stream.html" }, tags: { page: "like" } });
      check(like, { "rated": (r) => r.status === 200 });
    }
    sleep(1);
  }

  for (const [ path, page ] of [ [ "/liked-me", "liked_me" ], [ "/matches", "matches" ], [ "/live", "live" ], [ "/chats", "chats" ] ]) {
    check(http.get(`${BASE}${path}`, { tags: { page } }), { [`${page} ok`]: (r) => r.status === 200 });
  }
  sleep(1);
}
