# Fase 4 — reportes de prueba

El usuario autorizó reportes marcados PRUEBA PILOTO, sin atención municipal real, mientras la verificación de identidad continúa sintética. La implementación usa PostgreSQL/PostGIS, Auth, Storage privado y una Edge Function reales. No cambia ningún perfil a VERIFIED ni habilita reportes de operación real.

## Cómo probar

1. Abrir http://127.0.0.1:3000/ y recargar para obtener la nueva versión. La sesión web vive en memoria: puede ser necesario iniciar sesión otra vez.
2. Entrar en **Reportes de prueba · Crear y consultar** y después **Realizar reporte de prueba**.
3. Elegir una categoría. Baches y Alumbrado requieren foto; Recolección permite probar sin foto. Estas reglas se obtienen de Supabase.
4. Pedir GPS, tocar el mapa para colocar/mover el marcador o escribir coordenadas y pulsar Aplicar coordenadas. El centro inicial de Cuautla no se envía como ubicación hasta seleccionar un punto. Si se deniega GPS, la selección manual sigue disponible.
5. Añadir hasta tres fotos de objetos de prueba, sin personas, placas ni documentos. Se puede quitar una foto antes de enviar. La cámara del navegador depende del dispositivo; Galería abre su selector de archivos.
6. Describir el problema, llenar los campos adicionales y aceptar las condiciones del piloto. Revisar y enviar.
7. Comprobar folio, categoría, estado Recibido, prioridad, fotos privadas, ubicación y evento inicial en el historial. Actualizar o volver a Mis reportes. Los filtros se aplican en servidor y cada página contiene como máximo 20 reportes propios.

El límite es cinco reservas de envío por cuenta en 24 horas, incluso si una carga queda incompleta. Después de iniciar el envío, el formulario conserva el contenido y la misma clave para reintentar sin duplicados. Salir elimina el borrador de memoria; antes de crear otro tras un error de red, revisar Mis reportes. Persistencia offline corresponde a fase 7.

## Implementación y seguridad

- `report-pilot` verifica JWT mediante Auth.getUser. La RPC vuelve a verificar usuario confirmado, sesión activa, municipio y perfil activos. No usa permisos de user_metadata.
- `report_pilot_service` solo puede ejecutarse con service_role desde servidor. Las tablas mantienen RLS y los clientes no reciben INSERT/UPDATE/DELETE. Listado, detalle y firma de imágenes comprueban propietario y municipio.
- El servidor deriva ciudadano, municipio, prioridad y estado. El trigger genera el folio; la transacción registra reporte, imágenes, historial, consentimiento pilot-v1 y auditoría. Todos estos reportes llevan `is_pilot=true`, incluso para cuentas verificadas.
- `pg_jsonschema` valida los campos adicionales contra la configuración de categoría, que se conserva como snapshot. Flutter soporta texto, enteros/números, booleanos y opciones enumeradas; no se ofrecen esquemas de objetos anidados o listas en este piloto.
- La ubicación se valida como coordenadas geográficas y se guarda en geography(Point,4326), junto con referencia, precisión y fecha de captura. No se valida un perímetro municipal oficial: aún no se ha proporcionado ese polígono.
- Las fotos se comprimen en Flutter. El servidor acepta únicamente JPEG, comprueba tamaño y decodifica con límite de resolución y memoria. Recodifica solo píxeles para eliminar EXIF, comentarios y GPS incrustado. Máximo tres archivos, 700 KB cada uno, de 32 a 1600 píxeles por lado y hasta 2 megapíxeles. El nombre original no se conserva.
- Paths: `municipio/ciudadano/reserva/índice.jpg`. Las reservas ligan contenido y hashes a la clave idempotente; uploads inmutables, sin upsert. No se confirma el reporte si faltan objetos. Fotos servidas mediante URL firmada de 60 segundos. Las listas usan miniaturas decodificadas a menor tamaño, pero descargan el JPEG comprimido original; no existe un archivo thumbnail independiente.
- Las cargas sin reporte confirmado vencen a las 24 horas y se limpian por Storage API con el job existente de 15 minutos más un margen de 10 minutos. Las fotos de reportes confirmados se conservan para su consulta; **no están sujetas a la purga de 24 horas de INE sintética**. No usar contenido personal ni operación real hasta definir su retención institucional.
- No se contrata hosting, mapas comerciales, OCR, SMS ni otros servicios. Los límites gratuitos siguen aplicando. El servidor local no publica el sitio en internet.

## Mapas y permisos

Se usa flutter_map con las teselas estándar de OpenStreetMap para visualización interactiva del piloto, atribución visible y User-Agent de aplicación. El navegador mantiene su caché HTTP y el servidor local permite Referer de origen. No se descargan mapas offline ni se precargan ciudades. `MAP_TILE_URL` permite sustituir el proveedor al compilar. La disponibilidad de OSM es de mejor esfuerzo y requiere respetar su [política de teselas](https://operations.osmfoundation.org/policies/tiles/).

Android declara ubicación aproximada/precisa; iOS incluye descripciones para ubicación en uso, cámara y fotos. No se solicita GPS en segundo plano. La integración nativa está preparada pero Android/iOS y la recuperación de un selector de fotos interrumpido por el sistema todavía requieren validación en dispositivos. El piloto validado aquí es web local.

## Validación del 25 de septiembre de 2026

- 21/21 pruebas pgTAP de reportes en una transacción remota con rollback: sesión, permisos, consentimiento, formulario, coordenadas, idempotencia, aislamiento, foto obligatoria, carga incompleta y piloto deshabilitado.
- 4/4 pruebas Deno: recodificación y eliminación de comentarios, formatos inválidos, límites de tamaño/cuerpo, UUID.
- 10/10 pruebas Flutter previas y 4/4 nuevas: preparación de fotos, archivo inválido, serialización idempotente y categoría obligatoria.
- Análisis Dart de archivos nuevos sin incidencias; comprobación Deno de funciones aprobada.
- Prueba HTTP real con cuenta temporal aislada: login, categorías, rechazo de contenido falso, Storage privado, creación con folio, reintento sin duplicados, listado, detalle, URL firmada y sesión revocada.
- Purga HTTP real: 200, uploadsRemoved=1, failed=0, cero archivos de prueba restantes. Cuenta y municipio temporales eliminados; ninguna cuenta real modificada.
- Compilación web aprobada. No se ha validado la interacción del formulario completo en un dispositivo nativo.

Avisos conocidos del asesor: [RLS sin políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) para `private.identity_documents` y `private.report_uploads`, intencionalmente inaccesibles a clientes; [protección contra contraseñas filtradas desactivada](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), sin activar la función de pago. El asesor de rendimiento solo encontró índices aún sin uso; no se eliminaron por falta de tráfico.

## Ejecutar y mantener

```powershell
cd apps/mobile
flutter pub get
flutter test --concurrency=1
flutter build web --no-pub --dart-define-from-file=config/pilot.json --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none
cd ../..
node scripts/serve-mobile.mjs
```

Migraciones: `20260925174611_phase4_pilot_reports.sql` y `20260925174950_phase4_report_list_alias.sql`. La segunda corrige una ambigüedad detectada en pruebas; ambas están aplicadas en remoto. Los tipos TypeScript se regeneraron desde Supabase.

La carga real de INE sigue deshabilitada. No se implementó el dashboard ni transiciones administrativas de fase 5, Realtime/push de fase 6 ni sincronización offline de fase 7.
