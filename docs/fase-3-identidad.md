# Fase 3 — piloto de identidad con muestras sintéticas

## Alcance aprobado

El usuario eligió pruebas sintéticas porque aún no hay aviso de privacidad aprobado, plazo para INE reales ni responsable de revisión. **No se admite cámara, galería ni documentos personales.** El servidor acepta únicamente los dos PNG incluidos, verificando tamaño y SHA-256. Son tarjetas que dicen MUESTRA SINTÉTICA, NO ES UNA INE y SIN VALIDEZ, sin campos personales.

El flujo utiliza Supabase real: Auth, PostgreSQL, Storage privado y dos Edge Functions. No se contrató OCR, proveedor de identidad, hosting ni otro servicio de pago. Se reutiliza el proyecto Free.

## Probar en la aplicación

1. Abrir http://127.0.0.1:3000/ con el servidor local activo. Iniciar sesión y completar el perfil de Cuautla si todavía falta.
2. Entrar en **Probar identidad con muestras sintéticas**.
3. Leer y aceptar el consentimiento de prueba `synthetic-v1`.
4. Cargar frente y reverso con los botones de muestras. No se pide ni permite seleccionar una INE.
5. Enviar a revisión. El estado será **En revisión de prueba**. El perfil real permanece PENDING.
6. Actualizar estado para consultar la solicitud. Las imágenes vencen a las 24 horas, con purga cada 15 minutos y 10 minutos de margen para cargas en tránsito: normalmente se eliminan entre 24 h 10 min y 24 h 25 min. Un fallo externo puede retrasar la eliminación; el acceso queda bloqueado desde el vencimiento y el job reintenta.

Ejecutar la vista web según [guía de fase 2](fase-2-autenticacion.md). Para reconstruir:

```powershell
cd apps/mobile
flutter pub get
flutter test --concurrency=1
flutter build web --no-pub --dart-define-from-file=config/pilot.json --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none
cd ../..
node scripts/serve-mobile.mjs
```

## Seguridad y funcionamiento

- La Edge Function verifica el JWT con `Auth.getUser`; la RPC comprueba además `auth.sessions`, correo confirmado, perfil y municipio activos. No confía en UUID de actor enviados por el cliente.
- `identity_pilot_service` solo permite ejecución a service_role. Los clientes no pueden saltarse la comprobación de bytes de la Edge Function.
- El consentimiento se registra con cuenta, municipio, versión y hora del servidor. Es exclusivo de pruebas, no autoriza tratamiento de INE reales.
- Una solicitud activa por cuenta; máximo tres solicitudes al día. Los reintentos no duplican solicitudes ni consentimientos.
- Storage permanece privado sin permisos directos de cliente. Los archivos son inmutables y no se guardan URLs permanentes.
- `identity.read` permite un enlace de 60 segundos con auditoría. `identity.review` y `identity.read` son necesarios para decidir; no hay autoaprobación. No se asignaron esos permisos a nadie.
- Aprobar una simulación conserva UNDER_REVIEW y registra `simulation_approved`. Nunca produce VERIFIED ni modifica la identidad real del perfil.
- `OcrProvider` está separado de `IdentityVerificationProvider`. `DisabledOcrProvider` no extrae campos; `ManualPilotProvider` devuelve revisión pendiente. No se presenta OCR como autenticidad ni hay proveedor real integrado.
- La purga usa Storage API antes de marcar documentos eliminados. Una credencial exclusiva generada en Vault protege el endpoint; no llega a Flutter. El job ejecuta cuatro solicitudes por hora, dentro de la infraestructura gratuita existente.
- `verify_jwt=false` en las funciones es deliberado: identity-pilot valida el JWT dentro del código, y identity-purge valida su token independiente con una RPC restringida. Ninguna función acepta acceso anónimo a datos.

## Validación realizada el 24 de septiembre de 2026

- 12/12 aserciones pgTAP nuevas aprobadas en Supabase remoto, dentro de una transacción con rollback.
- 6/6 pruebas Node: huellas digitales, archivo modificado, lado arbitrario, límites de bytes, JSON y separación OCR/verificación.
- 10/10 pruebas Flutter, incluyendo consentimiento obligatorio y ausencia de cámara real.
- `dart analyze`: sin incidencias después de ajustes de formato.
- `deno check`: ambas Edge Functions verificadas, SDK fijado en 2.57.4.
- `plpgsql_check`: sin diagnósticos de funciones no-trigger.
- Prueba HTTP con cuenta temporal real: login, inicio, rechazo de archivo no autorizado, carga privada de ambos lados, envío a revisión, rechazo de lectura ciudadana y autoaprobación, cierre de sesión y rechazo del token revocado.
- Purga HTTP real: status 200, removed=1, failed=0; solicitud EXPIRED y cero archivos restantes. Se eliminaron solo cuenta, municipio y metadatos temporales de esa prueba.
- Migraciones alineadas con Supabase; tipos TypeScript regenerados.

El asesor de seguridad informa dos condiciones conocidas: [RLS sin políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) en `private.identity_documents`, intencional para denegar todo acceso cliente; y [protección de contraseñas filtradas desactivada](https://supabase.com/docs/guides/database/database-linter?lint=auth_leaked_password_protection), función que el panel reserva a Pro. No se cambia de plan. El asesor de rendimiento solo informa índices sin uso esperables sin tráfico.

## Archivos y mantenimiento

- `supabase/migrations/20260924170343_phase3_synthetic_identity.sql`: consentimiento, solicitudes sintéticas, autorización, documentos y purga.
- `supabase/migrations/20260924170542_phase3_purge_schedule.sql`: Vault y programación del proyecto remoto.
- `supabase/functions/identity-pilot`: API y adaptadores.
- `supabase/functions/identity-purge`: eliminación por Storage API.
- `supabase/tests/database/004_identity.test.sql`: seguridad transaccional.
- `scripts/identity/core.test.mjs`: pruebas de contenido.
- `scripts/identity/http-e2e.mjs`: requiere credencial de fixture temporal generada exclusivamente para la prueba; no usar cuentas reales. La credencial utilizada se eliminó al finalizar.

La migración de programación está destinada a este proyecto remoto; antes de aplicarla en un entorno local, desactivar el job o sustituir el destino para no invocar el proyecto remoto. Nunca copiar credenciales del Vault a archivos de cliente. Consultar ejecución del job en Cron y errores en Edge Functions sin registrar documentos, JWT ni URLs firmadas.

## Pendiente para INE reales

Aviso aprobado y finalidad, plazo institucional, responsable con permisos explícitos, mecanismo de verificación autorizado, revisión de captura/calidad en dispositivos y pruebas de retención/consentimiento reales. La cámara nativa, OCR real, autenticidad documental y panel administrativo no se presentan como terminados. Esta entrega completa exclusivamente el alcance sintético solicitado. No se inició la fase 4.
