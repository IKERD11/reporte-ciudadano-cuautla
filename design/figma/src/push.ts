import { supabase } from "./supabase"

const vapidPublicKey = import.meta.env.VITE_VAPID_PUBLIC_KEY

function decodeVapidKey(value: string) {
  const padding = "=".repeat((4 - (value.length % 4)) % 4)
  const base64 = (value + padding).replace(/-/g, "+").replace(/_/g, "/")
  return Uint8Array.from(atob(base64), (character) => character.charCodeAt(0))
}

async function authorizedRequest(path: string, init: RequestInit = {}) {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (!session) throw new Error("Authentication required")

  const response = await fetch(path, {
    ...init,
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      "Content-Type": "application/json",
      ...init.headers,
    },
  })
  if (!response.ok) throw new Error(`Push API error: ${response.status}`)
  return response
}

export async function subscribeToPush(apiBaseUrl: string) {
  if (
    !("serviceWorker" in navigator) ||
    !("PushManager" in window) ||
    !vapidPublicKey
  )
    return "unsupported" as const

  const permission = await Notification.requestPermission()
  if (permission !== "granted") return permission

  const registration = await navigator.serviceWorker.register(
    "/notification-sw.js",
  )
  const existing = await registration.pushManager.getSubscription()
  const subscription =
    existing ??
    (await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: decodeVapidKey(vapidPublicKey),
    }))

  await authorizedRequest(`${apiBaseUrl}/push-subscriptions`, {
    method: "POST",
    body: JSON.stringify({
      subscription: subscription.toJSON(),
      userAgent: navigator.userAgent,
    }),
  })
  return "granted" as const
}

export async function unsubscribeFromPush(apiBaseUrl: string) {
  if (!("serviceWorker" in navigator)) return
  const registration = await navigator.serviceWorker.getRegistration(
    "/notification-sw.js",
  )
  const subscription = await registration?.pushManager.getSubscription()
  if (!subscription) return

  await authorizedRequest(`${apiBaseUrl}/push-subscriptions`, {
    method: "DELETE",
    body: JSON.stringify({ endpoint: subscription.endpoint }),
  }).catch(() => undefined)
  await subscription.unsubscribe()
}
