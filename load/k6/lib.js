import http from "k6/http";
import { check } from "k6";

export const BASE = __ENV.BASE_URL || "http://localhost:3000";

// Signs in as load-N@example.com (bin/rails "load:users[N]") and returns the page's CSRF token.
export function signIn(n) {
  const page = http.get(`${BASE}/session/new`);
  const res = page.submitForm({
    formSelector: "form[action$='/session']",
    fields: { email_address: `load-${n}@example.com`, password: "password123" },
  });
  check(res, { "signed in": (r) => r.status === 200 && r.url !== `${BASE}/session/new` });
  return csrf(res);
}

export function csrf(res) {
  return res.html().find("meta[name=csrf-token]").attr("content");
}
