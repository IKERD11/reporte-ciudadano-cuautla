# Fase 6 — Notificaciones del piloto

Implementada el 26 de septiembre de 2026. Avisos internos en la app ciudadana, sin SMS, correo ni push externos. No se contrataron servicios.

## Funcionamiento
- Recepción, cambios de estado y reasignaciones generan avisos en la misma transacción del reporte. Solo reportes is_pilot.
- La primera asignación genera el aviso de estado ASIGNADO, sin duplicar el aviso de equipo.
- Bandeja de 20 avisos por página, fecha local, distinción leído/no leído, actualización manual y acceso al detalle del reporte.
- Acuse individual idempotente. Contador en campana al abrir inicio, cambiar sección, regresar de bandeja/reportes o reanudar la app. Sin sondeo periódico.
- Los avisos empiezan con los eventos posteriores a la migración; no se inventa ni reconstruye historial de notificaciones anteriores.

## Seguridad y validación
RPC con identidad del JWT y sesión activa, usuario confirmado, perfil activo y municipio propio. No admite destinatarios proporcionados por el cliente. Tabla sin escritura ni lectura directa para anon/authenticated; RPC limita campos y pagina resultados. Funciones privilegiadas internas con search_path vacío. No se expone información interna de operadores.

Migración: 20260926170146_phase6_notifications.sql aplicada a Supabase.
Pruebas SQL: 007_notifications.test.sql, 41/41, fixtures sintéticos y rollback. Incluye flujo administrativo completo, aislamiento entre usuarios del mismo municipio, entre municipios, lectura idempotente y sesión revocada.
Pruebas Flutter: 17/17; pruebas nuevas de acuse único, paginación y recuperación tras error de red. Prueba de inicio repetida después de integrar actualización al reanudar: 1/1.

Advisors: sin nuevos hallazgos. Persisten dos INFO de tablas privadas con RLS sin políticas deliberadamente y el aviso previo de protección de contraseñas filtradas desactivada. Referencia: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Alcance pendiente
No son notificaciones del sistema operativo cuando la app está cerrada. Falta prueba manual con cuentas del piloto en dispositivos reales; no se usaron credenciales personales para validarla. La publicación pública y gestión avanzada de equipos/exportaciones siguen siendo fases posteriores.
