# Fase 2 — autenticación del piloto

Proyecto Supabase: `mnjphahyqmwrvlaephla`. Municipio: **Cuautla, Morelos**. Plan Free; no se contrataron servicios, dominios, SMS ni complementos de pago.

## Implementado

Flutter con registro por correo y contraseña, confirmación, login, recuperación, cierre global de sesión, alta y edición del perfil. Supabase Auth administra las credenciales. Android/iOS usan almacenamiento seguro para sesión y verificador PKCE. La vista web de desarrollo mantiene la sesión en memoria: recargar requiere entrar de nuevo; el verificador PKCE del SDK sí debe sobrevivir al regreso del enlace.

La cuenta confirmada selecciona únicamente municipios activos con registro habilitado. El servidor asigna CITIZEN, ignora roles o estados de identidad enviados en metadatos y no permite cambiar municipio ni reactivar perfiles suspendidos. Los permisos y el aislamiento RLS de fase 1 siguen vigentes. Alta y edición generan auditoría sin copiar datos personales.

INE, reportes y administración visual pertenecen a fases posteriores. La interfaz muestra explícitamente identidad pendiente. No hay usuarios de demostración permanentes ni contraseñas incluidas.

## Ejecutar

Requiere Flutter 3.38.5 / Dart 3.10.4 o versión compatible. En este equipo: `C:\src\flutter\bin\flutter.bat`.

```powershell
cd C:\Users\ikdop\Desktop\IS\apps\mobile
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat build web --dart-define-from-file=config/pilot.json
cd ..\..
node scripts/serve-mobile.mjs
```

Abrir **http://127.0.0.1:3000/**. El servidor escucha solo en el equipo local. Detener con Ctrl+C. La configuración contiene exclusivamente URL y clave publicable, diseñada para clientes; no contiene service_role ni secretos de administración.

Para desarrollo con Flutter web: `flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 --dart-define-from-file=config/pilot.json`. No ejecutar simultáneamente con el servidor Node en el mismo puerto.

Android: con SDK y dispositivo configurados, `flutter run -d <device-id> --dart-define-from-file=config/pilot.json`. Hay permiso de Internet, backup desactivado y callback nativo configurado. Este equipo tiene pendientes Android SDK Command-line Tools; la compilación y enlaces nativos se deben probar en dispositivo. iOS requiere macOS/Xcode; se incluyeron esquema y entitlements de Keychain, sin contratar distribución ni compilación remota.

## Configuración real de Supabase

- Site URL: `http://localhost:3000`.
- Redirect URLs exactas: `http://localhost:3000/`, `http://127.0.0.1:3000/`, `mx.reporteciudadano.piloto://auth/callback`.
- Correo activado, confirmación obligatoria, contraseña mínima 12 caracteres y cambio seguro de contraseña activado.
- Registro anónimo y teléfono desactivados. Plantillas y remitente incluidos del plan gratuito.
- Cuautla habilitado en `settings.citizen_registration_enabled`; los demás municipios permanecen cerrados por defecto.

El remitente de correo predeterminado de Supabase solo entrega a direcciones autorizadas del equipo de la organización y tiene una cuota reducida (habitualmente 2 correos/hora). No alcanza para un piloto ciudadano abierto. Para ampliar destinatarios habrá que elegir expresamente una alternativa que respete costo cero; no se desactiva la confirmación para eludir esa restricción. [Documentación de SMTP](https://supabase.com/docs/guides/auth/auth-smtp).

## Prueba manual pendiente con tu correo

1. Abre la aplicación local y crea una cuenta usando un correo autorizado del equipo y una contraseña de 12 caracteres o más. Introduce la contraseña tú mismo; no la compartas en el chat.
2. Abre el enlace recibido en el mismo navegador/dispositivo donde inició el registro. Si vence o cambias de dispositivo, solicita otro desde la aplicación.
3. Completa nombre, apellidos y selecciona Cuautla, Morelos. Comprueba que el perfil aparece con identidad pendiente.
4. Edita tu perfil, cierra sesión y vuelve a entrar. Los datos deben persistir en Supabase.
5. Usa «Olvidé mi contraseña», abre el enlace en el mismo navegador, guarda otra contraseña e inicia sesión de nuevo. Respeta el límite de correo; no envíes repetidamente.
6. Repite los callbacks con la app Android/iOS instalada antes de aprobar esa plataforma.

El cierre global revoca refresh tokens. Los access tokens ya emitidos pueden seguir válidos hasta su expiración (comportamiento de Supabase); no se promete revocación instantánea de todos los JWT.

## Validación automatizada del 23–24 de septiembre de 2026

- 22/22 pruebas nuevas pgTAP de autenticación y perfiles en PostgreSQL remoto.
- 35/35 de RLS e integridad y 10/10 de Storage repetidas sin regresiones.
- 9/9 pruebas Flutter de controlador y widgets: validación, confirmación, perfil, recuperación, cierre y respuestas tardías.
- `flutter analyze`: sin incidencias.
- `npm run db:syntax`: SQL y PL/pgSQL válidos.
- `plpgsql_check`: sin diagnósticos en funciones PL/pgSQL no-trigger de public/private.
- Asesor de seguridad Supabase: cero hallazgos.
- HTTP real: Auth exige confirmación; perfiles y RPC de registro rechazan acceso anónimo con 401.

Las pruebas SQL usan fixtures exclusivos y ROLLBACK. El 23 de septiembre se verificaron cero usuarios y perfiles después del rollback. El 24 de septiembre el usuario inició un registro desde la aplicación: hay una cuenta pendiente de confirmación y todavía ningún perfil. Cuautla permanece configurado. La entrega y apertura del correo siguen pendientes de comprobación; las pruebas automatizadas no envían correos. Pruebas del controlador usan dobles solo dentro de test; la app conecta al Supabase real.

Para repetir: `node scripts/build-auth-tests.mjs` prepara SQL transaccional para execute_sql; no retirar ROLLBACK. `node scripts/check-auth-http.mjs` ejecuta comprobaciones HTTP sin sesión ni envío de correos. Con Docker operativo: `npm run db:test` incluye las tres suites. El generador de regresiones de fase 1 rechaza bases con usuarios/reportes reales; permite configuración municipal existente.

## Roles administrativos

Los clientes no pueden asignar roles. Para habilitar un responsable en una fase posterior, verificar su cuenta confirmada y UUID en Auth y realizar una asignación explícita desde una operación de servidor autorizada. Nunca usar `raw_user_meta_data`, nombres o correo como prueba de privilegios. El registro ciudadano no entrega acceso administrativo.



Revisión del 24 de septiembre: la vista web actualizada abre el login y valida campos obligatorios. Se comprobó visualmente la pantalla de confirmación del registro iniciado por el usuario. El análisis final con dart analyze lib test terminó sin incidencias. Evidencia resumida: phase2-test-results.json.

Compilación web final aprobada: flutter build web terminó con código 0. Recursos CanvasKit locales y sin service worker para la vista de prueba.
