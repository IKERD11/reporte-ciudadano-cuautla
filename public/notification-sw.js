self.addEventListener("push", (event) => {
  if (!event.data) return
  const payload = event.data.json()
  const options = {
    body: payload.message,
    icon: "/favicon.svg",
    badge: "/favicon.svg",
    tag: payload.dedupeKey || payload.id,
    renotify: payload.priority === "emergency",
    silent: payload.sound === false,
    vibrate: payload.vibration === false ? [] : [180, 80, 180],
    data: {
      notificationId: payload.id,
      destination: payload.destination,
    },
  }
  event.waitUntil(self.registration.showNotification(payload.title, options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const data = event.notification.data || {}
  const destination = data.destination || {}
  const target = new URL("/", self.location.origin)
  if (data.notificationId)
    target.searchParams.set("notification", data.notificationId)
  if (destination.kind) target.searchParams.set("kind", destination.kind)
  if (destination.entityId)
    target.searchParams.set("entityId", destination.entityId)

  event.waitUntil(
    clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((list) => {
        for (const client of list) {
          if ("focus" in client) {
            client.navigate(target.href)
            return client.focus()
          }
        }
        return clients.openWindow(target.href)
      }),
  )
})
