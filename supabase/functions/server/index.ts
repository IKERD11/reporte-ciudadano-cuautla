import { Hono } from "npm:hono@4.12.8"
import { cors } from "npm:hono@4.12.8/cors"
import { logger } from "npm:hono@4.12.8/logger"
import { createClient } from "jsr:@supabase/supabase-js@2.49.8"
import webpush from "npm:web-push@3.6.7"
import * as kv from "./kv_store.tsx"
import {
  evaluatePushDelivery,
  isCategoryEnabled,
  isVisibleInInbox,
  type DeliveryPreferences,
  type NotificationPriority,
  type NotificationType,
  type PushDeliveryDecision,
} from "./notification_policy.ts"
type AuthVariables = {
  userId: string
  role: string
}

const app = new Hono<{ Variables: AuthVariables }>()

type NotificationPreferences = DeliveryPreferences

type StoredNotification = {
  id: string
  type: NotificationType
  priority: NotificationPriority
  title: string
  message: string
  createdAt: string
  expiresAt: string
  dedupeKey: string
  destination: {
    kind: "report" | "alert"
    entityId: string
  }
  deliveredAt?: string
  seenAt?: string
  readAt?: string
  readStateChangedAt?: string
  actionedAt?: string
  archivedAt?: string
  deletedAt?: string
  groupedCount?: number
  pushDelivery?: PushDeliveryDecision
}

export type CreateNotificationInput = {
  userId: string
  type: NotificationType
  priority?: NotificationPriority
  entityId: string
  title: string
  message: string
  createdAt?: string
  expiresAt?: string
  dedupeKey?: string
  destinationKind: "report" | "alert"
}

type StoredPushSubscription = {
  endpoint: string
  keys: {
    p256dh: string
    auth: string
  }
  userAgent?: string
  createdAt: string
  updatedAt: string
}

const defaultPreferences: NotificationPreferences = {
  reportUpdates: true,
  communityAlerts: true,
  nearbyIncidents: true,
  emergencies: true,
  sound: true,
  vibration: true,
  quietHoursEnabled: false,
  quietStart: "22:00",
  quietEnd: "07:00",
  emergencyOverride: true,
  pushPermission: "default",
  timeZone: "America/Mexico_City",
}

const notificationsKey = (userId: string) => `notifications:${userId}`
const preferencesKey = (userId: string) => `notification-preferences:${userId}`
const metricsKey = (userId: string) => `notification-metrics:${userId}`
const pushSubscriptionsKey = (userId: string) => `push-subscriptions:${userId}`
const legacyDestinationIds = {
  report: [
    "report_robbery_centro",
    "report_lighting_jardines",
    "report_animal_febrero",
    "report_bache_constitucion",
  ],
  alert: [
    "alert_robbery_centro",
    "alert_roadwork_febrero",
    "alert_lighting_jardines",
    "alert_traffic_constituyentes",
  ],
} as const
const priorityRank: Record<NotificationPriority, number> = {
  critical: 0,
  important: 1,
  informational: 2,
}
const groupingWindowMs: Record<NotificationPriority, number> = {
  critical: 0,
  important: 15 * 60 * 1000,
  informational: 60 * 60 * 1000,
}
const expirationMs: Record<NotificationPriority, number> = {
  critical: 24 * 60 * 60 * 1000,
  important: 7 * 24 * 60 * 60 * 1000,
  informational: 30 * 24 * 60 * 60 * 1000,
}

const defaultPriority = (type: NotificationType): NotificationPriority => {
  if (type === "emergency") return "critical"
  if (type === "report_update") return "important"
  return "informational"
}

const seedNotifications = (): StoredNotification[] => {
  const now = Date.now()
  const day = 24 * 60 * 60 * 1000
  return [
    {
      id: "report-road-progress",
      type: "report_update",
      priority: "important",
      title: "Tu reporte está en proceso",
      message: "La cuadrilla municipal ya atiende el bache en Av. Reforma.",
      createdAt: new Date(now - 12 * 60 * 1000).toISOString(),
      deliveredAt: new Date(now - 12 * 60 * 1000).toISOString(),
      expiresAt: new Date(now + 30 * day).toISOString(),
      dedupeKey: "report:road:progress",
      destination: {
        kind: "report",
        entityId: "report_bache_constitucion",
      },
    },
    {
      id: "emergency-center",
      type: "emergency",
      priority: "critical",
      title: "Emergencia cerca de tu zona",
      message:
        "Evita la calle Galeana mientras los servicios atienden el incidente.",
      createdAt: new Date(now - 28 * 60 * 1000).toISOString(),
      deliveredAt: new Date(now - 28 * 60 * 1000).toISOString(),
      expiresAt: new Date(now + 5 * 60 * 60 * 1000).toISOString(),
      dedupeKey: "emergency:center:galeana",
      destination: { kind: "alert", entityId: "alert_robbery_centro" },
    },
    {
      id: "community-lighting",
      type: "community_alert",
      priority: "informational",
      title: "Nueva alerta comunitaria",
      message: "Vecinos reportaron falta de alumbrado en Col. Jardines.",
      createdAt: new Date(now - 2 * 60 * 60 * 1000).toISOString(),
      deliveredAt: new Date(now - 2 * 60 * 60 * 1000).toISOString(),
      expiresAt: new Date(now + 2 * day).toISOString(),
      dedupeKey: "alert:lighting:jardines",
      destination: { kind: "alert", entityId: "alert_lighting_jardines" },
    },
    {
      id: "report-comment",
      type: "report_update",
      priority: "important",
      title: "Respondieron a tu reporte",
      message: "Hay una nueva actualización en tu reporte de alumbrado.",
      createdAt: new Date(now - day).toISOString(),
      deliveredAt: new Date(now - day).toISOString(),
      expiresAt: new Date(now + 29 * day).toISOString(),
      dedupeKey: "report:lighting:comment",
      destination: {
        kind: "report",
        entityId: "report_lighting_jardines",
      },
      readAt: new Date(now - 20 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: "nearby-traffic",
      type: "nearby_incident",
      priority: "informational",
      title: "Incidente cercano",
      message: "Tráfico lento por un accidente en Av. Constituyentes.",
      createdAt: new Date(now - 26 * 60 * 60 * 1000).toISOString(),
      deliveredAt: new Date(now - 26 * 60 * 60 * 1000).toISOString(),
      expiresAt: new Date(now + day).toISOString(),
      dedupeKey: "nearby:traffic:constituyentes",
      destination: {
        kind: "alert",
        entityId: "alert_traffic_constituyentes",
      },
      readAt: new Date(now - day).toISOString(),
    },
  ]
}

const getPreferences = async (userId: string) => {
  const stored = (await kv.get(
    preferencesKey(userId),
  )) as Partial<NotificationPreferences> | undefined
  return { ...defaultPreferences, ...stored }
}

const getNotifications = async (userId: string) => {
  const stored = (await kv.get(
    notificationsKey(userId),
  )) as Array<Omit<StoredNotification, "destination"> & {
    timeLabel?: string
    destination: StoredNotification["destination"] | {
      kind: "report" | "alert"
      index: number
    }
  }> | undefined
  return (stored ?? []).map((item) => {
    const { timeLabel: _legacyTimeLabel, ...withoutTimeLabel } = item
    const normalized = {
      ...withoutTimeLabel,
      priority: item.priority ?? defaultPriority(item.type),
      deliveredAt: item.deliveredAt ?? item.createdAt,
    }
    if ("entityId" in normalized.destination)
      return normalized as StoredNotification
    const entityId =
      legacyDestinationIds[normalized.destination.kind][
        normalized.destination.index
      ]
    return {
      ...normalized,
      destination: {
        kind: normalized.destination.kind,
        entityId:
          entityId ??
          (normalized.destination.kind === "report"
            ? "report_robbery_centro"
            : "alert_robbery_centro"),
      },
      priority: item.priority ?? defaultPriority(item.type),
    }
  })
}

const buildInboxGroups = (notifications: StoredNotification[]) => {
  const groups: Array<{
    notification: StoredNotification
    events: StoredNotification[]
  }> = []
  const sorted = [...notifications].sort(
    (a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt),
  )

  for (const notification of sorted) {
    const windowMs = groupingWindowMs[notification.priority]
    const group =
      windowMs > 0
        ? groups.find(
            (candidate) =>
              candidate.notification.dedupeKey === notification.dedupeKey &&
              candidate.notification.priority === notification.priority &&
              Date.parse(candidate.notification.createdAt) -
                Date.parse(notification.createdAt) <=
                windowMs,
          )
        : undefined
    if (group) group.events.push(notification)
    else groups.push({ notification, events: [notification] })
  }

  return groups
    .map(({ notification, events }) => ({
      ...notification,
      groupedCount: events.length,
      groupedEventIds: events.map((event) => event.id),
      latestUpdatedAt: notification.createdAt,
      seenAt: events.every((event) => event.seenAt)
        ? notification.seenAt
        : undefined,
      readAt: events.every((event) => event.readAt)
        ? notification.readAt
        : undefined,
      actionedAt: events.some((event) => event.actionedAt)
        ? (notification.actionedAt ??
          events.find((event) => event.actionedAt)?.actionedAt)
        : undefined,
    }))
    .sort(
      (a, b) =>
        priorityRank[a.priority] - priorityRank[b.priority] ||
        Date.parse(b.createdAt) - Date.parse(a.createdAt),
    )
}

const recordMetric = async (
  userId: string,
  event: string,
  notificationId?: string,
) => {
  const current = (await kv.get(metricsKey(userId))) ?? []
  await kv.set(metricsKey(userId), [
    ...current.slice(-199),
    { event, notificationId, at: new Date().toISOString() },
  ])
}

const getPushSubscriptions = async (userId: string) =>
  (await kv.get(
    pushSubscriptionsKey(userId),
  )) as StoredPushSubscription[] | undefined ?? []

async function sendPushNotification(
  userId: string,
  notification: StoredNotification,
) {
  const publicKey = Deno.env.get("VAPID_PUBLIC_KEY")
  const privateKey = Deno.env.get("VAPID_PRIVATE_KEY")
  const subject = Deno.env.get("VAPID_SUBJECT")
  if (!publicKey || !privateKey || !subject) return

  webpush.setVapidDetails(subject, publicKey, privateKey)
  const subscriptions = await getPushSubscriptions(userId)
  const invalidEndpoints = new Set<string>()
  const payload = JSON.stringify({
    id: notification.id,
    dedupeKey: notification.dedupeKey,
    title: notification.title,
    message: notification.message,
    priority: notification.priority,
    destination: notification.destination,
    sound: notification.pushDelivery?.sound,
    vibration: notification.pushDelivery?.vibration,
  })

  await Promise.all(
    subscriptions.map(async (subscription) => {
      try {
        if (!validPushEndpoint(subscription.endpoint)) return
        await webpush.sendNotification(subscription, payload, { timeout: 8000 })
        await recordMetric(userId, "push_sent", notification.id)
      } catch (error) {
        const statusCode = (error as { statusCode?: number }).statusCode
        if (statusCode === 404 || statusCode === 410)
          invalidEndpoints.add(subscription.endpoint)
        await recordMetric(userId, "push_failed", notification.id)
      }
    }),
  )

  if (invalidEndpoints.size) {
    await kv.set(
      pushSubscriptionsKey(userId),
      subscriptions.filter(
        (subscription) => !invalidEndpoints.has(subscription.endpoint),
      ),
    )
  }
}

export async function createNotification(
  input: CreateNotificationInput,
): Promise<{
  accepted: boolean
  notification?: StoredNotification
  pushDelivery: PushDeliveryDecision
}> {
  const preferences = await getPreferences(input.userId)
  const now = new Date()
  const priority = input.priority ?? defaultPriority(input.type)
  const pushDelivery = evaluatePushDelivery(
    input.type,
    preferences,
    now,
    priority,
  )

  if (!isCategoryEnabled(input.type, preferences)) {
    await recordMetric(input.userId, "category_suppressed")
    return { accepted: false, pushDelivery }
  }

  const notifications = await getNotifications(input.userId)
  const dedupeKey =
    input.dedupeKey ?? `${input.type}:${input.entityId}:${input.title}`
  const duplicate = notifications.find(
    (item) =>
      item.dedupeKey === dedupeKey &&
      !item.deletedAt &&
      Date.parse(item.expiresAt) > now.getTime(),
  )
  const id = duplicate?.id ?? crypto.randomUUID()
  const notification: StoredNotification = {
    id,
    type: input.type,
    priority,
    title: input.title,
    message: input.message,
    createdAt: duplicate?.createdAt ?? now.toISOString(),
    deliveredAt:
      pushDelivery.status === "immediate" ? now.toISOString() : undefined,
    expiresAt:
      input.expiresAt ??
      new Date(now.getTime() + expirationMs[priority]).toISOString(),
    dedupeKey,
    destination: {
      kind: input.destinationKind,
      entityId: input.entityId,
    },
    groupedCount: duplicate ? (duplicate.groupedCount ?? 1) + 1 : undefined,
    pushDelivery,
  }
  const updated = duplicate
    ? notifications.map((item) =>
        item.id === duplicate.id ? notification : item,
      )
    : [notification, ...notifications]
  await kv.set(notificationsKey(input.userId), updated)
  await recordMetric(input.userId, "created", id)

  if (pushDelivery.status === "immediate")
    await sendPushNotification(input.userId, notification)
  return { accepted: true, notification, pushDelivery }
}

// Enable logger
app.use("*", logger(console.log))

app.use(
  "/*",
  cors({
    origin: (origin) => {
      const configured = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean)
      const localOrigins = ["http://localhost:8443", "http://localhost:5173", "https://ikerd11.github.io"]
      return configured.includes(origin) ||
        localOrigins.includes(origin)
        ? origin
        : ""
    },
    allowHeaders: ["Content-Type", "Authorization", "apikey"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    exposeHeaders: ["Content-Length"],
    maxAge: 600,
  }),
)

app.use("/server/make-server-66389b89/*", async (c, next) => {
  if (
    c.req.method === "OPTIONS" ||
    c.req.path === "/server/make-server-66389b89/health"
  )
    return next()

  const token = c.req.header("Authorization")?.replace(/^Bearer\s+/i, "")
  if (!token) return c.json({ error: "Unauthorized" }, 401)

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  if (serviceRoleKey && token === serviceRoleKey) {
    c.set("userId", "service")
    c.set("role", "service")
    return next()
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    { global: { headers: { Authorization: `Bearer ${token}` } } },
  )
  const { data, error } = await supabase.auth.getUser(token)
  if (error || !data.user || data.user.is_anonymous || !data.user.email_confirmed_at) return c.json({ error: "Unauthorized" }, 401)

  c.set("userId", data.user.id)
  c.set("role", String(data.user.app_metadata?.role ?? "citizen"))
  await next()
})

// Health check endpoint
app.get("/server/make-server-66389b89/health", (c) => {
  return c.json({ status: "ok", pushConfigured: Boolean(Deno.env.get("VAPID_PUBLIC_KEY") && Deno.env.get("VAPID_PRIVATE_KEY") && Deno.env.get("VAPID_SUBJECT")) })
})

app.get("/server/make-server-66389b89/notifications", async (c) => {
  const userId = c.get("userId")
  const preferences = await getPreferences(userId)
  const notifications = await getNotifications(userId)

  const now = Date.now()
  await kv.set(notificationsKey(userId), notifications)

  return c.json({
    notifications: buildInboxGroups(
      notifications.filter((item) => isVisibleInInbox(item, new Date(now))),
    ),
    preferences,
  })
})

app.put("/server/make-server-66389b89/notifications/read", async (c) => {
  const userId = c.get("userId")
  const {
    id,
    ids,
    all,
    unread,
    readAt: clientReadAt,
    operationAt: clientOperationAt,
  } = await c.req.json<{
    id?: string
    ids?: string[]
    all?: boolean
    unread?: boolean
    readAt?: string
    operationAt?: string
  }>()
  const notifications = await getNotifications(userId)
  const readAt =
    clientReadAt && Number.isFinite(Date.parse(clientReadAt))
      ? clientReadAt
      : new Date().toISOString()
  const operationAt =
    clientOperationAt && Number.isFinite(Date.parse(clientOperationAt))
      ? clientOperationAt
      : new Date().toISOString()
  const selectedIds = new Set(ids ?? (id ? [id] : []))
  const updated = notifications.map((item) => {
    if (!all && !selectedIds.has(item.id)) return item
    if (
      item.readStateChangedAt &&
      Date.parse(item.readStateChangedAt) > Date.parse(operationAt)
    )
      return item
    return {
      ...item,
      readAt: unread ? undefined : readAt,
      readStateChangedAt: operationAt,
    }
  })
  await kv.set(notificationsKey(userId), updated)
  await recordMetric(userId, unread ? "unread" : all ? "read_all" : "read", id)
  return c.json({ notifications: updated })
})

app.put("/server/make-server-66389b89/notifications/seen", async (c) => {
  const userId = c.get("userId")
  const { ids, seenAt: clientSeenAt } = await c.req.json<{
    ids: string[]
    seenAt?: string
  }>()
  const seenAt =
    clientSeenAt && Number.isFinite(Date.parse(clientSeenAt))
      ? clientSeenAt
      : new Date().toISOString()
  const selectedIds = new Set(ids)
  const notifications = await getNotifications(userId)
  const updated = notifications.map((item) =>
    selectedIds.has(item.id) && !item.seenAt ? { ...item, seenAt } : item,
  )
  await kv.set(notificationsKey(userId), updated)
  await recordMetric(userId, "seen")
  return c.json({ ok: true })
})

app.put("/server/make-server-66389b89/notifications/archive", async (c) => {
  const userId = c.get("userId")
  const { id, ids, all } = await c.req.json<{
    id?: string
    ids?: string[]
    all?: boolean
  }>()
  const notifications = await getNotifications(userId)
  const archivedAt = new Date().toISOString()
  const selectedIds = new Set(ids ?? (id ? [id] : []))
  const updated = notifications.map((item) =>
    all || selectedIds.has(item.id)
      ? { ...item, archivedAt: item.archivedAt ?? archivedAt }
      : item,
  )
  await kv.set(notificationsKey(userId), updated)
  await recordMetric(userId, all ? "archive_all" : "archive", id)
  return c.json({
    notifications: updated.filter((item) => isVisibleInInbox(item)),
  })
})

app.delete("/server/make-server-66389b89/notifications/:id", async (c) => {
  const userId = c.get("userId")
  const id = c.req.param("id")
  const notifications = await getNotifications(userId)
  const deletedAt = new Date().toISOString()
  const updated = notifications.map((item) =>
    item.id === id ? { ...item, deletedAt } : item,
  )
  await kv.set(notificationsKey(userId), updated)
  await recordMetric(userId, "delete", id)
  return c.json({ ok: true })
})

app.post("/server/make-server-66389b89/notification-events", async (c) => {
  if (!["admin", "municipal", "service"].includes(c.get("role")))
    return c.json({ error: "Forbidden" }, 403)

  const incoming = await c.req.json<CreateNotificationInput>()
  const validTypes: NotificationType[] = [
    "report_update",
    "community_alert",
    "nearby_incident",
    "emergency",
  ]
  if (
    !incoming.userId ||
    !incoming.entityId ||
    !incoming.title?.trim() ||
    !incoming.message?.trim() ||
    !validTypes.includes(incoming.type) ||
    !["report", "alert"].includes(incoming.destinationKind)
  )
    return c.json({ error: "Invalid notification event" }, 400)

  if (
    incoming.type === "emergency" &&
    !["admin", "service"].includes(c.get("role"))
  )
    return c.json({ error: "Only administrators can issue emergencies" }, 403)

  const result = await createNotification(incoming)
  return c.json(result, result.accepted ? 201 : 202)
})

app.post(
  "/server/make-server-66389b89/notification-deliveries/process-due",
  async (c) => {
    const userId = c.get("userId")
    const preferences = await getPreferences(userId)
    const notifications = await getNotifications(userId)
    const now = new Date()
    const dueIds = new Set(
      notifications
        .filter(
          (item) =>
            item.pushDelivery?.status === "pending" &&
            item.pushDelivery.deliverAt &&
            Date.parse(item.pushDelivery.deliverAt) <= now.getTime(),
        )
        .map((item) => item.id),
    )
    const deliveries: StoredNotification[] = []
    const updated = notifications.map((item) => {
      if (!dueIds.has(item.id)) return item
      const pushDelivery = evaluatePushDelivery(
        item.type,
        preferences,
        now,
        item.priority,
      )
      const next = {
        ...item,
        pushDelivery,
        deliveredAt:
          pushDelivery.status === "immediate"
            ? (item.deliveredAt ?? now.toISOString())
            : item.deliveredAt,
      }
      if (pushDelivery.status === "immediate") deliveries.push(next)
      return next
    })

    await kv.set(notificationsKey(userId), updated)
    await Promise.all(
      deliveries.map(async (item) => {
        await sendPushNotification(userId, item)
        await recordMetric(userId, "push_due", item.id)
      }),
    )
    return c.json({
      deliveries: deliveries.map((item) => ({
        notification: item,
        pushDelivery: item.pushDelivery,
      })),
      processed: dueIds.size,
    })
  },
)

app.post("/server/make-server-66389b89/notifications/action", async (c) => {
  const userId = c.get("userId")
  const { id, ids } = await c.req.json<{
    id?: string
    ids?: string[]
  }>()
  const selectedIds = new Set(ids ?? (id ? [id] : []))
  const notifications = await getNotifications(userId)
  const actionedAt = new Date().toISOString()
  const updated = notifications.map((item) =>
    selectedIds.has(item.id) && !item.actionedAt
      ? { ...item, actionedAt }
      : item,
  )
  await kv.set(notificationsKey(userId), updated)
  await recordMetric(userId, "action", id)
  return c.json({ ok: true, actionedAt })
})

app.get("/server/make-server-66389b89/notification-preferences", async (c) => {
  const preferences = await getPreferences(c.get("userId"))
  return c.json({ preferences })
})

app.put("/server/make-server-66389b89/notification-preferences", async (c) => {
  const userId = c.get("userId")
  const incoming = await c.req.json<Partial<NotificationPreferences>>()
  const current = await getPreferences(userId)
  const preferences = { ...current, ...incoming }
  await kv.set(preferencesKey(userId), preferences)
  await recordMetric(userId, "preferences_updated")
  return c.json({ preferences })
})

function validPushEndpoint(endpoint: unknown): endpoint is string {
  if (typeof endpoint !== "string" || endpoint.length > 2048) return false
  try {
    const url = new URL(endpoint)
    return url.protocol === "https:" && !url.port && !url.username && !url.password &&
      (["fcm.googleapis.com", "updates.push.services.mozilla.com", "web.push.apple.com"].includes(url.hostname) ||
        url.hostname.endsWith(".notify.windows.com"))
  } catch { return false }
}

app.post("/server/make-server-66389b89/push-subscriptions", async (c) => {
  const userId = c.get("userId")
  const { subscription, userAgent } = await c.req.json<{
    subscription: {
      endpoint: string
      keys?: {
        p256dh?: string
        auth?: string
      }
    }
    userAgent?: string
  }>()
  if (
    !subscription || !validPushEndpoint(subscription.endpoint) ||
    !subscription.keys?.p256dh ||
    !subscription.keys.auth
  )
    return c.json({ error: "Invalid push subscription" }, 400)

  const subscriptions = await getPushSubscriptions(userId)
  const now = new Date().toISOString()
  const stored: StoredPushSubscription = {
    endpoint: subscription.endpoint,
    keys: {
      p256dh: subscription.keys.p256dh,
      auth: subscription.keys.auth,
    },
    userAgent,
    createdAt:
      subscriptions.find((item) => item.endpoint === subscription.endpoint)
        ?.createdAt ?? now,
    updatedAt: now,
  }
  await kv.set(pushSubscriptionsKey(userId), [
    stored,
    ...subscriptions.filter((item) => item.endpoint !== stored.endpoint),
  ])
  await recordMetric(userId, "push_device_registered")
  return c.json({ ok: true }, 201)
})

app.delete("/server/make-server-66389b89/push-subscriptions", async (c) => {
  const userId = c.get("userId")
  const { endpoint } = await c.req.json<{ endpoint: string }>()
  const subscriptions = await getPushSubscriptions(userId)
  await kv.set(
    pushSubscriptionsKey(userId),
    subscriptions.filter((item) => item.endpoint !== endpoint),
  )
  await recordMetric(userId, "push_device_removed")
  return c.json({ ok: true })
})

Deno.serve(app.fetch)
