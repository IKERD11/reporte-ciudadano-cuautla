# Conexión verificada entre app y dashboard

Verificada el 23 de noviembre de 2026 sobre el proyecto Supabase existente
`mnjphahyqmwrvlaephla`. No se modificó el esquema ni se ampliaron permisos.

## Flujo de datos

La app Flutter utiliza `SupabaseReportRepository`, que envía los reportes a la
Edge Function `report-pilot`. Esta valida la sesión y llama a
`report_pilot_service`, que guarda reportes, ubicaciones e historial en PostgreSQL.

El dashboard Next.js consulta y modifica esos mismos registros mediante
`admin_pilot`. Los cambios de estado generan eventos por los triggers existentes.
La app consulta su historial mediante `report-pilot` y sus avisos mediante
`citizen_notifications`. Las fotografías usan el bucket privado `report-evidence`
y enlaces temporales; no se publicaron permisos nuevos para esos archivos.

La configuración local de ambas aplicaciones y los archivos publicados del
dashboard apuntan al mismo proyecto. La demostración continúa deshabilitada en
la compilación pública.

## Mejora implementada

Antes, el panel recargaba los reportes al entrar o al pulsar Actualizar. Ahora
Resumen, Reportes, Mapa y Métricas también se actualizan cada 30 segundos y al
recuperar visibilidad, foco o conexión. Se conservan filtros y página actual.
Las consultas se omiten si la pestaña está oculta o hay una operación en curso;
el sincronizador no inicia dos consultas automáticas simultáneas.

El detalle editable no se recarga automáticamente para evitar reemplazar cambios
sin guardar. Equipos y Configuración mantienen sus mecanismos actuales de carga.
Es actualización periódica mediante las RPC autorizadas, no una suscripción
Realtime. La app sigue consultando los cambios al abrir o recargar sus vistas.

## Evidencia

- 29/29 comprobaciones de administración: permisos, transiciones, asignaciones,
  versiones concurrentes, historial y sesiones revocadas.
- 41/41 comprobaciones de notificaciones y administración.
- 53/53 comprobaciones de equipos, exportaciones y notificaciones.
- 21/21 comprobaciones nuevas de integración: creación por el servicio ciudadano,
  aparición en dashboard y métricas, revisión, validación, asignación, atención,
  resolución, lectura por la app, historial y avisos. También se rechazaron accesos
  de otro ciudadano. Todas estas pruebas SQL terminan con rollback.
- Prueba HTTP autenticada contra los servicios desplegados: CORS del origen
  público, creación por Edge Function, reintento sin duplicación, consulta en
  dashboard y métricas, cambio a En revisión y Rechazado, lectura desde el servicio
  de la app y tres avisos asociados. Se usaron dos cuentas sintéticas distintas
  con rol municipal; la restricción de cuentas ciudadanas se probó en SQL.
- El reporte HTTP sintético y sus registros relacionados se retiraron por UUID.
  La base conservó los cuatro reportes anteriores.
- 5/5 pruebas del panel, incluidas dos pruebas del sincronizador con temporizadores
  simulados, pestaña oculta, operaciones pendientes, reconexión y limpieza.
- Compilación estática de producción y validación TypeScript aprobadas.

Esto verifica contratos, permisos y servicios desplegados. No acredita GPS real,
captura de fotografías en un dispositivo ni todos los recorridos visuales de Flutter.

## Repetir las comprobaciones

```powershell
npm run test --prefix apps/admin
```

Ejecutar `supabase/tests/database/010_app_dashboard_integration.test.sql` con una
conexión autorizada a la base de pruebas; incluye fixtures aislados y rollback.
Las pruebas 006, 007 y 008 también usan sus propios fixtures transaccionales.

Para la comprobación HTTP, se requieren la configuración local de la app y las
credenciales locales de prueba existentes:

```powershell
node scripts/check-dashboard-app-http.mjs --write-test
```

Esta última prueba crea un reporte sintético nuevo; el indicador `--write-test`
es obligatorio. Guarda sus identificadores en
`tmp/dashboard-app-http-result.json`, excluido de Git, para retirarlo con una
conexión administrativa después de comprobarlo. No elimina reportes existentes
ni expone contraseñas o tokens. Cierra sus sesiones al terminar.
