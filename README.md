# Reporte Ciudadano

**Colaboradores:** empezar por [CONTRIBUTING.md](CONTRIBUTING.md), con instalación, configuración, pruebas y reglas del piloto. Las notificaciones de fase 6 están documentadas en [fase 6](docs/fase-6-notificaciones.md).

## Qué falta desarrollar, corregir o retirar

El proyecto es un piloto en desarrollo, no una aplicación municipal terminada. Esta lista sirve como punto de partida para los colaboradores; no sustituye una revisión completa del código.

### App ciudadana (Flutter)

- **Corregir y comprobar la ubicación real:** el navegador integrado ha agotado el tiempo de espera. Se ajustó la solicitud y se probó con ubicaciones simuladas, pero falta validar permisos y captura real en navegadores y dispositivos. No dar este problema por resuelto solo porque pasan las pruebas.
- **Completar la búsqueda por dirección si se necesita un marcador automático:** actualmente escribir una dirección guarda texto; el marcador se coloca con GPS o tocando el mapa. No hay geocodificación implementada.
- **Revisar la interfaz en dispositivos reales:** tamaños de tarjetas, teclado, textos largos, accesibilidad, navegación inferior/lateral y tarjeta sobre el marcador con fotos reales del piloto. Los últimos ajustes tienen pruebas automatizadas, pero falta la validación manual completa.
- **Probar Android/iOS:** instalación, permisos, cámara, galería, GPS, autenticación y recuperación de cuenta. La versión web es la más trabajada.
- **Completar las notificaciones si el alcance lo requiere:** existen avisos internos; no hay notificaciones del sistema operativo con la app cerrada.

### Panel administrativo (Next.js)

- **Completar la gestión avanzada de equipos, roles y permisos**, y las exportaciones previstas; no confundir consultas y asignaciones existentes con un módulo completo de administración de personal.
- **Validar métricas y filtros** con conjuntos de prueba representativos: fechas, estados, reportes sin coordenadas, datos vacíos y cambios concurrentes.
- **Corregir textos desactualizados:** la configuración todavía indica “Notificaciones automáticas: Pendientes · Fase 6”, aunque los avisos internos de esa fase ya están implementados.
- **Revisar diseño adaptable y controles** en pantallas pequeñas: calendarios, tablas, menús, gráficas y formularios.

### Backend, seguridad y entrega

- Ejecutar el flujo completo ciudadano → administración → notificación con cuentas de prueba de distintos roles y municipios; comprobar aislamiento, sesiones revocadas, evidencias privadas y límites de uso.
- Verificar todas las migraciones desde una base local limpia y documentar respaldo/restauración y límites del plan gratuito. No ejecutar un reset contra el proyecto remoto.
- Revisar los avisos de seguridad conocidos y documentados, incluyendo protección de contraseñas filtradas desactivada; no cambiar políticas ni contratar funciones sin evaluar su efecto y costo.
- Preparar la publicación cuando corresponda: aún no hay despliegue público configurado por este repositorio. La plantilla de CI está en `docs/ci/`, sin activar.
- Para una futura operación real faltan aviso de privacidad y términos aprobados, política de conservación y responsables autorizados. Mientras tanto, mantener bloqueadas las INE reales y conservar la modalidad de prueba.

### Qué eliminar o sustituir antes de una entrega real

- **Retirar de la interfaz pública los accesos de demostración y ejemplos sintéticos**, o separarlos claramente en un entorno de demostración. El panel contiene un modo de diseño con datos ficticios.
- **Sustituir textos provisionales y documentación desactualizada**, así como enlaces o controles que una revisión funcional identifique como incompletos. No eliminar funciones útiles sin comprobar primero su uso.
- **Revisar capturas y recursos antiguos** en `docs/` y `assets/`; retirar solo los que no tengan referencias ni valor como documentación.
- **No eliminar fixtures ni pruebas necesarias para desarrollo.** Mantenerlos fuera de los datos operativos. No retirar las etiquetas de piloto hasta que exista autorización para operar realmente.
- **No subir secretos, sesiones, dependencias descargadas ni compilaciones** al repositorio. Se conservan plantillas y lockfiles para reconstruir el entorno.

Prioridad recomendada: ubicación real y revisión móvil → flujo completo y seguridad → funciones administrativas pendientes → documentación y limpieza → publicación. Todo el trabajo debe respetar el costo cero del piloto.

**Piloto de Cuautla, Morelos: costo cero obligatorio.** Consultar [restricciones de presupuesto](docs/piloto-costo-cero.md) antes de configurar cualquier servicio.

Plataforma municipal con Flutter, Next.js y Supabase. **Fases 1 y 2 implementadas; fase 3 con muestras sintéticas y fase 4 con reportes de prueba y panel administrativo de fase 5 implementado para el piloto.** Flutter conecta al Supabase real. La captura de INE reales y la operación municipal siguen deshabilitadas.

**Estado:** consultar [fase 4: ejecutar y probar](docs/fase-4-reportes.md) para la validación más reciente y las limitaciones. El asesor conserva avisos conocidos sobre tablas privadas sin políticas (denegación intencional) y protección de contraseñas filtradas desactivada. Dispositivos nativos y Docker local siguen pendientes.

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
