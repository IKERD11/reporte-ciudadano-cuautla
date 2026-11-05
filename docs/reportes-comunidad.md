# Reportes de la comunidad

La aplicación ciudadana permite consultar reportes del mismo municipio mediante el mapa de incidentes y la opción Comunidad en Mis reportes. Solo míos conserva el servicio privado anterior. El mapa se actualiza al abrirlo y consulta páginas de veinte, con un máximo de quinientos marcadores recientes; el listado mantiene paginación.

La nueva función community_report_service utiliza la validación vigente de sesión y perfil del piloto. Solo service_role puede invocarla: el cliente accede por report-pilot, que valida el token. No se amplía RLS de reports, Storage ni profiles. Solo incluye reportes del piloto, municipio del solicitante y categorías activas públicas.

La proyección comunitaria muestra folio, categoría, prioridad, estado, descripción del incidente y fechas de estado sin comentarios internos. La ubicación se redondea a tres decimales y muestra zona o una etiqueta aproximada, sin dirección detallada. No entrega citizen_id, perfiles, teléfono, correo, documentos, datos adicionales de formularios, rutas de Storage ni evidencias privadas. La API privada anterior conserva la restricción de propietario.

Se comprobó en la base real que tres cuentas con reportes reciben cuatro reportes comunitarios, todos geolocalizados, incluidos los de otras cuentas. El detalle de otra cuenta funciona a través de la proyección comunitaria. Pruebas negativas: sesión inválida rechazada, detalle privado ajeno rechazado y endpoint comunitario sin sesión devuelve 401. No se consultaron ni mostraron nombres, teléfonos, correos o credenciales para esta validación.

Migración community_reports aplicada. report-pilot versión 5 desplegada. Parser SQL/PostgreSQL aprobado; 58 pruebas Flutter existentes y dos nuevas pruebas de comunidad aprobadas. Análisis final limpio. Aviso de envío actualizado para indicar visibilidad comunitaria con ubicación aproximada y privacidad de cuenta y fotos.

Avisos de seguridad previos fuera de alcance: protección de contraseñas filtradas desactivada (https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection); tablas privadas con RLS y sin políticas de cliente intencionadamente inaccesibles (https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

Publicación web: commit 16b41bf477762ba62a2496c491e49a5cab62568f; GitHub Pages 39697035279. URL https://ikerd11.github.io/reporte-ciudadano-app/?version=16b41bf.

Alertas comunitarias también consulta community_list, conserva los filtros Todas/Seguridad/Tránsito/Servicios y abre community_detail. Los filtros se aplican antes de paginar para no omitir coincidencias en páginas posteriores. Las notificaciones personales y su marcado de lectura quedan en Actividad. Siete pruebas aprobadas incluyendo reporte de otra cuenta en segunda página, categoría y apertura del detalle sin llamadas de notificaciones.

Alertas comunitarias publicada: commit 9238b68, Pages 39698274098 aprobado; HTML público verificado con flutter_bootstrap.ca60ce7515cb.js. Clasificación por categoría explícita del reporte y actividad personal separada.
