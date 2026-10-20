# Renovación ciudadana del 19 de octubre de 2026

Fuente: `Subir carpeta al proyecto.zip`, facilitado por el propietario el 19 de octubre. Se revisaron sus 4,900 líneas de interfaz, estilos, rutas, recursos y manejo de mapas. La exportación React se compila como referencia; la aplicación publicada conserva Flutter y el backend existente.

## Contenido integrado

- Se verificaron los 53 archivos de `public` contra los recursos locales por SHA-256: idénticos y no vacíos. Once PNG nuevos: cinco iconos de actividad, cinco de seguimiento e ilustración de configuración de zona. Se conservan las seis ilustraciones de acceso, el paisaje, la tipografía Manrope y el mosaico original del perfil.
- Bienvenida, inicio de sesión, registro, recuperación y restablecimiento usan el diseño y recursos originales. Botones de acceso con degradado azul/turquesa y flecha circular; títulos centrados y campos con iconos. Registro incorpora nombre completo y aceptación explícita de condiciones del piloto. Se conserva la contraseña mínima de 12 caracteres del servicio, aunque la maqueta proponía ocho.
- La recuperación real envía el enlace mediante el servicio existente. Nunca se habilita el cambio de contraseña por un temporizador de la maqueta. El perfil se completa después de confirmar correo; el nombre capturado se reutiliza cuando se conserva la misma sesión de registro.
- Configurar mi zona se abre desde la tarjeta de ubicación o desde Perfil. Dirección mediante formulario, búsqueda autenticada con candidatos y selección explícita; selección del punto en mapa, GPS con errores y límites de tiempo; radio 1–10 km; círculo geográfico actualizado y ajuste de cámara. No se asigna una dirección sin coincidencia a un punto anterior.
- Zona guardada por cuenta en este navegador, con validación al leerla y aviso si el almacenamiento está bloqueado. Filtra los reportes propios cargados en el mapa. No es una suscripción a notificaciones push ni una preferencia sincronizada entre dispositivos.
- Actividad separada de Alertas: filtros Todo/Reportes/Comentarios/Alertas, búsqueda, modo solo no leídas, agrupación Hoy/Ayer/fecha, iconos originales, lectura persistida en servidor, paginación y reintento. El aviso asociado abre el reporte real. Campana del inicio abre pendientes de lectura y el contador se actualiza al leer.
- Seguimiento del reporte desde su detalle: folio, categoría, ubicación, estado e historial real con fechas. Se conservan los iconos originales. Se omiten porcentajes y horas ficticias de asignación/revisión del prototipo. La vista del mapa se libera al abrir seguimiento.
- Se revisaron los flujos ya renovados: inicio, ocho categorías, tres pasos de envío con confirmación real, compresión de fotografías, reintento idempotente, éxito, lista y detalle, mapa 2D/3D, perfil, contactos y alertas.
- Se añadieron al catálogo remoto del piloto seis categorías faltantes: Robo / Asalto, Accidente, Vandalismo, Violencia, Maltrato animal y Otro. Baches y Alumbrado público conservan sus identificadores y requisitos de fotografía/formulario. Recolección de residuos permanece disponible en servidor para compatibilidad. Migración `20261020033544_citizen_renewal_categories.sql`, restringida a Cuautla con piloto habilitado, sin alterar permisos ni políticas.

## Mapas y revisión del ZIP

MapLibre GL JS 4.7.1 y OpenFreeMap sin clave ni facturación, con recursos locales del motor y atribución visible. Captura siempre en 2D; consulta permite edificios 3D. Marcadores reales por categoría, toque, arrastre, reintento, actualización del radio y liberación de eventos/contextos al desmontar. Se incorpora el manejo de imágenes faltantes del estilo presente en la nueva exportación.

La prueba con datos reales de OpenFreeMap en Cuautla cargó 13 elementos de edificios en el área consultada. Esa cantidad corresponde a esa vista y no acredita cobertura completa de edificios/alturas del municipio. Se corrigió la prueba previa para ejecutar la comprobación real en un contexto sin interceptaciones de datos simulados.

La exportación conserva un `.env.example` de Google Maps obsoleto; no se usa ni publica. Tampoco se copian el backend independiente de Figma, los reportes de muestra, las fotografías remotas de demostración ni sus accesos simulados al sitio real.

## Verificación y límites

- 38 pruebas Flutter aprobadas, análisis sin incidencias, tres pruebas del normalizador de direcciones y validación sintáctica SQL aprobadas.
- Pruebas de navegador del puente: 2D/3D, clic de categoría, separación de demostraciones, filtros, atribución en móvil, toque/arrastre, reintento, radio y liberación.
- Compilación de referencia React aprobada; revisión visual con siete capturas nuevas y datos sintéticos en `output/figma-renovacion/oct19-*.png`.
- Catálogo remoto consultado después de la migración; las ocho categorías del diseño están activas. Se preservan los avisos de seguridad preexistentes: cuatro tablas privadas con denegación directa intencional y protección de contraseñas filtradas desactivada. No se amplían accesos.

Los reportes, fotografías y avisos conservan su acceso privado. El diseño de Figma contiene incidentes públicos, comentarios y alertas de muestra; esos datos no se convierten en un feed municipal operativo. El filtro Comentarios solo mostrará eventos cuando el servicio los produzca; la renovación no inventa comentarios ni activa una red social.

El propietario indicó que comprobó el acceso. No había una sesión autenticada disponible en el navegador conectado para acreditar aquí un envío real completo. GPS en teléfono, entrega de correo y una comprobación autenticada de extremo a extremo siguen diferenciados de las pruebas simuladas. INE reales y operación municipal continúan bloqueadas. No se habilitan servicios de pago.

## Publicación

Destino autorizado: https://ikerd11.github.io/reporte-ciudadano-app/ . Compilación Flutter web JavaScript con base y retorno públicos; empaquetado de entradas por hash para evitar que clientes reutilicen archivos de la entrega anterior. Solo se publica el paquete ciudadano; el panel administrativo se conserva.

Publicación final: commit `43874c8`, ejecución Pages `39366775411` completada con éxito. Se comprobó HTTP 200 y contenido idéntico al paquete local para HTML, entrada Dart, bootstrap, puente/CSS del mapa y nuevos recursos representativos. Navegador público: bienvenida, acceso y recuperación visibles. Código principal: `8de1529`, con corrección adicional del empaquetador en la misma rama/PR.

Se corrigió un defecto previo del empaquetado: Flutter sustituye su token de versión incluyendo comillas, lo que dejaba atributos sobrantes en HTML. Dos pruebas de regresión cubren tokens con/sin comillas, URLs válidas y hashes de los archivos. El puente final de mapas volvió a pasar las pruebas de navegador con datos reales de Cuautla después del último ajuste del radio.

Último ajuste incluido en la entrega: cada flujo de autenticación reinicia su desplazamiento al abrirse. Se repitieron las 38 pruebas Flutter y el análisis sin incidencias; nueva compilación aprobada. Los 53 recursos originales también se verificaron individualmente en la URL pública, con HTTP 200 y contenido idéntico. Código del ajuste: `3ddf0ac`.
