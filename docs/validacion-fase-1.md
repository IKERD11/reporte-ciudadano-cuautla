# Fase 1 — validada en Supabase remoto

Proyecto: **Reporte Ciudadano**, organización **IKERD11's Org**, región **us-east-1**.
Referencia: `mnjphahyqmwrvlaephla`.
[Abrir Supabase](https://supabase.com/dashboard/project/mnjphahyqmwrvlaephla).

## Resultado

- Cuatro migraciones aplicadas y registradas: esquema, seguridad, Storage e índices de FK.
- 23 tablas de aplicación, las 23 con RLS habilitada.
- PostGIS 3.3 activo e índices geoespaciales presentes.
- **35/35 aserciones de RLS e integridad aprobadas.**
- **10/10 aserciones de Storage aprobadas.**
- Asesor de seguridad sin hallazgos.
- Análisis de funciones y triggers con plpgsql_check sin diagnósticos.
- Tipos generados desde la base en packages/shared/database.types.ts.
- Versiones locales de migraciones alineadas con el historial remoto.

Evidencia detallada: [phase1-test-results.json](phase1-test-results.json).

## Método y alcance

Pruebas ejecutadas mediante MCP execute_sql en transacciones con fixtures, roles authenticated/anon, resultados pgTAP y ROLLBACK. Al terminar se verificaron cero usuarios Auth, municipios, reportes y objetos Storage. Permanecen los catálogos estructurales de roles, permisos y estados. Las secuencias pueden tener huecos: PostgreSQL no revierte nextval.

Storage alojado añade un trigger que rechaza DELETE directo por SQL. La prueba admite rechazo 42501 o cero filas afectadas, nunca borrado efectivo. Solo se probaron metadatos temporales; validación binaria y cargas HTTP corresponden a fases 3 y 4.

El asesor de rendimiento ya no informa claves foráneas sin índice. Solo señala índices sin uso, esperable sin tráfico. [Criterios de revisión de Supabase](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index). Revaluar con carga real antes de eliminar índices.

Docker local sigue pendiente de reparación. No se ejecutaron db:reset/db:lint locales ni el workflow GitHub. Las migraciones, pruebas y análisis plpgsql_check sí se ejecutaron contra Supabase remoto real.

## Repetir

Local con Docker operativo:

```powershell
npm ci
npm run db:start
npm run db:reset
npm run db:syntax
npm run db:lint
npm run db:test
npm run db:types
```

Para preparar consultas transaccionales para MCP en una base de desarrollo vacía:

```powershell
node scripts/build-remote-tests.mjs
```

Ejecutar cada archivo generado completo mediante execute_sql. Incluye fixtures temporales y ROLLBACK; no extraer el seed ni quitar el rollback. El generador incluye una comprobación que rechaza bases con usuarios o municipios existentes.

La fase 2 no se inició. Las escrituras de clientes permanecen cerradas hasta incorporar sus flujos validados.
