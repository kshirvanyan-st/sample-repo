// A crowd watching one live stream: each viewer opens the watch page, keeps an Action Cable
// connection with the chat + presence subscriptions, and pulls the HLS playlist like a player.
//   STREAM_ID=12 k6 run -e BASE_URL=... load/k6/live_viewers.js
import http from "k6/http";
import ws from "k6/ws";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";
import { BASE, signIn } from "./lib.js";

const confirmed = new Counter("cable_subscriptions_confirmed");
const segments = new Counter("hls_playlist_fetches");

export const options = {
  scenarios: {
    viewers: { executor: "ramping-vus", stages: [ { duration: "10s", target: Number(__ENV.VUS || 30) }, { duration: __ENV.DURATION || "30s", target: Number(__ENV.VUS || 30) } ] },
  },
  thresholds: { http_req_failed: [ "rate<0.02" ], checks: [ "rate>0.98" ] },
};

export default function () {
  signIn(((__VU - 1) % Number(__ENV.USERS || 50)) + 1);
  const page = http.get(`${BASE}/live/${__ENV.STREAM_ID}`, { tags: { page: "watch" } });
  check(page, { "watch page": (r) => r.status === 200 });

  const doc = page.html();
  const streams = doc.find("turbo-cable-stream-source").toArray().map((el) => el.attr("signed-stream-name"));
  const player = doc.find("[data-playback-token-value]");
  const token = player.attr("data-playback-token-value");
  const hls = player.attr("data-playback-hls-url-value");

  const cookies = http.cookieJar().cookiesForURL(BASE);
  const cableUrl = BASE.replace(/^http/, "ws") + "/cable";
  const holdSeconds = 20;

  const res = ws.connect(cableUrl, { headers: { Origin: BASE, Cookie: `session_id=${cookies.session_id}` } }, (socket) => {
    socket.on("open", () => {
      for (const name of streams) socket.send(JSON.stringify({ command: "subscribe", identifier: JSON.stringify({ channel: "Turbo::StreamsChannel", signed_stream_name: name }) }));
      socket.send(JSON.stringify({ command: "subscribe", identifier: JSON.stringify({ channel: "StreamPresenceChannel", stream_id: Number(__ENV.STREAM_ID) }) }));
    });
    socket.on("message", (data) => { if (JSON.parse(data).type === "confirm_subscription") confirmed.add(1); });
    // Poll the playlist while connected, as an HLS player would.
    socket.setInterval(() => {
      if (!hls || !token) return;
      const playlist = http.get(`${hls}?token=${encodeURIComponent(token)}`, { tags: { page: "hls" } });
      check(playlist, { "hls playlist": (r) => r.status === 200 && r.body.includes("#EXTM3U") });
      segments.add(1);
    }, 2000);
    socket.setTimeout(() => socket.close(), holdSeconds * 1000);
  });
  check(res, { "cable connected": (r) => r && r.status === 101 });
  sleep(1);
}
