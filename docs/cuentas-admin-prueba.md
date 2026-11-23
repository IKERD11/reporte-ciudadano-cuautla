# Seis cuentas de prueba del panel administrativo

Autorizadas para el piloto de Cuautla el 23 de noviembre de 2026. Todas tienen
el rol `MUNICIPAL_ADMIN`, limitado al municipio de Cuautla, Morelos. No son
superadministradores ni habilitan verificación de INE reales.

- `admin.prueba.01@example.test`
- `admin.prueba.02@example.test`
- `admin.prueba.03@example.test`
- `admin.prueba.04@example.test`
- `admin.prueba.05@example.test`
- `admin.prueba.06@example.test`

Son identidades sintéticas con correo confirmado para pruebas de contraseña;
`example.test` no recibe correo. No se envían invitaciones. Cada cuenta tiene
una contraseña aleatoria diferente, guardada fuera de Git en
`tmp/admin-test-accounts/credentials.json`. No publicar ese archivo ni el SQL
generado, que también contiene las contraseñas.

## Preparar y crear

Desde la raíz del repositorio:

```powershell
node scripts/admin-test-accounts.mjs prepare
```

Genera credenciales y `tmp/admin-test-accounts/provision.sql`, pero no conecta
ni modifica ninguna base. Aplicar ese SQL con una conexión administrativa
autorizada al proyecto de pruebas Reporte Ciudadano (`mnjphahyqmwrvlaephla`),
después de verificar el destino. Es aprovisionamiento explícito de fixtures,
no una migración automática ni parte del seed habitual.

El SQL usa el esquema Auth comprobado en este proyecto para insertar usuarios
con contraseñas bcrypt e identidades de correo, además de perfiles y roles.
Como el esquema Auth es administrado por Supabase, revisar compatibilidad
antes de reutilizarlo en otra versión. Toda la operación es transaccional:
si algún correo ya existe o la configuración es inválida, se aborta sin
sobrescribir contraseñas ni conceder permisos a usuarios existentes.

## Comprobar acceso

Con la configuración pública habitual en `apps/admin/.env.local`:

```powershell
node scripts/admin-test-accounts.mjs verify
```

Verifica las seis contraseñas contra Auth y consulta `admin_pilot` para validar
municipio, rol, permisos, resumen y listado. Cierra cada sesión de prueba y
no imprime contraseñas ni tokens. El panel local está en http://127.0.0.1:3001.

Los permisos se almacenan en `public.user_roles`; clonar el repositorio no
concede acceso. Para retirar estas cuentas, revocar sus sesiones y roles antes
de eliminarlas mediante la administración de Auth.

## Estado verificado

El 23 de noviembre de 2026 se crearon las seis cuentas en el proyecto indicado.
Las seis aprobaron inicio de sesión por contraseña, rol `MUNICIPAL_ADMIN`
exclusivo de Cuautla y consultas de contexto, resumen y listado de reportes.
Se cerraron las sesiones usadas en la comprobación. La sintaxis del SQL y
PL/pgSQL se validó con el parser PostgreSQL del repositorio.
