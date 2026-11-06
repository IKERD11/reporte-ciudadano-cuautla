import { createContext, useContext, useEffect, useState, type ReactNode } from "react"
import { supabase } from "./supabase"
import type { CitizenReport, MapIncident, ActivityEntry, CommunityAlert, ReportDraft } from "./App"

export const DESIGN_QA = import.meta.env.MODE === "design-qa"
type Row = Record<string, any>
export async function pilot(action: string, values: Row = {}): Promise<Row> {
  const { data, error } = await supabase.functions.invoke("report-pilot", { body: { action, ...values } })
  if (error) {
    let message = "No se pudo completar la operación. Intenta nuevamente."
    try { message = (await error.context.json()).error ?? message } catch { /* network failure */ }
    throw new Error(message)
  }
  if (data?.error) throw new Error(data.error)
  return data
}
const normal = (s: string) => s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
export function reportView(r: Row): CitizenReport {
  const category = normal(r.category ?? "")
  const sticker = category.includes("bache") ? "cone" : category.includes("alumbr") ? "bulb" : category.includes("animal") ? "paw" : category.includes("accident") ? "car" : category.includes("deceso") ? "mourning" : category.includes("vandal") ? "spray" : category.includes("robo") ? "robbery" : "shield"
  return { id: r.id, title: r.category, location: r.address ?? "Cuautla, Morelos", date: new Date(r.created_at).toLocaleString("es-MX"), status: ["RESUELTO", "CERRADO"].includes(r.status_code) || /resuelto|cerrado/i.test(r.status) ? "Resuelto" : r.status_code === "EN_ATENCION" || /atención|atencion/i.test(r.status) ? "En atención" : "En revisión", sticker, folio: r.folio, description: r.description ?? "", evidence: [], position: r.latitude != null && r.longitude != null ? { lat: Number(r.latitude), lng: Number(r.longitude) } : undefined, timeline: r.timeline ?? [], actualStatus: r.status }
}
export function incidentView(r: Row): MapIncident {
  const view = reportView(r), cat = normal(r.category ?? "")
  return { ...view, category: /bache|accident/.test(cat) ? "vialidad" : /alumbr|servicio/.test(cat) ? "servicios" : /animal/.test(cat) ? "animales" : "seguridad", position: view.position!, tone: "blue", source: "live", relativeTime: view.date, folio: r.folio, description: r.description ?? "", evidence: [] }
}
export function alertView(r: Row): CommunityAlert {
  const view = reportView(r), cat = incidentView(r).category
  return { id: r.id, title: view.title, description: view.description ?? "", details: `${view.description} · Estado: ${r.status}`, location: view.location, recommendations: [], images: [], time: view.date, category: cat === "vialidad" ? "Tránsito" : cat === "servicios" ? "Servicios" : "Seguridad", sticker: view.sticker }
}
async function allReports(action: string): Promise<Row[]> {
  const rows: Row[] = []
  for (let offset = 0; offset <= 10000; offset += 20) {
    const data = await pilot(action, { offset })
    rows.push(...data.reports)
    if (data.reports.length < 20 || data.has_more === false) break
  }
  return rows
}
type Runtime = { reports: CitizenReport[]; incidents: MapIncident[]; alerts: CommunityAlert[]; activity: ActivityEntry[]; error: string; refresh: () => Promise<void> }
const Context = createContext<Runtime>({ reports: [], incidents: [], alerts: [], activity: [], error: "", refresh: async () => {} })
export const useCitizenRuntime = () => useContext(Context)
export function CitizenRuntimeProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<Omit<Runtime, "refresh">>({ reports: [], incidents: [], alerts: [], activity: [], error: "" })
  const [actor, setActor] = useState<string | null>(null)
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => setActor(session?.user.id ?? null))
    return () => subscription.unsubscribe()
  }, [])
  useEffect(() => { setData({ reports: [], incidents: [], alerts: [], activity: [], error: "" }) }, [actor])
  const refresh = async () => {
    if (!actor || DESIGN_QA) return
    try {
      const [own, community] = await Promise.all([allReports("list"), allReports("community_list")])
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user.id !== actor) return
      setData({ reports: own.map(reportView), incidents: community.filter(r => r.latitude != null && r.longitude != null).map(incidentView), alerts: community.map(alertView), activity: own.map(r => ({ id: r.id, day: "Hoy", dateLabel: new Date(r.created_at).toLocaleDateString("es-MX"), kind: "report", title: `Reporte: ${r.status}`, subject: r.category, location: r.address, date: new Date(r.created_at).toLocaleString("es-MX"), report: reportView(r) })), error: "" })
    } catch (error) { setData(current => ({ ...current, error: String((error as Error).message) })) }
  }
  useEffect(() => {
    void refresh()
    const id = window.setInterval(() => { if (document.visibilityState === "visible") void refresh() }, 30000)
    const focus = () => void refresh()
    window.addEventListener("focus", focus)
    return () => { clearInterval(id); window.removeEventListener("focus", focus) }
  }, [actor])
  return <Context.Provider value={{ ...data, refresh }}>{children}</Context.Provider>
}
export async function reportDetail(report: CitizenReport): Promise<CitizenReport> {
  let raw: Row
  try { raw = await pilot("detail", { report_id: report.id }) }
  catch { raw = await pilot("community_detail", { report_id: report.id }) }
  const evidence = await Promise.all((raw.images ?? []).map(async (image: Row) => {
    const result = await pilot("image", { report_id: report.id, image_id: image.id })
    return { src: result.url, alt: "Evidencia del reporte" }
  }))
  return { ...reportView(raw), evidence }
}
async function jpeg(url: string, maxSize = 1280): Promise<string> {
  const image = await createImageBitmap(await (await fetch(url)).blob())
  const canvas = document.createElement("canvas"), scale = Math.min(1, maxSize / Math.max(image.width, image.height))
  canvas.width = Math.round(image.width * scale); canvas.height = Math.round(image.height * scale)
  canvas.getContext("2d")!.drawImage(image, 0, 0, canvas.width, canvas.height); image.close()
  let encoded = canvas.toDataURL("image/jpeg", 0.82)
  if (encoded.length > 900000) encoded = canvas.toDataURL("image/jpeg", 0.55)
  return encoded.split(",")[1]
}
let frozen: { signature: string; body: Row } | undefined
export async function submitReport(draft: ReportDraft) {
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) throw new Error("Inicia sesión para enviar el reporte.")
  const signature = session.user.id + JSON.stringify(draft)
  if (!frozen || frozen.signature !== signature) {
    const context = await pilot("context")
    if (!context.enabled) throw new Error("El envío de reportes no está habilitado para esta cuenta.")
    const key = normal(draft.category)
    const category = context.categories.find((c: Row) => normal(c.name) === key) ?? context.categories.find((c: Row) => normal(c.name).includes(key.split(/[ /]/)[0]))
    if (!category) throw new Error("Esta categoría no está disponible para tu municipio.")
    if (draft.description.trim().length < 10) throw new Error("Escribe al menos 10 caracteres en la descripción.")
    if (draft.evidence.length > 3) throw new Error("Puedes adjuntar hasta tres fotografías.")
    const required = category.schema?.required ?? []
    if (required.length) throw new Error("Esta categoría requiere información adicional. El formulario aún necesita conectarse a esos campos.")
    frozen = { signature, body: { request_key: crypto.randomUUID(), payload: { category_id: category.id, description: draft.description.trim(), address: draft.location, latitude: draft.position.lat, longitude: draft.position.lng, additional_data: {}, consent: true }, photos: await Promise.all(draft.evidence.map(p => jpeg(p.url))) } }
  }
  const result = await pilot("submit", frozen.body)
  if (!result.id || !result.folio || result.committed !== true) throw new Error("El servidor no confirmó el reporte. Reintenta sin cambiar los datos.")
  frozen = undefined
  return result
}
export async function loadProfile() {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null
  let { data: profile, error } = await supabase.from("profiles").select("first_name,last_name,phone").eq("id", user.id).maybeSingle()
  if (error) throw error
  if (!profile) {
    const { data: cities, error: citiesError } = await supabase.rpc("list_registration_municipalities")
    if (citiesError) throw citiesError
    const city = cities?.find((c: Row) => /cuautla/i.test(c.name))
    if (!city) throw new Error("El registro no está habilitado para Cuautla.")
    const words = String(user.user_metadata?.name ?? "Ciudadano Cuautla").trim().split(/\s+/)
    const { data, error } = await supabase.rpc("complete_citizen_profile", { p_municipality_id: city.id, p_first_name: words.shift(), p_last_name: words.join(" ") || "Cuautla" })
    if (error) throw error
    profile = data
  }
  return { name: `${profile!.first_name} ${profile!.last_name}`, email: user.email ?? "", phone: profile!.phone ?? "", avatarUrl: user.user_metadata?.avatar_url }
}
export async function saveProfile(profile: { name: string; email: string; phone: string; avatarUrl?: string }) {
  const parts = profile.name.trim().split(/\s+/)
  const { error } = await supabase.rpc("update_my_profile", { p_first_name: parts.shift(), p_last_name: parts.join(" "), p_phone: profile.phone || null })
  if (error) throw error
  const { data: { user } } = await supabase.auth.getUser()
  const avatarUrl = profile.avatarUrl && /^(blob:|data:)/.test(profile.avatarUrl) ? `data:image/jpeg;base64,${await jpeg(profile.avatarUrl, 256)}` : profile.avatarUrl
  const result = await supabase.auth.updateUser({ ...(profile.email !== user?.email ? { email: profile.email } : {}), data: { name: profile.name, avatar_url: avatarUrl } }, { emailRedirectTo: new URL(import.meta.env.BASE_URL, location.origin).href })
  if (result.error) throw result.error
}

// Existing report notifications remain readable after changing the web renderer.
export async function legacyInbox() {
  const items: Row[] = []
  for (let offset = 0; offset <= 10000; offset += 20) {
    const { data, error } = await supabase.rpc("citizen_notifications", { p_action: "list", p_offset: offset })
    if (error) throw error
    items.push(...(data.items ?? []))
    if (items.length >= data.total || data.items.length < 20) break
  }
  return items.map(item => ({ id: `legacy:${item.id}`, type: "report_update", priority: "important", title: item.title, message: item.body, createdAt: item.created_at, expiresAt: "9999-12-31T23:59:59Z", readAt: item.read_at ?? undefined, destination: { kind: "report", entityId: item.report_id }, dedupeKey: `legacy:${item.id}` }))
}
export async function markLegacyRead(ids: string[]) {
  for (const id of ids) {
    const { error } = await supabase.rpc("citizen_notifications", { p_action: "read", p_id: id.replace("legacy:", "") })
    if (error) throw error
  }
}
