import type {
  GeoJSONSource,
  Map as MapLibreMap,
  Marker as MapLibreMarker,
} from "maplibre-gl"
import mapLibreWorkerUrl from "maplibre-gl/dist/maplibre-gl-csp-worker.js?url"
import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type FormEvent,
  type ReactNode,
} from "react"
import { flushSync } from "react-dom"
import helpContactSupportImage from "./assets/help/contact-support.png"
import helpCreateReportImage from "./assets/help/create-report.png"
import helpFaqImage from "./assets/help/faq.png"
import helpMunicipalServiceImage from "./assets/help/municipal-service.png"
import helpReportProblemImage from "./assets/help/report-problem.png"
import helpReportTrackingImage from "./assets/help/report-tracking.png"
import helpSupportHeroImage from "./assets/help/support-hero.png"
import privacyAnonymousImage from "./assets/privacy/anonymous.png"
import privacyCameraImage from "./assets/privacy/camera.png"
import privacyDataImage from "./assets/privacy/data.png"
import privacyDeleteImage from "./assets/privacy/delete.png"
import privacyDownloadImage from "./assets/privacy/download.png"
import privacyLocationImage from "./assets/privacy/location.png"
import privacySecurityImage from "./assets/privacy/security.png"
import privacySessionsImage from "./assets/privacy/sessions.png"
import { projectId } from "../utils/supabase/info"
import { subscribeToPush, unsubscribeFromPush } from "./push"
import { supabase } from "./supabase"

const OPENFREEMAP_STYLE = "https://tiles.openfreemap.org/styles/liberty"
const CUAUTLA_CENTER: [number, number] = [-98.9548, 18.8126]
const MAP_ATTRIBUTION =
  '<a href="https://openfreemap.org/" target="_blank" rel="noopener noreferrer">OpenFreeMap</a> · <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener noreferrer">OpenStreetMap</a>'
const BUILDINGS_LAYER_ID = "building-3d"
type MapLibreModule = typeof import("maplibre-gl")
let mapLibrePromise: Promise<MapLibreModule> | undefined

function loadMapLibre() {
  mapLibrePromise ??= import("maplibre-gl")
    .then((maplibre) => {
      maplibre.setWorkerUrl(mapLibreWorkerUrl)
      return maplibre
    })
    .catch((error) => {
      mapLibrePromise = undefined
      throw error
    })
  return mapLibrePromise
}

function addMapAttribution(map: MapLibreMap, maplibre: MapLibreModule) {
  map.addControl(
    new maplibre.AttributionControl({
      compact: false,
      customAttribution: MAP_ATTRIBUTION,
    }),
    "bottom-left",
  )
}

function addMissingStyleImageFallback(map: MapLibreMap) {
  map.on("styleimagemissing", ({ id }) => {
    if (map.hasImage(id)) return

    map.addImage(id, {
      width: 1,
      height: 1,
      data: new Uint8Array([0, 0, 0, 0]),
    })
  })
}

function add3DBuildings(map: MapLibreMap) {
  if (!map.getSource("openmaptiles") || map.getLayer(BUILDINGS_LAYER_ID)) return

  const firstLabelLayer = map
    .getStyle()
    .layers?.find(
      (layer) =>
        layer.type === "symbol" &&
        typeof layer.layout?.["text-field"] !== "undefined",
    )?.id

  map.addLayer(
    {
      id: BUILDINGS_LAYER_ID,
      type: "fill-extrusion",
      source: "openmaptiles",
      "source-layer": "building",
      minzoom: 14,
      paint: {
        "fill-extrusion-color": [
          "interpolate",
          ["linear"],
          ["zoom"],
          14,
          "#d7e3e8",
          17,
          "#b9ccd5",
        ],
        "fill-extrusion-height": [
          "coalesce",
          ["get", "render_height"],
          ["get", "height"],
          6,
        ],
        "fill-extrusion-base": [
          "coalesce",
          ["get", "render_min_height"],
          ["get", "min_height"],
          0,
        ],
        "fill-extrusion-opacity": 0.72,
      },
    },
    firstLabelLayer,
  )
}

type IconName = "activity" | "alert" | "arrow-left" | "arrow-right" | "bell" | "bulb" | "calendar" | "camera" | "car" | "check" | "chevron" | "clipboard" | "close" | "cone" | "copy" | "crosshair" | "edit" | "eye" | "eye-off" | "filter" | "gallery" | "heart" | "help" | "home" | "lock" | "logout" | "mail" | "map" | "mask" | "megaphone" | "message" | "moon" | "more" | "paw" | "phone" | "pin" | "plus" | "refresh" | "search" | "settings" | "share" | "shield" | "spray" | "sos" | "user" | "users" | "volume" | "woman"

function Icon({
  name,
  size = 24,
  strokeWidth = 2,
}: {
  name: IconName
  size?: number
  strokeWidth?: number
}) {
  const paths: Record<IconName, ReactNode> = {
    activity: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M12 7v5l3 2" />
      </>
    ),
    "arrow-left": <path d="m19 12-14 0m6-6-6 6 6 6" />,
    "arrow-right": <path d="m5 12 14 0m-6-6 6 6-6 6" />,
    alert: (
      <>
        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
        <path d="M10 21h4" />
      </>
    ),
    bell: (
      <>
        <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
        <path d="M10 21h4" />
      </>
    ),
    bulb: (
      <>
        <path d="M9 18h6M10 22h4" />
        <path d="M8.5 15.5a7 7 0 1 1 7 0c-.8.6-1.1 1.3-1.1 2.5H9.6c0-1.2-.3-1.9-1.1-2.5Z" />
        <path d="M12 2V.8M4.9 4.9 4 4M19.1 4.9 20 4" />
      </>
    ),
    calendar: (
      <>
        <rect x="3" y="5" width="18" height="16" rx="2" />
        <path d="M8 3v4M16 3v4M3 10h18" />
        <path d="M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01" />
      </>
    ),
    camera: (
      <>
        <path d="M5 7h3l1.5-2h5L16 7h3a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2Z" />
        <circle cx="12" cy="13" r="4" />
      </>
    ),
    car: (
      <>
        <path d="m5 11 1.7-5h10.6l1.7 5" />
        <path d="M4 11h16a2 2 0 0 1 2 2v5H2v-5a2 2 0 0 1 2-2Z" />
        <path d="M5 18v3M19 18v3" />
        <circle cx="6" cy="14.5" r="1" />
        <circle cx="18" cy="14.5" r="1" />
      </>
    ),
    check: <path d="m4 12 5 5L20 6" />,
    chevron: <path d="m9 18 6-6-6-6" />,
    clipboard: (
      <>
        <rect x="5" y="4" width="14" height="17" rx="2" />
        <path d="M9 4V2h6v2M9 10h6M9 14h6" />
      </>
    ),
    cone: (
      <>
        <path d="m9 3-4 16h14L15 3Z" />
        <path d="M7.5 10h9M6 16h12M3 21h18" />
      </>
    ),
    copy: (
      <>
        <rect x="8" y="8" width="11" height="12" rx="2" />
        <path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h3" />
      </>
    ),
    close: <path d="m6 6 12 12M18 6 6 18" />,
    crosshair: (
      <>
        <circle cx="12" cy="12" r="6" />
        <circle cx="12" cy="12" r="2" />
        <path d="M12 2v4M12 18v4M2 12h4M18 12h4" />
      </>
    ),
    edit: (
      <path d="m14 5 5 5M4 20l3.5-.7L20 6.8a1.8 1.8 0 0 0-2.6-2.6L5 16.5Z" />
    ),
    eye: (
      <>
        <path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z" />
        <circle cx="12" cy="12" r="2.5" />
      </>
    ),
    "eye-off": (
      <>
        <path d="M3 3l18 18" />
        <path d="M10.6 6.2A11.8 11.8 0 0 1 12 6c6.5 0 10 6 10 6a17 17 0 0 1-3 3.7M6.6 6.7C3.6 8.5 2 12 2 12s3.5 6 10 6c1.6 0 3-.4 4.2-1" />
        <path d="M9.9 9.8a3 3 0 0 0 4.2 4.3" />
      </>
    ),
    filter: <path d="M4 5h16M7 12h10M10 19h4" />,
    gallery: (
      <>
        <rect x="3" y="4" width="18" height="16" rx="2" />
        <circle cx="9" cy="10" r="2" />
        <path d="m4 18 5-5 3 3 2-2 6 5" />
      </>
    ),
    heart: (
      <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z" />
    ),
    help: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M9.5 9a2.7 2.7 0 1 1 4.2 2.3c-1 .7-1.7 1.1-1.7 2.7M12 18h.01" />
      </>
    ),
    home: (
      <>
        <path d="m3 11 9-8 9 8" />
        <path d="M5 10v10h14V10M9 20v-6h6v6" />
      </>
    ),
    map: (
      <>
        <path d="m3 6 5-2 8 2 5-2v14l-5 2-8-2-5 2Z" />
        <path d="M8 4v14M16 6v14" />
      </>
    ),
    lock: (
      <>
        <rect x="5" y="10" width="14" height="11" rx="2" />
        <path d="M8 10V7a4 4 0 0 1 8 0v3" />
      </>
    ),
    logout: (
      <>
        <path d="M10 4H4v16h6M14 8l4 4-4 4M8 12h10" />
      </>
    ),
    mail: (
      <>
        <rect x="3" y="5" width="18" height="14" rx="2" />
        <path d="m4 7 8 6 8-6" />
      </>
    ),
    mask: (
      <>
        <path d="M4 5c4 2 12 2 16 0v7c0 5-3.6 9-8 10-4.4-1-8-5-8-10Z" />
        <path d="M7.5 11c1.4-1 2.7-1 4 0M12.5 11c1.3-1 2.6-1 4 0M10 16c1.3 1 2.7 1 4 0" />
      </>
    ),
    megaphone: (
      <>
        <path d="m3 11 13-5v12L3 13Z" />
        <path d="M6 14v5h4l1-4M19 9c1 1 1 5 0 6" />
      </>
    ),
    message: (
      <path d="M21 11.5a8.5 8.5 0 0 1-11.7 7.9L4 21l1.6-5.3A8.5 8.5 0 1 1 21 11.5Z" />
    ),
    moon: <path d="M20.5 15.2A8.7 8.7 0 0 1 8.8 3.5 9 9 0 1 0 20.5 15.2Z" />,
    more: (
      <>
        <circle cx="5" cy="12" r="1.5" fill="currentColor" stroke="none" />
        <circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none" />
        <circle cx="19" cy="12" r="1.5" fill="currentColor" stroke="none" />
      </>
    ),
    paw: (
      <>
        <ellipse cx="12" cy="16.5" rx="5.5" ry="4.5" />
        <ellipse cx="6" cy="10" rx="2" ry="2.8" />
        <ellipse cx="18" cy="10" rx="2" ry="2.8" />
        <ellipse cx="9.5" cy="6.5" rx="2" ry="2.8" />
        <ellipse cx="14.5" cy="6.5" rx="2" ry="2.8" />
      </>
    ),
    phone: (
      <path d="M5 3h4l2 5-3 2a16 16 0 0 0 6 6l2-3 5 2v4a2 2 0 0 1-2 2C10.2 20.5 3.5 13.8 3 5a2 2 0 0 1 2-2Z" />
    ),
    pin: (
      <>
        <path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z" />
        <circle cx="12" cy="10" r="2.5" />
      </>
    ),
    plus: <path d="M12 5v14M5 12h14" />,
    refresh: (
      <>
        <path d="M20 7v5h-5" />
        <path d="M4 17v-5h5" />
        <path d="M6.1 8a7 7 0 0 1 11.8-1L20 12M4 12l2.1 5a7 7 0 0 0 11.8-1" />
      </>
    ),
    search: (
      <>
        <circle cx="11" cy="11" r="7" />
        <path d="m16 16 5 5" />
      </>
    ),
    settings: (
      <>
        <circle cx="12" cy="12" r="3" />
        <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6v.2h-4V21a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H2.8v-4H3a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1a1.7 1.7 0 0 0 1.9.3A1.7 1.7 0 0 0 10 3V2.8h4V3a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.6 1h.2v4H21a1.7 1.7 0 0 0-1.6 1Z" />
      </>
    ),
    share: (
      <>
        <path d="M12 3v12M8 7l4-4 4 4" />
        <path d="M5 11H3v10h18V11h-2" />
      </>
    ),
    shield: (
      <>
        <path d="M12 2 4 5v6c0 5 3.4 8.7 8 11 4.6-2.3 8-6 8-11V5Z" />
        <path d="m8.5 12 2.2 2.2 4.8-5" />
      </>
    ),
    spray: (
      <>
        <path d="M8 8h9v13H7V10a2 2 0 0 1 1-2Z" />
        <path d="M10 8V5h5l2 3M15 5l3-2M19 6h3M19 9l2 1" />
      </>
    ),
    sos: (
      <>
        <path d="M12 3v3M5.6 5.6l2.1 2.1M3 12h3M18 12h3M16.3 7.7l2.1-2.1" />
        <path d="M7 20v-6a5 5 0 0 1 10 0v6Z" />
      </>
    ),
    user: (
      <>
        <circle cx="12" cy="8" r="4" />
        <path d="M4 21a8 8 0 0 1 16 0" />
      </>
    ),
    users: (
      <>
        <circle cx="12" cy="8" r="3.5" />
        <circle cx="5" cy="10" r="2.5" />
        <circle cx="19" cy="10" r="2.5" />
        <path d="M6 20v-2a6 6 0 0 1 12 0v2M1.5 19v-1a4 4 0 0 1 4-4M22.5 19v-1a4 4 0 0 0-4-4" />
      </>
    ),
    volume: (
      <>
        <path d="M5 9H2v6h3l5 4V5Z" />
        <path d="M14 9a4 4 0 0 1 0 6M17 6a8 8 0 0 1 0 12" />
      </>
    ),
    woman: (
      <>
        <circle cx="12" cy="6" r="3" />
        <path d="M8 21v-6H5l3-6h8l3 6h-3v6M10 15v6M14 15v6" />
      </>
    ),
  }

  return (
    <svg
      aria-hidden="true"
      fill="none"
      height={size}
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={strokeWidth}
      className="icon"
      vectorEffect="non-scaling-stroke"
      viewBox="0 0 24 24"
      width={size}
    >
      {paths[name]}
    </svg>
  )
}

type StickerName = "activity" | "bell" | "bell-header" | "bulb" | "camera" | "car" | "cone" | "contact-anonymous" | "contact-citizen" | "contact-phone" | "contact-plus" | "contact-police" | "contact-protection" | "contact-woman" | "emergency" | "gallery" | "home" | "map" | "map-white" | "megaphone" | "megaphone-white" | "more" | "mourning" | "paw" | "pin" | "plus" | "reports" | "robbery" | "shield" | "shield-header" | "spray" | "user" | "users"

function Sticker({
  name,
  className = "",
}: {
  name: StickerName
  className?: string
}) {
  return (
    <img
      alt=""
      aria-hidden="true"
      className={`sticker ${className}`}
      draggable="false"
      src={`/icons/3d/${name}.${name === "mourning" ? "png" : "webp"}`}
    />
  )
}

type ActivityIconName = "accepted" | "alert" | "comment" | "pending" | "rejected"

function ActivityIcon({ name }: { name: ActivityIconName }) {
  return (
    <img
      alt=""
      aria-hidden="true"
      className="activity-3d-icon"
      draggable="false"
      src={`/icons/3d/activity-${name}.png`}
    />
  )
}

type TrackingIconName = "progress" | "complete" | "current" | "pending" | "notification"

function TrackingIcon({
  name,
  className = "",
}: {
  name: TrackingIconName
  className?: string
}) {
  return (
    <img
      alt=""
      aria-hidden="true"
      className={`tracking-3d-icon ${className}`}
      draggable="false"
      src={`/icons/3d/tracking-${name}.png`}
    />
  )
}

type NavItem = {
  label: string
  sticker: StickerName
}

const navItems: NavItem[] = [
  { label: "Inicio", sticker: "home" },
  { label: "Mapa", sticker: "map" },
  { label: "Reportar", sticker: "plus" },
  { label: "Actividad", sticker: "activity" },
  { label: "Perfil", sticker: "user" },
]

type ReportStatus = "En revisión" | "En atención" | "Resuelto"

type EvidencePhoto = {
  src: string
  alt: string
}

type CitizenReport = {
  id: string
  title: string
  location: string
  date: string
  status: ReportStatus
  sticker: StickerName
  folio?: string
  description?: string
  evidence?: readonly EvidencePhoto[]
  position?: Coordinates
}

const evidencePhotos = [
  {
    src: "https://images.unsplash.com/photo-1518105779142-d975f22f1b0a?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
    alt: "Calle urbana con edificios en México",
  },
  {
    src: "https://images.unsplash.com/photo-1501532349-1c215c24f718?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
    alt: "Personas caminando entre edificios coloniales",
  },
] as const

type MapIncident = CitizenReport & {
  id: string
  category: "seguridad" | "vialidad" | "servicios" | "animales"
  position: Coordinates
  tone: string
  source: "demo" | "live"
  relativeTime: string
  folio: string
  description: string
  evidence: readonly EvidencePhoto[]
}

const demoIncidentPoints: MapIncident[] = [
  {
    id: "demo-assault-centro",
    title: "Intento de asalto",
    location: "Centro, Cuautla",
    date: "17 oct 2026, 15:30",
    relativeTime: "Hace 1 h",
    status: "En revisión",
    folio: "RC-2026-001234",
    description:
      "Una persona intentó despojar a un peatón de sus pertenencias cerca de la esquina. Vestía una mochila negra y gorra.",
    evidence: evidencePhotos,
    category: "seguridad",
    sticker: "robbery",
    position: { lat: 18.8148, lng: -98.9584 },
    tone: "red",
    source: "demo",
  },
  {
    id: "demo-animal-welfare",
    title: "Reporte de maltrato animal",
    location: "Col. Emiliano Zapata",
    date: "17 oct 2026, 14:05",
    relativeTime: "Hace 2 h",
    status: "En atención",
    folio: "RC-2026-001235",
    description:
      "Se reportó un animal expuesto al sol y sin acceso visible a agua. Personal de atención animal fue notificado.",
    evidence: [],
    category: "animales",
    sticker: "paw",
    position: { lat: 18.8193, lng: -98.9503 },
    tone: "purple",
    source: "demo",
  },
  {
    id: "demo-road-damage",
    title: "Bache en vía pública",
    location: "Av. Reforma, Cuautla",
    date: "17 oct 2026, 12:40",
    relativeTime: "Hace 4 h",
    status: "En revisión",
    folio: "RC-2026-001236",
    description:
      "Bache profundo en el carril derecho que obliga a los vehículos a cambiar de trayectoria.",
    evidence: [],
    category: "vialidad",
    sticker: "cone",
    position: { lat: 18.8112, lng: -98.9466 },
    tone: "orange",
    source: "demo",
  },
  {
    id: "demo-traffic-incident",
    title: "Accidente vial",
    location: "Blvd. Jiquilpan, Cuautla",
    date: "17 oct 2026, 11:15",
    relativeTime: "Hace 5 h",
    status: "En atención",
    folio: "RC-2026-001237",
    description:
      "Colisión entre dos vehículos con afectación parcial a la circulación. Las unidades de apoyo ya fueron avisadas.",
    evidence: [evidencePhotos[0]],
    category: "vialidad",
    sticker: "car",
    position: { lat: 18.8066, lng: -98.9612 },
    tone: "blue",
    source: "demo",
  },
  {
    id: "demo-street-light",
    title: "Luminaria sin servicio",
    location: "Col. Gabriel Tepepa",
    date: "16 oct 2026, 21:10",
    relativeTime: "Hace 19 h",
    status: "En revisión",
    folio: "RC-2026-001238",
    description:
      "La luminaria de la esquina permanece apagada y deja el cruce con poca visibilidad durante la noche.",
    evidence: [],
    category: "servicios",
    sticker: "bulb",
    position: { lat: 18.8054, lng: -98.9512 },
    tone: "green",
    source: "demo",
  },
]

// La API real podrá llenar esta colección sin mezclar sus datos con la muestra.
const liveIncidentPoints: MapIncident[] = []
const incidentPoints = [...liveIncidentPoints, ...demoIncidentPoints]

const reportCategories: {
  label: string
  sticker: StickerName
  className: string
  wide?: boolean
}[] = [
  {
    label: "Robo / Asalto",
    sticker: "robbery",
    className: "category-robbery",
  },
  { label: "Accidente", sticker: "car", className: "category-accident" },
  {
    label: "Vandalismo",
    sticker: "spray",
    className: "category-vandalism",
  },
  { label: "Violencia", sticker: "users", className: "category-violence" },
  {
    label: "Alumbrado público",
    sticker: "bulb",
    className: "category-lighting",
  },
  {
    label: "Baches / Vía pública",
    sticker: "cone",
    className: "category-roads",
  },
  {
    label: "Maltrato animal",
    sticker: "paw",
    className: "category-animals",
  },
  {
    label: "Deceso",
    sticker: "mourning",
    className: "category-death",
  },
  {
    label: "Otro",
    sticker: "more",
    className: "category-other",
  },
]

function ReportScreen({
  onBack,
  onContinue,
  initialCategory,
}: {
  onBack: () => void
  onContinue: (category: string) => void
  initialCategory: string
}) {
  const [selected, setSelected] = useState(initialCategory)

  return (
    <div className="report-screen">
      <header className="report-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Nuevo reporte</h1>
        <span aria-hidden="true" />
      </header>

      <div className="report-body">
        <ol className="report-progress" aria-label="Progreso del reporte">
          <li className="current">
            <span>1</span>
            <strong>Tipo</strong>
          </li>
          <li>
            <span>2</span>
            <strong>Detalles</strong>
          </li>
          <li>
            <span>3</span>
            <strong>Confirmar</strong>
          </li>
        </ol>

        <div className="report-intro">
          <h2>¿Qué tipo de incidente quieres reportar?</h2>
          <p>Selecciona la categoría que mejor describa la situación.</p>
        </div>

        <div
          className="category-grid"
          role="radiogroup"
          aria-label="Tipo de incidente"
        >
          {reportCategories.map((category) => {
            const isSelected = selected === category.label
            return (
              <button
                type="button"
                role="radio"
                aria-checked={isSelected}
                className={`category-card ${category.className} ${
                  category.wide ? "category-wide" : ""
                } ${isSelected ? "selected" : ""}`}
                key={category.label}
                onClick={() => setSelected(category.label)}
              >
                <span className="category-icon">
                  <Sticker name={category.sticker} />
                </span>
                <strong>{category.label}</strong>
              </button>
            )
          })}
        </div>

        <button
          type="button"
          className="continue-button"
          onClick={() => onContinue(selected)}
        >
          <span>Siguiente</span>
          <Icon name="arrow-right" size={25} strokeWidth={2.4} />
        </button>
      </div>
    </div>
  )
}

type Coordinates = {
  lat: number
  lng: number
}

type ReportEvidence = {
  id: string
  name: string
  url: string
}

type ReportDraft = {
  category: string
  description: string
  location: string
  position: Coordinates
  evidence: ReportEvidence[]
}

function AddressSearch({
  className,
  value,
  placeholder,
  onChange,
  onUnavailable,
}: {
  className: string
  value: string
  placeholder: string
  onChange: (value: string) => void
  onUnavailable: () => void
}) {
  const submitSearch = (event: FormEvent) => {
    event.preventDefault()
    if (!value.trim()) return
    onUnavailable()
  }

  return (
    <form
      className={className}
      onSubmit={submitSearch}
      data-geocoding-status="unconfigured"
    >
      {className === "map-search" && (
        <Icon name="search" size={24} strokeWidth={2.2} />
      )}
      <input
        value={value}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        aria-label={placeholder}
      />
    </form>
  )
}

function MapLibreLocationPicker({
  position,
  onLocationChange,
}: {
  position: Coordinates
  onLocationChange: (address: string, position: Coordinates) => void
}) {
  const mapElement = useRef<HTMLDivElement>(null)
  const map = useRef<MapLibreMap | null>(null)
  const marker = useRef<MapLibreMarker | null>(null)
  const [loading, setLoading] = useState(true)
  const [mapError, setMapError] = useState("")
  const [retryKey, setRetryKey] = useState(0)

  useEffect(() => {
    let disposed = false
    setLoading(true)
    setMapError("")

    const initializeMap = async () => {
      try {
        const maplibregl = await loadMapLibre()
        if (disposed || !mapElement.current) return

        const mapInstance = new maplibregl.Map({
          container: mapElement.current,
          style: OPENFREEMAP_STYLE,
          center: [position.lng, position.lat],
          zoom: 16,
          pitch: 0,
          attributionControl: false,
        })
        addMissingStyleImageFallback(mapInstance)
        addMapAttribution(mapInstance, maplibregl)

        const markerElement = document.createElement("div")
        markerElement.className = "report-location-marker"
        markerElement.innerHTML = '<img src="/icons/3d/pin.webp" alt="" />'

        const mapMarker = new maplibregl.Marker({
          element: markerElement,
          anchor: "bottom",
          draggable: true,
        })
          .setLngLat([position.lng, position.lat])
          .addTo(mapInstance)

        const updateLocation = (coordinates: Coordinates) => {
          const coordinateLabel = `${coordinates.lat.toFixed(5)}, ${coordinates.lng.toFixed(5)}`
          mapMarker.setLngLat([coordinates.lng, coordinates.lat])
          onLocationChange(coordinateLabel, coordinates)
        }

        mapInstance.on("click", (event) => {
          updateLocation({ lat: event.lngLat.lat, lng: event.lngLat.lng })
        })
        mapMarker.on("dragend", () => {
          const nextPosition = mapMarker.getLngLat()
          updateLocation({
            lat: nextPosition.lat,
            lng: nextPosition.lng,
          })
        })
        mapInstance.once("load", () => {
          if (!disposed) setLoading(false)
        })
        mapInstance.on("error", () => {
          if (!disposed && !mapInstance.loaded()) {
            setLoading(false)
            setMapError("No se pudo cargar el mapa de OpenFreeMap")
          }
        })

        map.current = mapInstance
        marker.current = mapMarker
      } catch {
        if (!disposed) {
          setLoading(false)
          setMapError("No se pudo iniciar el mapa de OpenFreeMap")
        }
      }
    }

    void initializeMap()

    return () => {
      disposed = true
      marker.current?.remove()
      marker.current = null
      map.current?.remove()
      map.current = null
    }
  }, [retryKey])

  useEffect(() => {
    if (!map.current || !marker.current) return
    marker.current.setLngLat([position.lng, position.lat])
    map.current.easeTo({ center: [position.lng, position.lat] })
  }, [position])

  return (
    <div className="maplibre-location-picker">
      <div className="maplibre-map-canvas" ref={mapElement} />
      {loading && <div className="map-state">Cargando OpenFreeMap...</div>}
      {mapError && (
        <div className="map-state map-error">
          <Icon name="map" size={24} />
          <span>{mapError}</span>
          <button type="button" onClick={() => setRetryKey((key) => key + 1)}>
            Reintentar
          </button>
        </div>
      )}
      {!loading && !mapError && (
        <span className="map-help">Toca el mapa o arrastra el marcador</span>
      )}
    </div>
  )
}

type UserZone = {
  address: string
  position: Coordinates
  radius: number
}

type NominatimResult = {
  lat: string
  lon: string
  display_name: string
  address?: Record<string, string>
}

type ZoneCircleFeature = {
  type: "Feature"
  properties: Record<string, never>
  geometry: {
    type: "Polygon"
    coordinates: number[][][]
  }
}

const ZONE_RADIUS_SOURCE_ID = "configured-zone-radius"
const ZONE_RADIUS_FILL_ID = "configured-zone-radius-fill"
const ZONE_RADIUS_LINE_ID = "configured-zone-radius-line"

function createZoneCircle(
  position: Coordinates,
  radiusKm: number,
): ZoneCircleFeature {
  const earthRadiusKm = 6371.0088
  const angularDistance = radiusKm / earthRadiusKm
  const latitudeRadians = (position.lat * Math.PI) / 180
  const coordinates: number[][] = []

  for (let index = 0; index <= 96; index += 1) {
    const bearing = (index / 96) * Math.PI * 2
    const latitude =
      Math.asin(
        Math.sin(latitudeRadians) * Math.cos(angularDistance) +
          Math.cos(latitudeRadians) *
            Math.sin(angularDistance) *
            Math.cos(bearing),
      ) *
      (180 / Math.PI)
    const longitude =
      position.lng +
      Math.atan2(
        Math.sin(bearing) *
          Math.sin(angularDistance) *
          Math.cos(latitudeRadians),
        Math.cos(angularDistance) -
          Math.sin(latitudeRadians) * Math.sin((latitude * Math.PI) / 180),
      ) *
        (180 / Math.PI)

    coordinates.push([longitude, latitude])
  }

  return {
    type: "Feature",
    properties: {},
    geometry: { type: "Polygon", coordinates: [coordinates] },
  }
}

function getZoneBounds(position: Coordinates, radiusKm: number) {
  const latitudeDelta = radiusKm / 110.574
  const longitudeDelta =
    radiusKm / (111.32 * Math.cos((position.lat * Math.PI) / 180))

  return [
    [position.lng - longitudeDelta, position.lat - latitudeDelta],
    [position.lng + longitudeDelta, position.lat + latitudeDelta],
  ] as [[number, number], [number, number]]
}

function updateZoneRadius(
  map: MapLibreMap,
  position: Coordinates,
  radiusKm: number,
) {
  const source = map.getSource(
    ZONE_RADIUS_SOURCE_ID,
  ) as GeoJSONSource | undefined
  source?.setData(createZoneCircle(position, radiusKm))
}

function fitZoneRadius(
  map: MapLibreMap,
  position: Coordinates,
  radiusKm: number,
  duration = 500,
) {
  map.fitBounds(getZoneBounds(position, radiusKm), {
    padding: { top: 34, right: 34, bottom: 34, left: 34 },
    duration,
  })
}

function formatNominatimAddress(result: NominatimResult) {
  const details = result.address ?? {}
  const road = details.road ?? details.pedestrian ?? details.path
  const street = road
    ? `${road}${details.house_number ? ` ${details.house_number}` : ""}`
    : ""
  const neighbourhood =
    details.neighbourhood ??
    details.suburb ??
    details.quarter ??
    details.residential
  const colony = neighbourhood
    ? neighbourhood.toLowerCase().startsWith("col")
      ? neighbourhood
      : `Col. ${neighbourhood}`
    : ""
  const locality =
    details.city ??
    details.town ??
    details.municipality ??
    details.village ??
    "Cuautla"
  const state = details.state ?? "Morelos"
  const parts = [street, colony, locality, state].filter(
    (part, index, all) => part && all.indexOf(part) === index,
  )

  return parts.length >= 2
    ? parts.join(", ")
    : result.display_name.split(",").slice(0, 4).join(",").trim()
}

async function reverseGeocodeZone(position: Coordinates) {
  const params = new URLSearchParams({
    format: "jsonv2",
    lat: String(position.lat),
    lon: String(position.lng),
    addressdetails: "1",
    "accept-language": "es",
  })
  const response = await fetch(
    `https://nominatim.openstreetmap.org/reverse?${params}`,
    { headers: { Accept: "application/json" } },
  )
  if (!response.ok) throw new Error("Reverse geocoding failed")
  return formatNominatimAddress((await response.json()) as NominatimResult)
}

async function searchZoneAddress(query: string) {
  const params = new URLSearchParams({
    format: "jsonv2",
    q: `${query}, Cuautla, Morelos, México`,
    limit: "1",
    addressdetails: "1",
    "accept-language": "es",
  })
  const response = await fetch(
    `https://nominatim.openstreetmap.org/search?${params}`,
    { headers: { Accept: "application/json" } },
  )
  if (!response.ok) throw new Error("Forward geocoding failed")
  const results = (await response.json()) as NominatimResult[]
  if (!results[0]) return null

  return {
    address: formatNominatimAddress(results[0]),
    position: {
      lat: Number(results[0].lat),
      lng: Number(results[0].lon),
    },
  }
}

function ZoneConfigurationScreen({
  initialZone,
  onBack,
  onSave,
  onNotice,
}: {
  initialZone: UserZone
  onBack: () => void
  onSave: (zone: UserZone) => void
  onNotice: (message: string) => void
}) {
  const mapElement = useRef<HTMLDivElement>(null)
  const map = useRef<MapLibreMap | null>(null)
  const marker = useRef<MapLibreMarker | null>(null)
  const [address, setAddress] = useState(initialZone.address)
  const [position, setPosition] = useState(initialZone.position)
  const [radius, setRadius] = useState(initialZone.radius)
  const [loading, setLoading] = useState(true)
  const [mapError, setMapError] = useState("")
  const [locating, setLocating] = useState(false)
  const [addressEditorOpen, setAddressEditorOpen] = useState(false)
  const [savingManualAddress, setSavingManualAddress] = useState(false)
  const [manualAddress, setManualAddress] = useState({
    street: "",
    number: "",
    colony: "",
    postalCode: "",
    zone: "Cuautla",
  })
  const [retryKey, setRetryKey] = useState(0)
  const geocodingRequest = useRef(0)

  const resolveAddress = async (
    nextPosition: Coordinates,
    fallback = "Zona seleccionada, Cuautla, Morelos",
  ) => {
    const requestId = geocodingRequest.current + 1
    geocodingRequest.current = requestId
    setAddress("Buscando dirección...")
    try {
      const nextAddress = await reverseGeocodeZone(nextPosition)
      if (requestId === geocodingRequest.current) setAddress(nextAddress)
    } catch {
      if (requestId === geocodingRequest.current) setAddress(fallback)
    }
  }

  useEffect(() => {
    let disposed = false
    setLoading(true)
    setMapError("")

    const initializeMap = async () => {
      try {
        const maplibregl = await loadMapLibre()
        if (disposed || !mapElement.current) return

        const mapInstance = new maplibregl.Map({
          container: mapElement.current,
          style: OPENFREEMAP_STYLE,
          center: [position.lng, position.lat],
          zoom: 14.6,
          pitch: 0,
          attributionControl: false,
        })
        addMissingStyleImageFallback(mapInstance)
        addMapAttribution(mapInstance, maplibregl)

        const markerElement = document.createElement("div")
        markerElement.className = "zone-map-marker"
        markerElement.innerHTML = '<img src="/icons/3d/pin.webp" alt="" />'
        const mapMarker = new maplibregl.Marker({
          element: markerElement,
          anchor: "bottom",
        })
          .setLngLat([position.lng, position.lat])
          .addTo(mapInstance)

        mapInstance.on("click", (event) => {
          const nextPosition = {
            lat: event.lngLat.lat,
            lng: event.lngLat.lng,
          }
          setPosition(nextPosition)
          void resolveAddress(nextPosition)
          mapMarker.setLngLat([nextPosition.lng, nextPosition.lat])
        })
        mapInstance.once("load", () => {
          if (disposed) return
          mapInstance.addSource(ZONE_RADIUS_SOURCE_ID, {
            type: "geojson",
            data: createZoneCircle(position, radius),
          })
          mapInstance.addLayer({
            id: ZONE_RADIUS_FILL_ID,
            type: "fill",
            source: ZONE_RADIUS_SOURCE_ID,
            paint: {
              "fill-color": "#3b9df5",
              "fill-opacity": 0.19,
            },
          })
          mapInstance.addLayer({
            id: ZONE_RADIUS_LINE_ID,
            type: "line",
            source: ZONE_RADIUS_SOURCE_ID,
            paint: {
              "line-color": "#2387e9",
              "line-opacity": 0.5,
              "line-width": 2,
            },
          })
          fitZoneRadius(mapInstance, position, radius, 0)
          setLoading(false)
        })
        mapInstance.on("error", () => {
          if (!disposed && !mapInstance.loaded()) {
            setLoading(false)
            setMapError("No se pudo cargar el mapa")
          }
        })

        map.current = mapInstance
        marker.current = mapMarker
      } catch {
        if (!disposed) {
          setLoading(false)
          setMapError("No se pudo iniciar el mapa")
        }
      }
    }

    void initializeMap()

    return () => {
      disposed = true
      marker.current?.remove()
      marker.current = null
      map.current?.remove()
      map.current = null
    }
  }, [retryKey])

  useEffect(() => {
    marker.current?.setLngLat([position.lng, position.lat])
    const mapInstance = map.current
    if (!mapInstance || !mapInstance.loaded()) return
    updateZoneRadius(mapInstance, position, radius)
    fitZoneRadius(mapInstance, position, radius)
  }, [position, radius])

  const useCurrentLocation = () => {
    if (!navigator.geolocation) {
      onNotice("La geolocalización no está disponible")
      return
    }

    setLocating(true)
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const nextPosition = {
          lat: coords.latitude,
          lng: coords.longitude,
        }
        setPosition(nextPosition)
        void resolveAddress(nextPosition, "Ubicación actual, Cuautla, Morelos")
        setLocating(false)
      },
      () => {
        setLocating(false)
        onNotice("No fue posible obtener tu ubicación")
      },
      { enableHighAccuracy: true, timeout: 8000 },
    )
  }

  const saveManualAddress = async (event: FormEvent) => {
    event.preventDefault()
    const streetLine =
      `${manualAddress.street.trim()} ${manualAddress.number.trim()}`.trim()
    const colony = manualAddress.colony.trim()
    const postalCode = manualAddress.postalCode.trim()
    const zone = manualAddress.zone.trim() || "Cuautla"
    const formattedAddress = [
      streetLine,
      colony ? `Col. ${colony}` : "",
      postalCode ? `C.P. ${postalCode}` : "",
      zone,
      "Morelos",
    ]
      .filter(Boolean)
      .join(", ")

    setSavingManualAddress(true)
    setAddress(formattedAddress)
    try {
      const result = await searchZoneAddress(
        `${streetLine}, ${colony}, ${postalCode}, ${zone}`,
      )
      if (result) setPosition(result.position)
      else
        onNotice(
          "Guardamos la dirección, pero no pudimos ubicarla exactamente en el mapa",
        )
    } catch {
      onNotice(
        "Guardamos la dirección, pero el mapa no pudo actualizarse en este momento",
      )
    } finally {
      setSavingManualAddress(false)
      setAddressEditorOpen(false)
    }
  }

  return (
    <div className="zone-screen">
      <header className="zone-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={30} strokeWidth={2.5} />
        </button>
        <h1>Configurar mi zona</h1>
        <span aria-hidden="true" />
      </header>

      <div className="zone-content">
        <section className="zone-intro">
          <img src="/icons/3d/zone-location.png" alt="" aria-hidden="true" />
          <div>
            <h2>Define tu zona</h2>
            <p>
              Recibe notificaciones de incidentes en la zona que te interesa de
              Cuautla, Morelos.
            </p>
          </div>
        </section>

        <button
          type="button"
          className="zone-address"
          onClick={() => setAddressEditorOpen(true)}
          aria-haspopup="dialog"
          aria-expanded={addressEditorOpen}
        >
          <span className="zone-address-icon">
            <Sticker name="pin" />
          </span>
          <strong>{address}</strong>
          <Icon name="chevron" size={22} strokeWidth={2.5} />
        </button>

        <div className="zone-map">
          <div className="zone-map-canvas" ref={mapElement} />
          {loading && <div className="zone-map-state">Cargando mapa...</div>}
          {mapError && (
            <div className="zone-map-state zone-map-error">
              <span>{mapError}</span>
              <button
                type="button"
                onClick={() => setRetryKey((key) => key + 1)}
              >
                Reintentar
              </button>
            </div>
          )}
          <button
            type="button"
            className="zone-map-locate"
            onClick={useCurrentLocation}
            aria-label={
              locating
                ? "Obteniendo mi ubicación"
                : "Centrar mapa en mi ubicación"
            }
            disabled={locating}
          >
            <Icon name="crosshair" size={25} strokeWidth={2.2} />
          </button>
        </div>

        <section className="zone-radius-control">
          <div>
            <h2>Radio de notificaciones: {radius} km</h2>
            <strong>{radius} km</strong>
          </div>
          <input
            type="range"
            min="1"
            max="10"
            step="1"
            value={radius}
            onChange={(event) => setRadius(Number(event.target.value))}
            aria-label={`Radio de notificaciones: ${radius} kilómetros`}
          />
          <div className="zone-range-labels">
            <span>1 km</span>
            <span>10 km</span>
          </div>
        </section>

        <button
          type="button"
          className="zone-save"
          onClick={() => onSave({ address, position, radius })}
        >
          Guardar zona
        </button>
      </div>

      {addressEditorOpen && (
        <div
          className="zone-address-modal"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget)
              setAddressEditorOpen(false)
          }}
        >
          <section
            className="zone-address-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="zone-address-title"
          >
            <div className="zone-address-dialog-heading">
              <span className="zone-dialog-pin">
                <Sticker name="pin" />
              </span>
              <div>
                <p>Cuautla, Morelos</p>
                <h2 id="zone-address-title">Escribe tu dirección</h2>
              </div>
              <button
                type="button"
                onClick={() => setAddressEditorOpen(false)}
                aria-label="Cerrar captura de dirección"
              >
                <Icon name="close" size={20} strokeWidth={2.3} />
              </button>
            </div>

            <form className="zone-address-form" onSubmit={saveManualAddress}>
              <label>
                <span>Calle</span>
                <input
                  autoFocus
                  required
                  value={manualAddress.street}
                  onChange={(event) =>
                    setManualAddress((current) => ({
                      ...current,
                      street: event.target.value,
                    }))
                  }
                  placeholder="Ej. Av. Insurgentes"
                />
              </label>

              <div className="zone-address-form-row">
                <label>
                  <span>Número</span>
                  <input
                    value={manualAddress.number}
                    onChange={(event) =>
                      setManualAddress((current) => ({
                        ...current,
                        number: event.target.value,
                      }))
                    }
                    placeholder="123"
                    inputMode="numeric"
                  />
                </label>
                <label>
                  <span>Código postal</span>
                  <input
                    required
                    value={manualAddress.postalCode}
                    onChange={(event) =>
                      setManualAddress((current) => ({
                        ...current,
                        postalCode: event.target.value
                          .replace(/\D/g, "")
                          .slice(0, 5),
                      }))
                    }
                    placeholder="62740"
                    inputMode="numeric"
                    pattern="[0-9]{5}"
                  />
                </label>
              </div>

              <label>
                <span>Colonia o localidad</span>
                <input
                  required
                  value={manualAddress.colony}
                  onChange={(event) =>
                    setManualAddress((current) => ({
                      ...current,
                      colony: event.target.value,
                    }))
                  }
                  placeholder="Ej. Emiliano Galeana"
                />
              </label>

              <label>
                <span>Municipio o zona</span>
                <input
                  required
                  value={manualAddress.zone}
                  onChange={(event) =>
                    setManualAddress((current) => ({
                      ...current,
                      zone: event.target.value,
                    }))
                  }
                  placeholder="Cuautla"
                />
              </label>

              <div className="zone-address-form-actions">
                <button
                  type="button"
                  onClick={() => setAddressEditorOpen(false)}
                >
                  Cancelar
                </button>
                <button type="submit" disabled={savingManualAddress}>
                  {savingManualAddress ? "Ubicando..." : "Usar dirección"}
                </button>
              </div>
            </form>
          </section>
        </div>
      )}
    </div>
  )
}

function DetailsScreen({
  initialDraft,
  onBack,
  onContinue,
  onNotice,
}: {
  initialDraft: ReportDraft
  onBack: () => void
  onContinue: (draft: ReportDraft) => void
  onNotice: (message: string) => void
}) {
  const [description, setDescription] = useState(initialDraft.description)
  const [location, setLocation] = useState(initialDraft.location)
  const [position, setPosition] = useState<Coordinates>(initialDraft.position)
  const [locating, setLocating] = useState(false)
  const [evidence, setEvidence] = useState<ReportEvidence[]>(
    initialDraft.evidence,
  )
  const [addressEditorOpen, setAddressEditorOpen] = useState(false)
  const [savingManualAddress, setSavingManualAddress] = useState(false)
  const [manualAddress, setManualAddress] = useState({
    street: "",
    number: "",
    colony: "",
    postalCode: "",
    zone: "Cuautla",
  })

  const useCurrentLocation = () => {
    if (!navigator.geolocation) {
      onNotice("La geolocalización no está disponible")
      return
    }

    setLocating(true)
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const coordinates = {
          lat: coords.latitude,
          lng: coords.longitude,
        }
        setPosition(coordinates)
        setLocation(
          `${coords.latitude.toFixed(5)}, ${coords.longitude.toFixed(5)}`,
        )
        setLocating(false)
        onNotice("Ubicación actualizada")
      },
      () => {
        setLocating(false)
        onNotice("No fue posible obtener tu ubicación")
      },
      { enableHighAccuracy: true, timeout: 8000 },
    )
  }

  const handleEvidence = (files: FileList | null) => {
    if (!files?.length) return
    const nextEvidence = Array.from(files).map((file, index) => ({
      id: `${file.name}-${file.lastModified}-${index}`,
      name: file.name,
      url: URL.createObjectURL(file),
    }))
    setEvidence((current) => [...current, ...nextEvidence])
    onNotice(`${files.length} archivo${files.length > 1 ? "s" : ""} agregado`)
  }

  const saveManualAddress = async (event: FormEvent) => {
    event.preventDefault()
    const streetLine =
      `${manualAddress.street.trim()} ${manualAddress.number.trim()}`.trim()
    const colony = manualAddress.colony.trim()
    const postalCode = manualAddress.postalCode.trim()
    const zone = manualAddress.zone.trim() || "Cuautla"
    const formattedAddress = [
      streetLine,
      colony ? `Col. ${colony}` : "",
      postalCode ? `C.P. ${postalCode}` : "",
      zone,
      "Morelos",
    ]
      .filter(Boolean)
      .join(", ")

    setSavingManualAddress(true)
    setLocation(formattedAddress)
    try {
      const result = await searchZoneAddress(
        `${streetLine}, ${colony}, ${postalCode}, ${zone}`,
      )
      if (result) {
        setPosition(result.position)
        setLocation(result.address)
      } else {
        onNotice(
          "Guardamos la dirección, pero no pudimos ubicarla exactamente en el mapa",
        )
      }
    } catch {
      onNotice(
        "Guardamos la dirección, pero el mapa no pudo actualizarse en este momento",
      )
    } finally {
      setSavingManualAddress(false)
      setAddressEditorOpen(false)
    }
  }

  return (
    <div className="report-screen details-screen">
      <header className="report-header">
        <button type="button" onClick={onBack} aria-label="Volver a categorías">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Nuevo reporte</h1>
        <span aria-hidden="true" />
      </header>

      <div className="details-body">
        <ol
          className="report-progress details-progress"
          aria-label="Progreso del reporte"
        >
          <li className="complete">
            <span>
              <Icon name="check" size={24} strokeWidth={2.8} />
            </span>
            <strong>Tipo</strong>
          </li>
          <li className="current">
            <span>2</span>
            <strong>Detalles</strong>
          </li>
          <li>
            <span>3</span>
            <strong>Confirmar</strong>
          </li>
        </ol>

        <div className="details-intro">
          <h2>Cuéntanos más</h2>
          <p>Agrega los detalles del incidente.</p>
        </div>

        <label className="description-field">
          <span className="field-title">
            <Icon name="message" size={24} strokeWidth={1.9} />
            <strong>Descripción del incidente</strong>
          </span>
          <textarea
            value={description}
            maxLength={500}
            onChange={(event) => setDescription(event.target.value)}
            placeholder="Describe lo que ocurrió..."
          />
          <span className="character-count">{description.length}/500</span>
        </label>

        <section className="location-section" aria-labelledby="location-title">
          <h3 id="location-title">Ubicación del incidente</h3>
          <button
            type="button"
            className="incident-location"
            onClick={() => setAddressEditorOpen(true)}
            aria-haspopup="dialog"
            aria-expanded={addressEditorOpen}
          >
            <Sticker name="pin" className="location-sticker" />
            <strong>{location}</strong>
            <Icon name="edit" size={23} strokeWidth={2.1} />
          </button>

          <MapLibreLocationPicker
            position={position}
            onLocationChange={(nextAddress, nextPosition) => {
              setLocation(nextAddress)
              setPosition(nextPosition)
            }}
          />

          <button
            type="button"
            className="current-location-button"
            onClick={useCurrentLocation}
            disabled={locating}
          >
            <Icon name="crosshair" size={23} strokeWidth={2.1} />
            {locating ? "Buscando ubicación..." : "Usar mi ubicación actual"}
          </button>
        </section>

        <section className="evidence-section" aria-labelledby="evidence-title">
          <h3 id="evidence-title">
            Agregar evidencia <span>(opcional)</span>
          </h3>
          <div className="evidence-grid">
            <label className="evidence-card camera-evidence">
              <input
                type="file"
                accept="image/*"
                capture="environment"
                onChange={(event) => handleEvidence(event.target.files)}
              />
              <Sticker name="camera" className="evidence-sticker" />
              <strong>Cámara</strong>
            </label>
            <label className="evidence-card gallery-evidence">
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={(event) => handleEvidence(event.target.files)}
              />
              <Sticker name="gallery" className="evidence-sticker" />
              <strong>Galería</strong>
            </label>
          </div>
          {evidence.length > 0 && (
            <p className="evidence-status">
              {evidence.length} archivo{evidence.length > 1 ? "s" : ""} adjunto
              {evidence.length > 1 ? "s" : ""}
            </p>
          )}
        </section>

        <div className="details-actions">
          <button type="button" className="back-text-button" onClick={onBack}>
            Atrás
          </button>
          <button
            type="button"
            className="continue-button details-continue"
            onClick={() =>
              onContinue({
                category: initialDraft.category,
                description,
                location,
                position,
                evidence,
              })
            }
          >
            <span>Siguiente</span>
            <Icon name="arrow-right" size={25} strokeWidth={2.4} />
          </button>
        </div>
      </div>

      {addressEditorOpen && (
        <div
          className="zone-address-modal"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget)
              setAddressEditorOpen(false)
          }}
        >
          <section
            className="zone-address-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="report-address-title"
          >
            <div className="zone-address-dialog-heading">
              <span className="zone-dialog-pin">
                <Sticker name="pin" />
              </span>
              <div>
                <p>Ubicación del incidente</p>
                <h2 id="report-address-title">Escribe la dirección</h2>
              </div>
              <button
                type="button"
                onClick={() => setAddressEditorOpen(false)}
                aria-label="Cerrar captura de dirección"
              >
                <Icon name="close" size={20} strokeWidth={2.3} />
              </button>
            </div>

            <form className="zone-address-form" onSubmit={saveManualAddress}>
              <label>
                <span>Calle</span>
                <input
                  autoFocus
                  required
                  value={manualAddress.street}
                  onChange={(event) =>
                    setManualAddress((current) => ({
                      ...current,
                      street: event.target.value,
                    }))
                  }
                  placeholder="Ej. Av. Insurgentes"
                />
              </label>

              <div className="zone-address-form-row">
                <label>
                  <span>Número</span>
                  <input
                    value={manualAddress.number}
                    onChange={(event) =>
                      setManualAddress((current) => ({
                        ...current,
                        number: event.target.value,
                      }))
                    }
                    placeholder="123"
                    inputMode="numeric"
                  />
                </label>
                <label>
                  <span>Código postal</span>
                  <input
                    required
                    value={manualAddress.postalCode}
                    onChange={(event) =>
                      setManualAddress((current) => ({
                        ...current,
                        postalCode: event.target.value
                          .replace(/\D/g, "")
                          .slice(0, 5),
                      }))
                    }
                    placeholder="62740"
                    inputMode="numeric"
                    pattern="[0-9]{5}"
                  />
                </label>
              </div>

              <label>
                <span>Colonia o localidad</span>
                <input
                  required
                  value={manualAddress.colony}
                  onChange={(event) =>
                    setManualAddress((current) => ({
                      ...current,
                      colony: event.target.value,
                    }))
                  }
                  placeholder="Ej. Emiliano Galeana"
                />
              </label>

              <label>
                <span>Municipio o zona</span>
                <input
                  required
                  value={manualAddress.zone}
                  onChange={(event) =>
                    setManualAddress((current) => ({
                      ...current,
                      zone: event.target.value,
                    }))
                  }
                  placeholder="Cuautla"
                />
              </label>

              <div className="zone-address-form-actions">
                <button
                  type="button"
                  onClick={() => setAddressEditorOpen(false)}
                >
                  Cancelar
                </button>
                <button type="submit" disabled={savingManualAddress}>
                  {savingManualAddress ? "Ubicando..." : "Usar dirección"}
                </button>
              </div>
            </form>
          </section>
        </div>
      )}
    </div>
  )
}

function ConfirmationScreen({
  draft,
  onBack,
  onEditType,
  onEditDetails,
  onSubmit,
}: {
  draft: ReportDraft
  onBack: () => void
  onEditType: () => void
  onEditDetails: () => void
  onSubmit: () => void
}) {
  const category =
    reportCategories.find((item) => item.label === draft.category) ??
    reportCategories[reportCategories.length - 1]

  return (
    <div className="report-screen confirmation-screen">
      <header className="report-header">
        <button type="button" onClick={onBack} aria-label="Volver a detalles">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Nuevo reporte</h1>
        <span aria-hidden="true" />
      </header>

      <div className="confirmation-body">
        <ol
          className="report-progress confirmation-progress"
          aria-label="Progreso del reporte"
        >
          <li className="complete">
            <span>
              <Icon name="check" size={24} strokeWidth={2.8} />
            </span>
            <strong>Tipo</strong>
          </li>
          <li className="complete">
            <span>
              <Icon name="check" size={24} strokeWidth={2.8} />
            </span>
            <strong>Detalles</strong>
          </li>
          <li className="current">
            <span>3</span>
            <strong>Confirmar</strong>
          </li>
        </ol>

        <div className="confirmation-intro">
          <h2>Revisa tu reporte</h2>
          <p>Todo listo. Revisa los detalles antes de enviar.</p>
        </div>

        <div className="confirmation-cards">
          <section className="confirmation-card compact-card">
            <span className={`confirmation-icon ${category.className}`}>
              <Sticker name={category.sticker} />
            </span>
            <div className="confirmation-card-copy">
              <h3>{draft.category}</h3>
              <p>Tipo de incidente</p>
            </div>
            <button
              type="button"
              className="edit-report-button"
              onClick={onEditType}
            >
              <Icon name="edit" size={19} strokeWidth={2.2} />
              Editar
            </button>
          </section>

          <section className="confirmation-card compact-card">
            <span className="confirmation-icon description-confirmation-icon">
              <img
                src="/icons/3d/description.png"
                alt=""
                aria-hidden="true"
                draggable="false"
              />
            </span>
            <div className="confirmation-card-copy">
              <h3>Descripción</h3>
              <p>{draft.description.trim() || "Sin descripción adicional."}</p>
            </div>
            <button
              type="button"
              className="edit-report-button"
              onClick={onEditDetails}
            >
              <Icon name="edit" size={19} strokeWidth={2.2} />
              Editar
            </button>
          </section>

          <section className="confirmation-card location-confirmation-card">
            <div className="confirmation-card-heading">
              <span className="confirmation-icon location-confirmation-icon">
                <Sticker name="pin" />
              </span>
              <div className="confirmation-card-copy">
                <h3>Ubicación</h3>
                <p>{draft.location}</p>
              </div>
              <button
                type="button"
                className="edit-report-button"
                onClick={onEditDetails}
              >
                <Icon name="edit" size={19} strokeWidth={2.2} />
                Editar
              </button>
            </div>
            <ReportLocationPreview position={draft.position} />
          </section>

          <section className="confirmation-card evidence-confirmation-card">
            <div className="confirmation-card-heading">
              <span className="confirmation-icon evidence-confirmation-icon">
                <Sticker name="gallery" />
              </span>
              <div className="confirmation-card-copy">
                <h3>
                  Evidencias
                  <small>
                    {" "}
                    · {draft.evidence.length} foto
                    {draft.evidence.length === 1 ? "" : "s"}
                  </small>
                </h3>
              </div>
              <button
                type="button"
                className="edit-report-button"
                onClick={onEditDetails}
              >
                <Icon name="edit" size={19} strokeWidth={2.2} />
                Editar
              </button>
            </div>
            {draft.evidence.length > 0 ? (
              <div className="confirmation-gallery">
                {draft.evidence.slice(0, 3).map((item) => (
                  <img key={item.id} src={item.url} alt={item.name} />
                ))}
              </div>
            ) : (
              <p className="confirmation-no-evidence">
                No agregaste fotografías.
              </p>
            )}
          </section>
        </div>

        <div className="confirmation-notice">
          <Icon name="shield" size={23} strokeWidth={2.2} />
          <span>Se enviará al municipio para su revisión.</span>
        </div>

        <button
          type="button"
          className="continue-button submit-report-button"
          onClick={onSubmit}
        >
          <span>Enviar reporte</span>
          <span className="submit-report-arrow">
            <Icon name="arrow-right" size={25} strokeWidth={2.5} />
          </span>
        </button>
        <button
          type="button"
          className="confirmation-back-button"
          onClick={onBack}
        >
          Volver a detalles
        </button>
      </div>
    </div>
  )
}

function IncidentMapScreen({
  onBack,
  onHome,
  onReport,
  onActivity,
  onOpenIncident,
  onNotice,
}: {
  onBack: () => void
  onHome: () => void
  onReport: () => void
  onActivity: () => void
  onOpenIncident: (incident: MapIncident) => void
  onNotice: (message: string) => void
}) {
  const mapElement = useRef<HTMLDivElement>(null)
  const map = useRef<MapLibreMap | null>(null)
  const markers = useRef<{
    marker: MapLibreMarker
    category: typeof incidentPoints[number]["category"]
  }[]>([])
  const [query, setQuery] = useState("")
  const [filter, setFilter] =
    useState<"todos" | typeof incidentPoints[number]["category"]>("todos")
  const [filterOpen, setFilterOpen] = useState(false)
  const [showAllIncidents, setShowAllIncidents] = useState(false)
  const [nearbyCollapsed, setNearbyCollapsed] = useState(false)
  const [loading, setLoading] = useState(true)
  const [mapError, setMapError] = useState("")
  const [is3D, setIs3D] = useState(true)
  const [retryKey, setRetryKey] = useState(0)

  useEffect(() => {
    let disposed = false
    setLoading(true)
    setMapError("")

    const initializeMap = async () => {
      try {
        const maplibregl = await loadMapLibre()
        if (disposed || !mapElement.current) return

        const mapInstance = new maplibregl.Map({
          container: mapElement.current,
          style: OPENFREEMAP_STYLE,
          center: CUAUTLA_CENTER,
          zoom: 15.2,
          pitch: is3D ? 48 : 0,
          bearing: is3D ? -18 : 0,
          attributionControl: false,
        })
        addMissingStyleImageFallback(mapInstance)
        addMapAttribution(mapInstance, maplibregl)
        mapInstance.addControl(
          new maplibregl.NavigationControl({
            showCompass: false,
            visualizePitch: false,
          }),
          "bottom-right",
        )

        map.current = mapInstance
        markers.current = incidentPoints.map((point) => {
          const content = document.createElement("button")
          content.type = "button"
          content.className = `incident-marker marker-${point.tone}`
          content.title = `${point.title} · Reporte de demostración`
          content.setAttribute("aria-label", content.title)
          content.innerHTML = `<img src="/icons/3d/${point.sticker}.webp" alt="" />`
          content.addEventListener("click", () => onOpenIncident(point))

          return {
            category: point.category,
            marker: new maplibregl.Marker({
              element: content,
              anchor: "bottom",
              offset: [0, -7],
            })
              .setLngLat([point.position.lng, point.position.lat])
              .addTo(mapInstance),
          }
        })

        mapInstance.once("load", () => {
          if (disposed) return
          add3DBuildings(mapInstance)
          mapInstance.setLayoutProperty(
            BUILDINGS_LAYER_ID,
            "visibility",
            is3D ? "visible" : "none",
          )
          setLoading(false)
        })
        mapInstance.on("error", () => {
          if (!disposed && !mapInstance.loaded()) {
            setLoading(false)
            setMapError("No se pudo cargar el mapa de OpenFreeMap")
          }
        })
      } catch {
        if (!disposed) {
          setLoading(false)
          setMapError("No se pudo iniciar el mapa de OpenFreeMap")
        }
      }
    }

    void initializeMap()

    return () => {
      disposed = true
      markers.current.forEach(({ marker }) => {
        marker.remove()
      })
      markers.current = []
      map.current?.remove()
      map.current = null
    }
  }, [retryKey])

  useEffect(() => {
    markers.current.forEach(({ marker, category }) => {
      if (filter === "todos" || filter === category) {
        if (map.current) marker.addTo(map.current)
      } else {
        marker.remove()
      }
    })
  }, [filter, retryKey])

  useEffect(() => {
    const mapInstance = map.current
    if (!mapInstance) return

    mapInstance.easeTo({
      pitch: is3D ? 48 : 0,
      bearing: is3D ? -18 : 0,
      duration: 650,
    })
    if (mapInstance.getLayer(BUILDINGS_LAYER_ID)) {
      mapInstance.setLayoutProperty(
        BUILDINGS_LAYER_ID,
        "visibility",
        is3D ? "visible" : "none",
      )
    }
  }, [is3D])

  const toggleMapMode = () => {
    setIs3D((enabled) => !enabled)
  }

  const visibleIncidents =
    filter === "todos"
      ? incidentPoints
      : incidentPoints.filter((incident) => incident.category === filter)

  const locateUser = () => {
    if (!navigator.geolocation) {
      onNotice("La geolocalización no está disponible")
      return
    }

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const position = { lat: coords.latitude, lng: coords.longitude }
        map.current?.easeTo({
          center: [position.lng, position.lat],
          zoom: 16,
          duration: 700,
        })
        onNotice("Mostrando tu ubicación")
      },
      () => onNotice("No fue posible obtener tu ubicación"),
      { enableHighAccuracy: true, timeout: 8000 },
    )
  }

  return (
    <div className="incidents-screen">
      <header className="incidents-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Mapa de incidentes</h1>
        <span aria-hidden="true" />
      </header>

      <section
        className={`incidents-map-area ${
          nearbyCollapsed ? "nearby-collapsed" : ""
        } ${showAllIncidents ? "nearby-expanded" : ""}`}
        aria-label="Mapa de incidentes"
      >
        <div className="incidents-map-canvas" ref={mapElement} />

        <AddressSearch
          className="map-search"
          value={query}
          onChange={setQuery}
          placeholder="Buscar en esta zona..."
          onUnavailable={() =>
            onNotice("Conecta un servicio de geocodificación para buscar")
          }
        />

        <button
          type="button"
          className={`map-filter-button ${filterOpen ? "open" : ""}`}
          onClick={() => setFilterOpen((open) => !open)}
          aria-label="Filtrar incidentes"
        >
          <Icon name="filter" size={25} strokeWidth={2.5} />
        </button>

        {filterOpen && (
          <div className="map-filter-menu">
            {[
              ["todos", "Todos"],
              ["seguridad", "Seguridad"],
              ["vialidad", "Vialidad"],
              ["servicios", "Servicios"],
              ["animales", "Animales"],
            ].map(([value, label]) => (
              <button
                type="button"
                className={filter === value ? "active" : ""}
                key={value}
                onClick={() => {
                  setFilter(
                    value as "todos" | typeof incidentPoints[number]["category"],
                  )
                  setFilterOpen(false)
                }}
              >
                {label}
              </button>
            ))}
          </div>
        )}

        <span className="map-demo-label">Datos de demostración</span>

        <button
          type="button"
          className={`map-mode-button ${is3D ? "active" : ""}`}
          onClick={toggleMapMode}
          aria-label={`Cambiar a vista ${is3D ? "2D" : "3D"}`}
          aria-pressed={is3D}
        >
          {is3D ? "3D" : "2D"}
        </button>

        <button
          type="button"
          className="map-location-button"
          onClick={locateUser}
          aria-label="Usar mi ubicación actual"
        >
          <Icon name="crosshair" size={26} strokeWidth={2.2} />
        </button>

        {loading && <div className="incident-map-state">Cargando mapa...</div>}
        {mapError && (
          <div className="incident-map-state map-fallback">
            <p>{mapError}</p>
            <button
              type="button"
              className="map-retry-button"
              onClick={() => setRetryKey((key) => key + 1)}
            >
              Reintentar
            </button>
            <div className="fallback-marker fallback-one">
              <Sticker name="robbery" />
            </div>
            <div className="fallback-marker fallback-two">
              <Sticker name="paw" />
            </div>
            <div className="fallback-marker fallback-three">
              <Sticker name="cone" />
            </div>
            <div className="fallback-marker fallback-four">
              <Sticker name="car" />
            </div>
          </div>
        )}
      </section>

      <aside
        className={`nearby-sheet ${showAllIncidents ? "show-all" : ""} ${
          nearbyCollapsed ? "collapsed" : ""
        }`}
      >
        <div className="nearby-heading">
          <h2>Incidentes cercanos</h2>
          <div className="nearby-heading-actions">
            {!nearbyCollapsed && (
              <button
                type="button"
                aria-expanded={showAllIncidents}
                onClick={() => {
                  setFilter("todos")
                  setShowAllIncidents((showAll) => !showAll)
                }}
              >
                {showAllIncidents ? "Ver menos" : "Ver todos"}
                <Icon name="chevron" size={18} strokeWidth={2.5} />
              </button>
            )}
            <button
              type="button"
              className="nearby-collapse"
              aria-expanded={!nearbyCollapsed}
              aria-label={
                nearbyCollapsed
                  ? "Mostrar incidentes cercanos"
                  : "Ocultar incidentes cercanos"
              }
              onClick={() => {
                setNearbyCollapsed((collapsed) => !collapsed)
                setShowAllIncidents(false)
              }}
            >
              {nearbyCollapsed && <span>Mostrar</span>}
              <Icon name="chevron" size={19} strokeWidth={2.7} />
            </button>
          </div>
        </div>
        <div className="nearby-list">
          {visibleIncidents.map((incident) => (
            <button
              type="button"
              className="nearby-card"
              key={incident.id}
              onClick={() => onOpenIncident(incident)}
              aria-label={`Ver detalle de ${incident.title}`}
            >
              <span className={`nearby-icon nearby-icon-${incident.tone}`}>
                <Sticker name={incident.sticker} />
              </span>
              <span>
                <strong>{incident.title}</strong>
                <small>{incident.location}</small>
                <small>{incident.relativeTime}</small>
                {incident.source === "demo" && (
                  <small className="demo-report-label">
                    Reporte de demostración
                  </small>
                )}
              </span>
              <Icon name="chevron" size={22} strokeWidth={2.4} />
            </button>
          ))}
        </div>
      </aside>

      <nav
        className="bottom-nav map-bottom-nav"
        aria-label="Navegación principal"
      >
        {navItems.map((item) => (
          <button
            className={`${item.label === "Mapa" ? "active" : ""} ${
              item.label === "Reportar" ? "create-nav" : ""
            }`}
            key={item.label}
            onClick={() => {
              if (item.label === "Inicio") onHome()
              else if (item.label === "Mapa") return
              else if (item.label === "Reportar") onReport()
              else if (item.label === "Actividad") onActivity()
              else onNotice(`${item.label}: sección en preparación`)
            }}
          >
            <span className="nav-icon">
              <Sticker name={item.sticker} />
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

const citizenReports: CitizenReport[] = [
  {
    id: "report_robbery_centro",
    title: "Robo / Asalto",
    location: "Centro, Cuautla",
    date: "17 oct 2026, 15:30",
    status: "En revisión",
    sticker: "robbery",
  },
  {
    id: "report_lighting_jardines",
    title: "Alumbrado público",
    location: "Col. Jardines",
    date: "12 oct 2026, 18:20",
    status: "En atención",
    sticker: "bulb",
  },
  {
    id: "report_animal_febrero",
    title: "Maltrato animal",
    location: "Av. 5 de Febrero",
    date: "8 oct 2026, 10:15",
    status: "Resuelto",
    sticker: "paw",
  },
  {
    id: "report_bache_constitucion",
    title: "Bache en la vía pública",
    location: "C. Constitución",
    date: "5 oct 2026, 09:40",
    status: "Resuelto",
    sticker: "cone",
  },
]

function MyReportsScreen({
  onBack,
  onHome,
  onMap,
  onReport,
  onActivity,
  onOpenReport,
  onNotice,
}: {
  onBack: () => void
  onHome: () => void
  onMap: () => void
  onReport: () => void
  onActivity: () => void
  onOpenReport: (report: typeof citizenReports[number]) => void
  onNotice: (message: string) => void
}) {
  const [filter, setFilter] = useState<"Todos" | ReportStatus>("Todos")
  const visibleReports =
    filter === "Todos"
      ? citizenReports
      : citizenReports.filter((report) => report.status === filter)

  return (
    <div className="my-reports-screen">
      <header className="reports-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Mis reportes</h1>
        <span aria-hidden="true" />
      </header>

      <div className="reports-content">
        <div
          className="reports-filters"
          role="tablist"
          aria-label="Filtrar reportes"
        >
          {(["Todos", "En revisión", "En atención", "Resuelto"] as const).map(
            (option) => (
              <button
                type="button"
                role="tab"
                aria-selected={filter === option}
                className={filter === option ? "active" : ""}
                key={option}
                onClick={() => setFilter(option)}
              >
                {option}
              </button>
            ),
          )}
        </div>

        <div className="reports-list" aria-live="polite">
          {visibleReports.map((report) => (
            <button
              type="button"
              className="report-list-card"
              key={`${report.title}-${report.date}`}
              onClick={() => onOpenReport(report)}
            >
              <span
                className={`report-list-icon report-icon-${report.sticker}`}
              >
                <Sticker name={report.sticker} />
              </span>
              <span className="report-list-copy">
                <strong>{report.title}</strong>
                <small>{report.location}</small>
                <small>{report.date}</small>
              </span>
              <span
                className={`report-status status-${report.status
                  .toLowerCase()
                  .replace(" ", "-")
                  .replace("ó", "o")}`}
              >
                {report.status}
              </span>
              <Icon name="chevron" size={21} strokeWidth={2.4} />
            </button>
          ))}
          {visibleReports.length === 0 && (
            <div className="reports-empty">
              No hay reportes con este estado.
            </div>
          )}
        </div>
      </div>

      <nav
        className="bottom-nav reports-bottom-nav"
        aria-label="Navegación principal"
      >
        {navItems.map((item) => (
          <button
            className={`${item.label === "Inicio" ? "active" : ""} ${
              item.label === "Reportar" ? "create-nav" : ""
            }`}
            key={item.label}
            onClick={() => {
              if (item.label === "Inicio") onHome()
              else if (item.label === "Mapa") onMap()
              else if (item.label === "Reportar") onReport()
              else if (item.label === "Actividad") onActivity()
              else onNotice(`${item.label}: sección en preparación`)
            }}
          >
            <span className="nav-icon">
              <Sticker name={item.sticker} />
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

function ReportLocationPreview({
  position = { lat: CUAUTLA_CENTER[1], lng: CUAUTLA_CENTER[0] },
}: {
  position?: Coordinates
}) {
  const mapElement = useRef<HTMLDivElement>(null)
  const [loading, setLoading] = useState(true)
  const [mapError, setMapError] = useState("")
  const [retryKey, setRetryKey] = useState(0)

  useEffect(() => {
    let disposed = false
    let mapInstance: MapLibreMap | null = null
    let mapMarker: MapLibreMarker | null = null
    setLoading(true)
    setMapError("")

    const initializeMap = async () => {
      try {
        const maplibregl = await loadMapLibre()
        if (disposed || !mapElement.current) return

        mapInstance = new maplibregl.Map({
          container: mapElement.current,
          style: OPENFREEMAP_STYLE,
          center: [position.lng, position.lat],
          zoom: 15,
          pitch: 0,
          interactive: false,
          attributionControl: false,
        })
        addMissingStyleImageFallback(mapInstance)
        addMapAttribution(mapInstance, maplibregl)

        const content = document.createElement("div")
        content.className = "detail-map-pin"
        content.innerHTML = '<img src="/icons/3d/pin.webp" alt="" />'
        mapMarker = new maplibregl.Marker({
          element: content,
          anchor: "bottom",
        })
          .setLngLat([position.lng, position.lat])
          .addTo(mapInstance)

        mapInstance.once("load", () => {
          if (!disposed) setLoading(false)
        })
        mapInstance.on("error", () => {
          if (!disposed && mapInstance && !mapInstance.loaded()) {
            setLoading(false)
            setMapError("No se pudo cargar")
          }
        })
      } catch {
        if (!disposed) {
          setLoading(false)
          setMapError("No se pudo iniciar")
        }
      }
    }

    void initializeMap()

    return () => {
      disposed = true
      mapMarker?.remove()
      mapInstance?.remove()
    }
  }, [position.lat, position.lng, retryKey])

  return (
    <div className="detail-map">
      <div className="detail-map-canvas" ref={mapElement} />
      {loading && <div className="detail-map-state">Cargando...</div>}
      {mapError && (
        <div className="detail-map-fallback">
          <Sticker name="pin" />
          <button type="button" onClick={() => setRetryKey((key) => key + 1)}>
            Reintentar
          </button>
        </div>
      )}
    </div>
  )
}

type TrackingStageState = "complete" | "current" | "pending"

function ReportTrackingScreen({
  report,
  onBack,
  onViewReport,
}: {
  report: CitizenReport
  onBack: () => void
  onViewReport: () => void
}) {
  const currentStage =
    report.status === "Resuelto" ? 4 : report.status === "En atención" ? 3 : 1
  const progress =
    report.status === "Resuelto" ? 100 : currentStage === 3 ? 75 : 40
  const reportDate = report.date.split(",")[0]
  const stageDetails = [
    {
      title: "Recibido",
      time: `${reportDate} · 11:24`,
      description: "Recibimos tu reporte correctamente.",
    },
    {
      title: "En revisión",
      time: `${reportDate} · 12:05`,
      description: "El municipio revisó la información.",
    },
    {
      title: "Asignado",
      time: `${reportDate} · 13:10`,
      description: "Se asignó al área municipal correspondiente.",
    },
    {
      title: "En atención",
      time: `${reportDate} · 15:30`,
      description: "El equipo responsable está trabajando en la zona.",
    },
    {
      title: "Resuelto",
      time:
        report.status === "Resuelto" ? `${reportDate} · 17:45` : "Pendiente",
      description:
        report.status === "Resuelto"
          ? "El reporte fue atendido y cerrado."
          : "Te avisaremos cuando se complete.",
    },
  ]

  const getStageState = (index: number): TrackingStageState => {
    if (index < currentStage || (report.status === "Resuelto" && index === 4))
      return "complete"
    if (index === currentStage) return "current"
    return "pending"
  }

  const progressTitle =
    report.status === "Resuelto"
      ? "Tu reporte fue resuelto"
      : report.status === "En atención"
        ? "Estamos atendiendo tu reporte"
        : "Estamos revisando tu reporte"

  return (
    <div className="tracking-screen">
      <header className="tracking-header">
        <button type="button" onClick={onBack} aria-label="Volver">
          <Icon name="arrow-left" size={30} strokeWidth={2.5} />
        </button>
        <h1>Seguimiento del reporte</h1>
        <span aria-hidden="true" />
      </header>

      <div className="tracking-content">
        <section className="tracking-summary">
          <span className={`tracking-category report-icon-${report.sticker}`}>
            <Sticker name={report.sticker} />
          </span>
          <div>
            <h2>{report.title}</h2>
            <p>Folio: {report.folio ?? "RC-2026-001234"}</p>
            <p>{report.location}</p>
            <p>{reportDate}</p>
          </div>
          <span
            className={`tracking-status status-${report.status
              .toLowerCase()
              .replace(" ", "-")
              .replace("ó", "o")}`}
          >
            {report.status}
          </span>
        </section>

        <section className="tracking-progress-card">
          <TrackingIcon name="progress" />
          <div className="tracking-progress-copy">
            <h2>{progressTitle}</h2>
            <p>Consulta aquí cada actualización.</p>
            <div className="tracking-progress-row">
              <span className="tracking-progress-track">
                <span
                  className={`tracking-progress-fill progress-${progress}`}
                />
              </span>
              <strong>{progress}%</strong>
            </div>
          </div>
        </section>

        <ol className="tracking-timeline" aria-label="Avance del reporte">
          {stageDetails.map((stage, index) => {
            const state = getStageState(index)
            return (
              <li className={`tracking-stage ${state}`} key={stage.title}>
                <span className="tracking-stage-marker">
                  <TrackingIcon
                    name={
                      state === "complete"
                        ? "complete"
                        : state === "current"
                          ? "current"
                          : "pending"
                    }
                  />
                </span>
                <div>
                  <h2>{stage.title}</h2>
                  <time>{stage.time}</time>
                  <p>{stage.description}</p>
                </div>
              </li>
            )
          })}
        </ol>

        <div className="tracking-footer">
          <div>
            <TrackingIcon name="notification" />
            <span>Te notificaremos cuando haya novedades.</span>
          </div>
          <button type="button" onClick={onViewReport}>
            Ver mi reporte
          </button>
        </div>
      </div>
    </div>
  )
}

function ReportDetailScreen({
  report,
  onBack,
  onTrack,
  onNotice,
}: {
  report: CitizenReport
  onBack: () => void
  onTrack: () => void
  onNotice: (message: string) => void
}) {
  const shareReport = async () => {
    const text = `${report.title} · Folio ${report.folio ?? "RC-2025-001234"} · ${report.status}`
    try {
      if (navigator.share) {
        await navigator.share({ title: "Reporte ciudadano", text })
      } else {
        await navigator.clipboard.writeText(text)
        onNotice("Información del reporte copiada")
      }
    } catch {
      onNotice("No fue posible compartir el reporte")
    }
  }

  return (
    <div className="report-detail-screen">
      <header className="detail-header">
        <button
          type="button"
          onClick={onBack}
          aria-label="Volver a la pantalla anterior"
        >
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Detalle del reporte</h1>
        <span aria-hidden="true" />
      </header>

      <div className="detail-content">
        <section className="detail-summary-card">
          <span
            className={`detail-category-icon report-icon-${report.sticker}`}
          >
            <Sticker name={report.sticker} />
          </span>
          <div>
            <h2>{report.title}</h2>
            <p>Folio: {report.folio ?? "RC-2025-001234"}</p>
            <p>{report.date}</p>
          </div>
          <span
            className={`report-status detail-status status-${report.status
              .toLowerCase()
              .replace(" ", "-")
              .replace("ó", "o")}`}
          >
            {report.status}
          </span>
        </section>

        <section className="detail-location-card">
          <div className="detail-location-copy">
            <Sticker name="pin" />
            <span>
              <h2>Ubicación</h2>
              <p>{report.location}</p>
            </span>
          </div>
          <ReportLocationPreview position={report.position} />
        </section>

        <section className="detail-info-card">
          <h2>Descripción</h2>
          <p>
            {report.description ??
              "Persona sospechosa en la esquina, viste una mochila negra y gorra."}
          </p>

          <h2 className="evidence-title">Evidencia</h2>
          {report.evidence?.length ? (
            <div className="detail-gallery">
              {report.evidence.slice(0, 2).map((photo) => (
                <img src={photo.src} alt={photo.alt} key={photo.src} />
              ))}
              {report.evidence.length > 2 && (
                <button
                  type="button"
                  onClick={() =>
                    onNotice(
                      `Mostrando ${report.evidence!.length - 2} evidencias adicionales`,
                    )
                  }
                >
                  <img src={report.evidence[2].src} alt="" />
                  <span>+{report.evidence.length - 2}</span>
                </button>
              )}
            </div>
          ) : (
            <p className="detail-no-evidence">
              No se adjuntó evidencia fotográfica a este reporte.
            </p>
          )}
        </section>

        <div className="detail-actions">
          <button type="button" onClick={shareReport}>
            <Icon name="share" size={27} strokeWidth={2.1} />
            Compartir
          </button>
          <button type="button" onClick={onTrack}>
            <Icon name="refresh" size={28} strokeWidth={2.1} />
            Seguimiento
          </button>
        </div>
      </div>
    </div>
  )
}

type EmergencyContact = {
  id: string
  name: string
  subtitle: string
  sticker: StickerName
  phone?: string
  phoneLabel: string
  services: string[]
  hours: string
  location: string
  featured?: boolean
}

const usefulContacts: EmergencyContact[] = [
  {
    id: "emergencies",
    name: "Emergencias 911",
    subtitle: "Atención inmediata",
    sticker: "contact-phone",
    phone: "911",
    phoneLabel: "911",
    services: [
      "Emergencias médicas",
      "Seguridad pública",
      "Incendios y rescate",
    ],
    hours: "Las 24 horas, todos los días",
    location: "Cobertura nacional y atención en Cuautla",
    featured: true,
  },
  {
    id: "police",
    name: "Policía Municipal",
    subtitle: "Seguridad y auxilio",
    sticker: "contact-police",
    phone: "911",
    phoneLabel: "911 · Canal de emergencias",
    services: ["Auxilio policial", "Situaciones de riesgo", "Hechos en curso"],
    hours: "Atención de emergencias las 24 horas",
    location: "Cuautla, Morelos",
  },
  {
    id: "anonymous",
    name: "Denuncia Anónima",
    subtitle: "Reporte confidencial",
    sticker: "contact-anonymous",
    phone: "089",
    phoneLabel: "089",
    services: [
      "Denuncia confidencial",
      "Información sobre delitos",
      "Orientación anónima",
    ],
    hours: "Las 24 horas, todos los días",
    location: "Atención telefónica nacional",
  },
  {
    id: "civil-protection",
    name: "Protección Civil Morelos",
    subtitle: "Prevención y riesgos",
    sticker: "contact-protection",
    phone: "7771000515",
    phoneLabel: "(777) 100 0515",
    services: [
      "Atención de riesgos",
      "Prevención y orientación",
      "Coordinación ante contingencias",
    ],
    hours: "Atención telefónica permanente",
    location: "Coordinación Estatal de Protección Civil, Morelos",
  },
  {
    id: "women",
    name: "Atención a la Mujer",
    subtitle: "Orientación y acompañamiento",
    sticker: "contact-woman",
    phone: "079",
    phoneLabel: "079 · Línea de las Mujeres",
    services: [
      "Orientación especializada",
      "Atención ante violencia",
      "Canalización a servicios",
    ],
    hours: "Las 24 horas, todos los días",
    location: "Línea nacional de atención para las mujeres",
  },
  {
    id: "citizen",
    name: "Atención Ciudadana",
    subtitle: "Servicios municipales",
    sticker: "contact-citizen",
    phoneLabel: "Número municipal por validar",
    services: [
      "Orientación sobre trámites",
      "Canalización de solicitudes",
      "Información municipal",
    ],
    hours: "Lunes a viernes, horario de oficina",
    location: "Centro, Cuautla, Morelos",
  },
]

function UsefulContactsScreen({
  onBack,
  onHome,
  onMap,
  onReport,
  onActivity,
  onSOS,
  onOpenContact,
  onNotice,
}: {
  onBack: () => void
  onHome: () => void
  onMap: () => void
  onReport: () => void
  onActivity: () => void
  onSOS: () => void
  onOpenContact: (contact: EmergencyContact) => void
  onNotice: (message: string) => void
}) {
  const [searchOpen, setSearchOpen] = useState(false)
  const [query, setQuery] = useState("")
  const visibleContacts = usefulContacts.filter((contact) =>
    contact.name.toLowerCase().includes(query.trim().toLowerCase()),
  )

  return (
    <div className="contacts-screen">
      <header className="contacts-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Emergencias</h1>
        <button
          type="button"
          onClick={() => setSearchOpen((open) => !open)}
          aria-label="Buscar contacto"
        >
          <Icon name="search" size={28} strokeWidth={2.3} />
        </button>
      </header>

      <div className="contacts-content">
        <section className="sos-entry-card">
          <span className="sos-entry-icon">
            <Sticker name="emergency" />
          </span>
          <span className="sos-entry-copy">
            <small>Ayuda urgente</small>
            <strong>Enviar SOS</strong>
            <span>Comparte tu ubicación y solicita apoyo inmediato.</span>
            <button type="button" onClick={onSOS}>
              Iniciar
              <Icon name="arrow-right" size={18} strokeWidth={2.5} />
            </button>
          </span>
        </section>

        <div className="contacts-section-heading">
          <div>
            <h2>Contactos útiles</h2>
            <p>Selecciona una institución para ver sus servicios.</p>
          </div>
        </div>

        {searchOpen && (
          <label className="contacts-search">
            <Icon name="search" size={20} strokeWidth={2.2} />
            <input
              autoFocus
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Buscar contacto..."
            />
          </label>
        )}

        <div className="contacts-list">
          {visibleContacts.map((contact) => (
            <button
              type="button"
              className={`contact-card ${
                contact.featured ? "featured-contact" : ""
              }`}
              key={contact.name}
              onClick={() => onOpenContact(contact)}
            >
              <span className="contact-icon">
                <Sticker name={contact.sticker} />
              </span>
              <span className="contact-copy">
                <strong>{contact.name}</strong>
                <small>{contact.subtitle}</small>
              </span>
              <Icon name="chevron" size={24} strokeWidth={2.6} />
            </button>
          ))}
          {visibleContacts.length === 0 && (
            <div className="contacts-empty">No encontramos ese contacto.</div>
          )}
        </div>
      </div>

      <nav
        className="bottom-nav contacts-bottom-nav"
        aria-label="Navegación principal"
      >
        {navItems.map((item) => (
          <button
            className={`${item.label === "Inicio" ? "active" : ""} ${
              item.label === "Reportar" ? "create-nav" : ""
            }`}
            key={item.label}
            onClick={() => {
              if (item.label === "Inicio") onHome()
              else if (item.label === "Mapa") onMap()
              else if (item.label === "Reportar") onReport()
              else if (item.label === "Actividad") onActivity()
              else onNotice(`${item.label}: sección en preparación`)
            }}
          >
            <span className="nav-icon">
              <Sticker name={item.sticker} />
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

type SharedLocation = {
  lat: number
  lng: number
  label: string
}

function getCurrentLocation(fallback: SharedLocation) {
  return new Promise<SharedLocation>((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("Geolocalización no disponible"))
      return
    }

    navigator.geolocation.getCurrentPosition(
      ({ coords }) =>
        resolve({
          lat: coords.latitude,
          lng: coords.longitude,
          label: "Ubicación actual detectada",
        }),
      () => reject(new Error("No fue posible obtener tu ubicación")),
      { enableHighAccuracy: true, timeout: 9000, maximumAge: 30000 },
    )
  }).catch(() => fallback)
}

function CallConfirmation({
  contact,
  onClose,
}: {
  contact: EmergencyContact
  onClose: () => void
}) {
  const call = () => {
    if (!contact.phone) return
    window.location.href = `tel:${contact.phone}`
  }

  return (
    <div
      className="emergency-modal"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose()
      }}
    >
      <section
        className="call-confirmation"
        role="dialog"
        aria-modal="true"
        aria-labelledby="call-confirmation-title"
      >
        <span className="call-confirmation-icon">
          <Sticker name={contact.sticker} />
        </span>
        <small>Confirmar llamada</small>
        <h2 id="call-confirmation-title">{contact.name}</h2>
        <strong>{contact.phoneLabel}</strong>
        <p>
          Al continuar, se abrirá el marcador de tu dispositivo para realizar la
          llamada.
        </p>
        <div className="call-warning">
          <Sticker name="emergency" />
          <span>
            Cuautla Segura no sustituye al servicio de emergencias 911.
          </span>
        </div>
        <div className="call-confirmation-actions">
          <button type="button" onClick={onClose}>
            Cancelar
          </button>
          <button type="button" onClick={call}>
            <Sticker name="contact-phone" />
            Llamar
          </button>
        </div>
      </section>
    </div>
  )
}

function ContactDetailScreen({
  contact,
  fallbackLocation,
  onBack,
  onNotice,
}: {
  contact: EmergencyContact
  fallbackLocation: SharedLocation
  onBack: () => void
  onNotice: (message: string) => void
}) {
  const [callOpen, setCallOpen] = useState(false)
  const [sharing, setSharing] = useState(false)

  const shareLocation = async () => {
    setSharing(true)
    const location = await getCurrentLocation(fallbackLocation)
    const mapUrl = `https://www.openstreetmap.org/?mlat=${location.lat}&mlon=${location.lng}#map=17/${location.lat}/${location.lng}`
    const shareData = {
      title: "Mi ubicación en Cuautla Segura",
      text: `Comparto mi ubicación con ${contact.name}: ${location.label}`,
      url: mapUrl,
    }

    try {
      if (navigator.share) {
        await navigator.share(shareData)
        onNotice("Ubicación lista para compartir")
      } else {
        await navigator.clipboard.writeText(`${shareData.text} ${mapUrl}`)
        onNotice("Enlace de ubicación copiado")
      }
    } catch (error) {
      if ((error as DOMException).name !== "AbortError") {
        onNotice("No fue posible compartir la ubicación")
      }
    } finally {
      setSharing(false)
    }
  }

  return (
    <div className="contact-detail-screen">
      <header className="contact-detail-header">
        <button
          type="button"
          onClick={onBack}
          aria-label="Volver a emergencias"
        >
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Detalle de contacto</h1>
        <span aria-hidden="true" />
      </header>

      <div className="contact-detail-content">
        <section
          className={`contact-detail-hero ${
            contact.featured ? "featured" : ""
          }`}
        >
          <span className="contact-detail-art">
            <Sticker name={contact.sticker} />
          </span>
          <div>
            <small>Institución de apoyo</small>
            <h2>{contact.name}</h2>
            <p>{contact.subtitle}</p>
          </div>
        </section>

        <div
          className={`contact-availability ${
            contact.phone ? "available" : "informative"
          }`}
        >
          <span aria-hidden="true" />
          <div>
            <small>
              {contact.phone ? "Canal disponible" : "Canal informativo"}
            </small>
            <strong>
              {contact.phone
                ? "Puedes comunicarte desde la aplicación"
                : "Consulta los servicios y la ubicación"}
            </strong>
          </div>
          {contact.phone ? (
            <TrackingIcon name="complete" />
          ) : (
            <Sticker name="shield" />
          )}
        </div>

        <section className="contact-detail-card contact-services-card">
          <div className="contact-detail-card-title">
            <Sticker name="shield" />
            <h2>Servicios disponibles</h2>
          </div>
          <ul>
            {contact.services.map((service) => (
              <li key={service}>
                <TrackingIcon name="complete" />
                <span>{service}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="contact-detail-card contact-data-card">
          <div>
            <span>
              <Sticker name="activity" />
            </span>
            <p>
              <small>Horario</small>
              <strong>{contact.hours}</strong>
            </p>
          </div>
          <div>
            <span>
              <Sticker name="pin" />
            </span>
            <p>
              <small>Ubicación</small>
              <strong>{contact.location}</strong>
            </p>
          </div>
          <div>
            <span>
              <Sticker name="contact-phone" />
            </span>
            <p>
              <small>Número telefónico</small>
              <strong>{contact.phoneLabel}</strong>
            </p>
          </div>
        </section>

        <div className="contact-detail-actions">
          <button
            type="button"
            className="contact-call-action"
            disabled={!contact.phone}
            onClick={() => setCallOpen(true)}
          >
            <Sticker name="contact-phone" />
            {contact.phone ? "Llamar" : "No disponible"}
          </button>
          <button
            type="button"
            className="contact-share-action"
            disabled={sharing}
            onClick={() => void shareLocation()}
          >
            <Sticker name="pin" />
            {sharing ? "Obteniendo..." : "Compartir ubicación"}
          </button>
        </div>

        <div className="contact-detail-disclaimer">
          <Sticker name="shield" />
          <span>Ante peligro inmediato, llama directamente al 911.</span>
        </div>
      </div>

      {callOpen && contact.phone && (
        <CallConfirmation
          contact={contact}
          onClose={() => setCallOpen(false)}
        />
      )}
    </div>
  )
}

type SosStage = "compose" | "countdown" | "success" | "error"

function SosFlowScreen({
  fallbackLocation,
  onBack,
  onFinish,
  onOpenContact,
}: {
  fallbackLocation: SharedLocation
  onBack: () => void
  onFinish: () => void
  onOpenContact: (contact: EmergencyContact) => void
}) {
  const [selectedId, setSelectedId] = useState(usefulContacts[0].id)
  const [location, setLocation] = useState(fallbackLocation)
  const [locationState, setLocationState] =
    useState<"loading" | "ready" | "fallback">("loading")
  const [stage, setStage] = useState<SosStage>("compose")
  const [countdown, setCountdown] = useState(5)
  const selectedContact =
    usefulContacts.find((contact) => contact.id === selectedId) ??
    usefulContacts[0]

  useEffect(() => {
    let active = true
    getCurrentLocation(fallbackLocation).then((nextLocation) => {
      if (!active) return
      setLocation(nextLocation)
      setLocationState(
        nextLocation.label === fallbackLocation.label ? "fallback" : "ready",
      )
    })
    return () => {
      active = false
    }
  }, [fallbackLocation])

  useEffect(() => {
    if (stage !== "countdown") return

    const timer = window.setInterval(() => {
      setCountdown((current) => {
        if (current > 1) return current - 1
        window.clearInterval(timer)
        setStage(navigator.onLine ? "success" : "error")
        return 0
      })
    }, 1000)

    return () => window.clearInterval(timer)
  }, [stage])

  const startCountdown = () => {
    setCountdown(5)
    setStage("countdown")
  }

  return (
    <div className={`sos-flow-screen stage-${stage}`}>
      <header className="sos-flow-header">
        <button
          type="button"
          onClick={stage === "compose" ? onBack : () => setStage("compose")}
          aria-label={
            stage === "compose" ? "Volver a emergencias" : "Cancelar SOS"
          }
        >
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Enviar SOS</h1>
        <span aria-hidden="true" />
      </header>

      {stage === "compose" && (
        <div className="sos-compose">
          <section className="sos-compose-hero">
            <span>
              <Sticker name="emergency" />
            </span>
            <div>
              <small>Solicitud de ayuda</small>
              <h2>¿Quién debe recibir tu SOS?</h2>
              <p>Selecciona una institución y confirma tu ubicación.</p>
            </div>
          </section>

          <ol className="sos-progress" aria-label="Pasos para enviar un SOS">
            <li className="active">
              <span>1</span>
              <strong>Contacto</strong>
            </li>
            <li>
              <span>2</span>
              <strong>Ubicación</strong>
            </li>
            <li>
              <span>3</span>
              <strong>Confirmar</strong>
            </li>
          </ol>

          <section className="sos-section">
            <h2>1. Selecciona un contacto</h2>
            <div className="sos-contact-options">
              {usefulContacts.slice(0, 5).map((contact) => (
                <button
                  type="button"
                  className={selectedId === contact.id ? "selected" : ""}
                  key={contact.id}
                  onClick={() => setSelectedId(contact.id)}
                >
                  <span>
                    <Sticker name={contact.sticker} />
                  </span>
                  <strong>{contact.name}</strong>
                  <i>
                    {selectedId === contact.id && (
                      <Icon name="check" size={13} strokeWidth={3} />
                    )}
                  </i>
                </button>
              ))}
            </div>
          </section>

          <section className="sos-section">
            <h2>2. Ubicación que se compartirá</h2>
            <div className="sos-location-card">
              <span>
                <Sticker name="pin" />
              </span>
              <div>
                <strong>{location.label}</strong>
                <small>
                  {location.lat.toFixed(5)}, {location.lng.toFixed(5)}
                </small>
                <em className={locationState}>
                  {locationState === "loading"
                    ? "Detectando ubicación..."
                    : locationState === "ready"
                      ? "Ubicación actualizada"
                      : "Usando tu zona configurada"}
                </em>
              </div>
              <button
                type="button"
                onClick={() => {
                  setLocationState("loading")
                  void getCurrentLocation(fallbackLocation).then(
                    (nextLocation) => {
                      setLocation(nextLocation)
                      setLocationState(
                        nextLocation.label === fallbackLocation.label
                          ? "fallback"
                          : "ready",
                      )
                    },
                  )
                }}
                aria-label="Actualizar ubicación"
              >
                <Icon name="refresh" size={19} strokeWidth={2.2} />
              </button>
            </div>
          </section>

          <div className="sos-confirmation-card">
            <Sticker name="emergency" />
            <p>
              Enviarás una alerta a <strong>{selectedContact.name}</strong>.
              Tendrás 5 segundos para cancelarla.
            </p>
          </div>

          <button
            type="button"
            className="sos-confirm-button"
            onClick={startCountdown}
          >
            <Sticker name="emergency" />
            Confirmar y activar SOS
          </button>
          <p className="sos-911-note">
            Cuautla Segura no sustituye al 911. Si puedes, realiza también la
            llamada.
          </p>

          <section className="sos-guidance">
            <span>
              <Sticker name="shield" />
            </span>
            <div>
              <strong>Antes de enviar</strong>
              <p>
                Muévete a un lugar seguro si es posible y mantén tu teléfono
                disponible para recibir indicaciones.
              </p>
            </div>
          </section>
        </div>
      )}

      {stage === "countdown" && (
        <div className="sos-countdown-view">
          <span className="sos-pulse">
            <strong>{countdown}</strong>
          </span>
          <small>Enviando SOS a</small>
          <h2>{selectedContact.name}</h2>
          <p>
            Tu ubicación se compartirá automáticamente cuando termine la cuenta
            regresiva.
          </p>
          <div className="sos-countdown-recipient">
            <span>
              <Sticker name={selectedContact.sticker} />
            </span>
            <div>
              <small>Institución seleccionada</small>
              <strong>{selectedContact.name}</strong>
              <em>{selectedContact.phoneLabel}</em>
            </div>
            <TrackingIcon name="complete" />
          </div>
          <div className="sos-countdown-location">
            <Sticker name="pin" />
            <span>
              {location.label}
              <small>
                {location.lat.toFixed(5)}, {location.lng.toFixed(5)}
              </small>
            </span>
          </div>
          <button type="button" onClick={() => setStage("compose")}>
            Cancelar envío
          </button>
          <span className="sos-countdown-help">
            <Sticker name="shield" />
            La alerta todavía puede cancelarse.
          </span>
        </div>
      )}

      {stage === "success" && (
        <div className="sos-result-view success">
          <span className="sos-result-art">
            <TrackingIcon name="complete" />
          </span>
          <small>SOS enviado correctamente</small>
          <h2>Tu solicitud fue confirmada</h2>
          <p>
            Se compartió tu ubicación con {selectedContact.name}. Mantente en un
            lugar seguro y conserva tu teléfono disponible.
          </p>
          <div className="sos-result-summary">
            <span>
              <Sticker name="shield" />
              {selectedContact.name}
            </span>
            <span>
              <Sticker name="pin" />
              {location.label}
            </span>
            <span>
              <Sticker name="activity" />
              Confirmado ahora · Folio SOS-CUA-025
            </span>
          </div>
          <div className="sos-next-steps">
            <span>
              <Sticker name="contact-phone" />
              <small>Mantén tu teléfono disponible</small>
            </span>
            <span>
              <Sticker name="shield" />
              <small>Permanece en un lugar seguro</small>
            </span>
          </div>
          <button type="button" onClick={() => onOpenContact(selectedContact)}>
            Ver contacto y llamar
          </button>
          <button type="button" onClick={onFinish}>
            Volver a emergencias
          </button>
        </div>
      )}

      {stage === "error" && (
        <div className="sos-result-view error">
          <span className="sos-result-art">
            <ActivityIcon name="rejected" />
          </span>
          <small>No se pudo enviar</small>
          <h2>Revisa tu conexión</h2>
          <p>
            La solicitud SOS no fue confirmada. Intenta nuevamente o llama al
            911 si estás en peligro inmediato.
          </p>
          <div className="sos-error-alternative">
            <Sticker name="contact-phone" />
            <div>
              <small>Alternativa inmediata</small>
              <strong>Llama al 911 desde tu dispositivo</strong>
            </div>
          </div>
          <button type="button" onClick={startCountdown}>
            Reintentar envío
          </button>
          <button
            type="button"
            onClick={() => onOpenContact(usefulContacts[0])}
          >
            Llamar al 911
          </button>
        </div>
      )}
    </div>
  )
}

type AlertCategory = "Seguridad" | "Tránsito" | "Servicios"

type AlertImage = {
  src: string
  alt: string
}

const communityAlerts: {
  id: string
  title: string
  description: string
  details: string
  location: string
  recommendations: string[]
  images: readonly AlertImage[]
  time: string
  category: AlertCategory
  sticker: StickerName
}[] = [
  {
    id: "alert_robbery_centro",
    title: "Zona con aumento de robos",
    description: "Se han reportado varios incidentes en la colonia Centro.",
    details:
      "Vecinos de la colonia Centro han reportado un incremento de robos a transeúntes durante las últimas horas.",
    location: "Col. Centro, Cuautla",
    recommendations: [
      "Evita caminar solo por calles poco iluminadas.",
      "Mantén tus pertenencias fuera de la vista.",
      "Llama al 911 si observas una situación de riesgo.",
    ],
    images: evidencePhotos,
    time: "Hace 2 horas",
    category: "Seguridad",
    sticker: "robbery",
  },
  {
    id: "alert_roadwork_febrero",
    title: "Cierre de vialidad",
    description: "Av. 5 de Febrero, por obras.",
    details:
      "La circulación permanecerá parcialmente cerrada por trabajos de mantenimiento en la vialidad.",
    location: "Av. 5 de Febrero, Cuautla",
    recommendations: [
      "Utiliza vías alternas.",
      "Reduce la velocidad al acercarte a la zona.",
      "Respeta las indicaciones del personal vial.",
    ],
    images: [
      {
        src: "https://images.unsplash.com/photo-1689949723756-6867df5085a4?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
        alt: "Calle urbana con vehículos y peatones",
      },
      {
        src: "https://images.unsplash.com/photo-1789322245662-d0d98dde6719?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
        alt: "Calle con circulación vehicular",
      },
    ],
    time: "Hace 4 horas",
    category: "Tránsito",
    sticker: "cone",
  },
  {
    id: "alert_lighting_jardines",
    title: "Mantenimiento de alumbrado",
    description: "Trabajos programados en Col. Jardines.",
    details:
      "La cuadrilla de servicios realizará trabajos preventivos en luminarias y cableado de la colonia.",
    location: "Col. Jardines, Cuautla",
    recommendations: [
      "Toma precauciones durante los cortes temporales.",
      "Evita acercarte al equipo de mantenimiento.",
      "Reporta luminarias que continúen sin servicio.",
    ],
    images: [
      {
        src: "https://images.unsplash.com/photo-1601585088624-0a770da2bf21?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
        alt: "Iluminación urbana durante la noche",
      },
      {
        src: "https://images.unsplash.com/photo-1592846642494-bcf7ea25abb8?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
        alt: "Luces de una ciudad por la noche",
      },
    ],
    time: "Hace 1 día",
    category: "Servicios",
    sticker: "bulb",
  },
  {
    id: "alert_traffic_constituyentes",
    title: "Accidente vehicular",
    description: "Tráfico lento en Av. Constituyentes.",
    details:
      "Se reporta un accidente vehicular con afectación parcial de carriles y tráfico lento en la zona.",
    location: "Av. Constituyentes, Cuautla",
    recommendations: [
      "Conduce a baja velocidad.",
      "Mantén distancia con otros vehículos.",
      "Considera una ruta alterna.",
    ],
    images: [
      {
        src: "https://images.unsplash.com/photo-1759382033088-9726a2eb7688?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
        alt: "Tráfico vehicular intenso",
      },
      {
        src: "https://images.unsplash.com/photo-1699842424656-8e334d7133a9?crop=entropy&cs=tinysrgb&fit=crop&fm=jpg&q=85&w=700",
        alt: "Vehículos circulando en una avenida",
      },
    ],
    time: "Hace 1 día",
    category: "Tránsito",
    sticker: "car",
  },
]

type ActivityKind = "report" | "comment" | "alert"
type ActivityStatus = "Aceptado" | "Rechazado" | "En proceso"

type ActivityEntry = {
  id: string
  day: "Hoy" | "Ayer"
  dateLabel: string
  kind: ActivityKind
  status?: ActivityStatus
  icon?: ActivityIconName
  sticker?: StickerName
  title: string
  subject: string
  location: string
  date: string
  report?: CitizenReport
  alert?: typeof communityAlerts[number]
}

const activityEntries: ActivityEntry[] = [
  {
    id: "road-in-progress",
    day: "Hoy",
    dateLabel: "19 oct 2026",
    kind: "report",
    status: "En proceso",
    sticker: "cone",
    title: "Tu reporte está en proceso",
    subject: "Bache en la vía pública",
    location: "Av. Reforma, Cuautla",
    date: "19 oct 2026, 11:24",
    report: { ...demoIncidentPoints[2], status: "En atención" },
  },
  {
    id: "robbery-accepted",
    day: "Hoy",
    dateLabel: "19 oct 2026",
    kind: "report",
    status: "Aceptado",
    sticker: "robbery",
    title: "Tu reporte fue aceptado",
    subject: "Intento de asalto",
    location: "Centro, Cuautla",
    date: "19 oct 2026, 10:46",
    report: demoIncidentPoints[0],
  },
  {
    id: "lighting-comment",
    day: "Hoy",
    dateLabel: "19 oct 2026",
    kind: "comment",
    icon: "comment",
    title: "Nuevo comentario",
    subject: "En tu reporte de alumbrado público",
    location: "Col. Jardines, Cuautla",
    date: "19 oct 2026, 10:18",
    report: citizenReports[1],
  },
  {
    id: "nearby-alert",
    day: "Hoy",
    dateLabel: "19 oct 2026",
    kind: "alert",
    icon: "alert",
    title: "Alerta cerca de ti",
    subject: "Intento de asalto reportado",
    location: "Col. Centro, Cuautla",
    date: "19 oct 2026, 08:55",
    alert: communityAlerts[0],
  },
  {
    id: "vandalism-rejected",
    day: "Ayer",
    dateLabel: "18 oct 2026",
    kind: "report",
    status: "Rechazado",
    icon: "rejected",
    title: "Tu reporte fue rechazado",
    subject: "Vandalismo en espacio público",
    location: "Col. Emiliano Zapata",
    date: "18 oct 2026, 18:10",
    report: {
      id: "report_vandalism_zapata",
      title: "Vandalismo en espacio público",
      location: "Col. Emiliano Zapata",
      date: "18 oct 2026, 18:10",
      status: "En revisión",
      sticker: "spray",
      folio: "RC-2026-001239",
      description:
        "El reporte fue rechazado porque la ubicación proporcionada no pudo verificarse. Puedes crear uno nuevo con más referencias.",
      evidence: [],
    },
  },
  {
    id: "animal-accepted",
    day: "Ayer",
    dateLabel: "18 oct 2026",
    kind: "report",
    status: "Aceptado",
    icon: "accepted",
    title: "Tu reporte fue aceptado",
    subject: "Maltrato animal",
    location: "Av. 5 de Febrero",
    date: "18 oct 2026, 16:32",
    report: citizenReports[2],
  },
  {
    id: "car-in-progress",
    day: "Ayer",
    dateLabel: "18 oct 2026",
    kind: "report",
    status: "En proceso",
    sticker: "car",
    title: "Atención en camino",
    subject: "Accidente vial",
    location: "Blvd. Jiquilpan, Cuautla",
    date: "18 oct 2026, 14:05",
    report: demoIncidentPoints[3],
  },
]

function ActivityScreen({
  initialUnreadOnly,
  unreadIds,
  onHome,
  onMap,
  onReport,
  onProfile,
  onMarkRead,
  onOpenReport,
  onOpenAlert,
}: {
  initialUnreadOnly: boolean
  unreadIds: ReadonlySet<string>
  onHome: () => void
  onMap: () => void
  onReport: () => void
  onProfile: () => void
  onMarkRead: (id: string) => void
  onOpenReport: (report: CitizenReport) => void
  onOpenAlert: (alert: typeof communityAlerts[number]) => void
}) {
  const [filter, setFilter] =
    useState<"Todo" | "Reportes" | "Comentarios" | "Alertas">("Todo")
  const [searchOpen, setSearchOpen] = useState(false)
  const [query, setQuery] = useState("")
  const [unreadOnly, setUnreadOnly] = useState(initialUnreadOnly)

  const kindByFilter: Record<Exclude<typeof filter, "Todo">, ActivityKind> = {
    Reportes: "report",
    Comentarios: "comment",
    Alertas: "alert",
  }
  const normalizedQuery = query.trim().toLocaleLowerCase("es")
  const visibleEntries = activityEntries.filter((entry) => {
    const matchesFilter =
      filter === "Todo" || entry.kind === kindByFilter[filter]
    const matchesReadState = !unreadOnly || unreadIds.has(entry.id)
    const matchesQuery =
      !normalizedQuery ||
      `${entry.title} ${entry.subject} ${entry.location} ${entry.status ?? ""}`
        .toLocaleLowerCase("es")
        .includes(normalizedQuery)
    return matchesFilter && matchesReadState && matchesQuery
  })

  const openEntry = (entry: ActivityEntry) => {
    onMarkRead(entry.id)
    if (entry.alert) onOpenAlert(entry.alert)
    else if (entry.report) onOpenReport(entry.report)
  }

  return (
    <div className="activity-screen">
      <header className="activity-header">
        <span aria-hidden="true" />
        <h1>Actividad</h1>
        <button
          type="button"
          aria-label={searchOpen ? "Cerrar búsqueda" : "Buscar en actividad"}
          aria-expanded={searchOpen}
          onClick={() => setSearchOpen((open) => !open)}
        >
          <Icon name="search" size={28} strokeWidth={2.4} />
        </button>
      </header>

      <div className="activity-content">
        {searchOpen && (
          <label className="activity-search">
            <Icon name="search" size={20} strokeWidth={2.2} />
            <input
              autoFocus
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Buscar reporte, estado o colonia"
            />
          </label>
        )}

        <div
          className="activity-filters"
          role="tablist"
          aria-label="Filtrar actividad"
        >
          {(["Todo", "Reportes", "Comentarios", "Alertas"] as const).map(
            (option) => (
              <button
                type="button"
                role="tab"
                aria-selected={filter === option}
                className={filter === option ? "active" : ""}
                key={option}
                onClick={() => setFilter(option)}
              >
                {option}
              </button>
            ),
          )}
        </div>

        {unreadOnly && (
          <div className="activity-view-mode" role="status">
            <span>
              Mostrando {unreadIds.size}{" "}
              {unreadIds.size === 1
                ? "actividad no leída"
                : "actividades no leídas"}
            </span>
            <button type="button" onClick={() => setUnreadOnly(false)}>
              Ver todas
            </button>
          </div>
        )}

        <div className="activity-feed" aria-live="polite">
          {(["Hoy", "Ayer"] as const).map((day) => {
            const dayEntries = visibleEntries.filter(
              (entry) => entry.day === day,
            )
            if (!dayEntries.length) return null

            return (
              <section className="activity-day" key={day}>
                <div className="activity-day-heading">
                  <h2>{day}</h2>
                  <time>{dayEntries[0].dateLabel}</time>
                </div>
                <div className="activity-list">
                  {dayEntries.map((entry) => (
                    <button
                      type="button"
                      className={`activity-card ${
                        unreadIds.has(entry.id) ? "unread" : "read"
                      }`}
                      key={entry.id}
                      onClick={() => openEntry(entry)}
                    >
                      {entry.icon ? (
                        <ActivityIcon name={entry.icon} />
                      ) : (
                        <span
                          className={`activity-category-icon report-icon-${entry.sticker}`}
                        >
                          <Sticker name={entry.sticker ?? "more"} />
                        </span>
                      )}
                      <span className="activity-card-copy">
                        <span className="activity-card-title-row">
                          <strong>{entry.title}</strong>
                          <span className="activity-card-badges">
                            {entry.status && (
                              <small
                                className={`activity-status activity-status-${entry.status
                                  .toLowerCase()
                                  .replace(" ", "-")}`}
                              >
                                {entry.status}
                              </small>
                            )}
                            <small
                              className={`activity-read-state ${
                                unreadIds.has(entry.id) ? "unread" : "read"
                              }`}
                            >
                              {unreadIds.has(entry.id) ? "No leída" : "Leída"}
                            </small>
                          </span>
                        </span>
                        <span>{entry.subject}</span>
                        <small>{entry.location}</small>
                        <time>{entry.date}</time>
                      </span>
                      <Icon name="chevron" size={23} strokeWidth={2.6} />
                    </button>
                  ))}
                </div>
              </section>
            )
          })}
          {visibleEntries.length === 0 && (
            <div className="activity-empty">
              {unreadOnly
                ? "No tienes actividades pendientes por leer."
                : "No encontramos actividad con estos criterios."}
            </div>
          )}
        </div>
      </div>

      <nav
        className="bottom-nav activity-bottom-nav"
        aria-label="Navegación principal"
      >
        {navItems.map((item) => (
          <button
            type="button"
            className={`${item.label === "Actividad" ? "active" : ""} ${
              item.label === "Reportar" ? "create-nav" : ""
            }`}
            key={item.label}
            onClick={() => {
              if (item.label === "Inicio") onHome()
              else if (item.label === "Mapa") onMap()
              else if (item.label === "Reportar") onReport()
              else if (item.label === "Perfil") onProfile()
            }}
          >
            <span className="nav-icon alert-nav-icon">
              <Sticker name={item.sticker} />
              {item.label === "Actividad" && unreadIds.size > 0 && (
                <span className="nav-alert-badge">{unreadIds.size}</span>
              )}
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

function CommunityAlertsScreen({
  onBack,
  onNotifications,
  onHome,
  onMap,
  onReport,
  onActivity,
  onOpenAlert,
  onNotice,
}: {
  onBack: () => void
  onNotifications: () => void
  onHome: () => void
  onMap: () => void
  onReport: () => void
  onActivity: () => void
  onOpenAlert: (alert: typeof communityAlerts[number]) => void
  onNotice: (message: string) => void
}) {
  const [filter, setFilter] = useState<"Todas" | AlertCategory>("Todas")
  const visibleAlerts =
    filter === "Todas"
      ? communityAlerts
      : communityAlerts.filter((alert) => alert.category === filter)

  return (
    <div className="community-alerts-screen">
      <header className="alerts-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Alertas comunitarias</h1>
        <button
          type="button"
          onClick={onNotifications}
          aria-label="Configurar notificaciones"
        >
          <Icon name="bell" size={25} strokeWidth={2.1} />
        </button>
      </header>

      <div className="alerts-content">
        <div
          className="alerts-filters"
          role="tablist"
          aria-label="Filtrar alertas"
        >
          {(["Todas", "Seguridad", "Tránsito", "Servicios"] as const).map(
            (option) => (
              <button
                type="button"
                role="tab"
                aria-selected={filter === option}
                className={filter === option ? "active" : ""}
                key={option}
                onClick={() => setFilter(option)}
              >
                {option}
              </button>
            ),
          )}
        </div>

        <div className="alerts-list">
          {visibleAlerts.map((alert) => (
            <button
              type="button"
              className="alert-list-card"
              key={alert.title}
              onClick={() => onOpenAlert(alert)}
            >
              <span className={`alert-list-icon alert-icon-${alert.sticker}`}>
                <Sticker name={alert.sticker} />
              </span>
              <span className="alert-list-copy">
                <strong>{alert.title}</strong>
                <small>{alert.description}</small>
                <time>{alert.time}</time>
              </span>
              <Icon name="chevron" size={22} strokeWidth={2.5} />
            </button>
          ))}
          {visibleAlerts.length === 0 && (
            <div className="alerts-empty">
              No hay alertas en esta categoría.
            </div>
          )}
        </div>
      </div>

      <nav
        className="bottom-nav alerts-bottom-nav"
        aria-label="Navegación principal"
      >
        {navItems.map((item) => (
          <button
            className={item.label === "Reportar" ? "create-nav" : ""}
            key={item.label}
            onClick={() => {
              if (item.label === "Inicio") onHome()
              else if (item.label === "Mapa") onMap()
              else if (item.label === "Reportar") onReport()
              else if (item.label === "Actividad") onActivity()
              else {
                onNotice(`${item.label}: sección en preparación`)
              }
            }}
          >
            <span className="nav-icon alert-nav-icon">
              <Sticker name={item.sticker} />
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

function CommunityAlertDetailScreen({
  alert,
  onBack,
  onReport,
  onNotice,
}: {
  alert: typeof communityAlerts[number]
  onBack: () => void
  onReport: () => void
  onNotice: (message: string) => void
}) {
  const shareAlert = async () => {
    const text = `${alert.title}. ${alert.description} ${alert.location}`
    try {
      if (navigator.share) {
        await navigator.share({ title: "Alerta comunitaria", text })
      } else {
        await navigator.clipboard.writeText(text)
        onNotice("Información de la alerta copiada")
      }
    } catch {
      onNotice("No fue posible compartir la alerta")
    }
  }

  return (
    <div className="community-alert-detail">
      <header className="alert-detail-header">
        <button type="button" onClick={onBack} aria-label="Volver a alertas">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Detalle de la alerta</h1>
        <button
          type="button"
          onClick={shareAlert}
          aria-label="Compartir alerta"
        >
          <Icon name="share" size={24} strokeWidth={2.1} />
        </button>
      </header>

      <div className="alert-detail-content">
        <section className="alert-detail-summary">
          <span className={`alert-detail-icon alert-icon-${alert.sticker}`}>
            <Sticker name={alert.sticker} />
          </span>
          <div>
            <span className="alert-category-badge">{alert.category}</span>
            <h2>{alert.title}</h2>
            <time>{alert.time}</time>
          </div>
        </section>

        <section className="alert-detail-location">
          <div>
            <Sticker name="pin" />
            <span>
              <h2>Ubicación</h2>
              <p>{alert.location}</p>
            </span>
          </div>
          <ReportLocationPreview />
        </section>

        <section className="alert-detail-description">
          <h2>¿Qué está ocurriendo?</h2>
          <p>{alert.details}</p>
        </section>

        <section className="alert-detail-evidence">
          <h2>Evidencia</h2>
          <div className="alert-detail-gallery">
            <img src={alert.images[0].src} alt={alert.images[0].alt} />
            <img src={alert.images[1].src} alt={alert.images[1].alt} />
            <button
              type="button"
              onClick={() => onNotice("Mostrando 2 imágenes adicionales")}
            >
              <img src={alert.images[0].src} alt="" />
              <span>+2</span>
            </button>
          </div>
        </section>

        <section className="alert-recommendations">
          <h2>Recomendaciones</h2>
          <ul>
            {alert.recommendations.map((recommendation) => (
              <li key={recommendation}>
                <span>
                  <Icon name="check" size={15} strokeWidth={2.7} />
                </span>
                {recommendation}
              </li>
            ))}
          </ul>
        </section>

        <div className="alert-detail-actions">
          <button
            type="button"
            className="alert-share-button"
            onClick={shareAlert}
          >
            <Icon name="share" size={23} strokeWidth={2.1} />
            Compartir
          </button>
          <button
            type="button"
            className="alert-report-button"
            onClick={onReport}
          >
            <Icon name="megaphone" size={23} strokeWidth={2.1} />
            Reportar incidente
          </button>
        </div>
      </div>
    </div>
  )
}

type ProfileMenuIconName = "reports" | "notifications" | "location" | "privacy" | "help" | "logout"

type UserProfile = {
  name: string
  email: string
  phone: string
  avatarUrl?: string
}

type UserNotificationType = "report_update" | "community_alert" | "nearby_incident" | "emergency"
type UserNotificationPriority = "critical" | "important" | "informational"

type UserNotification = {
  id: string
  type: UserNotificationType
  priority: UserNotificationPriority
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
  actionedAt?: string
  archivedAt?: string
  groupedCount?: number
  groupedEventIds?: string[]
  latestUpdatedAt?: string
}

const notificationApiUrl = `https://${projectId}.supabase.co/functions/v1/server/make-server-66389b89`

class NotificationApiError extends Error {
  constructor(public status: number) {
    super(`Notification API error: ${status}`)
  }
}

async function notificationApi<T>(
  path: string,
  init?: RequestInit,
): Promise<T> {
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (!session) throw new Error("Authentication required")
  const response = await fetch(`${notificationApiUrl}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${session.access_token}`,
      "Content-Type": "application/json",
      ...init?.headers,
    },
  })
  if (!response.ok) throw new NotificationApiError(response.status)
  return response.json() as Promise<T>
}

type RegistrationError = {
  code?: string
  message: string
}

function getRegistrationErrorMessage(error: RegistrationError) {
  const message = error.message.toLocaleLowerCase("en")
  if (
    error.code === "user_already_exists" ||
    error.code === "email_exists" ||
    message.includes("already registered")
  )
    return "Este correo ya está registrado. Intenta iniciar sesión."
  if (error.code === "weak_password" || message.includes("password"))
    return "La contraseña no cumple los requisitos de seguridad."
  if (
    error.code === "over_email_send_rate_limit" ||
    message.includes("rate limit")
  )
    return "Se enviaron demasiados correos. Espera unos minutos e inténtalo de nuevo."
  if (
    error.code === "email_address_invalid" ||
    message.includes("invalid email")
  )
    return "Ingresa un correo electrónico válido."
  if (error.code === "signup_disabled")
    return "El registro está temporalmente deshabilitado."
  return `No fue posible crear la cuenta: ${error.message}`
}

const fallbackNotifications: UserNotification[] = []

const notificationMeta: Record<UserNotificationType, {
  label: string
  sticker: StickerName
  tone: string
}> = {
  report_update: {
    label: "Reporte",
    sticker: "reports",
    tone: "blue",
  },
  community_alert: {
    label: "Comunidad",
    sticker: "users",
    tone: "green",
  },
  nearby_incident: {
    label: "Cerca de ti",
    sticker: "pin",
    tone: "sky",
  },
  emergency: {
    label: "Emergencia",
    sticker: "emergency",
    tone: "red",
  },
}

const notificationPriorityLabel: Record<UserNotificationPriority, string> = {
  critical: "Crítica",
  important: "Importante",
  informational: "Informativa",
}

function formatNotificationTime(createdAt: string, now = new Date()) {
  const created = new Date(createdAt)
  const difference = Math.max(0, now.getTime() - created.getTime())
  const minutes = Math.floor(difference / 60_000)
  if (minutes < 1) return "Ahora"
  if (minutes < 60) return `Hace ${minutes} min`
  const hours = Math.floor(minutes / 60)
  if (hours < 24 && created.getDate() === now.getDate())
    return `Hace ${hours} h`

  const yesterday = new Date(now)
  yesterday.setDate(now.getDate() - 1)
  if (created.toDateString() === yesterday.toDateString()) return "Ayer"
  return new Intl.DateTimeFormat("es-MX", {
    day: "numeric",
    month: "short",
  })
    .format(created)
    .replace(".", "")
}

function notificationDayGroup(createdAt: string, now = new Date()) {
  const created = new Date(createdAt)
  if (created.toDateString() === now.toDateString()) return "Hoy"
  const yesterday = new Date(now)
  yesterday.setDate(now.getDate() - 1)
  return created.toDateString() === yesterday.toDateString()
    ? "Ayer"
    : "Anteriores"
}

function notificationEventIds(item: UserNotification) {
  return item.groupedEventIds?.length ? item.groupedEventIds : [item.id]
}

function notificationStateLabel(item: UserNotification) {
  if (item.actionedAt) return "Atendida"
  if (item.readAt) return "Leída"
  if (item.seenAt) return "Vista"
  if (item.deliveredAt) return "Entregada"
  return "Pendiente"
}

function NotificationsInboxScreen({
  notifications,
  syncing,
  syncError,
  pendingOperations,
  onBack,
  onSettings,
  onMarkAll,
  onOpen,
  onRefresh,
  onRetry,
  onToggleRead,
  onArchive,
  onDelete,
}: {
  notifications: UserNotification[]
  syncing: boolean
  syncError: string
  pendingOperations: number
  onBack: () => void
  onSettings: () => void
  onMarkAll: () => void
  onOpen: (notification: UserNotification) => void
  onRefresh: () => void
  onRetry: () => void
  onToggleRead: (notification: UserNotification) => void
  onArchive: (notification: UserNotification) => void
  onDelete: (notification: UserNotification) => void
}) {
  const [view, setView] = useState<"all" | "unread">("all")
  const unreadCount = notifications.filter((item) => !item.readAt).length
  const visibleNotifications =
    view === "unread"
      ? notifications.filter((item) => !item.readAt)
      : notifications
  const groupedByDay = (["Hoy", "Ayer", "Anteriores"] as const)
    .map((label) => ({
      label,
      notifications: visibleNotifications.filter(
        (item) => notificationDayGroup(item.createdAt) === label,
      ),
    }))
    .filter((group) => group.notifications.length)

  return (
    <div className="notification-inbox-screen">
      <header className="notification-inbox-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <span>
          <small>Mensajes para ti</small>
          <h1>Notificaciones</h1>
        </span>
        <button
          type="button"
          onClick={onSettings}
          aria-label="Configurar notificaciones"
        >
          <Icon name="settings" size={25} strokeWidth={2.1} />
        </button>
      </header>

      <div className="notification-inbox-content">
        <div className="notification-inbox-toolbar">
          <div role="tablist" aria-label="Filtrar notificaciones">
            <button
              type="button"
              role="tab"
              aria-selected={view === "all"}
              className={view === "all" ? "active" : ""}
              onClick={() => setView("all")}
            >
              Todas
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={view === "unread"}
              className={view === "unread" ? "active" : ""}
              onClick={() => setView("unread")}
            >
              No leídas{" "}
              {unreadCount > 0 && (
                <span>{unreadCount > 9 ? "9+" : unreadCount}</span>
              )}
            </button>
          </div>
          <span className="notification-toolbar-actions">
            <button
              type="button"
              className="notification-manual-refresh"
              onClick={onRefresh}
              disabled={syncing}
              aria-label="Actualizar notificaciones"
            >
              <Icon name="refresh" size={17} strokeWidth={2.4} />
            </button>
            <button
              type="button"
              onClick={onMarkAll}
              disabled={unreadCount === 0}
            >
              Marcar todas como leídas
            </button>
          </span>
        </div>

        {(syncing || pendingOperations > 0) && (
          <div className="notification-sync-status" role="status">
            <Icon name="refresh" size={15} strokeWidth={2.3} />
            {syncing
              ? "Sincronizando"
              : `${pendingOperations} ${
                  pendingOperations === 1
                    ? "cambio pendiente"
                    : "cambios pendientes"
                }`}
          </div>
        )}

        {syncError && (
          <div className="notification-sync-error" role="alert">
            <span>
              <Icon name="alert" size={18} strokeWidth={2.2} />
              <span>{syncError}</span>
            </span>
            <button type="button" onClick={onRetry}>
              Reintentar
            </button>
          </div>
        )}

        <div className="notification-inbox-list" aria-live="polite">
          {groupedByDay.map((group) => (
            <section className="notification-day-group" key={group.label}>
              <h2>{group.label}</h2>
              <div>
                {group.notifications.map((item) => {
                  const meta = notificationMeta[item.type]
                  return (
                    <article
                      className={`notification-inbox-card ${
                        item.readAt ? "read" : "unread"
                      } priority-${item.priority}`}
                      key={item.id}
                    >
                      <button
                        type="button"
                        className="notification-card-main"
                        onClick={() => onOpen(item)}
                      >
                        <span
                          className={`notification-inbox-icon notification-icon-${meta.tone}`}
                        >
                          <Sticker name={meta.sticker} />
                          {!item.readAt && <i aria-label="No leída" />}
                        </span>
                        <span className="notification-inbox-copy">
                          <span>
                            <small>{meta.label}</small>
                            <time>
                              {formatNotificationTime(item.createdAt)}
                            </time>
                          </span>
                          <span className="notification-card-badges">
                            <em
                              className={`notification-priority priority-${item.priority}`}
                            >
                              {notificationPriorityLabel[item.priority]}
                            </em>
                            <em className="notification-lifecycle">
                              {notificationStateLabel(item)}
                            </em>
                          </span>
                          <strong>{item.title}</strong>
                          <span>{item.message}</span>
                          {(item.groupedCount ?? 0) > 1 && (
                            <em>
                              {item.groupedCount} eventos · actualizado{" "}
                              {formatNotificationTime(
                                item.latestUpdatedAt ?? item.createdAt,
                              )}
                            </em>
                          )}
                        </span>
                        <Icon name="chevron" size={21} strokeWidth={2.5} />
                      </button>
                      <div className="notification-card-actions">
                        <button
                          type="button"
                          onClick={() => onToggleRead(item)}
                        >
                          <Icon
                            name={item.readAt ? "mail" : "check"}
                            size={15}
                            strokeWidth={2.3}
                          />
                          {item.readAt ? "No leída" : "Leída"}
                        </button>
                        <button type="button" onClick={() => onArchive(item)}>
                          <Icon name="clipboard" size={15} strokeWidth={2.2} />
                          Archivar
                        </button>
                        <button type="button" onClick={() => onDelete(item)}>
                          <Icon name="close" size={15} strokeWidth={2.3} />
                          Eliminar
                        </button>
                      </div>
                    </article>
                  )
                })}
              </div>
            </section>
          ))}
        </div>

        {visibleNotifications.length === 0 && (
          <div className="notification-inbox-empty">
            <span>
              <Sticker name={syncError ? "emergency" : "bell"} />
            </span>
            <h2>
              {syncError
                ? "No pudimos cargar tus notificaciones"
                : view === "unread"
                  ? "Estás al día"
                  : "Aún no tienes notificaciones"}
            </h2>
            <p>
              {syncError
                ? syncError
                : view === "unread"
                  ? "No tienes mensajes pendientes por leer."
                  : "Aquí aparecerán los mensajes y avisos dirigidos a ti."}
            </p>
            {syncError ? (
              <button type="button" onClick={onRetry}>
                Reintentar
              </button>
            ) : view === "unread" ? (
              <button type="button" onClick={() => setView("all")}>
                Ver todas
              </button>
            ) : null}
          </div>
        )}
      </div>
    </div>
  )
}

type NotificationPreferences = {
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
  pushPermission: "default" | "granted" | "denied" | "unsupported"
  timeZone: string
}

const defaultClientNotificationPreferences: NotificationPreferences = {
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
  pushPermission:
    typeof Notification === "undefined"
      ? "unsupported"
      : Notification.permission,
  timeZone:
    Intl.DateTimeFormat().resolvedOptions().timeZone || "America/Mexico_City",
}

type NotificationToggleKey = "reportUpdates" | "communityAlerts" | "nearbyIncidents" | "emergencies" | "sound" | "vibration" | "quietHoursEnabled" | "emergencyOverride"

type PendingNotificationOperation = {
  id: string
  kind: "read" | "unread" | "read_all" | "seen" | "archive" | "delete" | "action" | "preferences"
  payload: {
    id?: string
    ids?: string[]
    all?: boolean
    unread?: boolean
    readAt?: string
    seenAt?: string
    operationAt?: string
  } | NotificationPreferences
  attempts: number
  nextAttemptAt: number
  createdAt: string
}

const NOTIFICATION_CACHE_KEY = "cuautla-segura:notifications"
const NOTIFICATION_PREFERENCES_KEY = "cuautla-segura:notification-preferences"
const NOTIFICATION_QUEUE_KEY = "cuautla-segura:notification-queue"
const legacyNotificationDestinationIds = {
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

function readLocalValue<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback
  try {
    const value = window.localStorage.getItem(key)
    return value ? JSON.parse(value) as T : fallback
  } catch {
    return fallback
  }
}

function writeLocalValue(key: string, value: unknown) {
  try {
    window.localStorage.setItem(key, JSON.stringify(value))
  } catch {
    // The in-memory state remains usable when storage is unavailable.
  }
}

function loadCachedNotifications() {
  const cached = readLocalValue<Array<Omit<UserNotification, "destination"> & {
    priority?: UserNotificationPriority
    timeLabel?: string
    destination: UserNotification["destination"] | {
      kind: "report" | "alert"
      index: number
    }
  }>>(NOTIFICATION_CACHE_KEY, fallbackNotifications)
  return cached.map((notification) => {
    const {
      timeLabel: _legacyTimeLabel,
      priority: storedPriority,
      ...withoutLegacyTime
    } = notification
    const priority =
      storedPriority ??
      (notification.type === "emergency"
        ? "critical"
        : notification.type === "report_update"
          ? "important"
          : "informational")
    if ("entityId" in notification.destination)
      return {
        ...withoutLegacyTime,
        priority,
      } as UserNotification
    const entityId =
      legacyNotificationDestinationIds[notification.destination.kind][
        notification.destination.index
      ]
    return {
      ...withoutLegacyTime,
      priority,
      destination: {
        kind: notification.destination.kind,
        entityId:
          entityId ??
          (notification.destination.kind === "report"
            ? "report_robbery_centro"
            : "alert_robbery_centro"),
      },
    }
  })
}

function createPendingOperation(
  kind: PendingNotificationOperation["kind"],
  payload: PendingNotificationOperation["payload"],
): PendingNotificationOperation {
  return {
    id:
      typeof crypto.randomUUID === "function"
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    kind,
    payload,
    attempts: 0,
    nextAttemptAt: Date.now(),
    createdAt: new Date().toISOString(),
  }
}

function formatQuietTime(value: string) {
  const [hour, minute] = value.split(":").map(Number)
  return new Intl.DateTimeFormat("es-MX", {
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(2026, 0, 1, hour, minute))
}

type QuietPeriod = "AM" | "PM"

function splitQuietTime(value: string) {
  const [hour24, minute] = value.split(":").map(Number)
  return {
    hour: hour24 % 12 || 12,
    minute,
    period: (hour24 >= 12 ? "PM" : "AM") as QuietPeriod,
  }
}

function composeQuietTime(hour: number, minute: number, period: QuietPeriod) {
  const hour24 = (hour % 12) + (period === "PM" ? 12 : 0)
  return `${String(hour24).padStart(2, "0")}:${String(minute).padStart(2, "0")}`
}

function NotificationPreferencesScreen({
  preferences,
  onBack,
  onSave,
  onRequestPush,
}: {
  preferences: NotificationPreferences
  onBack: () => void
  onSave: (preferences: NotificationPreferences) => void
  onRequestPush: () => Promise<NotificationPreferences["pushPermission"]>
}) {
  const [draft, setDraft] = useState(preferences)
  const [scheduleOpen, setScheduleOpen] = useState(false)
  const [quietStart, setQuietStart] = useState(preferences.quietStart)
  const [quietEnd, setQuietEnd] = useState(preferences.quietEnd)
  const scheduleTriggerRef = useRef<HTMLButtonElement>(null)
  const scheduleDialogRef = useRef<HTMLElement>(null)
  const scheduleInitialFocusRef = useRef<HTMLSelectElement>(null)
  const startTime = splitQuietTime(quietStart)
  const endTime = splitQuietTime(quietEnd)
  const minuteOptions = Array.from({ length: 12 }, (_, index) => index * 5)

  const togglePreference = (key: NotificationToggleKey) => {
    setDraft((current) => ({ ...current, [key]: !current[key] }))
  }

  const notificationRows: {
    key: NotificationToggleKey
    title: string
    description: string
    tone: string
    icon: ReactNode
  }[] = [
    {
      key: "reportUpdates",
      title: "Actualizaciones de reportes",
      description: "Estado de tus reportes.",
      tone: "blue",
      icon: <Sticker name="bell" />,
    },
    {
      key: "communityAlerts",
      title: "Alertas comunitarias",
      description: "Avisos de tu zona.",
      tone: "green",
      icon: <Sticker name="users" />,
    },
    {
      key: "nearbyIncidents",
      title: "Incidentes cercanos",
      description: "En un radio de tu ubicación.",
      tone: "sky",
      icon: <Sticker name="car" />,
    },
    {
      key: "emergencies",
      title: "Emergencias",
      description: "Situaciones de riesgo.",
      tone: "red",
      icon: <Sticker name="emergency" />,
    },
  ]

  const saveSchedule = () => {
    setDraft((current) => ({
      ...current,
      quietStart,
      quietEnd,
    }))
    setScheduleOpen(false)
  }

  useEffect(() => {
    if (!scheduleOpen) return
    const dialog = scheduleDialogRef.current
    const focusable = () =>
      Array.from(
        dialog?.querySelectorAll<HTMLElement>(
          'button:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])',
        ) ?? [],
      )
    window.requestAnimationFrame(() => scheduleInitialFocusRef.current?.focus())

    const handleDialogKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault()
        setScheduleOpen(false)
        return
      }
      if (event.key !== "Tab") return
      const elements = focusable()
      if (!elements.length) return
      const first = elements[0]
      const last = elements[elements.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }
    document.addEventListener("keydown", handleDialogKey)
    return () => {
      document.removeEventListener("keydown", handleDialogKey)
      scheduleTriggerRef.current?.focus()
    }
  }, [scheduleOpen])

  return (
    <div className="notifications-screen">
      <div
        className="notifications-main"
        aria-hidden={scheduleOpen || undefined}
        inert={scheduleOpen || undefined}
      >
        <header className="notifications-header">
          <button type="button" onClick={onBack} aria-label="Volver">
            <Icon name="arrow-left" size={29} strokeWidth={2.4} />
          </button>
          <h1>Preferencias</h1>
          <span aria-hidden="true" />
        </header>

        <div className="notifications-content">
          <p className="notifications-subtitle">
            Elige qué avisos quieres recibir.
          </p>

          <section className="notifications-card">
            {notificationRows.map((row) => (
              <div className="notification-preference-row" key={row.key}>
                <span
                  className={`notification-preference-icon notification-icon-${row.tone}`}
                >
                  {row.icon}
                </span>
                <span className="notification-preference-copy">
                  <strong>{row.title}</strong>
                  <small>{row.description}</small>
                </span>
                <button
                  type="button"
                  className={`notification-switch ${
                    draft[row.key] ? "active" : ""
                  }`}
                  role="switch"
                  aria-checked={draft[row.key]}
                  aria-label={`${
                    draft[row.key] ? "Desactivar" : "Activar"
                  } ${row.title.toLocaleLowerCase("es")}`}
                  onClick={() => togglePreference(row.key)}
                >
                  <span />
                </button>
              </div>
            ))}
          </section>

          <section className="notifications-card notifications-behavior-card">
            <div className="notification-preference-row">
              <span className="notification-preference-icon notification-icon-purple">
                <img
                  className="notification-sound-asset"
                  src="/icons/3d/notification-sound.png"
                  alt=""
                />
              </span>
              <span className="notification-preference-copy">
                <strong>Sonido</strong>
                <small>Reproducir un tono al recibir avisos.</small>
              </span>
              <button
                type="button"
                className={`notification-switch ${draft.sound ? "active" : ""}`}
                role="switch"
                aria-checked={draft.sound}
                aria-label="Activar o desactivar sonido"
                onClick={() => togglePreference("sound")}
              >
                <span />
              </button>
            </div>

            <div className="notification-preference-row">
              <span className="notification-preference-icon notification-icon-sky">
                <Icon name="phone" size={28} strokeWidth={2.1} />
              </span>
              <span className="notification-preference-copy">
                <strong>Vibración</strong>
                <small>Vibrar si el dispositivo lo permite.</small>
              </span>
              <button
                type="button"
                className={`notification-switch ${
                  draft.vibration ? "active" : ""
                }`}
                role="switch"
                aria-checked={draft.vibration}
                aria-label="Activar o desactivar vibración"
                onClick={() => togglePreference("vibration")}
              >
                <span />
              </button>
            </div>

            <div className="notification-preference-row">
              <span className="notification-preference-icon notification-icon-moon">
                <img
                  className="notification-moon-asset"
                  src="/icons/3d/quiet-hours.png"
                  alt=""
                />
              </span>
              <span className="notification-preference-copy">
                <strong>Horarios de silencio</strong>
                <small>
                  {draft.quietHoursEnabled
                    ? `De ${formatQuietTime(draft.quietStart)} a ${formatQuietTime(
                        draft.quietEnd,
                      )}`
                    : "Desactivado"}
                </small>
              </span>
              <button
                type="button"
                className={`notification-switch ${
                  draft.quietHoursEnabled ? "active" : ""
                }`}
                role="switch"
                aria-checked={draft.quietHoursEnabled}
                aria-label="Activar o desactivar horarios de silencio"
                onClick={() => togglePreference("quietHoursEnabled")}
              >
                <span />
              </button>
            </div>

            {draft.quietHoursEnabled && (
              <button
                type="button"
                ref={scheduleTriggerRef}
                className="notification-schedule-row compact"
                onClick={() => {
                  setQuietStart(draft.quietStart)
                  setQuietEnd(draft.quietEnd)
                  setScheduleOpen(true)
                }}
                aria-haspopup="dialog"
                aria-expanded={scheduleOpen}
              >
                <span className="notification-preference-copy">
                  <strong>Ajustar horario</strong>
                  <small>
                    De {formatQuietTime(draft.quietStart)} a{" "}
                    {formatQuietTime(draft.quietEnd)}
                  </small>
                  <em>Zona horaria: {draft.timeZone}</em>
                </span>
                <Icon name="chevron" size={24} strokeWidth={2.7} />
              </button>
            )}
          </section>

          <section className="notifications-card notifications-behavior-card">
            <div className="notification-preference-row">
              <span className="notification-preference-icon notification-icon-red">
                <Sticker name="emergency" />
              </span>
              <span className="notification-preference-copy">
                <strong>Emergencias durante el silencio</strong>
                <small>
                  {draft.emergencies
                    ? "Permite sonido y vibración durante el horario de silencio."
                    : "Activa primero la categoría Emergencias."}
                </small>
              </span>
              <button
                type="button"
                className={`notification-switch ${
                  draft.emergencyOverride ? "active" : ""
                }`}
                role="switch"
                aria-checked={draft.emergencyOverride}
                aria-label="Permitir emergencias durante el horario de silencio"
                disabled={!draft.emergencies}
                onClick={() => togglePreference("emergencyOverride")}
              >
                <span />
              </button>
            </div>

            <div className="notification-permission-row">
              <span>
                <strong>Notificaciones del dispositivo</strong>
                <small>
                  {draft.pushPermission === "granted"
                    ? "Permiso concedido"
                    : draft.pushPermission === "denied"
                      ? "Permiso bloqueado en el navegador"
                      : draft.pushPermission === "unsupported"
                        ? "No disponible en este dispositivo"
                        : "Permiso pendiente"}
                </small>
              </span>
              {draft.pushPermission === "default" && (
                <button
                  type="button"
                  onClick={async () => {
                    const pushPermission = await onRequestPush()
                    setDraft((current) => ({ ...current, pushPermission }))
                  }}
                >
                  Activar
                </button>
              )}
            </div>
          </section>

          <button
            type="button"
            className="notifications-save"
            onClick={() => onSave(draft)}
          >
            Guardar preferencias
          </button>
        </div>
      </div>

      {scheduleOpen && (
        <div
          className="notifications-schedule-modal"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) setScheduleOpen(false)
          }}
        >
          <section
            ref={scheduleDialogRef}
            className="notifications-schedule-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="quiet-hours-title"
          >
            <div className="notifications-schedule-heading">
              <span>
                <img src="/icons/3d/quiet-hours.png" alt="" />
              </span>
              <div>
                <small>Notificaciones sin sonido</small>
                <h2 id="quiet-hours-title">Horarios de silencio</h2>
              </div>
              <button
                type="button"
                onClick={() => setScheduleOpen(false)}
                aria-label="Cerrar horarios de silencio"
              >
                <Icon name="close" size={20} strokeWidth={2.3} />
              </button>
            </div>

            <div className="notifications-time-fields">
              <section className="notification-time-control">
                <strong>Desde</strong>
                <div className="notification-time-selectors">
                  <label>
                    <span>Hora</span>
                    <select
                      ref={scheduleInitialFocusRef}
                      value={startTime.hour}
                      onChange={(event) =>
                        setQuietStart(
                          composeQuietTime(
                            Number(event.target.value),
                            startTime.minute,
                            startTime.period,
                          ),
                        )
                      }
                    >
                      {Array.from({ length: 12 }, (_, index) => index + 1).map(
                        (hour) => (
                          <option key={hour} value={hour}>
                            {hour}
                          </option>
                        ),
                      )}
                    </select>
                  </label>
                  <label>
                    <span>Minutos</span>
                    <select
                      value={startTime.minute}
                      onChange={(event) =>
                        setQuietStart(
                          composeQuietTime(
                            startTime.hour,
                            Number(event.target.value),
                            startTime.period,
                          ),
                        )
                      }
                    >
                      {minuteOptions.map((minute) => (
                        <option key={minute} value={minute}>
                          {String(minute).padStart(2, "0")}
                        </option>
                      ))}
                    </select>
                  </label>
                  <div className="notification-period-switch">
                    {(["AM", "PM"] as const).map((period) => (
                      <button
                        type="button"
                        className={startTime.period === period ? "active" : ""}
                        aria-pressed={startTime.period === period}
                        key={period}
                        onClick={() =>
                          setQuietStart(
                            composeQuietTime(
                              startTime.hour,
                              startTime.minute,
                              period,
                            ),
                          )
                        }
                      >
                        {period}
                      </button>
                    ))}
                  </div>
                </div>
              </section>

              <section className="notification-time-control">
                <strong>Hasta</strong>
                <div className="notification-time-selectors">
                  <label>
                    <span>Hora</span>
                    <select
                      value={endTime.hour}
                      onChange={(event) =>
                        setQuietEnd(
                          composeQuietTime(
                            Number(event.target.value),
                            endTime.minute,
                            endTime.period,
                          ),
                        )
                      }
                    >
                      {Array.from({ length: 12 }, (_, index) => index + 1).map(
                        (hour) => (
                          <option key={hour} value={hour}>
                            {hour}
                          </option>
                        ),
                      )}
                    </select>
                  </label>
                  <label>
                    <span>Minutos</span>
                    <select
                      value={endTime.minute}
                      onChange={(event) =>
                        setQuietEnd(
                          composeQuietTime(
                            endTime.hour,
                            Number(event.target.value),
                            endTime.period,
                          ),
                        )
                      }
                    >
                      {minuteOptions.map((minute) => (
                        <option key={minute} value={minute}>
                          {String(minute).padStart(2, "0")}
                        </option>
                      ))}
                    </select>
                  </label>
                  <div className="notification-period-switch">
                    {(["AM", "PM"] as const).map((period) => (
                      <button
                        type="button"
                        className={endTime.period === period ? "active" : ""}
                        aria-pressed={endTime.period === period}
                        key={period}
                        onClick={() =>
                          setQuietEnd(
                            composeQuietTime(
                              endTime.hour,
                              endTime.minute,
                              period,
                            ),
                          )
                        }
                      >
                        {period}
                      </button>
                    ))}
                  </div>
                </div>
              </section>
            </div>

            <div className="notifications-schedule-actions">
              <button type="button" onClick={() => setScheduleOpen(false)}>
                Cancelar
              </button>
              <button type="button" onClick={saveSchedule}>
                Guardar horario
              </button>
            </div>
          </section>
        </div>
      )}
    </div>
  )
}

function ProfileMenuIcon({ name }: { name: ProfileMenuIconName }) {
  return (
    <span
      className={`profile-row-icon profile-menu-icon profile-menu-icon-${name}`}
      aria-hidden="true"
    />
  )
}

function ProfileScreen({
  profile,
  onBack,
  onEditProfile,
  onNotifications,
  onPrivacy,
  onHelp,
  onHome,
  onMap,
  onReport,
  onReports,
  onActivity,
  onLogout,
  onNotice,
}: {
  profile: UserProfile
  onBack: () => void
  onEditProfile: () => void
  onNotifications: () => void
  onPrivacy: () => void
  onHelp: () => void
  onHome: () => void
  onMap: () => void
  onReport: () => void
  onReports: () => void
  onActivity: () => void
  onLogout: () => void
  onNotice: (message: string) => void
}) {
  return (
    <div className="profile-screen">
      <header className="profile-header">
        <button type="button" onClick={onBack} aria-label="Volver al inicio">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Mi perfil</h1>
        <button
          type="button"
          onClick={onEditProfile}
          aria-label="Editar perfil"
        >
          <Icon name="settings" size={27} strokeWidth={2} />
        </button>
      </header>

      <div className="profile-content">
        <section className="profile-identity">
          <span className="profile-avatar">
            {profile.avatarUrl ? (
              <img src={profile.avatarUrl} alt="" />
            ) : (
              <Sticker name="user" />
            )}
          </span>
          <div>
            <h2>{profile.name}</h2>
            <p>{profile.email}</p>
          </div>
        </section>

        <section className="profile-menu">
          <button
            type="button"
            className="profile-menu-row"
            onClick={onReports}
          >
            <ProfileMenuIcon name="reports" />
            <strong>Mis reportes</strong>
            <Icon name="chevron" size={21} strokeWidth={2.5} />
          </button>

          <button
            type="button"
            className="profile-menu-row"
            onClick={onNotifications}
          >
            <ProfileMenuIcon name="notifications" />
            <strong>Preferencias de notificaciones</strong>
            <Icon name="chevron" size={21} strokeWidth={2.5} />
          </button>

          <button
            type="button"
            className="profile-menu-row"
            onClick={() => onNotice("Ubicación actual: Centro, Cuautla")}
          >
            <ProfileMenuIcon name="location" />
            <strong>Ubicación</strong>
            <small>Centro, Cuautla</small>
            <Icon name="chevron" size={21} strokeWidth={2.5} />
          </button>

          <button
            type="button"
            className="profile-menu-row"
            onClick={onPrivacy}
          >
            <ProfileMenuIcon name="privacy" />
            <strong>Privacidad</strong>
            <Icon name="chevron" size={21} strokeWidth={2.5} />
          </button>

          <button type="button" className="profile-menu-row" onClick={onHelp}>
            <ProfileMenuIcon name="help" />
            <strong>Ayuda y soporte</strong>
            <Icon name="chevron" size={21} strokeWidth={2.5} />
          </button>

          <button
            type="button"
            className="profile-menu-row logout-row"
            onClick={onLogout}
          >
            <ProfileMenuIcon name="logout" />
            <strong>Cerrar sesión</strong>
          </button>
        </section>
      </div>

      <nav
        className="bottom-nav profile-bottom-nav"
        aria-label="Navegación principal"
      >
        {navItems.map((item) => (
          <button
            className={`${item.label === "Perfil" ? "active" : ""} ${
              item.label === "Reportar" ? "create-nav" : ""
            }`}
            key={item.label}
            onClick={() => {
              if (item.label === "Inicio") onHome()
              else if (item.label === "Mapa") onMap()
              else if (item.label === "Reportar") onReport()
              else if (item.label === "Actividad") onActivity()
            }}
          >
            <span className="nav-icon">
              <Sticker name={item.sticker} />
            </span>
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </div>
  )
}

type PrivacyTopicId = "location" | "camera" | "anonymous" | "data" | "sessions" | "download" | "delete"

type PrivacyTopic = {
  id: PrivacyTopicId
  title: string
  subtitle: string
  image: string
  eyebrow: string
  description: string
  detail: string
  action?: string
}

const privacyTopics: Record<PrivacyTopicId, PrivacyTopic> = {
  location: {
    id: "location",
    title: "Ubicación",
    subtitle: "Permiso activo",
    image: privacyLocationImage,
    eyebrow: "Permiso de la app",
    description:
      "Usamos tu ubicación para situar reportes, mostrar alertas cercanas y configurar tu zona de interés.",
    detail:
      "Tu posición solo se consulta mientras utilizas una función que la necesita. Puedes cambiar este permiso desde la configuración de tu dispositivo.",
    action: "Comprobar permiso",
  },
  camera: {
    id: "camera",
    title: "Cámara y fotografías",
    subtitle: "Para adjuntar evidencias",
    image: privacyCameraImage,
    eyebrow: "Permiso de la app",
    description:
      "La cámara y tu galería se usan únicamente cuando decides agregar evidencia a un reporte.",
    detail:
      "Ciudad Segura no abre tu cámara ni revisa tus fotografías en segundo plano. El permiso se solicita justo antes de usarlo.",
    action: "Revisar permiso",
  },
  anonymous: {
    id: "anonymous",
    title: "Reportes anónimos",
    subtitle: "Tu identidad está protegida",
    image: privacyAnonymousImage,
    eyebrow: "Tu privacidad",
    description:
      "Tu nombre, teléfono y correo no se muestran públicamente al enviar un reporte.",
    detail:
      "Las autoridades reciben la categoría, descripción, ubicación y evidencias del incidente. Tus datos de cuenta permanecen protegidos.",
    action: "Entendido",
  },
  data: {
    id: "data",
    title: "Tratamiento de datos",
    subtitle: "Cómo protegemos tu información",
    image: privacyDataImage,
    eyebrow: "Tu privacidad",
    description:
      "Conservamos solo los datos necesarios para operar tu cuenta, dar seguimiento a reportes y mejorar la seguridad.",
    detail:
      "La información se almacena de forma protegida y no se vende. El acceso se limita a procesos autorizados y a las autoridades que atienden tus reportes.",
    action: "Entendido",
  },
  sessions: {
    id: "sessions",
    title: "Sesiones abiertas",
    subtitle: "1 dispositivo activo",
    image: privacySessionsImage,
    eyebrow: "Tu cuenta",
    description:
      "Esta sesión está activa en tu dispositivo actual y no detectamos otros accesos recientes.",
    detail:
      "Si notas actividad desconocida, cambia tu contraseña desde Mi perfil. Esto ayuda a proteger el acceso a tu cuenta.",
    action: "Cerrar otras sesiones",
  },
  download: {
    id: "download",
    title: "Descargar mis datos",
    subtitle: "Solicita una copia de tu información",
    image: privacyDownloadImage,
    eyebrow: "Tu cuenta",
    description:
      "Puedes obtener una copia legible de los datos principales asociados con tu perfil.",
    detail:
      "La descarga incluye tu información de contacto y una marca de tiempo. Tus evidencias y reportes requieren un proceso de exportación independiente.",
    action: "Descargar copia",
  },
  delete: {
    id: "delete",
    title: "Eliminar cuenta",
    subtitle: "Esta acción es permanente",
    image: privacyDeleteImage,
    eyebrow: "Zona de riesgo",
    description:
      "Al eliminar tu cuenta perderás el acceso a tu perfil, preferencias y seguimiento de reportes.",
    detail:
      "Los reportes ya enviados pueden conservarse de forma anónima cuando sean necesarios para la seguridad pública o el cumplimiento legal.",
    action: "Solicitar eliminación",
  },
}

function PrivacyRow({
  topic,
  onOpen,
}: {
  topic: PrivacyTopic
  onOpen: (topic: PrivacyTopic) => void
}) {
  return (
    <button
      type="button"
      className={`privacy-row ${topic.id === "delete" ? "danger" : ""}`}
      data-topic={topic.id}
      onClick={() => onOpen(topic)}
    >
      <span className="privacy-row-art" aria-hidden="true">
        <img src={topic.image} alt="" />
      </span>
      <span className="privacy-row-copy">
        <strong>{topic.title}</strong>
        <small>{topic.subtitle}</small>
      </span>
      <Icon name="chevron" size={21} strokeWidth={2.5} />
    </button>
  )
}

function PrivacySecurityScreen({
  profile,
  onBack,
  onNotice,
}: {
  profile: UserProfile
  onBack: () => void
  onNotice: (message: string) => void
}) {
  const [selectedTopic, setSelectedTopic] = useState<PrivacyTopic | null>(null)
  const [permissionState, setPermissionState] = useState("")
  const [deleteConfirmation, setDeleteConfirmation] = useState(false)

  useEffect(() => {
    if (!selectedTopic) return

    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSelectedTopic(null)
    }
    window.addEventListener("keydown", closeOnEscape)
    return () => window.removeEventListener("keydown", closeOnEscape)
  }, [selectedTopic])

  const closeDialog = () => {
    setSelectedTopic(null)
    setPermissionState("")
    setDeleteConfirmation(false)
  }

  const checkPermission = async (kind: "geolocation" | "camera") => {
    if (!navigator.permissions) {
      setPermissionState("Revísalo en la configuración de tu dispositivo")
      return
    }

    try {
      const status = await navigator.permissions.query({
        name: kind as PermissionName,
      })
      const labels: Record<PermissionState, string> = {
        granted: "Permiso activo",
        denied: "Permiso bloqueado",
        prompt: "Se solicitará al usarlo",
      }
      setPermissionState(labels[status.state])
    } catch {
      setPermissionState("Revísalo en la configuración de tu dispositivo")
    }
  }

  const downloadData = () => {
    const data = {
      perfil: {
        nombre: profile.name,
        correo: profile.email,
        telefono: profile.phone,
      },
      exportadoEl: new Date().toISOString(),
    }
    const url = URL.createObjectURL(
      new Blob([JSON.stringify(data, null, 2)], {
        type: "application/json",
      }),
    )
    const link = document.createElement("a")
    link.href = url
    link.download = "mis-datos-ciudad-segura.json"
    link.click()
    URL.revokeObjectURL(url)
    closeDialog()
    onNotice("Tu copia de datos se descargó correctamente")
  }

  const performAction = () => {
    if (!selectedTopic) return
    if (selectedTopic.id === "location") {
      void checkPermission("geolocation")
      return
    }
    if (selectedTopic.id === "camera") {
      void checkPermission("camera")
      return
    }
    if (selectedTopic.id === "download") {
      downloadData()
      return
    }
    if (selectedTopic.id === "sessions") {
      closeDialog()
      onNotice("No hay otras sesiones abiertas")
      return
    }
    if (selectedTopic.id === "delete" && !deleteConfirmation) {
      setDeleteConfirmation(true)
      return
    }
    if (selectedTopic.id === "delete") {
      closeDialog()
      onNotice("Solicitud de eliminación registrada")
      return
    }
    closeDialog()
  }

  return (
    <div className="privacy-screen">
      <header className="privacy-header">
        <button type="button" onClick={onBack} aria-label="Volver a mi perfil">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Privacidad y seguridad</h1>
        <span aria-hidden="true" />
      </header>

      <div className="privacy-content">
        <section className="privacy-hero">
          <div>
            <span>Protección activa</span>
            <h2>Tu seguridad, en tus manos</h2>
            <p>Consulta y administra cómo cuidamos tu información.</p>
          </div>
          <img src={privacySecurityImage} alt="" />
        </section>

        <section className="privacy-group">
          <h3>Permisos de la app</h3>
          <div className="privacy-card">
            <PrivacyRow
              topic={privacyTopics.location}
              onOpen={setSelectedTopic}
            />
            <PrivacyRow
              topic={privacyTopics.camera}
              onOpen={setSelectedTopic}
            />
          </div>
        </section>

        <section className="privacy-group">
          <h3>Tu privacidad</h3>
          <div className="privacy-card">
            <PrivacyRow
              topic={privacyTopics.anonymous}
              onOpen={setSelectedTopic}
            />
            <PrivacyRow topic={privacyTopics.data} onOpen={setSelectedTopic} />
          </div>
        </section>

        <section className="privacy-group">
          <h3>Tu cuenta</h3>
          <div className="privacy-card">
            <PrivacyRow
              topic={privacyTopics.sessions}
              onOpen={setSelectedTopic}
            />
            <PrivacyRow
              topic={privacyTopics.download}
              onOpen={setSelectedTopic}
            />
          </div>
        </section>

        <div className="privacy-card privacy-danger-card">
          <PrivacyRow topic={privacyTopics.delete} onOpen={setSelectedTopic} />
        </div>
      </div>

      {selectedTopic && (
        <div
          className="privacy-modal"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) closeDialog()
          }}
        >
          <section
            className={`privacy-dialog ${
              selectedTopic.id === "delete" ? "danger" : ""
            }`}
            data-topic={selectedTopic.id}
            role="dialog"
            aria-modal="true"
            aria-labelledby="privacy-dialog-title"
          >
            <button
              type="button"
              className="privacy-dialog-close"
              onClick={closeDialog}
              aria-label="Cerrar"
            >
              <Icon name="close" size={20} strokeWidth={2.3} />
            </button>
            <div className="privacy-dialog-art">
              <img src={selectedTopic.image} alt="" />
            </div>
            <small>{selectedTopic.eyebrow}</small>
            <h2 id="privacy-dialog-title">{selectedTopic.title}</h2>
            <p>{selectedTopic.description}</p>
            <div className="privacy-dialog-detail">
              {deleteConfirmation ? (
                <>
                  <strong>¿Confirmas que deseas continuar?</strong>
                  <span>Esta solicitud no se puede deshacer.</span>
                </>
              ) : (
                selectedTopic.detail
              )}
            </div>
            {permissionState && (
              <div className="privacy-permission-state" role="status">
                <span />
                {permissionState}
              </div>
            )}
            <button
              type="button"
              className="privacy-dialog-action"
              onClick={performAction}
            >
              {deleteConfirmation
                ? "Confirmar eliminación"
                : selectedTopic.action}
            </button>
            <button
              type="button"
              className="privacy-dialog-secondary"
              onClick={closeDialog}
            >
              {deleteConfirmation ? "Cancelar" : "Cerrar"}
            </button>
          </section>
        </div>
      )}
    </div>
  )
}

type HelpTopicId = "faq" | "create" | "tracking" | "support" | "problem" | "municipal"

type HelpTopic = {
  id: HelpTopicId
  title: string
  subtitle: string
  image: string
  eyebrow: string
  description: string
  detail: string
  action: string
  destination?: "report" | "reports" | "contacts"
  notice?: string
}

const helpTopics: Record<HelpTopicId, HelpTopic> = {
  faq: {
    id: "faq",
    title: "Preguntas frecuentes",
    subtitle: "Respuestas a las dudas más comunes",
    image: helpFaqImage,
    eyebrow: "Respuestas rápidas",
    description:
      "Puedes reportar de forma segura, consultar alertas cercanas y seguir el avance de cada caso desde la aplicación.",
    detail:
      "Tus datos personales no se muestran públicamente. Si un reporte queda pendiente, podrás consultarlo en Mis reportes; para una emergencia en curso llama al 911.",
    action: "Entendido",
  },
  create: {
    id: "create",
    title: "Cómo crear un reporte",
    subtitle: "Consulta la guía paso a paso",
    image: helpCreateReportImage,
    eyebrow: "Guía de reporte",
    description:
      "Selecciona el tipo de incidente, describe lo ocurrido y confirma la ubicación antes de enviarlo.",
    detail:
      "Agrega fotografías solo si hacerlo es seguro. Revisa el resumen final y conserva el folio que genera Cuautla Segura para dar seguimiento.",
    action: "Crear un reporte",
    destination: "report",
  },
  tracking: {
    id: "tracking",
    title: "Seguimiento de reportes",
    subtitle: "Conoce cómo consultar su estado",
    image: helpReportTrackingImage,
    eyebrow: "Tus reportes",
    description:
      "Cada reporte muestra su folio, fecha y estado actual: pendiente, en atención, resuelto o rechazado.",
    detail:
      "En Mis reportes puedes abrir un caso y consultar su línea de tiempo. Las novedades también aparecen en Actividad y, si lo permites, mediante notificaciones.",
    action: "Ver mis reportes",
    destination: "reports",
  },
  support: {
    id: "support",
    title: "Contactar soporte",
    subtitle: "Consulta los canales de ayuda",
    image: helpContactSupportImage,
    eyebrow: "Soporte de la app",
    description:
      "El equipo de soporte puede orientarte sobre el acceso a tu cuenta, el uso de la app y problemas técnicos.",
    detail:
      "Describe qué estabas intentando hacer y evita compartir contraseñas o información sensible. El soporte no recibe ni atiende emergencias.",
    action: "Solicitar orientación",
    notice: "Tu solicitud de orientación quedó preparada",
  },
  problem: {
    id: "problem",
    title: "Reportar un problema",
    subtitle: "Cuéntanos qué falla en la aplicación",
    image: helpReportProblemImage,
    eyebrow: "Problema técnico",
    description:
      "Si una pantalla no carga o una función no responde, puedes ayudarnos indicando dónde ocurrió y qué mensaje viste.",
    detail:
      "Antes de reportarlo, verifica tu conexión y vuelve a abrir la app. Una captura de pantalla puede facilitar el diagnóstico, pero no incluyas datos privados.",
    action: "Preparar reporte técnico",
    notice: "Reporte técnico preparado; gracias por ayudarnos a mejorar",
  },
  municipal: {
    id: "municipal",
    title: "Atención municipal",
    subtitle: "Consulta números y canales disponibles",
    image: helpMunicipalServiceImage,
    eyebrow: "Canales de atención",
    description:
      "Consulta los contactos disponibles para emergencias, denuncia anónima y servicios de atención en Cuautla.",
    detail:
      "Llama al 911 ante una emergencia inmediata o al 089 para denuncia anónima. Para otros servicios, revisa el directorio de contactos de la app.",
    action: "Ver contactos",
    destination: "contacts",
  },
}

function HelpRow({
  topic,
  onOpen,
}: {
  topic: HelpTopic
  onOpen: (topic: HelpTopic) => void
}) {
  return (
    <button
      type="button"
      className="help-row"
      data-topic={topic.id}
      onClick={() => onOpen(topic)}
    >
      <span className="help-row-art" aria-hidden="true">
        <img src={topic.image} alt="" />
      </span>
      <span className="help-row-copy">
        <strong>{topic.title}</strong>
        <small>{topic.subtitle}</small>
      </span>
      <Icon name="chevron" size={21} strokeWidth={2.5} />
    </button>
  )
}

function HelpSupportScreen({
  onBack,
  onReport,
  onReports,
  onContacts,
  onNotice,
}: {
  onBack: () => void
  onReport: () => void
  onReports: () => void
  onContacts: () => void
  onNotice: (message: string) => void
}) {
  const [selectedTopic, setSelectedTopic] = useState<HelpTopic | null>(null)

  useEffect(() => {
    if (!selectedTopic) return

    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape") setSelectedTopic(null)
    }
    window.addEventListener("keydown", closeOnEscape)
    return () => window.removeEventListener("keydown", closeOnEscape)
  }, [selectedTopic])

  const performAction = () => {
    if (!selectedTopic) return
    const { destination, notice } = selectedTopic
    setSelectedTopic(null)

    if (destination === "report") onReport()
    else if (destination === "reports") onReports()
    else if (destination === "contacts") onContacts()
    else if (notice) onNotice(notice)
  }

  return (
    <div className="help-screen">
      <header className="help-header">
        <button type="button" onClick={onBack} aria-label="Volver a mi perfil">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Ayuda y soporte</h1>
        <span aria-hidden="true" />
      </header>

      <div className="help-content">
        <section className="help-hero">
          <img src={helpSupportHeroImage} alt="" />
          <div>
            <h2>Estamos para ayudarte</h2>
            <p>Encuentra respuestas y orientación para usar la app.</p>
          </div>
        </section>

        <section className="help-group">
          <h3>Resuelve tus dudas</h3>
          <div className="help-card">
            <HelpRow topic={helpTopics.faq} onOpen={setSelectedTopic} />
            <HelpRow topic={helpTopics.create} onOpen={setSelectedTopic} />
          </div>
        </section>

        <section className="help-group">
          <h3>Tus reportes</h3>
          <div className="help-card">
            <HelpRow topic={helpTopics.tracking} onOpen={setSelectedTopic} />
            <HelpRow topic={helpTopics.support} onOpen={setSelectedTopic} />
          </div>
        </section>

        <section className="help-group">
          <h3>Más ayuda</h3>
          <div className="help-card">
            <HelpRow topic={helpTopics.problem} onOpen={setSelectedTopic} />
            <HelpRow topic={helpTopics.municipal} onOpen={setSelectedTopic} />
          </div>
        </section>

        <div className="help-emergency-note">
          <Icon name="help" size={20} strokeWidth={2.2} />
          <span>El soporte de la app no atiende emergencias.</span>
        </div>
      </div>

      {selectedTopic && (
        <div
          className="help-modal"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) setSelectedTopic(null)
          }}
        >
          <section
            className="help-dialog"
            data-topic={selectedTopic.id}
            role="dialog"
            aria-modal="true"
            aria-labelledby="help-dialog-title"
          >
            <button
              type="button"
              className="help-dialog-close"
              onClick={() => setSelectedTopic(null)}
              aria-label="Cerrar"
            >
              <Icon name="close" size={20} strokeWidth={2.3} />
            </button>
            <div className="help-dialog-art">
              <img src={selectedTopic.image} alt="" />
            </div>
            <small>{selectedTopic.eyebrow}</small>
            <h2 id="help-dialog-title">{selectedTopic.title}</h2>
            <p>{selectedTopic.description}</p>
            <div className="help-dialog-detail">{selectedTopic.detail}</div>
            <button
              type="button"
              className="help-dialog-action"
              onClick={performAction}
            >
              {selectedTopic.action}
            </button>
            <button
              type="button"
              className="help-dialog-secondary"
              onClick={() => setSelectedTopic(null)}
            >
              Cerrar
            </button>
          </section>
        </div>
      )}
    </div>
  )
}

function EditProfileScreen({
  profile,
  onBack,
  onSave,
  onPassword,
  onNotice,
}: {
  profile: UserProfile
  onBack: () => void
  onSave: (profile: UserProfile) => void
  onPassword: () => void
  onNotice: (message: string) => void
}) {
  const [name, setName] = useState(profile.name)
  const [email, setEmail] = useState(profile.email)
  const [phone, setPhone] = useState(profile.phone)
  const [avatarUrl, setAvatarUrl] = useState(profile.avatarUrl)
  const firstName = name.trim().split(/\s+/)[0] || "Iker"

  const changePhoto = (files: FileList | null) => {
    const file = files?.[0]
    if (!file) return
    setAvatarUrl(URL.createObjectURL(file))
    onNotice("Foto de perfil actualizada")
  }

  const saveProfile = () => {
    if (!name.trim() || !email.trim() || !phone.trim()) {
      onNotice("Completa todos tus datos")
      return
    }
    if (!email.includes("@")) {
      onNotice("Ingresa un correo electrónico válido")
      return
    }
    onSave({
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      avatarUrl,
    })
  }

  return (
    <div className="edit-profile-screen">
      <header className="edit-profile-header">
        <button type="button" onClick={onBack} aria-label="Volver a mi perfil">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Editar mi perfil</h1>
        <span aria-hidden="true" />
      </header>

      <div className="edit-profile-content">
        <section className="edit-profile-hero">
          <div className="edit-profile-avatar">
            <span className="edit-profile-avatar-media">
              {avatarUrl ? (
                <img src={avatarUrl} alt="Foto de perfil seleccionada" />
              ) : (
                <Sticker name="user" />
              )}
            </span>
            <label className="edit-profile-camera">
              <input
                type="file"
                accept="image/*"
                onChange={(event) => changePhoto(event.target.files)}
              />
              <Icon name="camera" size={20} strokeWidth={2.2} />
              <span className="sr-only">Cambiar foto de perfil</span>
            </label>
          </div>
          <div className="edit-profile-greeting">
            <h2>¡Hola, {firstName}!</h2>
            <p>Dale tu toque a tu perfil.</p>
          </div>
        </section>

        <section className="edit-profile-data">
          <div className="edit-profile-section-heading">
            <h2>Tus datos</h2>
            <p>Así podemos mantenerte informado.</p>
          </div>

          <div className="edit-profile-fields">
            <label className="edit-profile-field">
              <span>
                <small>Nombre completo</small>
                <input
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  autoComplete="name"
                />
              </span>
              <i>
                <Icon name="user" size={28} strokeWidth={2} />
              </i>
            </label>

            <label className="edit-profile-field">
              <span>
                <small>Correo electrónico</small>
                <input
                  type="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  autoComplete="email"
                />
              </span>
              <i>
                <Icon name="mail" size={27} strokeWidth={2} />
              </i>
            </label>

            <label className="edit-profile-field">
              <span>
                <small>Teléfono</small>
                <input
                  type="tel"
                  value={phone}
                  onChange={(event) => setPhone(event.target.value)}
                  autoComplete="tel"
                />
              </span>
              <i>
                <Icon name="phone" size={27} strokeWidth={2} />
              </i>
            </label>
          </div>
        </section>

        <section className="edit-profile-access">
          <h2>Acceso a tu cuenta</h2>
          <button type="button" onClick={onPassword}>
            <img src="/icons/3d/profile-security.png" alt="" />
            <span>
              <strong>Contraseña</strong>
              <small>Actualiza tu contraseña.</small>
            </span>
            <i>
              <Icon name="chevron" size={25} strokeWidth={2.7} />
            </i>
          </button>
        </section>

        <button
          type="button"
          className="edit-profile-save"
          onClick={saveProfile}
        >
          <span>
            <Icon name="check" size={23} strokeWidth={2.8} />
          </span>
          Guardar cambios
        </button>
        <button type="button" className="edit-profile-discard" onClick={onBack}>
          Descartar cambios
        </button>
      </div>
    </div>
  )
}

function ChangePasswordScreen({
  onBack,
  onProfile,
}: {
  onBack: () => void
  onProfile: () => void
}) {
  const [currentPassword, setCurrentPassword] = useState("")
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [visibleField, setVisibleField] =
    useState<"current" | "new" | "confirm" | null>(null)
  const [submitted, setSubmitted] = useState(false)
  const [success, setSuccess] = useState(false)

  const requirements = [
    {
      label: "Al menos 12 caracteres",
      met: newPassword.length >= 12,
    },
    {
      label: "Mayúsculas y minúsculas",
      met: /[A-Z]/.test(newPassword) && /[a-z]/.test(newPassword),
    },
    {
      label: "Un número",
      met: /\d/.test(newPassword),
    },
    {
      label: "Un símbolo",
      met: /[^A-Za-z0-9]/.test(newPassword),
    },
  ]
  const passwordsMatch =
    confirmPassword.length > 0 && newPassword === confirmPassword
  const hasError =
    submitted &&
    (!currentPassword ||
      requirements.some((requirement) => !requirement.met) ||
      !passwordsMatch)

  const submitPassword = (event: FormEvent) => {
    event.preventDefault()
    setSubmitted(true)
    if (
      !currentPassword ||
      requirements.some((requirement) => !requirement.met) ||
      !passwordsMatch
    )
      return
    setSuccess(true)
  }

  if (success) {
    return (
      <div className="change-password-screen password-success-screen">
        <header className="change-password-header">
          <button
            type="button"
            onClick={onProfile}
            aria-label="Volver al perfil"
          >
            <Icon name="arrow-left" size={29} strokeWidth={2.4} />
          </button>
          <h1>Cambiar contraseña</h1>
          <span aria-hidden="true" />
        </header>

        <div className="password-success-content">
          <img src="/icons/3d/password-updated.png" alt="" aria-hidden="true" />
          <section>
            <h2>¡Contraseña actualizada!</h2>
            <p>Tu contraseña se cambió correctamente.</p>
            <button type="button" onClick={onProfile}>
              Volver a mi perfil
              <Icon name="arrow-right" size={23} strokeWidth={2.5} />
            </button>
          </section>
        </div>
      </div>
    )
  }

  return (
    <div className="change-password-screen">
      <header className="change-password-header">
        <button type="button" onClick={onBack} aria-label="Volver">
          <Icon name="arrow-left" size={29} strokeWidth={2.4} />
        </button>
        <h1>Cambiar contraseña</h1>
        <span aria-hidden="true" />
      </header>

      <form className="change-password-content" onSubmit={submitPassword}>
        <div className="change-password-intro">
          <img src="/icons/3d/change-password.png" alt="" aria-hidden="true" />
          <h2>Protege tu cuenta</h2>
          <p>Elige una contraseña segura para tu cuenta.</p>
        </div>

        <div className="change-password-fields">
          {[
            {
              key: "current" as const,
              label: "Contraseña actual",
              value: currentPassword,
              onChange: setCurrentPassword,
              autoComplete: "current-password",
            },
            {
              key: "new" as const,
              label: "Nueva contraseña",
              value: newPassword,
              onChange: setNewPassword,
              autoComplete: "new-password",
            },
            {
              key: "confirm" as const,
              label: "Confirmar contraseña",
              value: confirmPassword,
              onChange: setConfirmPassword,
              autoComplete: "new-password",
            },
          ].map((field) => {
            const fieldError =
              submitted &&
              ((field.key === "current" && !currentPassword) ||
                (field.key === "new" &&
                  requirements.some((requirement) => !requirement.met)) ||
                (field.key === "confirm" && !passwordsMatch))
            const visible = visibleField === field.key
            return (
              <label
                className={`change-password-field ${fieldError ? "error" : ""}`}
                key={field.key}
              >
                <span>
                  <small>{field.label}</small>
                  <input
                    type={visible ? "text" : "password"}
                    value={field.value}
                    onChange={(event) => field.onChange(event.target.value)}
                    autoComplete={field.autoComplete}
                  />
                </span>
                <button
                  type="button"
                  onClick={() =>
                    setVisibleField((current) =>
                      current === field.key ? null : field.key,
                    )
                  }
                  aria-label={
                    visible
                      ? `Ocultar ${field.label.toLocaleLowerCase("es")}`
                      : `Mostrar ${field.label.toLocaleLowerCase("es")}`
                  }
                >
                  <PasswordVisibilityIcon visible={visible} />
                </button>
              </label>
            )
          })}
          {submitted && confirmPassword && !passwordsMatch && (
            <p className="change-password-field-error">
              Las contraseñas no coinciden.
            </p>
          )}
        </div>

        <section className="password-requirements-card">
          <h3>Tu contraseña debe tener:</h3>
          <ul>
            {requirements.map((requirement) => (
              <li
                className={
                  newPassword ? (requirement.met ? "met" : "unmet") : ""
                }
                key={requirement.label}
              >
                <span>
                  <Icon name="check" size={14} strokeWidth={2.8} />
                </span>
                {requirement.label}
              </li>
            ))}
          </ul>
        </section>

        {hasError && (
          <div className="change-password-error" role="alert">
            <span>!</span>
            Revisa los datos e inténtalo de nuevo.
          </div>
        )}

        <button type="submit" className="change-password-submit">
          Guardar contraseña
          <Icon name="arrow-right" size={23} strokeWidth={2.5} />
        </button>
      </form>
    </div>
  )
}

function WelcomeScreen({ onStart }: { onStart: () => void }) {
  return (
    <div className="auth-screen welcome-screen">
      <div className="auth-brand">
        <img src="/auth/logo.webp" alt="" />
        <strong>Ciudad Segura</strong>
      </div>

      <img
        className="welcome-city"
        src="/auth/city.webp"
        alt="Ilustración de una ciudad segura con parques y edificios"
      />

      <div className="welcome-copy">
        <h1>Una ciudad más segura empieza contigo</h1>
        <p>Reporta incidentes, recibe alertas y cuida de tu comunidad.</p>
      </div>

      <button type="button" className="auth-primary-button" onClick={onStart}>
        <span>Comenzar</span>
        <span className="auth-button-arrow">
          <Icon name="arrow-right" size={19} strokeWidth={2.5} />
        </span>
      </button>

      <p className="welcome-community">
        <Icon name="users" size={17} strokeWidth={2.1} />
        Juntos cuidamos nuestra comunidad
      </p>
    </div>
  )
}

function LoginScreen({
  onBack,
  onLogin,
  onRegister,
  onForgot,
  onNotice,
}: {
  onBack: () => void
  onLogin: (email: string, password: string) => Promise<boolean>
  onRegister: () => void
  onForgot: () => void
  onNotice: (message: string) => void
}) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  const submitLogin = async (event: FormEvent) => {
    event.preventDefault()
    if (!email.trim() || !password.trim()) {
      onNotice("Completa tu correo y contraseña")
      return
    }
    setSubmitting(true)
    await onLogin(email.trim(), password)
    setSubmitting(false)
  }

  return (
    <div className="auth-screen login-screen">
      <button type="button" className="auth-back" onClick={onBack}>
        <Icon name="arrow-left" size={27} strokeWidth={2.4} />
      </button>

      <img className="login-illustration" src="/auth/lock.webp" alt="" />

      <div className="auth-heading">
        <p>Ciudad Segura</p>
        <h1>¡Qué gusto verte!</h1>
        <span>Inicia sesión para seguir cuidando tu comunidad.</span>
      </div>

      <form className="auth-form" onSubmit={submitLogin}>
        <label className="auth-field">
          <Icon name="mail" size={21} strokeWidth={2} />
          <span>
            <strong>Correo electrónico</strong>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="Tu correo electrónico"
              autoComplete="email"
            />
          </span>
        </label>

        <label className="auth-field">
          <Icon name="lock" size={21} strokeWidth={2} />
          <span>
            <strong>Contraseña</strong>
            <input
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Tu contraseña"
              autoComplete="current-password"
            />
          </span>
          <button
            type="button"
            onClick={() => setShowPassword((visible) => !visible)}
            aria-label={
              showPassword ? "Ocultar contraseña" : "Mostrar contraseña"
            }
          >
            <Icon name="eye" size={21} strokeWidth={2} />
          </button>
        </label>

        <button type="button" className="forgot-password" onClick={onForgot}>
          ¿Olvidaste tu contraseña?
        </button>

        <button
          type="submit"
          className="auth-primary-button"
          disabled={submitting}
        >
          <span>{submitting ? "Iniciando..." : "Iniciar sesión"}</span>
          <span className="auth-button-arrow">
            <Icon name="arrow-right" size={19} strokeWidth={2.5} />
          </span>
        </button>
      </form>

      <p className="auth-switch">
        ¿Aún no tienes cuenta?
        <button type="button" onClick={onRegister}>
          Crear cuenta
        </button>
      </p>
    </div>
  )
}

function ForgotPasswordScreen({
  onBack,
  onLogin,
  onSent,
  onNotice,
}: {
  onBack: () => void
  onLogin: () => void
  onSent: () => void
  onNotice: (message: string) => void
}) {
  const [email, setEmail] = useState("")
  const [sent, setSent] = useState(false)

  const sendRecoveryLink = (event: FormEvent) => {
    event.preventDefault()
    if (!email.trim() || !email.includes("@")) {
      onNotice("Ingresa un correo electrónico válido")
      return
    }
    setSent(true)
    onNotice("Enlace de recuperación enviado")
    window.setTimeout(onSent, 700)
  }

  return (
    <div className="auth-screen recovery-screen">
      <button type="button" className="auth-back" onClick={onBack}>
        <Icon name="arrow-left" size={27} strokeWidth={2.4} />
      </button>

      <img className="recovery-illustration" src="/auth/recovery.webp" alt="" />

      <div className="auth-heading recovery-heading">
        <p>Ciudad Segura</p>
        <h1>Recupera tu cuenta</h1>
        <span>
          Ingresa tu correo electrónico y te enviaremos un enlace para
          restablecer tu contraseña.
        </span>
      </div>

      <form className="auth-form recovery-form" onSubmit={sendRecoveryLink}>
        <label className="auth-field">
          <Icon name="mail" size={21} strokeWidth={2} />
          <span>
            <strong>Correo electrónico</strong>
            <input
              type="email"
              value={email}
              onChange={(event) => {
                setEmail(event.target.value)
                setSent(false)
              }}
              placeholder="Tu correo electrónico"
              autoComplete="email"
            />
          </span>
        </label>

        <button type="submit" className="auth-primary-button">
          <span>{sent ? "Enlace enviado" : "Enviar enlace"}</span>
          <span className="auth-button-arrow">
            {sent ? (
              <Icon name="check" size={19} strokeWidth={2.6} />
            ) : (
              <Icon name="arrow-right" size={19} strokeWidth={2.5} />
            )}
          </span>
        </button>
      </form>

      <p className="recovery-security">
        <span>
          <Icon name="shield" size={18} strokeWidth={2.2} />
        </span>
        Te ayudamos a volver de forma segura.
      </p>

      <p className="auth-switch recovery-switch">
        ¿Ya recuerdas tu contraseña?
        <button type="button" onClick={onLogin}>
          Inicia sesión
        </button>
      </p>
    </div>
  )
}

function PasswordVisibilityIcon({ visible }: { visible: boolean }) {
  return (
    <span className={`password-visibility-icon ${visible ? "is-visible" : ""}`}>
      <span className="password-eye password-eye-closed">
        <Icon name="eye-off" size={24} strokeWidth={2} />
      </span>
      <span className="password-eye password-eye-open">
        <Icon name="eye" size={24} strokeWidth={2} />
      </span>
    </span>
  )
}

function ResetPasswordScreen({
  onBack,
  onReset,
  onLogin,
  onNotice,
}: {
  onBack: () => void
  onReset: () => void
  onLogin: () => void
  onNotice: (message: string) => void
}) {
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)

  const resetPassword = (event: FormEvent) => {
    event.preventDefault()
    if (password.length < 8) {
      onNotice("La contraseña debe tener al menos 8 caracteres")
      return
    }
    if (password !== confirmPassword) {
      onNotice("Las contraseñas no coinciden")
      return
    }
    onReset()
  }

  return (
    <div className="auth-screen reset-screen">
      <button type="button" className="auth-back" onClick={onBack}>
        <Icon name="arrow-left" size={27} strokeWidth={2.4} />
      </button>

      <div className="reset-brand">
        <img src="/auth/logo.webp" alt="" />
        <strong>Ciudad Segura</strong>
      </div>

      <img className="reset-illustration" src="/auth/reset.webp" alt="" />

      <div className="reset-heading">
        <h1>Nueva contraseña</h1>
        <p>Elige una contraseña segura para volver a tu comunidad.</p>
      </div>

      <form className="reset-form" onSubmit={resetPassword}>
        <div className="reset-fields-card">
          <label>
            <strong>Nueva contraseña</strong>
            <span className="reset-field">
              <Icon name="lock" size={24} strokeWidth={2} />
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Escribe tu contraseña"
                autoComplete="new-password"
              />
              <button
                type="button"
                className={showPassword ? "is-visible" : ""}
                onClick={() => setShowPassword((visible) => !visible)}
                aria-label={
                  showPassword ? "Ocultar contraseña" : "Mostrar contraseña"
                }
                aria-pressed={showPassword}
              >
                <PasswordVisibilityIcon visible={showPassword} />
              </button>
            </span>
          </label>

          <label>
            <strong>Confirmar contraseña</strong>
            <span className="reset-field">
              <Icon name="lock" size={24} strokeWidth={2} />
              <input
                type={showConfirmPassword ? "text" : "password"}
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                placeholder="Repite tu contraseña"
                autoComplete="new-password"
              />
              <button
                type="button"
                className={showConfirmPassword ? "is-visible" : ""}
                onClick={() => setShowConfirmPassword((visible) => !visible)}
                aria-label={
                  showConfirmPassword
                    ? "Ocultar contraseña"
                    : "Mostrar contraseña"
                }
                aria-pressed={showConfirmPassword}
              >
                <PasswordVisibilityIcon visible={showConfirmPassword} />
              </button>
            </span>
          </label>

          <p className="reset-requirement">
            <span>
              <Icon name="check" size={15} strokeWidth={2.7} />
            </span>
            Mínimo 8 caracteres
          </p>
        </div>

        <button type="submit" className="auth-primary-button">
          <span>Restablecer contraseña</span>
          <span className="auth-button-arrow">
            <Icon name="arrow-right" size={19} strokeWidth={2.5} />
          </span>
        </button>
      </form>

      <p className="reset-security">
        <Icon name="lock" size={18} strokeWidth={2.2} />
        Protegemos tu información
      </p>

      <button type="button" className="reset-login-link" onClick={onLogin}>
        Volver a iniciar sesión
      </button>
    </div>
  )
}

function RegisterScreen({
  onBack,
  onRegister,
  onLogin,
  onNotice,
}: {
  onBack: () => void
  onRegister: (
    name: string,
    email: string,
    password: string,
  ) => Promise<boolean>
  onLogin: () => void
  onNotice: (message: string) => void
}) {
  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [accepted, setAccepted] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const passwordIsStrong =
    password.length >= 12 &&
    /[A-Z]/.test(password) &&
    /[a-z]/.test(password) &&
    /\d/.test(password)

  const submitRegistration = async (event: FormEvent) => {
    event.preventDefault()
    if (!name.trim() || !email.trim() || !password.trim()) {
      onNotice("Completa todos los campos")
      return
    }
    if (!passwordIsStrong) {
      onNotice("Usa 12 caracteres, mayúscula, minúscula y número")
      return
    }
    if (password !== confirmPassword) {
      onNotice("Las contraseñas no coinciden")
      return
    }
    if (!accepted) {
      onNotice("Acepta los términos y el aviso de privacidad")
      return
    }
    setSubmitting(true)
    await onRegister(name.trim(), email.trim(), password)
    setSubmitting(false)
  }

  return (
    <div className="auth-screen register-screen">
      <button type="button" className="auth-back" onClick={onBack}>
        <Icon name="arrow-left" size={27} strokeWidth={2.4} />
      </button>

      <img className="register-illustration" src="/auth/people.webp" alt="" />

      <div className="auth-heading register-heading">
        <h1>Únete a Ciudad Segura</h1>
        <span>Crea tu cuenta y conecta con tu comunidad.</span>
      </div>

      <form className="auth-form register-form" onSubmit={submitRegistration}>
        <label className="auth-field">
          <Icon name="user" size={21} strokeWidth={2} />
          <span>
            <strong>Nombre completo</strong>
            <input
              value={name}
              onChange={(event) => setName(event.target.value)}
              placeholder="Tu nombre"
              autoComplete="name"
            />
          </span>
        </label>

        <label className="auth-field">
          <Icon name="mail" size={21} strokeWidth={2} />
          <span>
            <strong>Correo electrónico</strong>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="Tu correo electrónico"
              autoComplete="email"
            />
          </span>
        </label>

        <label className="auth-field">
          <Icon name="lock" size={21} strokeWidth={2} />
          <span>
            <strong>Contraseña</strong>
            <input
              type={showPassword ? "text" : "password"}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Crea una contraseña"
              autoComplete="new-password"
            />
          </span>
          <button
            type="button"
            onClick={() => setShowPassword((visible) => !visible)}
            aria-label={
              showPassword ? "Ocultar contraseña" : "Mostrar contraseña"
            }
          >
            <Icon name="eye" size={21} strokeWidth={2} />
          </button>
        </label>

        <label className="auth-field">
          <Icon name="lock" size={21} strokeWidth={2} />
          <span>
            <strong>Confirmar contraseña</strong>
            <input
              type={showPassword ? "text" : "password"}
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              placeholder="Repite tu contraseña"
              autoComplete="new-password"
            />
          </span>
          <button
            type="button"
            onClick={() => setShowPassword((visible) => !visible)}
            aria-label={
              showPassword ? "Ocultar contraseña" : "Mostrar contraseña"
            }
          >
            <Icon name="eye" size={21} strokeWidth={2} />
          </button>
        </label>

        <small className="password-help">
          Usa 12 caracteres, mayúscula, minúscula y número.
        </small>

        <label className="terms-check">
          <input
            type="checkbox"
            checked={accepted}
            onChange={(event) => setAccepted(event.target.checked)}
          />
          <span>
            Acepto los <u>Términos</u> y el <u>Aviso de privacidad</u>
          </span>
        </label>

        <button
          type="submit"
          className="auth-primary-button"
          disabled={submitting}
        >
          <span>{submitting ? "Creando..." : "Crear cuenta"}</span>
          <span className="auth-button-arrow">
            <Icon name="arrow-right" size={19} strokeWidth={2.5} />
          </span>
        </button>
      </form>

      <p className="auth-switch register-switch">
        ¿Ya tienes cuenta?
        <button type="button" onClick={onLogin}>
          Inicia sesión
        </button>
      </p>
    </div>
  )
}

function SuccessScreen({
  onViewReports,
  onNewReport,
  onNotice,
}: {
  onViewReports: () => void
  onNewReport: () => void
  onNotice: (message: string) => void
}) {
  const folio = "RC-2025-001234"
  const [submittedAt] = useState(() => new Date())
  const formattedDate = new Intl.DateTimeFormat("es-MX", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  })
    .format(submittedAt)
    .replace(".", "")

  const copyFolio = async () => {
    try {
      await navigator.clipboard.writeText(folio)
      onNotice("Folio copiado")
    } catch {
      onNotice(`Folio: ${folio}`)
    }
  }

  return (
    <div className="success-screen">
      <div className="success-visual" aria-hidden="true">
        <span className="success-aura" />
        <Sticker name="shield-header" className="success-shield" />
        <i className="confetti confetti-one" />
        <i className="confetti confetti-two" />
        <i className="confetti confetti-three" />
        <i className="confetti confetti-four" />
        <i className="confetti confetti-five" />
        <i className="confetti confetti-six" />
        <i className="confetti confetti-seven" />
        <i className="confetti confetti-eight" />
      </div>

      <div className="success-heading">
        <h1>¡Reporte enviado!</h1>
        <p>Tu reporte ha sido registrado correctamente.</p>
      </div>

      <button type="button" className="folio-card" onClick={copyFolio}>
        <span>
          <small>Folio del reporte</small>
          <strong>{folio}</strong>
        </span>
        <Icon name="copy" size={29} strokeWidth={2.1} />
      </button>

      <div className="report-summary">
        <div className="summary-row">
          <span className="summary-icon status-icon">
            <Icon name="activity" size={18} strokeWidth={2.4} />
          </span>
          <span className="summary-copy">
            <small>Estado actual</small>
          </span>
          <strong className="status-badge">En revisión</strong>
        </div>
        <div className="summary-row">
          <span className="summary-icon date-icon">
            <Icon name="calendar" size={22} strokeWidth={2.1} />
          </span>
          <span className="summary-copy">
            <small>Fecha y hora</small>
            <strong>{formattedDate}</strong>
          </span>
        </div>
      </div>

      <div className="success-actions">
        <button
          type="button"
          className="success-primary"
          onClick={onViewReports}
        >
          Ver mis reportes
        </button>
        <button
          type="button"
          className="success-secondary"
          onClick={onNewReport}
        >
          Enviar otro reporte
        </button>
      </div>
    </div>
  )
}

type AppScreen = "welcome" | "login" | "forgot" | "reset" | "register" | "home" | "zone" | "report" | "details" | "confirmation" | "success" | "map" | "reports" | "reportDetail" | "tracking" | "contacts" | "contactDetail" | "sos" | "activity" | "alerts" | "alertDetail" | "profile" | "editProfile" | "notifications" | "notificationSettings" | "privacy" | "help" | "changePassword"

const SCREEN_DEPTH: Record<AppScreen, number> = {
  welcome: 0,
  login: 1,
  forgot: 2,
  reset: 3,
  register: 2,
  home: 0,
  zone: 1,
  report: 1,
  details: 2,
  confirmation: 3,
  success: 4,
  map: 1,
  reports: 1,
  reportDetail: 2,
  tracking: 3,
  contacts: 1,
  contactDetail: 2,
  sos: 2,
  activity: 1,
  alerts: 1,
  alertDetail: 2,
  profile: 1,
  editProfile: 2,
  notifications: 1,
  notificationSettings: 2,
  privacy: 2,
  help: 2,
  changePassword: 3,
}

type TransitionDocument = Document & {
  startViewTransition?: (
    update: () => void,
  ) => {
    finished: Promise<void>
  }
}

export default function App() {
  const [activeTab, setActiveTab] = useState("Inicio")
  const [notice, setNotice] = useState("")
  const [screen, setScreenState] = useState<AppScreen>("welcome")
  const [authenticated, setAuthenticated] = useState(false)
  const [userProfile, setUserProfile] = useState<UserProfile>({
    name: "Iker Pichardo Téllez",
    email: "iker@email.com",
    phone: "777 123 4567",
  })
  const [notificationPreferences, setNotificationPreferences] =
    useState<NotificationPreferences>(() => ({
      ...defaultClientNotificationPreferences,
      ...readLocalValue(
        NOTIFICATION_PREFERENCES_KEY,
        defaultClientNotificationPreferences,
      ),
    }))
  const [notificationOrigin, setNotificationOrigin] =
    useState<"profile" | "alerts" | "notifications">("profile")
  const [userNotifications, setUserNotifications] = useState(
    loadCachedNotifications,
  )
  const [notificationsSyncing, setNotificationsSyncing] = useState(false)
  const [notificationSyncError, setNotificationSyncError] = useState("")
  const [pendingNotificationOperations, setPendingNotificationOperations] =
    useState<PendingNotificationOperation[]>(() =>
      readLocalValue(NOTIFICATION_QUEUE_KEY, []),
    )
  const pendingNotificationOperationsRef = useRef(pendingNotificationOperations)
  const notificationSyncLock = useRef(false)
  const [selectedCategory, setSelectedCategory] = useState("Robo / Asalto")
  const [reportDraft, setReportDraft] = useState<ReportDraft>({
    category: "Robo / Asalto",
    description: "",
    location: "Centro, Cuautla",
    position: { lat: 18.8126, lng: -98.9548 },
    evidence: [],
  })
  const [userZone, setUserZone] = useState<UserZone>({
    address: "Centro, Cuautla",
    position: { lat: CUAUTLA_CENTER[1], lng: CUAUTLA_CENTER[0] },
    radius: 3,
  })
  const [selectedReport, setSelectedReport] = useState(citizenReports[0])
  const [selectedEmergencyContact, setSelectedEmergencyContact] = useState(
    usefulContacts[0],
  )
  const [reportDetailOrigin, setReportDetailOrigin] =
    useState<"activity" | "map" | "reports" | "notifications">("reports")
  const [selectedAlert, setSelectedAlert] = useState(communityAlerts[0])
  const [alertDetailOrigin, setAlertDetailOrigin] =
    useState<"activity" | "alerts" | "notifications">("alerts")
  const [unreadActivityIds, setUnreadActivityIds] = useState(
    () => new Set(activityEntries.slice(0, 3).map((entry) => entry.id)),
  )
  const [activityUnreadOnly, setActivityUnreadOnly] = useState(false)
  const unreadNotificationCount = userNotifications.filter(
    (item) => !item.readAt,
  ).length

  const updatePendingNotificationOperations = useCallback(
    (operations: PendingNotificationOperation[]) => {
      pendingNotificationOperationsRef.current = operations
      setPendingNotificationOperations(operations)
      writeLocalValue(NOTIFICATION_QUEUE_KEY, operations)
    },
    [],
  )

  const flushPendingNotificationOperations = useCallback(
    async (force = false) => {
      if (notificationSyncLock.current) return false
      notificationSyncLock.current = true
      let operations = [...pendingNotificationOperationsRef.current]
      let failed = false

      try {
        for (const operation of [...operations]) {
          if (!force && operation.nextAttemptAt > Date.now()) continue

          try {
            if (operation.kind === "preferences") {
              const result = await notificationApi<{
                preferences: NotificationPreferences
              }>("/notification-preferences", {
                method: "PUT",
                body: JSON.stringify(operation.payload),
              })
              setNotificationPreferences(result.preferences)
            } else if (operation.kind === "seen") {
              await notificationApi("/notifications/seen", {
                method: "PUT",
                body: JSON.stringify(operation.payload),
              })
            } else if (operation.kind === "archive") {
              await notificationApi("/notifications/archive", {
                method: "PUT",
                body: JSON.stringify(operation.payload),
              })
            } else if (operation.kind === "delete") {
              const ids =
                "ids" in operation.payload ? (operation.payload.ids ?? []) : []
              await Promise.all(
                ids.map((id) =>
                  notificationApi(`/notifications/${id}`, {
                    method: "DELETE",
                  }),
                ),
              )
            } else if (operation.kind === "action") {
              await notificationApi("/notifications/action", {
                method: "POST",
                body: JSON.stringify(operation.payload),
              })
            } else {
              await notificationApi("/notifications/read", {
                method: "PUT",
                body: JSON.stringify(operation.payload),
              })
            }
            operations = operations.filter((item) => item.id !== operation.id)
          } catch {
            failed = true
            if (operation.kind === "preferences") {
              setNotice(
                "No se pudieron guardar las preferencias; reintentaremos",
              )
              window.setTimeout(() => setNotice(""), 3200)
            }
            operations = operations.map((item) => {
              if (item.id !== operation.id) return item
              const attempts = item.attempts + 1
              const delay = Math.min(5 * 60_000, 2_000 * 2 ** attempts)
              return {
                ...item,
                attempts,
                nextAttemptAt: Date.now() + delay,
              }
            })
          }
        }
      } finally {
        updatePendingNotificationOperations(operations)
        notificationSyncLock.current = false
      }

      setNotificationSyncError(
        failed
          ? "No se pudieron sincronizar algunos cambios."
          : operations.length
            ? "Hay cambios esperando el próximo reintento."
            : "",
      )
      return !failed
    },
    [updatePendingNotificationOperations],
  )

  const enqueueNotificationOperation = useCallback(
    (
      kind: PendingNotificationOperation["kind"],
      payload: PendingNotificationOperation["payload"],
    ) => {
      let operations = [...pendingNotificationOperationsRef.current]
      if (kind === "read_all") {
        operations = operations.filter(
          (operation) =>
            operation.kind !== "read" &&
            operation.kind !== "unread" &&
            operation.kind !== "read_all",
        )
      } else if (kind === "read" || kind === "unread") {
        const id = "id" in payload ? payload.id : undefined
        operations = operations.filter(
          (operation) =>
            operation.kind !== "read_all" &&
            !(
              (operation.kind === "read" || operation.kind === "unread") &&
              "id" in operation.payload &&
              operation.payload.id === id
            ),
        )
      } else if (kind === "preferences") {
        operations = operations.filter(
          (operation) => operation.kind !== "preferences",
        )
      } else if (kind === "seen") {
        operations = operations.filter((operation) => operation.kind !== "seen")
      }
      operations.push(createPendingOperation(kind, payload))
      updatePendingNotificationOperations(operations)
      window.setTimeout(() => void flushPendingNotificationOperations(true), 0)
    },
    [flushPendingNotificationOperations, updatePendingNotificationOperations],
  )

  const refreshNotifications = useCallback(async () => {
    setNotificationsSyncing(true)
    try {
      const { notifications, preferences } = await notificationApi<{
        notifications: UserNotification[]
        preferences: NotificationPreferences
      }>("/notifications")
      setUserNotifications((current) =>
        notifications.map((remote) => {
          const local = current.find((item) => item.id === remote.id)
          return {
            ...remote,
            readAt: remote.readAt ?? local?.readAt,
            seenAt: remote.seenAt ?? local?.seenAt,
            actionedAt: remote.actionedAt ?? local?.actionedAt,
          }
        }),
      )
      if (
        !pendingNotificationOperationsRef.current.some(
          (operation) => operation.kind === "preferences",
        )
      )
        setNotificationPreferences(preferences)
      if (!pendingNotificationOperationsRef.current.length)
        setNotificationSyncError("")
    } catch (error) {
      if (error instanceof NotificationApiError && error.status === 404) {
        setUserNotifications([])
        setNotificationSyncError("")
        return
      }
      setNotificationSyncError(
        !navigator.onLine
          ? "Sin conexión. Se muestra la última copia disponible."
          : error instanceof NotificationApiError &&
              (error.status === 401 || error.status === 403)
            ? "La sesión expiró. Inicia sesión nuevamente para sincronizar."
            : "No se pudieron cargar las notificaciones.",
      )
    } finally {
      setNotificationsSyncing(false)
    }
  }, [])

  useEffect(() => {
    writeLocalValue(NOTIFICATION_CACHE_KEY, userNotifications)
  }, [userNotifications])

  useEffect(() => {
    writeLocalValue(NOTIFICATION_PREFERENCES_KEY, notificationPreferences)
  }, [notificationPreferences])

  useEffect(() => {
    const applySession = async () => {
      const {
        data: { session },
      } = await supabase.auth.getSession()
      if (!session) return
      setAuthenticated(true)
      setUserNotifications([])
      setUserProfile((current) => ({
        ...current,
        name: String(session.user.user_metadata?.name ?? current.name),
        email: session.user.email ?? current.email,
      }))
      setScreenState("home")
    }
    void applySession()
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setAuthenticated(Boolean(session))
      if (!session) {
        setUserNotifications([])
        pendingNotificationOperationsRef.current = []
        setPendingNotificationOperations([])
        window.localStorage.removeItem(NOTIFICATION_CACHE_KEY)
        window.localStorage.removeItem(NOTIFICATION_PREFERENCES_KEY)
        window.localStorage.removeItem(NOTIFICATION_QUEUE_KEY)
      }
    })
    return () => subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (!authenticated) return
    void flushPendingNotificationOperations().then(() => refreshNotifications())
    const polling = window.setInterval(
      () => void refreshNotifications(),
      30_000,
    )
    const syncAfterReconnect = () => {
      void flushPendingNotificationOperations(true).then(() =>
        refreshNotifications(),
      )
    }
    const refreshAfterFocus = () => {
      if (document.visibilityState === "visible") void refreshNotifications()
    }
    window.addEventListener("online", syncAfterReconnect)
    window.addEventListener("focus", refreshAfterFocus)
    document.addEventListener("visibilitychange", refreshAfterFocus)

    return () => {
      window.clearInterval(polling)
      window.removeEventListener("online", syncAfterReconnect)
      window.removeEventListener("focus", refreshAfterFocus)
      document.removeEventListener("visibilitychange", refreshAfterFocus)
    }
  }, [authenticated, flushPendingNotificationOperations, refreshNotifications])

  useEffect(() => {
    if (screen !== "notifications") return
    const unseen = userNotifications.filter((item) => !item.seenAt)
    if (!unseen.length) return
    const seenAt = new Date().toISOString()
    setUserNotifications((current) =>
      current.map((item) => (item.seenAt ? item : { ...item, seenAt })),
    )
    enqueueNotificationOperation("seen", {
      ids: unseen.flatMap((item) => notificationEventIds(item)),
      seenAt,
    })
  }, [screen, userNotifications, enqueueNotificationOperation])

  const showNotice = (message: string) => {
    setNotice(message)
    window.setTimeout(() => setNotice(""), message.length > 55 ? 5200 : 3000)
  }

  const setScreen = (nextScreen: AppScreen) => {
    if (nextScreen === screen) return

    const root = document.documentElement
    const direction =
      SCREEN_DEPTH[nextScreen] < SCREEN_DEPTH[screen]
        ? "back"
        : SCREEN_DEPTH[nextScreen] > SCREEN_DEPTH[screen]
          ? "forward"
          : "cross"
    const kind =
      nextScreen === "success"
        ? "success"
        : nextScreen === "map" || screen === "map"
          ? "fade"
          : direction === "cross"
            ? "fade"
            : "slide"
    const transitionDocument = document as TransitionDocument

    root.dataset.navigationDirection = direction
    root.dataset.navigationKind = kind

    if (
      !transitionDocument.startViewTransition ||
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    ) {
      setScreenState(nextScreen)
      delete root.dataset.navigationDirection
      delete root.dataset.navigationKind
      return
    }

    const transition = transitionDocument.startViewTransition(() => {
      flushSync(() => setScreenState(nextScreen))
    })
    void transition.finished.finally(() => {
      delete root.dataset.navigationDirection
      delete root.dataset.navigationKind
    })
  }

  const markActivityRead = (id: string) => {
    setUnreadActivityIds((current) => {
      if (!current.has(id)) return current
      const next = new Set(current)
      next.delete(id)
      return next
    })
  }

  const markNotificationRead = (item: UserNotification) => {
    const readAt = new Date().toISOString()
    const ids = new Set(notificationEventIds(item))
    setUserNotifications((current) =>
      current.map((notification) =>
        notification.id === item.id && !notification.readAt
          ? { ...notification, readAt }
          : notification,
      ),
    )
    enqueueNotificationOperation("read", {
      id: item.id,
      ids: [...ids],
      readAt,
      operationAt: readAt,
    })
  }

  const markAllNotificationsRead = () => {
    const readAt = new Date().toISOString()
    setUserNotifications((current) =>
      current.map((item) => ({ ...item, readAt: item.readAt ?? readAt })),
    )
    enqueueNotificationOperation("read_all", {
      all: true,
      readAt,
      operationAt: readAt,
    })
    showNotice("Todas las notificaciones se marcaron como leídas")
  }

  const toggleNotificationRead = (item: UserNotification) => {
    if (!item.readAt) {
      markNotificationRead(item)
      return
    }
    const operationAt = new Date().toISOString()
    setUserNotifications((current) =>
      current.map((notification) =>
        notification.id === item.id
          ? { ...notification, readAt: undefined }
          : notification,
      ),
    )
    enqueueNotificationOperation("unread", {
      id: item.id,
      ids: notificationEventIds(item),
      unread: true,
      operationAt,
    })
  }

  const archiveNotification = (item: UserNotification) => {
    const ids = notificationEventIds(item)
    setUserNotifications((current) =>
      current.filter((notification) => notification.id !== item.id),
    )
    enqueueNotificationOperation("archive", { ids })
    showNotice("Notificación archivada")
  }

  const deleteNotification = (item: UserNotification) => {
    const ids = notificationEventIds(item)
    setUserNotifications((current) =>
      current.filter((notification) => notification.id !== item.id),
    )
    enqueueNotificationOperation("delete", { ids })
    showNotice("Notificación eliminada")
  }

  const openNotification = (item: UserNotification) => {
    if (Date.parse(item.expiresAt) <= Date.now()) {
      setNotificationSyncError("Esta notificación ya expiró.")
      return
    }
    markNotificationRead(item)
    const eventIds = notificationEventIds(item)
    const actionedAt = new Date().toISOString()
    setUserNotifications((current) =>
      current.map((notification) =>
        notification.id === item.id
          ? { ...notification, actionedAt }
          : notification,
      ),
    )
    enqueueNotificationOperation("action", {
      id: item.id,
      ids: eventIds,
    })
    if (item.destination.kind === "report") {
      const report = citizenReports.find(
        (candidate) => candidate.id === item.destination.entityId,
      )
      if (!report) {
        setNotificationSyncError(
          "El reporte relacionado fue eliminado o ya no existe.",
        )
        return
      }
      setSelectedReport(report)
      setReportDetailOrigin("notifications")
      setScreen("reportDetail")
    } else {
      const alert = communityAlerts.find(
        (candidate) => candidate.id === item.destination.entityId,
      )
      if (!alert) {
        setNotificationSyncError(
          "La alerta relacionada fue eliminada o ya no existe.",
        )
        return
      }
      setSelectedAlert(alert)
      setAlertDetailOrigin("notifications")
      setScreen("alertDetail")
    }
  }

  useEffect(() => {
    if (!authenticated) return
    const params = new URLSearchParams(window.location.search)
    const notificationId = params.get("notification")
    const kind = params.get("kind")
    const entityId = params.get("entityId")
    if (!notificationId || !kind || !entityId) return

    const destination = { kind, entityId }
    const notification = userNotifications.find(
      (item) => item.id === notificationId,
    )
    if (notification) markNotificationRead(notification)
    else
      enqueueNotificationOperation("read", {
        id: notificationId,
        readAt: new Date().toISOString(),
      })
    void notificationApi("/notifications/action", {
      method: "POST",
      body: JSON.stringify({ id: notificationId }),
    }).catch(() => undefined)

    if (destination.kind === "report") {
      const report = citizenReports.find((item) => item.id === entityId)
      if (report) {
        setSelectedReport(report)
        setReportDetailOrigin("notifications")
        setScreen("reportDetail")
      }
    } else if (destination.kind === "alert") {
      const alert = communityAlerts.find((item) => item.id === entityId)
      if (alert) {
        setSelectedAlert(alert)
        setAlertDetailOrigin("notifications")
        setScreen("alertDetail")
      }
    }
    window.history.replaceState({}, "", window.location.pathname)
  }, [authenticated])

  if (screen === "welcome") {
    return (
      <main className="app-shell">
        <section
          className="phone-app auth-phone"
          aria-label="Bienvenida a Ciudad Segura"
        >
          <WelcomeScreen onStart={() => setScreen("login")} />
        </section>
      </main>
    )
  }

  if (screen === "login") {
    return (
      <main className="app-shell">
        <section
          className="phone-app auth-phone"
          aria-label="Iniciar sesión en Ciudad Segura"
        >
          <LoginScreen
            onBack={() => setScreen("welcome")}
            onLogin={async (email, password) => {
              const { data, error } = await supabase.auth.signInWithPassword({
                email,
                password,
              })
              if (error || !data.session) {
                if (error?.code === "email_not_confirmed") {
                  const { error: resendError } = await supabase.auth.resend({
                    type: "signup",
                    email,
                  })
                  showNotice(
                    resendError
                      ? "Confirma tu correo. Si no ves el mensaje, espera unos minutos para reenviarlo."
                      : "Tu correo aún no está confirmado. Te enviamos un nuevo enlace.",
                  )
                  return false
                }
                showNotice(
                  error?.message === "Invalid login credentials"
                    ? "Correo o contraseña incorrectos"
                    : `No fue posible iniciar sesión${
                        error?.message ? `: ${error.message}` : ""
                      }`,
                )
                return false
              }
              setAuthenticated(true)
              setUserNotifications([])
              setUserProfile((current) => ({
                ...current,
                name: String(data.user.user_metadata?.name ?? current.name),
                email: data.user.email ?? email,
              }))
              setScreen("home")
              setActiveTab("Inicio")
              void refreshNotifications()
              return true
            }}
            onRegister={() => setScreen("register")}
            onForgot={() => setScreen("forgot")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast auth-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "forgot") {
    return (
      <main className="app-shell">
        <section
          className="phone-app auth-phone"
          aria-label="Recuperar contraseña"
        >
          <ForgotPasswordScreen
            onBack={() => setScreen("login")}
            onLogin={() => setScreen("login")}
            onSent={() => setScreen("reset")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast auth-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "reset") {
    return (
      <main className="app-shell">
        <section
          className="phone-app auth-phone"
          aria-label="Restablecer contraseña"
        >
          <ResetPasswordScreen
            onBack={() => setScreen("forgot")}
            onReset={() => {
              setScreen("login")
              showNotice("Contraseña restablecida correctamente")
            }}
            onLogin={() => setScreen("login")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast auth-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "register") {
    return (
      <main className="app-shell">
        <section
          className="phone-app auth-phone"
          aria-label="Crear una cuenta en Ciudad Segura"
        >
          <RegisterScreen
            onBack={() => setScreen("login")}
            onRegister={async (name, email, password) => {
              const { data, error } = await supabase.auth.signUp({
                email,
                password,
                options: { data: { name } },
              })
              if (error) {
                showNotice(getRegistrationErrorMessage(error))
                return false
              }
              if (data.user?.identities?.length === 0) {
                setScreen("login")
                showNotice(
                  "Este correo ya tiene una cuenta. Inicia sesión o recupera tu contraseña.",
                )
                return false
              }
              setUserProfile((current) => ({
                ...current,
                name,
                email,
              }))
              if (data.session) {
                setAuthenticated(true)
                setUserNotifications([])
                setScreen("home")
                setActiveTab("Inicio")
                void refreshNotifications()
                showNotice("Cuenta creada correctamente")
              } else {
                setScreen("login")
                showNotice(
                  "Cuenta creada. Revisa tu correo para confirmarla antes de iniciar sesión.",
                )
              }
              return true
            }}
            onLogin={() => setScreen("login")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast auth-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "profile") {
    return (
      <main className="app-shell">
        <section className="phone-app profile-phone" aria-label="Mi perfil">
          <ProfileScreen
            profile={userProfile}
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onEditProfile={() => setScreen("editProfile")}
            onNotifications={() => {
              setNotificationOrigin("profile")
              setScreen("notificationSettings")
            }}
            onPrivacy={() => setScreen("privacy")}
            onHelp={() => setScreen("help")}
            onHome={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onMap={() => {
              setScreen("map")
              setActiveTab("Mapa")
            }}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onReports={() => setScreen("reports")}
            onActivity={() => {
              setActivityUnreadOnly(false)
              setScreen("activity")
              setActiveTab("Actividad")
            }}
            onLogout={async () => {
              await unsubscribeFromPush(notificationApiUrl)
              await supabase.auth.signOut()
              setAuthenticated(false)
              setUserNotifications([])
              updatePendingNotificationOperations([])
              window.localStorage.removeItem(NOTIFICATION_CACHE_KEY)
              window.localStorage.removeItem(NOTIFICATION_PREFERENCES_KEY)
              setScreen("login")
              setActiveTab("Inicio")
              showNotice("Sesión cerrada")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast profile-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "privacy") {
    return (
      <main className="app-shell">
        <section
          className="phone-app privacy-phone"
          aria-label="Privacidad y seguridad"
        >
          <PrivacySecurityScreen
            profile={userProfile}
            onBack={() => setScreen("profile")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast privacy-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "help") {
    return (
      <main className="app-shell">
        <section className="phone-app help-phone" aria-label="Ayuda y soporte">
          <HelpSupportScreen
            onBack={() => setScreen("profile")}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onReports={() => setScreen("reports")}
            onContacts={() => setScreen("contacts")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast help-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "editProfile") {
    return (
      <main className="app-shell">
        <section
          className="phone-app edit-profile-phone"
          aria-label="Editar mi perfil"
        >
          <EditProfileScreen
            profile={userProfile}
            onBack={() => setScreen("profile")}
            onSave={(profile) => {
              setUserProfile(profile)
              setScreen("profile")
              showNotice("Perfil actualizado correctamente")
            }}
            onPassword={() => setScreen("changePassword")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast edit-profile-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "changePassword") {
    return (
      <main className="app-shell">
        <section
          className="phone-app change-password-phone"
          aria-label="Cambiar contraseña"
        >
          <ChangePasswordScreen
            onBack={() => setScreen("editProfile")}
            onProfile={() => setScreen("profile")}
          />
        </section>
      </main>
    )
  }

  if (screen === "notifications") {
    return (
      <main className="app-shell">
        <section
          className="phone-app notification-inbox-phone"
          aria-label="Notificaciones dirigidas al usuario"
        >
          <NotificationsInboxScreen
            notifications={userNotifications}
            syncing={notificationsSyncing}
            syncError={notificationSyncError}
            pendingOperations={pendingNotificationOperations.length}
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onSettings={() => {
              setNotificationOrigin("notifications")
              setScreen("notificationSettings")
            }}
            onMarkAll={markAllNotificationsRead}
            onOpen={openNotification}
            onToggleRead={toggleNotificationRead}
            onArchive={archiveNotification}
            onDelete={deleteNotification}
            onRefresh={() => void refreshNotifications()}
            onRetry={() => {
              void flushPendingNotificationOperations(true).then(() =>
                refreshNotifications(),
              )
            }}
          />
          {notice && (
            <div className="toast notifications-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "notificationSettings") {
    return (
      <main className="app-shell">
        <section
          className="phone-app notifications-phone"
          aria-label="Preferencias de notificaciones"
        >
          <NotificationPreferencesScreen
            preferences={notificationPreferences}
            onBack={() => setScreen(notificationOrigin)}
            onRequestPush={async () => {
              try {
                return await subscribeToPush(notificationApiUrl)
              } catch {
                showNotice("No fue posible registrar este dispositivo")
                return "unsupported"
              }
            }}
            onSave={async (preferences) => {
              setNotificationPreferences(preferences)
              setScreen(notificationOrigin)
              showNotice(
                navigator.onLine
                  ? "Preferencias actualizadas"
                  : "Preferencias pendientes de sincronización",
              )
              enqueueNotificationOperation("preferences", preferences)
            }}
          />
          {notice && (
            <div className="toast notifications-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "zone") {
    return (
      <main className="app-shell">
        <section
          className="phone-app zone-phone"
          aria-label="Configurar mi zona de interés"
        >
          <ZoneConfigurationScreen
            initialZone={userZone}
            onBack={() => setScreen("home")}
            onSave={(zone) => {
              setUserZone(zone)
              setScreen("home")
              setActiveTab("Inicio")
              showNotice(`Zona guardada con un radio de ${zone.radius} km`)
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast zone-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "alertDetail") {
    return (
      <main className="app-shell">
        <section
          className="phone-app alert-detail-phone"
          aria-label="Detalle de alerta comunitaria"
        >
          <CommunityAlertDetailScreen
            alert={selectedAlert}
            onBack={() => setScreen(alertDetailOrigin)}
            onReport={() => {
              setSelectedCategory(
                selectedAlert.category === "Tránsito"
                  ? "Accidente"
                  : selectedAlert.category === "Servicios"
                    ? "Alumbrado público"
                    : "Robo / Asalto",
              )
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast alert-detail-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "activity") {
    return (
      <main className="app-shell">
        <section
          className="phone-app activity-phone"
          aria-label="Actividad de reportes y alertas"
        >
          <ActivityScreen
            initialUnreadOnly={activityUnreadOnly}
            unreadIds={unreadActivityIds}
            onHome={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onMap={() => {
              setScreen("map")
              setActiveTab("Mapa")
            }}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onProfile={() => {
              setScreen("profile")
              setActiveTab("Perfil")
            }}
            onMarkRead={markActivityRead}
            onOpenReport={(report) => {
              setSelectedReport(report)
              setReportDetailOrigin("activity")
              setScreen("reportDetail")
            }}
            onOpenAlert={(alert) => {
              setSelectedAlert(alert)
              setAlertDetailOrigin("activity")
              setScreen("alertDetail")
            }}
          />
        </section>
      </main>
    )
  }

  if (screen === "alerts") {
    return (
      <main className="app-shell">
        <section
          className="phone-app alerts-phone"
          aria-label="Alertas comunitarias"
        >
          <CommunityAlertsScreen
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onNotifications={() => {
              setNotificationOrigin("alerts")
              setScreen("notificationSettings")
            }}
            onHome={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onMap={() => {
              setScreen("map")
              setActiveTab("Mapa")
            }}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onActivity={() => {
              setActivityUnreadOnly(false)
              setScreen("activity")
              setActiveTab("Actividad")
            }}
            onOpenAlert={(alert) => {
              setSelectedAlert(alert)
              setAlertDetailOrigin("alerts")
              setScreen("alertDetail")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast alerts-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "contacts") {
    return (
      <main className="app-shell">
        <section
          className="phone-app contacts-phone"
          aria-label="Contactos útiles y de emergencia"
        >
          <UsefulContactsScreen
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onHome={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onMap={() => {
              setScreen("map")
              setActiveTab("Mapa")
            }}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onActivity={() => {
              setActivityUnreadOnly(false)
              setScreen("activity")
              setActiveTab("Actividad")
            }}
            onSOS={() => setScreen("sos")}
            onOpenContact={(contact) => {
              setSelectedEmergencyContact(contact)
              setScreen("contactDetail")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast contacts-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "contactDetail") {
    return (
      <main className="app-shell">
        <section
          className="phone-app contact-detail-phone"
          aria-label={`Detalle de ${selectedEmergencyContact.name}`}
        >
          <ContactDetailScreen
            contact={selectedEmergencyContact}
            fallbackLocation={{
              lat: userZone.position.lat,
              lng: userZone.position.lng,
              label: userZone.address,
            }}
            onBack={() => setScreen("contacts")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast contact-detail-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "sos") {
    return (
      <main className="app-shell">
        <section className="phone-app sos-phone" aria-label="Enviar alerta SOS">
          <SosFlowScreen
            fallbackLocation={{
              lat: userZone.position.lat,
              lng: userZone.position.lng,
              label: userZone.address,
            }}
            onBack={() => setScreen("contacts")}
            onFinish={() => setScreen("contacts")}
            onOpenContact={(contact) => {
              setSelectedEmergencyContact(contact)
              setScreen("contactDetail")
            }}
          />
        </section>
      </main>
    )
  }

  if (screen === "reportDetail") {
    return (
      <main className="app-shell">
        <section
          className="phone-app report-detail-phone"
          aria-label="Detalle del reporte ciudadano"
        >
          <ReportDetailScreen
            report={selectedReport}
            onBack={() => setScreen(reportDetailOrigin)}
            onTrack={() => setScreen("tracking")}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast detail-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "tracking") {
    return (
      <main className="app-shell">
        <section
          className="phone-app tracking-phone"
          aria-label="Seguimiento del reporte ciudadano"
        >
          <ReportTrackingScreen
            report={selectedReport}
            onBack={() => setScreen("reportDetail")}
            onViewReport={() => setScreen("reportDetail")}
          />
        </section>
      </main>
    )
  }

  if (screen === "reports") {
    return (
      <main className="app-shell">
        <section
          className="phone-app reports-phone"
          aria-label="Mis reportes ciudadanos"
        >
          <MyReportsScreen
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onHome={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onMap={() => {
              setScreen("map")
              setActiveTab("Mapa")
            }}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onActivity={() => {
              setActivityUnreadOnly(false)
              setScreen("activity")
              setActiveTab("Actividad")
            }}
            onOpenReport={(report) => {
              setSelectedReport(report)
              setReportDetailOrigin("reports")
              setScreen("reportDetail")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast reports-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "map") {
    return (
      <main className="app-shell">
        <section
          className="phone-app map-phone"
          aria-label="Mapa de incidentes ciudadanos"
        >
          <IncidentMapScreen
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onHome={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onReport={() => {
              setScreen("report")
              setActiveTab("Reportar")
            }}
            onActivity={() => {
              setActivityUnreadOnly(false)
              setScreen("activity")
              setActiveTab("Actividad")
            }}
            onOpenIncident={(incident) => {
              setSelectedReport(incident)
              setReportDetailOrigin("map")
              setScreen("reportDetail")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast map-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "success") {
    return (
      <main className="app-shell">
        <section
          className="phone-app report-phone success-phone"
          aria-label="Reporte enviado correctamente"
        >
          <SuccessScreen
            onViewReports={() => {
              setScreen("reports")
              setActiveTab("Inicio")
            }}
            onNewReport={() => {
              setSelectedCategory("Robo / Asalto")
              setReportDraft({
                category: "Robo / Asalto",
                description: "",
                location: "Centro, Cuautla",
                position: { lat: 18.8126, lng: -98.9548 },
                evidence: [],
              })
              setScreen("report")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast success-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "confirmation") {
    return (
      <main className="app-shell">
        <section
          className="phone-app report-phone confirmation-phone"
          aria-label="Confirmar nuevo reporte ciudadano"
        >
          <ConfirmationScreen
            draft={reportDraft}
            onBack={() => setScreen("details")}
            onEditType={() => {
              setSelectedCategory(reportDraft.category)
              setScreen("report")
            }}
            onEditDetails={() => setScreen("details")}
            onSubmit={() => setScreen("success")}
          />
        </section>
      </main>
    )
  }

  if (screen === "details") {
    return (
      <main className="app-shell">
        <section
          className="phone-app report-phone details-phone"
          aria-label="Detalles del nuevo reporte ciudadano"
        >
          <DetailsScreen
            initialDraft={reportDraft}
            onBack={() => setScreen("report")}
            onContinue={(draft) => {
              setReportDraft(draft)
              setScreen("confirmation")
            }}
            onNotice={showNotice}
          />
          {notice && (
            <div className="toast report-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  if (screen === "report") {
    return (
      <main className="app-shell">
        <section
          className="phone-app report-phone"
          aria-label="Crear un nuevo reporte ciudadano"
        >
          <ReportScreen
            initialCategory={selectedCategory}
            onBack={() => {
              setScreen("home")
              setActiveTab("Inicio")
            }}
            onContinue={(category) => {
              setSelectedCategory(category)
              setReportDraft((current) => ({ ...current, category }))
              setScreen("details")
            }}
          />
          {notice && (
            <div className="toast report-toast" role="status">
              {notice}
            </div>
          )}
        </section>
      </main>
    )
  }

  return (
    <main className="app-shell">
      <section
        className="phone-app"
        aria-label="Inicio de Reporte Ciudadano Cuautla"
      >
        <div className="hero">
          <img
            className="hero-landscape"
            src="/cuautla-cityscape-header.webp"
            alt=""
            aria-hidden="true"
          />
          <header className="brand-row">
            <div className="brand">
              <span className="brand-mark">
                <Sticker name="shield-header" />
              </span>
              <div>
                <p className="eyebrow">Municipio de Cuautla</p>
                <p className="brand-name">Cuautla Segura</p>
              </div>
            </div>
            <button
              className="notification-button"
              onClick={() => {
                setScreen("notifications")
              }}
              aria-label={`Ver notificaciones: ${unreadNotificationCount} no leídas`}
            >
              <Sticker name="bell-header" />
              {unreadNotificationCount > 0 && (
                <span className="notification-dot">
                  {unreadNotificationCount}
                </span>
              )}
            </button>
          </header>

          <div className="welcome">
            <p>Hola, Iker</p>
            <h1>Tu voz mejora nuestra ciudad</h1>
          </div>
        </div>

        <div className="content">
          <button className="location-card" onClick={() => setScreen("zone")}>
            <span className="location-icon">
              <Sticker name="pin" />
            </span>
            <span className="location-copy">
              <span>Tu ubicación</span>
              <strong>{userZone.address}</strong>
            </span>
            <Icon name="chevron" size={22} strokeWidth={2.4} />
          </button>

          <div className="primary-grid">
            <button
              className="primary-card report-card"
              onClick={() => setScreen("report")}
            >
              <span className="primary-icon">
                <Sticker name="megaphone-white" />
              </span>
              <span className="primary-text">
                <strong>Realizar reporte</strong>
                <span>Comparte lo que ves</span>
              </span>
              <span className="arrow-button">
                <Icon name="chevron" size={19} strokeWidth={2.6} />
              </span>
            </button>

            <button
              className="primary-card map-card"
              onClick={() => {
                setActiveTab("Mapa")
                setScreen("map")
              }}
            >
              <span className="primary-icon">
                <Sticker name="map-white" />
              </span>
              <span className="primary-text">
                <strong>Mapa de reportes</strong>
                <span>Consulta en tu zona</span>
              </span>
              <span className="arrow-button">
                <Icon name="chevron" size={19} strokeWidth={2.6} />
              </span>
            </button>
          </div>

          <div className="secondary-grid">
            <button
              className="secondary-card reports-card"
              onClick={() => setScreen("reports")}
            >
              <span className="secondary-icon">
                <Sticker name="reports" />
              </span>
              <strong>Mis reportes</strong>
              <span>Ver seguimiento</span>
            </button>
            <button
              className="secondary-card alerts-card"
              onClick={() => setScreen("alerts")}
            >
              <span className="secondary-icon">
                <Sticker name="bell" />
              </span>
              <strong>Alertas</strong>
              <span>De tu comunidad</span>
            </button>
            <button
              className="secondary-card emergency-card"
              onClick={() => setScreen("contacts")}
            >
              <span className="secondary-icon">
                <Sticker name="emergency" />
              </span>
              <strong>Emergencias</strong>
              <span>Llama o envía SOS</span>
            </button>
          </div>
        </div>

        <nav className="bottom-nav" aria-label="Navegación principal">
          {navItems.map((item) => {
            const isActive = activeTab === item.label
            return (
              <button
                className={`${isActive ? "active" : ""} ${
                  item.label === "Reportar" ? "create-nav" : ""
                }`}
                key={item.label}
                onClick={() => {
                  setActiveTab(item.label)
                  if (item.label === "Reportar") {
                    setScreen("report")
                  } else if (item.label === "Mapa") {
                    setScreen("map")
                  } else if (item.label === "Actividad") {
                    setActivityUnreadOnly(false)
                    setScreen("activity")
                  } else if (item.label === "Perfil") {
                    setScreen("profile")
                  } else if (item.label !== "Inicio") {
                    showNotice(`${item.label}: sección en preparación`)
                  }
                }}
              >
                <span
                  className={`nav-icon ${
                    item.label === "Actividad" ? "alert-nav-icon" : ""
                  }`}
                >
                  <Sticker name={item.sticker} />
                  {item.label === "Actividad" && unreadActivityIds.size > 0 && (
                    <span className="nav-alert-badge">
                      {unreadActivityIds.size}
                    </span>
                  )}
                </span>
                <span>{item.label}</span>
              </button>
            )
          })}
        </nav>

        {notice && (
          <div className="toast" role="status">
            {notice}
          </div>
        )}
      </section>
    </main>
  )
}
