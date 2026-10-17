# Atlas de diagramas — Reporte Ciudadano

> Instantánea histórica. Las novedades de roles y geocodificación del 15 de octubre están en [el registro actual](../cierre-piloto-2026-10-15.md); aún no figuran en estos diagramas.

Fecha de documentación: 6 de octubre de 2026. Fuente: código y migraciones del checkout local. No es una inspección del estado remoto de Supabase.

Piloto de Cuautla, Morelos, sin atención municipal real y con identidad exclusivamente sintética. Los diagramas conceptuales simplifican la implementación; los diagramas ER y el diccionario se extraen del SQL. Las tablas auth/storage/cron/vault son administradas por Supabase y no se detallan como si pertenecieran al esquema propio.

No se presentan como implementados OCR real, FCM, Realtime, geocodificación de direcciones, SLA operativo ni hosting público. Existen tablas para algunas capacidades futuras, lo que no implica que sus pantallas y procesos estén completos.

## Entregables

- `index.html`: visor local sin CDN, con búsqueda, filtros, zoom y descarga SVG. Abrir después de generar los SVG.
- `atlas.md`: todos los diagramas editables en bloques Mermaid, visibles también en GitHub.
- `fuentes/`: un archivo Mermaid por diagrama.
- `svg/`: figuras vectoriales para documentos, presentaciones e impresión.
- `diccionario.md` y `schema.json`: 25 tablas de aplicación, columnas, claves y nulabilidad. No contienen registros de usuarios.

## Regeneración

Desde la raíz: `node scripts/diagram-schema.mjs` y `python scripts/generate-diagrams.py`. El extractor procesa CREATE TABLE y ALTER TABLE ADD COLUMN/ADD CONSTRAINT de las migraciones actuales; no ejecuta SQL ni reconstruye cambios dinámicos futuros. Los índices parciales, CHECK, valores por defecto y lógica de triggers permanecen en las migraciones originales. Revisar el extractor al introducir otros tipos de ALTER.

Renderizar con Mermaid CLI 12.0.0 usando `atlas.md` como entrada y `svg/atlas.svg` como salida; produce `atlas-1.svg`, `atlas-2.svg`, etc. Mantener el orden del catálogo. La CLI puede utilizar un navegador local mediante configuración Puppeteer. No requiere API ni servicio de pago. Las tablas muy grandes se consultan mejor en SVG con zoom o en las fichas individuales.

Los diagramas de actividad, casos de uso, componentes y despliegue emplean notación Mermaid equivalente y no afirman conformidad gráfica estricta con todas las notaciones UML 2.x. Clases, secuencias y estados usan sus tipos Mermaid específicos.

## Índice
- [01-contexto · Contexto del sistema](fuentes/01-contexto.mmd) · [SVG](svg/atlas-1.svg)
- [02-contenedores · Contenedores y canales reales](fuentes/02-contenedores.mmd) · [SVG](svg/atlas-2.svg)
- [03-componentes-flutter · Componentes de la app ciudadana](fuentes/03-componentes-flutter.mmd) · [SVG](svg/atlas-3.svg)
- [04-componentes-admin · Componentes del panel](fuentes/04-componentes-admin.mmd) · [SVG](svg/atlas-4.svg)
- [05-despliegue · Despliegue actual y distribución](fuentes/05-despliegue.mmd) · [SVG](svg/atlas-5.svg)
- [06-casos-uso · Casos de uso y actores](fuentes/06-casos-uso.mmd) · [SVG](svg/atlas-6.svg)
- [07-clases-autenticacion · Clases de autenticación Flutter](fuentes/07-clases-autenticacion.mmd) · [SVG](svg/atlas-7.svg)
- [08-clases-reportes · Clases del módulo de reportes](fuentes/08-clases-reportes.mmd) · [SVG](svg/atlas-8.svg)
- [09-estados-sesion · Estados de sesión](fuentes/09-estados-sesion.mmd) · [SVG](svg/atlas-9.svg)
- [10-secuencia-registro · Registro y perfil](fuentes/10-secuencia-registro.mmd) · [SVG](svg/atlas-10.svg)
- [11-actividad-crear · Actividad: crear reporte](fuentes/11-actividad-crear.mmd) · [SVG](svg/atlas-11.svg)
- [12-secuencia-envio · Envío de reporte y evidencia](fuentes/12-secuencia-envio.mmd) · [SVG](svg/atlas-12.svg)
- [13-estados-reporte · Máquina de estados del reporte](fuentes/13-estados-reporte.mmd) · [SVG](svg/atlas-13.svg)
- [14-secuencia-admin · Actualización administrativa y concurrencia](fuentes/14-secuencia-admin.mmd) · [SVG](svg/atlas-14.svg)
- [15-secuencia-notificaciones · Notificaciones internas](fuentes/15-secuencia-notificaciones.mmd) · [SVG](svg/atlas-15.svg)
- [16-secuencia-foto · Acceso privado a fotografías](fuentes/16-secuencia-foto.mmd) · [SVG](svg/atlas-16.svg)
- [17-identidad-sintetica · Estados de identidad sintética](fuentes/17-identidad-sintetica.mmd) · [SVG](svg/atlas-17.svg)
- [18-purga · Purga programada de archivos](fuentes/18-purga.mmd) · [SVG](svg/atlas-18.svg)
- [19-autorizacion · Decisión de autorización](fuentes/19-autorizacion.mmd) · [SVG](svg/atlas-19.svg)
- [20-navegacion · Navegación ciudadana](fuentes/20-navegacion.mmd) · [SVG](svg/atlas-20.svg)
- [21-ubicacion · Selección de ubicación](fuentes/21-ubicacion.mmd) · [SVG](svg/atlas-21.svg)
- [22-flujo-datos · Flujo de datos de nivel 1](fuentes/22-flujo-datos.mmd) · [SVG](svg/atlas-22.svg)
- [23-limites-confianza · Límites de confianza](fuentes/23-limites-confianza.mmd) · [SVG](svg/atlas-23.svg)
- [24-colaboracion · Colaboración y validación](fuentes/24-colaboracion.mmd) · [SVG](svg/atlas-24.svg)
- [25-er-general · Modelo entidad-relación general](fuentes/25-er-general.mmd) · [SVG](svg/atlas-25.svg)
- [26-er-acceso · Identidad de usuario y permisos](fuentes/26-er-acceso.mmd) · [SVG](svg/atlas-26.svg)
- [27-er-catalogos · Catálogos y configuración](fuentes/27-er-catalogos.mmd) · [SVG](svg/atlas-27.svg)
- [28-er-reportes · Reportes y seguimiento](fuentes/28-er-reportes.mmd) · [SVG](svg/atlas-28.svg)
- [29-er-identidad · Verificación sintética y consentimiento](fuentes/29-er-identidad.mmd) · [SVG](svg/atlas-29.svg)
- [30-er-avisos · Avisos, auditoría y reservas](fuentes/30-er-avisos.mmd) · [SVG](svg/atlas-30.svg)
- [31-tabla-public-municipalities · public.municipalities](fuentes/31-tabla-public-municipalities.mmd) · [SVG](svg/atlas-31.svg)
- [32-tabla-public-profiles · public.profiles](fuentes/32-tabla-public-profiles.mmd) · [SVG](svg/atlas-32.svg)
- [33-tabla-public-roles · public.roles](fuentes/33-tabla-public-roles.mmd) · [SVG](svg/atlas-33.svg)
- [34-tabla-public-permissions · public.permissions](fuentes/34-tabla-public-permissions.mmd) · [SVG](svg/atlas-34.svg)
- [35-tabla-public-role_permissions · public.role_permissions](fuentes/35-tabla-public-role_permissions.mmd) · [SVG](svg/atlas-35.svg)
- [36-tabla-public-user_roles · public.user_roles](fuentes/36-tabla-public-user_roles.mmd) · [SVG](svg/atlas-36.svg)
- [37-tabla-public-priorities · public.priorities](fuentes/37-tabla-public-priorities.mmd) · [SVG](svg/atlas-37.svg)
- [38-tabla-public-report_statuses · public.report_statuses](fuentes/38-tabla-public-report_statuses.mmd) · [SVG](svg/atlas-38.svg)
- [39-tabla-public-departments · public.departments](fuentes/39-tabla-public-departments.mmd) · [SVG](svg/atlas-39.svg)
- [40-tabla-public-zones · public.zones](fuentes/40-tabla-public-zones.mmd) · [SVG](svg/atlas-40.svg)
- [41-tabla-public-categories · public.categories](fuentes/41-tabla-public-categories.mmd) · [SVG](svg/atlas-41.svg)
- [42-tabla-public-subcategories · public.subcategories](fuentes/42-tabla-public-subcategories.mmd) · [SVG](svg/atlas-42.svg)
- [43-tabla-public-settings · public.settings](fuentes/43-tabla-public-settings.mmd) · [SVG](svg/atlas-43.svg)
- [44-tabla-public-consents · public.consents](fuentes/44-tabla-public-consents.mmd) · [SVG](svg/atlas-44.svg)
- [45-tabla-public-identity_verifications · public.identity_verifications](fuentes/45-tabla-public-identity_verifications.mmd) · [SVG](svg/atlas-45.svg)
- [46-tabla-public-reports · public.reports](fuentes/46-tabla-public-reports.mmd) · [SVG](svg/atlas-46.svg)
- [47-tabla-public-report_images · public.report_images](fuentes/47-tabla-public-report_images.mmd) · [SVG](svg/atlas-47.svg)
- [48-tabla-public-report_status_history · public.report_status_history](fuentes/48-tabla-public-report_status_history.mmd) · [SVG](svg/atlas-48.svg)
- [49-tabla-public-report_assignments · public.report_assignments](fuentes/49-tabla-public-report_assignments.mmd) · [SVG](svg/atlas-49.svg)
- [50-tabla-public-report_comments · public.report_comments](fuentes/50-tabla-public-report_comments.mmd) · [SVG](svg/atlas-50.svg)
- [51-tabla-public-notifications · public.notifications](fuentes/51-tabla-public-notifications.mmd) · [SVG](svg/atlas-51.svg)
- [52-tabla-public-audit_logs · public.audit_logs](fuentes/52-tabla-public-audit_logs.mmd) · [SVG](svg/atlas-52.svg)
- [53-tabla-public-sla_rules · public.sla_rules](fuentes/53-tabla-public-sla_rules.mmd) · [SVG](svg/atlas-53.svg)
- [54-tabla-private-identity_documents · private.identity_documents](fuentes/54-tabla-private-identity_documents.mmd) · [SVG](svg/atlas-54.svg)
- [55-tabla-private-report_uploads · private.report_uploads](fuentes/55-tabla-private-report_uploads.mmd) · [SVG](svg/atlas-55.svg)
