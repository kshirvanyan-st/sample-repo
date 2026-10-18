// JSON calls to /api/v1/driver/*, with the Rails CSRF token. Errors carry the server's message.
export class ApiError extends Error {}

function csrfToken() {
  return document.querySelector("meta[name=csrf-token]")?.content
}

export async function request(path, { method = "GET", body } = {}) {
  const response = await fetch(path, {
    method,
    credentials: "same-origin",
    headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
    body: body && JSON.stringify(body)
  })
  if (response.status === 401) {
    window.location.href = "/session/new"
    throw new ApiError("signed out")
  }
  const data = await response.json().catch(() => ({}))
  if (!response.ok) throw new ApiError(data.message || data.error || response.statusText)
  return data
}

export const api = {
  state: (url) => request(url),
  online: () => request("/api/v1/driver/state/online", { method: "POST" }),
  offline: () => request("/api/v1/driver/state/offline", { method: "POST" }),
  accept: (id) => request(`/api/v1/driver/offers/${id}/accept`, { method: "POST" }),
  decline: (id) => request(`/api/v1/driver/offers/${id}/decline`, { method: "POST" }),
  trip: (id, action, body) => request(`/api/v1/driver/trips/${id}/${action}`, { method: "POST", body }),
  wallet: () => request("/api/v1/driver/wallet"),
  topUp: (amount) => request("/api/v1/driver/top_ups", { method: "POST", body: { amount } })
}
