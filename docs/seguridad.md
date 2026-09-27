# RLS y permisos

La fase 1 solo concede SELECT a authenticated. Anon no tiene privilegios sobre tablas de aplicación. RLS está habilitada en las 23 tablas públicas. No existe INSERT, UPDATE, DELETE ni RPC de escritura para clientes: un permiso registrado en `permissions` expresa una capacidad futura, no habilita una operación por sí solo.

## Alcance de cada rol

- **CITIZEN:** perfil propio activo, municipio y catálogos públicos activos, configuración no secreta, consentimientos propios, reportes propios, imágenes, historial y comentarios externos de esos reportes, notificaciones propias. No lee metadatos internos de identidad, roles ajenos, asignaciones internas ni auditoría. La aplicación consultará el estado de identidad en profiles.
- **OPERATOR:** lo anterior y reportes asignados activamente a su UUID, incluyendo notas y asignaciones de esos reportes. No basta compartir departamento. No ve INE ni el resto del municipio.
- **SUPERVISOR:** lectura por asignación igual que OPERATOR. Las capacidades de asignar y cerrar se reservan para RPC de fase 5. Una futura bandeja departamental necesitará membresías departamentales y políticas explícitas.
- **MUNICIPAL_ADMIN:** reportes completos de su municipio, perfiles municipales, catálogos y auditoría. No recibe `identity.read` ni `identity.review` automáticamente.
- **VIEWER:** lectura de reportes del municipio, incluida información interna operativa. Asignar este rol solo a personal autorizado para esa información; no es un rol público.
- **SUPER_ADMIN:** asignación global explícita y permisos registrados, incluyendo identidad. Solo procesos administrativos confiables pueden aprovisionarlo. Aun este rol no puede escribir directamente mediante Data API en fase 1.

Todos los accesos privados requieren perfil y municipio activos y perfil no eliminado. Los catálogos globales de roles, permisos y estados no contienen datos privados y son legibles por usuarios autenticados. Municipios desactivados dejan de ser legibles mediante los permisos de aplicación, incluido el superadministrador; el mantenimiento excepcional usa un proceso de servidor.

## Cómo se aplican

`private.is_member` comprueba perfil y municipio activos. `private.has_permission` une asignaciones, roles y permisos almacenados en BD: nunca confía en `user_metadata` del JWT. `private.can_read_report` autoriza propietario, lectura municipal completa o permiso más asignación activa. Son funciones SECURITY DEFINER pequeñas, con search_path vacío, referencias calificadas y EXECUTE limitado; el esquema private no se expone en la API. Evitan recursión de RLS al consultar roles/asignaciones.

Las relaciones con riesgo de cruce incluyen municipio en sus FK. Un rol global únicamente puede ser SUPER_ADMIN. El perfil administrativo tiene un único municipio en esta versión; incorporar membresías en varios municipios requiere una migración explícita.

## Escrituras y datos sensibles

En fases siguientes los RPC comprobarán permisos y validarán campos admitidos, identidad vigente y transición; ninguna autorización dependerá solo del frontend. Las funciones de servidor con service role deberán repetir autorización porque ese rol omite RLS. La tabla profiles no tiene passwords ni tokens. `settings` no admite secretos: contiene únicamente configuración visible al municipio.

Los documentos INE no se leen directamente desde Storage. Incluso un revisor con identity.read necesitará una función que registre la consulta y firme un acceso breve. `verification_metadata` está restringido a revisores; no guardar respuesta cruda OCR, CURP, domicilio completo ni imagen allí. Los metadatos son objetos JSON, pero su lista de campos admitidos se validará al integrar el proveedor.

`audit_logs`, `consents` e historial son inmutables para clientes. El trigger actual registra creación y cambios de estado con UUID y estado, sin descripción ni PII. Los eventos de prioridad, asignación y revisión se incorporarán con sus RPC. La cuenta postgres/service role sigue siendo privilegiada: RLS no sustituye proteger esas credenciales.

## Validación

Las pruebas pgTAP cambian a los roles PostgreSQL authenticated/anon y fijan auth.uid() dentro de una transacción, verificando la seguridad sin filtros de interfaz. Los cambios de fixtures se revierten al terminar. No prueban todavía login, firma de JWT, proveedor de identidad ni carga HTTP de archivos. Esas pruebas se añaden junto a cada integración.

## Escrituras de perfiles (fase 2)

Las funciones públicas list_registration_municipalities, complete_citizen_profile y update_my_profile son fachadas SECURITY INVOKER. Sus helpers privados SECURITY DEFINER tienen search_path vacío, permisos explícitos y validan correo confirmado, cuenta vigente, municipio activo y campos permitidos. Se serializa el alta por auth.users para que los reintentos no dupliquen roles. No hay INSERT/UPDATE directo en profiles. El registro queda cerrado por defecto por municipio; supabase/provisioning/cuautla.sql documenta la habilitación del piloto.

