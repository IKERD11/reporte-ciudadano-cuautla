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
`example.test` no recibe correo. No se envían invitaciones.

## Credenciales de acceso

Correos y contraseñas incluidos por solicitud expresa del propietario el
23 de noviembre de 2026. Quienes tengan acceso al repositorio pueden usar
estas cuentas con permisos de administrador municipal de Cuautla.

### Cuenta 1

- Correo: `admin.prueba.01@example.test`
- Contraseña: `Rc!QiRqb655RxmDLQ7FBow1Y48Kq_2i559b9a`

### Cuenta 2

- Correo: `admin.prueba.02@example.test`
- Contraseña: `Rc!m32njnTTqaSDxQjGWOjYJBSp8tz-vVbX9a`

### Cuenta 3

- Correo: `admin.prueba.03@example.test`
- Contraseña: `Rc!x5I-Y_rDNrKFP9JWpftg291sfIKL014O9a`

### Cuenta 4

- Correo: `admin.prueba.04@example.test`
- Contraseña: `Rc!44ed5Gw-kmYx7jrmt5JWp1gQOuez3ziR9a`

### Cuenta 5

- Correo: `admin.prueba.05@example.test`
- Contraseña: `Rc!2mPhbejbfwRVnqIN0IWRd-LO4M2uaVYE9a`

### Cuenta 6

- Correo: `admin.prueba.06@example.test`
- Contraseña: `Rc!ni3_cVe4CJJaCfp1lwg1Z4usngc3gjDG9a`

La copia local permanece en `tmp/admin-test-accounts/credentials.json`.
El SQL generado permanece excluido de Git.

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
