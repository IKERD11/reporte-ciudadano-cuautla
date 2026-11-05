export type NotificationType = "report_update" | "community_alert" | "nearby_incident" | "emergency"
export type NotificationPriority = "critical" | "important" | "informational"

export type PushPermission = "default" | "granted" | "denied" | "unsupported"

export type DeliveryPreferences = {
  reportUpdates: boolean
  communityAlerts: boolean
  nearbyIncidents: boolean
  emergencies: boolean
  sound: boolean
  vibration: boolean
  quietHoursEnabled: boolean
  quietStart: string
  quietEnd: string
  emergencyOverride: boolean
  pushPermission: PushPermission
  timeZone: string
}

export type PushDeliveryDecision = {
  status: "immediate" | "pending" | "suppressed"
  categoryEnabled: boolean
  inQuietHours: boolean
  sound: boolean
  vibration: boolean
  evaluatedAt: string
  deliverAt?: string
  timeZone: string
  reason: "category_disabled" | "push_permission" | "quiet_hours" | "emergency_override" | "critical_priority" | "immediate"
}

export type InboxNotificationState = {
  expiresAt: string
  archivedAt?: string
  deletedAt?: string
}

const CLOCK_PATTERN = /^([01]\d|2[0-3]):([0-5]\d)$/

function clockMinutes(value: string) {
  const match = CLOCK_PATTERN.exec(value)
  if (!match) return null
  return Number(match[1]) * 60 + Number(match[2])
}

function safeTimeZone(timeZone: string) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone }).format()
    return timeZone
  } catch {
    return "America/Mexico_City"
  }
}

function localMinutes(date: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date)
  const hour = Number(parts.find((part) => part.type === "hour")?.value ?? 0)
  const minute = Number(
    parts.find((part) => part.type === "minute")?.value ?? 0,
  )
  return hour * 60 + minute
}

export function isCategoryEnabled(
  type: NotificationType,
  preferences: DeliveryPreferences,
) {
  if (type === "emergency") return preferences.emergencies
  if (type === "report_update") return preferences.reportUpdates
  if (type === "community_alert") return preferences.communityAlerts
  return preferences.nearbyIncidents
}

export function isVisibleInInbox(
  notification: InboxNotificationState,
  at = new Date(),
) {
  return (
    !notification.archivedAt &&
    !notification.deletedAt &&
    Date.parse(notification.expiresAt) > at.getTime()
  )
}

export function isWithinQuietHours(
  preferences: DeliveryPreferences,
  at = new Date(),
) {
  if (!preferences.quietHoursEnabled) return false

  const start = clockMinutes(preferences.quietStart)
  const end = clockMinutes(preferences.quietEnd)
  if (start === null || end === null || start === end) return false

  const current = localMinutes(at, safeTimeZone(preferences.timeZone))
  return start < end
    ? current >= start && current < end
    : current >= start || current < end
}

function nextQuietEnd(
  preferences: DeliveryPreferences,
  from: Date,
): string | undefined {
  if (!isWithinQuietHours(preferences, from)) return undefined

  for (let minute = 1; minute <= 26 * 60; minute += 1) {
    const candidate = new Date(from.getTime() + minute * 60_000)
    if (!isWithinQuietHours(preferences, candidate))
      return candidate.toISOString()
  }
  return undefined
}

export function evaluatePushDelivery(
  type: NotificationType,
  preferences: DeliveryPreferences,
  at = new Date(),
  priority: NotificationPriority = "important",
): PushDeliveryDecision {
  const timeZone = safeTimeZone(preferences.timeZone)
  const normalizedPreferences = { ...preferences, timeZone }
  const evaluatedAt = at.toISOString()
  const categoryEnabled = isCategoryEnabled(type, normalizedPreferences)

  if (!categoryEnabled) {
    return {
      status: "suppressed",
      categoryEnabled: false,
      inQuietHours: isWithinQuietHours(normalizedPreferences, at),
      sound: false,
      vibration: false,
      evaluatedAt,
      timeZone,
      reason: "category_disabled",
    }
  }

  const inQuietHours = isWithinQuietHours(normalizedPreferences, at)
  if (preferences.pushPermission !== "granted") {
    return {
      status: "suppressed",
      categoryEnabled: true,
      inQuietHours,
      sound: false,
      vibration: false,
      evaluatedAt,
      timeZone,
      reason: "push_permission",
    }
  }

  if (inQuietHours && priority === "critical") {
    return {
      status: "immediate",
      categoryEnabled: true,
      inQuietHours: true,
      sound: preferences.sound,
      vibration: preferences.vibration,
      evaluatedAt,
      timeZone,
      reason: "critical_priority",
    }
  }

  if (inQuietHours && type === "emergency" && preferences.emergencyOverride) {
    return {
      status: "immediate",
      categoryEnabled: true,
      inQuietHours: true,
      sound: preferences.sound,
      vibration: preferences.vibration,
      evaluatedAt,
      timeZone,
      reason: "emergency_override",
    }
  }

  if (inQuietHours) {
    return {
      status: "pending",
      categoryEnabled: true,
      inQuietHours: true,
      sound: false,
      vibration: false,
      evaluatedAt,
      deliverAt: nextQuietEnd(normalizedPreferences, at),
      timeZone,
      reason: "quiet_hours",
    }
  }

  return {
    status: "immediate",
    categoryEnabled: true,
    inQuietHours: false,
    sound: priority === "informational" ? false : preferences.sound,
    vibration: priority === "informational" ? false : preferences.vibration,
    evaluatedAt,
    timeZone,
    reason: "immediate",
  }
}
