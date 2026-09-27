# Storage privado

## report-evidence

Bucket privado, máximo 10 MiB por objeto, MIME JPEG/PNG/WebP. Path previsto: `{municipality_id}/{report_id}/{image_uuid}.{ext}`. PostgreSQL almacena path, MIME, bytes y relación, nunca binarios ni URLs firmadas persistentes.

La política SELECT requiere coincidencia exacta entre `storage.objects.name` y `report_images.storage_path`, más autorización sobre el reporte. No basta conocer el UUID ni escribir un prefijo ajeno. En fase 1 no se admiten INSERT/UPDATE/DELETE por clientes. Los tests usan solo metadatos transaccionales, no objetos reales.

En fase 4 el servidor comprobará propietario, reporte editable, cantidad máxima municipal, bytes reales/MIME/extensión/dimensiones y eliminará EXIF sensible. Usará staging privado y promoverá el archivo validado de forma controlada; la evidencia enviada no podrá sobrescribirse. La subida no recibirá privilegios service role en el cliente. La retención requiere `evidence_retention_days` institucional y un proceso auditable de purga.

## identity-documents

Bucket privado, máximo 10 MiB, JPEG/PNG. Path previsto: `{municipality_id}/{user_id}/{verification_id}/{document_uuid}.{ext}`. No hay políticas de cliente de lectura ni escritura en fase 1. En fase 3 un endpoint comprobará consentimiento vigente, identidad de usuario, finalidad, plazo configurado y calidad del documento antes de aceptar la captura.

Lecturas futuras: endpoint con `identity.read`, autorización municipal y auditoría emite URL firmada de máximo 60 segundos. Estas URLs son credenciales temporales: no guardarlas en logs ni en tablas públicas. La retención usa `identity_retention_days`, `document_delete_after` y `documents_deleted_at`; el plazo queda NULL hasta decisión institucional. Con plazo sin configurar el futuro endpoint debe rechazar capturas.

## Retención pendiente de fase 3

Los campos de retención están creados; **todavía no existe un job de eliminación**. La fase 1 no admite cargas de documentos, por lo que no se presenta la retención como operativa. El job posterior eliminará bytes por Storage API y después actualizará metadatos, con reintentos e idempotencia. No borrar únicamente filas de storage.objects: dejaría archivos huérfanos.

Referencias oficiales: [control de acceso](https://supabase.com/docs/guides/storage/security/access-control), [esquema Storage](https://supabase.com/docs/guides/storage/schema/design).

## Actualización de fase 3 sintética

identity-pilot acepta únicamente dos muestras PNG identificadas por SHA-256. Conserva rutas en private.identity_documents. identity-purge elimina bytes mediante Storage API y después marca metadatos; job activo cada 15 minutos. No se admiten documentos reales. Ver fase-3-identidad.md para retención, pruebas y alcance.

