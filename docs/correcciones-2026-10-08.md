# Correcciones del 8 de octubre de 2026

Registro histórico. Consultar el [estado actualizado del 15 de octubre](cierre-piloto-2026-10-15.md).

Alcance de validación solicitado: web. Android/iOS quedan pendientes por indicación del usuario. Se mantiene costo cero, identidad sintética y etiquetas del piloto.

## Aplicado

- Demostración accesible solo en desarrollo y con `NEXT_PUBLIC_ENABLE_DEMO=true`. Producción no ofrece ese acceso.
- Recuperación de cuenta configura su enlace mediante `NEXT_PUBLIC_CITIZEN_APP_URL`. En producción sin configuración no muestra un enlace a localhost.
- Configuración distingue avisos internos existentes de push pendiente.
- Filtros convierten las fechas elegidas a medianoche de Cuautla (UTC−06:00); el contrato existente agrega un día al límite superior. Se rechazan fechas invertidas.
- Los errores al cargar reportes limpian también el contador de resultados.
- La demostración calcula conteos a partir de los resultados filtrados. No inventa tiempos de resolución o tendencias cuando no dispone de datos.
- Exportación CSV de la página visible, hasta 20 reportes autorizados; no incluye fotos ni datos del ciudadano. Escapa comillas y neutraliza fórmulas de hojas de cálculo. No es exportación masiva.
- Las comprobaciones nativas de servicio y permisos de ubicación tienen tiempos máximos, además del límite que ya existía para obtener coordenadas. Esto no demuestra funcionamiento del GPS real.

## Verificado

- 22 pruebas Flutter aprobadas.
- Flutter analyze sin incidencias.
- 3 pruebas de filtros, conteos y CSV aprobadas (`npm test --prefix apps/admin`, requiere Node con soporte de TypeScript nativo, probado en Node 25).
- Compilación de producción Next.js aprobada.
- Sintaxis SQL/PLpgSQL de migraciones, seed y pruebas aprobada. No equivale a ejecutar políticas o triggers.

## Pendientes, sin declarar resueltos

- GPS real y prueba visual completa: la herramienta de navegador agotó su espera; solo se han validado escenarios automatizados.
- Geocodificación: proveedor gratuito, límites globales, caché y privacidad por definir. No conectar búsquedas masivas a servidores comunitarios sin resolver sus condiciones.
- Gestión avanzada de equipos y roles, exportación completa y push.
- Prueba integrada de seguridad y migraciones desde una base limpia: Docker no respondió al intentar consultar su motor. No se hizo reset remoto.
- Respaldo/restauración, revisión actual de avisos de seguridad y publicación de las aplicaciones.
- Aviso de privacidad, términos y responsables: requieren documentos y decisiones institucionales; no pueden reemplazarse con textos de prueba.
- Revisión de recursos antiguos: no se eliminaron imágenes ni fixtures sin evidencia de que fueran prescindibles.

La página pública de diagramas es independiente del despliegue de las aplicaciones. Estos cambios permanecen locales, pendientes de revisión y subida.
