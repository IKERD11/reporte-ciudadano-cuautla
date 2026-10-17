# Reporte Ciudadano

## Diagramas del proyecto

Consultar el [atlas técnico de 55 diagramas](docs/diagramas/README.md): arquitectura, UML de clases/secuencias/estados, casos de uso, actividades, navegación y modelo entidad-relación. Incluye 25 fichas de tablas, fuentes Mermaid, SVG y un visor HTML sin conexión. Basado en el código y las migraciones; distingue el piloto implementado de las funciones pendientes.

**Colaboradores:** empezar por [CONTRIBUTING.md](CONTRIBUTING.md), con instalación, configuración, pruebas y reglas del piloto. Las notificaciones de fase 6 están documentadas en [fase 6](docs/fase-6-notificaciones.md).

Estado actualizado al 16 de octubre: [lista de pendientes](PENDIENTES.txt) y [registro de comprobaciones](docs/cierre-piloto-2026-10-15.md).

## Qué falta desarrollar, corregir o retirar

**Actualizado al 16 de octubre de 2026:** consultar [PENDIENTES.txt](PENDIENTES.txt) para la lista de entrega y [evidencia de validación](docs/cierre-piloto-2026-10-15.md) para distinguir lo probado de lo pendiente. El sistema sigue en modalidad piloto; el alcance actual es web.

**Implementado:** reportes y avisos internos, búsqueda explícita por dirección con candidatos y marcador, administración de roles municipales existentes, auditoría y exportación CSV filtrada hasta 5,000 registros. También se corrigieron filtros de fechas, textos de notificaciones y acceso a demostración en producción. El procedimiento de respaldo está documentado, pero aún no se ha ensayado.

**Pendiente para cerrar el piloto web:**

- Comprobar GPS real, permisos y búsqueda autenticada con direcciones públicas de Cuautla. Las pruebas simuladas no sustituyen esta validación.
- Completar el recorrido en navegador ciudadano → administración → aviso, y revisar accesibilidad, tamaños, teclado, mapas, métricas y filtros con datos representativos.
- Reconstruir una base local limpia y ensayar respaldo/restauración, incluidos archivos de Storage. Docker local sigue sin estar disponible; nunca ejecutar un reset remoto.
- Publicar app y panel con costo cero, verificar configuración de autenticación y seguridad, y activar CI. Solo el atlas está publicado; CI sigue como plantilla.
- Actualizar atlas/PDF con geocodificación, caché y roles; revisar textos, enlaces y recursos antiguos sin eliminar pruebas o documentación útil.
- Revisar los avisos de seguridad conocidos: protección de contraseñas filtradas desactivada y denegación intencional de acceso directo a cuatro tablas privadas. No ampliar permisos para silenciar avisos.

Las pruebas automatizadas de base de datos y aplicaciones ya aprobadas se detallan en el registro de evidencia. No acreditan GPS real, reconstrucción limpia, restauración ni revisión visual completa.

**Pospuesto o condicionado al alcance:** Android/iOS por decisión del usuario; notificaciones con la app cerrada, roles personalizados e invitaciones por correo no implementados. Los avisos internos y los roles existentes sí están disponibles.

**Antes de operar realmente:** aprobar privacidad y términos, conservación de datos y responsables autorizados. Mantener bloqueadas las INE reales, datos sintéticos y etiquetas de piloto. No subir secretos, sesiones, respaldos privados, dependencias descargadas ni compilaciones.

**Piloto de Cuautla, Morelos: costo cero obligatorio.** Consultar [restricciones de presupuesto](docs/piloto-costo-cero.md) antes de configurar cualquier servicio.

Plataforma municipal con Flutter, Next.js y Supabase. **Fases 1 y 2 implementadas; fase 3 con muestras sintéticas y fase 4 con reportes de prueba y panel administrativo de fase 5 implementado para el piloto.** Flutter conecta al Supabase real. La captura de INE reales y la operación municipal siguen deshabilitadas.

**Estado:** consultar el [registro de cierre y validación](docs/cierre-piloto-2026-10-15.md) para la evidencia más reciente y las limitaciones. El asesor conserva avisos conocidos sobre tablas privadas sin políticas (denegación intencional) y protección de contraseñas filtradas desactivada. Dispositivos nativos y Docker local siguen pendientes.

## Diseño

Leer [arquitectura y fases](docs/arquitectura.md), [modelo de datos](docs/modelo-datos.md), [RLS](docs/seguridad.md), [Storage](docs/storage.md) y [contratos de Edge Functions](supabase/functions/README.md).

```text
apps/
  admin/                  Next.js en fase 5
  mobile/                 Flutter a partir de fase 2
packages/shared/          Tipos generados desde Supabase
supabase/
  config.toml             Entorno local PostgreSQL 17
  migrations/             Esquema, seguridad, Storage
  tests/database/         Pruebas pgTAP
  functions/              Contratos futuros
  seed.sql                Solo desarrollo
scripts/generate-types.mjs
docs/
.env.example
```

## Requisitos

Node.js LTS compatible con Supabase CLI, npm y Docker Desktop con motor Linux operativo. La CLI está fijada en package-lock.json y se instala localmente; no requiere instalación global. En Windows usar PowerShell. Se necesita internet y espacio para descargar las imágenes iniciales.

## Ejecutar fase 1

Desde la carpeta del proyecto:

```powershell
npm ci
docker info
npm run db:start
npm run db:status
Copy-Item .env.example .env
```

Copiar de `db:status` únicamente URL y clave pública al entorno de cliente. La clave service role es exclusiva del servidor y no es necesaria para los clientes. No compartir la salida completa de status porque puede contener claves locales.

Supabase Studio: http://127.0.0.1:54323. API: http://127.0.0.1:54321. PostgreSQL: puerto 54322. Estos endpoints no quedan operativos hasta que `db:start` termine correctamente. Auth, Storage y PostgreSQL se ejecutan en contenedores reales.

## Reconstruir y probar

`db:reset` **elimina y recrea solamente la base local de este proyecto**; se usa para fixtures reproducibles y nunca debe apuntarse a producción.

```powershell
npm run db:reset
npm run db:syntax
npm run db:lint
npm run db:test
npm run db:types
```

Las pruebas requieren el seed incluido. Se ejecutan en transacciones con rollback. El seed contiene dos municipios, tres ciudadanos, operador, administrador, supervisor y viewer del municipio A, un superadministrador y tres reportes sintéticos. Las cuentas fixture no tienen contraseña ni están listas para login: se usan para probar RLS; el registro real está implementado en Flutter (fase 2).

## Qué comprobar

1. Las nueve migraciones se aplican sin errores en una base limpia; la programación de purga requiere adaptar el destino remoto según la guía de fase 3.
2. `db:lint` no reporta errores ni advertencias.
3. `db:test` termina con todas las aserciones correctas: ciudadano A no lee B, operador A no lee municipio B, no se permite cambiar prioridad/estado ni autoverificarse, identidades sin permiso y datos anónimos están bloqueados.
4. Storage tiene ambos buckets privados; las pruebas confirman lectura solo de evidencia autorizada y bloqueo de carga, modificación, borrado y lectura directa de INE.
5. En Studio SQL ejecutar `select extensions.postgis_version();` y comprobar `reports_location_gist` y `zones_boundary_gist` en `pg_indexes`.
6. `db:types` genera `packages/shared/database.types.ts` desde el esquema real.

Studio usa privilegios administrativos: poder ver todos los reportes allí **no** prueba ni invalida RLS. Las pruebas cambian explícitamente a anon/authenticated para verificarlo.

## Detener

```powershell
npm run db:stop
```

## Remoto, build y deploy

Proyecto remoto de desarrollo: **Reporte Ciudadano**, referencia `mnjphahyqmwrvlaephla`, creado y migrado mediante MCP. Los nombres de archivo locales coinciden con el historial remoto. Para vincular la CLI en el futuro, ejecutar `npx supabase login`, `npx supabase link --project-ref mnjphahyqmwrvlaephla` y revisar `npx supabase db push --dry-run` antes de aplicar nuevos cambios. **No usar `--include-seed` fuera de desarrollo.** Configurar Auth, URLs de redirección, SMTP, secretos y políticas institucionales en sus fases. Este proyecto aún no está habilitado para operación municipal real.

Flutter ya tiene comandos de ejecución y build en [su guía](docs/fase-2-autenticacion.md). Next.js corresponde a fase 5. No se ha publicado en tiendas ni contratado hosting.

## Referencias

[Desarrollo local](https://supabase.com/docs/guides/local-development/cli-workflows), [migraciones](https://supabase.com/docs/guides/local-development/database-migrations), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [PostGIS](https://supabase.com/docs/guides/database/extensions/postgis).


## Fase 3 — pruebas sintéticas

Flujo de identidad con consentimiento, dos muestras privadas y purga automática desplegado. Las INE reales siguen bloqueadas por decisión del usuario. [Cómo probar y alcance exacto](docs/fase-3-identidad.md).

## Fase 4 — reportes de prueba

Autorizada expresamente por el usuario: categorías desde Supabase, ubicación GPS/manual, mapa, fotos privadas, descripción, formularios dinámicos, folio, idempotencia y consulta con paginación. Todo envío queda marcado como PRUEBA PILOTO y no modifica la identidad. [Guía y pruebas](docs/fase-4-reportes.md). El dashboard administrativo corresponde a la fase 5.



## Fase 5 — Panel administrativo

Panel local con acceso autorizado, resumen, tabla paginada, mapa, detalle, prioridad, estados, asignaciones y departamentos. [Guía y límites](docs/fase-5-administracion.md). Abrir http://127.0.0.1:3001 .
