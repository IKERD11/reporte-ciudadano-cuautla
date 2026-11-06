# Diseño ciudadano publicado

La versión web canónica es `apps/citizen-web`, basada directamente en el ZIP recibido el 5 de noviembre de 2026 (SHA256 `a8aaf5145dbdda1485a0daa1c87f2097d976a36c24640d2937fd85118f47e3a4`). `design/figma` conserva los 106 archivos de referencia originales, sin el ZIP duplicado ni la caché de Supabase. El archivo anidado tiene las mismas 28 rutas y los mismos archivos compartidos; no contiene componentes adicionales.

La web renderiza las 28 pantallas originales en React, sin marcos Flutter ni encabezados añadidos: bienvenida, acceso, recuperación, restablecimiento, registro, inicio, zona, categoría, detalles de captura, confirmación, éxito, mapa, mis reportes, detalle, seguimiento, contactos, detalle de contacto, SOS, actividad, alertas comunitarias, detalle de alerta, perfil, editar perfil, bandeja, preferencias, privacidad, ayuda y cambiar contraseña.

El CSS y los 74 recursos visuales son idénticos a la referencia. Se conservaron colores, posiciones, menús, transiciones, estados, tarjetas y diálogos. La referencia conserva un error de sintaxis del ZIP en el tipo de opciones del selector horario; la aplicación corrige únicamente su separador, además de los tipos de caché de notificaciones. Las rutas de recursos y del trabajador Push se adaptan al subdirectorio de GitHub Pages.

## Conexiones

`src/runtime.tsx` adapta el diseño a los servicios existentes: Supabase Auth, perfiles, `report-pilot`, comunidad, evidencias privadas con URL temporal y notificaciones anteriores. La nueva bandeja también consulta `server/make-server-66389b89`. Las listas de producción empiezan vacías, sin sustituir errores por reportes de muestra. La compilación `design-qa` conserva datos de referencia únicamente para comparaciones locales; nunca se publica.

La dirección se conserva por cuenta, reconociendo el formato de la versión anterior. El historial muestra las fechas del servidor. El envío tiene exclusión de doble clic, clave de reintento estable y folio confirmado por el backend. Las fotografías se convierten a JPEG antes de usar el contrato existente. La recuperación y el cambio de contraseña llaman a Auth.

## Flujos pendientes

El diseño completo no implica que todos los servicios estén conectados. SOS conserva sus estados originales, pero muestra el estado de fallo mientras no haya un receptor real; nunca inventa una recepción municipal. Soporte y eliminación de cuenta necesitan sus servicios correspondientes. Las categorías que exigen campos dinámicos adicionales siguen pendientes de integrar con un formulario aprobado; no se omiten validaciones del servidor ni se envían valores inventados. Las notificaciones antiguas admiten lectura mediante el RPC previo; sus otras acciones no se deben considerar migradas al almacén nuevo. El disparo automático de Push desde cada evento de reportes también requiere completar su integración.

`apps/mobile` permanece como código anterior; no es el punto de entrada de la publicación nueva. No se modificaron las políticas de acceso ni los servicios de administración.

## Verificación

- Compilación de producción y TypeScript sin errores.
- `scripts/verify-citizen-assets.mjs`: CSS idéntico, 74 recursos incluidos y 28 rutas.
- 56 capturas comparativas del ZIP y la adaptación; revisión de las 28 vistas a 360, 390 y 412 píxeles, sin desbordamiento horizontal ni imágenes locales rotas.
- Diálogos de ayuda y permisos: abrir, cerrar y Escape.
- `scripts/test-citizen-web.cjs`: servicios simulados de sesión, perfil, dirección, reportes propios/comunitarios, detalle, historial, error de envío y reintento idempotente. No sustituye pruebas con cuentas reales ni confirma entrega Push en un teléfono.
- Endpoint real de salud de notificaciones: HTTP 200, Push configurado. Consulta anónima a bandeja: HTTP 401.
