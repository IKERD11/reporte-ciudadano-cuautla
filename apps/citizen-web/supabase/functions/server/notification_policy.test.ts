import assert from "node:assert/strict"
import test from "node:test"
import {
  evaluatePushDelivery,
  isVisibleInInbox,
  isWithinQuietHours,
  type DeliveryPreferences,
} from "./notification_policy.ts"

const preferences: DeliveryPreferences = {
  reportUpdates: true,
  communityAlerts: true,
  nearbyIncidents: true,
  emergencies: true,
  sound: true,
  vibration: true,
  quietHoursEnabled: true,
  quietStart: "22:00",
  quietEnd: "07:00",
  emergencyOverride: true,
  pushPermission: "granted",
  timeZone: "America/Mexico_City",
}

test("emergency override never enables a disabled emergency category", () => {
  const decision = evaluatePushDelivery(
    "emergency",
    { ...preferences, emergencies: false, emergencyOverride: true },
    new Date("2026-01-15T05:00:00.000Z"),
  )

  assert.equal(decision.categoryEnabled, false)
  assert.equal(decision.status, "suppressed")
  assert.equal(decision.reason, "category_disabled")
})

test("quiet hours work when the interval crosses midnight", () => {
  assert.equal(
    isWithinQuietHours(preferences, new Date("2026-01-15T05:00:00.000Z")),
    true,
  )
  assert.equal(
    isWithinQuietHours(preferences, new Date("2026-01-15T18:00:00.000Z")),
    false,
  )
})

test("normal notifications wait silently until quiet hours finish", () => {
  const decision = evaluatePushDelivery(
    "community_alert",
    preferences,
    new Date("2026-01-15T05:00:00.000Z"),
  )

  assert.equal(decision.status, "pending")
  assert.equal(decision.sound, false)
  assert.equal(decision.vibration, false)
  assert.ok(decision.deliverAt)
})

test("enabled emergency override bypasses quiet delivery, not category state", () => {
  const decision = evaluatePushDelivery(
    "emergency",
    preferences,
    new Date("2026-01-15T05:00:00.000Z"),
  )

  assert.equal(decision.status, "immediate")
  assert.equal(decision.reason, "emergency_override")
  assert.equal(decision.sound, true)
  assert.equal(decision.vibration, true)
})

test("sound and vibration remain independent", () => {
  const decision = evaluatePushDelivery(
    "report_update",
    { ...preferences, quietHoursEnabled: false, sound: false },
    new Date("2026-01-15T18:00:00.000Z"),
  )

  assert.equal(decision.status, "immediate")
  assert.equal(decision.sound, false)
  assert.equal(decision.vibration, true)
})

test("critical priority bypasses quiet hours", () => {
  const decision = evaluatePushDelivery(
    "report_update",
    preferences,
    new Date("2026-01-15T05:00:00.000Z"),
    "critical",
  )

  assert.equal(decision.status, "immediate")
  assert.equal(decision.reason, "critical_priority")
})

test("informational priority is delivered without sound or vibration", () => {
  const decision = evaluatePushDelivery(
    "community_alert",
    { ...preferences, quietHoursEnabled: false },
    new Date("2026-01-15T18:00:00.000Z"),
    "informational",
  )

  assert.equal(decision.status, "immediate")
  assert.equal(decision.sound, false)
  assert.equal(decision.vibration, false)
})

test("the configured user time zone controls quiet-hour evaluation", () => {
  const instant = new Date("2026-01-15T12:30:00.000Z")
  assert.equal(isWithinQuietHours(preferences, instant), true)
  assert.equal(
    isWithinQuietHours({ ...preferences, timeZone: "UTC" }, instant),
    false,
  )
})

test("inbox history only hides archived, deleted, or expired items", () => {
  const now = new Date("2026-01-15T12:30:00.000Z")
  const active = { expiresAt: "2026-01-16T12:30:00.000Z" }

  assert.equal(isVisibleInInbox(active, now), true)
  assert.equal(
    isVisibleInInbox({ ...active, archivedAt: now.toISOString() }, now),
    false,
  )
  assert.equal(
    isVisibleInInbox({ ...active, deletedAt: now.toISOString() }, now),
    false,
  )
  assert.equal(
    isVisibleInInbox({ expiresAt: "2026-01-14T12:30:00.000Z" }, now),
    false,
  )
})
