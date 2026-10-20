# Renovación visual desde Figma Make

> Esta entrega inicial queda ampliada por [la renovación del 19 de octubre](renovacion-2026-10-19.md), con MapLibre/OpenFreeMap publicado, catálogo completo, zona, actividad y seguimiento. Los apartados sobre Google Maps y categorías pendientes describen el estado anterior.

Referencia: https://www.figma.com/make/KImRQTzbnmmNVWyYFe86jH/Subir-carpeta-al-proyecto

Fuente: ZIP facilitado por el propietario el 18 de octubre de 2026. La segunda revisión sustituye las adaptaciones visuales de la primera por la composición de la nueva versión: inicio, categorías, detalles, confirmación, envío, lista y detalle de reportes, mapa, alertas, contactos y perfil.

## Implementación

- Paisaje e iconos 3D originales, tipografía Manrope local con licencia OFL, medidas y colores del prototipo.
- Navegación inferior uniforme y marco de 430 px en escritorio. Vista completa en móvil.
- Tres pasos: Tipo, Detalles y Confirmar. Ubicación y evidencia se capturan en Detalles. Se conservan validaciones, campos adicionales que exige el servidor, consentimiento y reintentos sin duplicados.
- MapLibre GL JS con OpenFreeMap sustituye Google Maps en captura, consulta, fichas y alertas. Consulta permite 2D/3D; captura usa 2D. La búsqueda de direcciones es independiente y se conecta al servicio autenticado existente. Detalles en [integración de mapas](maplibre-openfreemap.md).
- Emergencias abre los contactos del diseño. Solo 911 y 089 tienen números en el archivo fuente; los otros contactos permanecen pendientes de configuración. No se simula un envío de SOS.
- El perfil usa datos reales de la cuenta. Configuración conserva el formulario de edición anterior. El interruptor de notificaciones controla los indicadores durante la sesión; no representa una suscripción de notificaciones push.

No se cambian políticas, esquema ni datos remotos. No se publica automáticamente.

## Mapas sin claves

La integración actual usa OpenFreeMap con MapLibre GL JS, sin claves ni facturación. Las instrucciones de configuración de Google Maps de revisiones anteriores quedan sustituidas por [MapLibre y OpenFreeMap](maplibre-openfreemap.md). La búsqueda de direcciones utiliza el servicio autenticado existente y no devuelve resultados simulados.

## Datos que dependen del servicio existente

Los nombres, folios, fechas, estados, fotografías y contadores proceden de la cuenta. No se incluyen los incidentes, alertas o fotografías de ejemplo del prototipo como datos operativos.

Se muestran las ocho categorías del diseño. El servidor todavía conserva su catálogo anterior: una categoría nueva sin correspondencia se informa como no habilitada, nunca se envía usando el identificador de otra. Los campos adicionales que exige una categoría existente siguen siendo obligatorios. Habilitar todo el nuevo catálogo requiere una decisión y un cambio de backend aparte.

La lista de alertas conserva el acceso privado del servicio de avisos existente; esta revisión no crea un feed público municipal. Evidencia y recomendaciones se muestran cuando existen en los datos disponibles.

El ZIP `Subir carpeta al proyecto (1).zip` incorpora bienvenida, acceso, registro, recuperación y nueva contraseña. Se adaptaron a Flutter con sus seis ilustraciones originales, botones con degradado, autocompletado y visibilidad independiente de contraseñas. El registro conserva la confirmación de correo y el paso de perfil con municipio; la contraseña mantiene el mínimo de 12 caracteres del servicio. La recuperación utiliza el servicio real y sus mensajes, sin temporizadores de éxito simulado. Se retiran los botones de acceso social deshabilitados. Volver desde registro o recuperación regresa al acceso. Los avisos sobre el piloto continúan en ayuda, privacidad y confirmación del envío.

## Revisión visual y funcional

Las capturas en `output/figma-renovacion/` usan exclusivamente datos sintéticos. Incluyen inicio, categorías, detalles, perfil, contactos, mapa, lista y detalle de reportes, envío y alertas. Se compararon con la ejecución local del prototipo original. Las capturas iniciales del mapa muestran el estado anterior sin clave. Las nuevas comprobaciones con OpenFreeMap se documentan en la integración de mapas.

Las pruebas usan repositorios simulados. No acreditan GPS real, envío autenticado en producción ni entrega de correo. La compilación web JavaScript es el destino del piloto; la comprobación opcional de Wasm presenta avisos conocidos de la dependencia `image`.

Comprobaciones finales: 28 pruebas funcionales aprobadas, revisión visual de 11 capturas con datos sintéticos y análisis sin incidencias.

Compilación final validada: flutter build web --no-pub --no-wasm-dry-run --dart-define-from-file=config/pilot.json. Terminó correctamente; la comprobación opcional de Wasm se omitió porque el destino del piloto es web JavaScript. Los cambios siguen locales.


## Integración del ZIP actualizado — 18 de octubre de 2026

Se conservaron los cambios locales anteriores y se sincronizaron los recursos interiores del ZIP. El mapa usa ahora exclusivamente MapLibre GL JS con OpenFreeMap, por solicitud posterior del propietario. La búsqueda de direcciones queda separada y conectada al servicio autenticado de reportes. Los incidentes de demostración del ZIP no se importan a los datos de la cuenta.

Validación: 28 pruebas Flutter aprobadas, incluida bienvenida a 320, 390 y 1280 px y validación del registro. Estas pruebas usan datos simulados y no acreditan entrega de correo ni GPS real.

Revisión adicional: capturas locales `output/figma-renovacion/zip-bienvenida.png`, `zip-acceso.png`, `zip-registro.png` y `zip-recuperacion.png`, generadas con fuentes e imágenes reales y cuenta simulada. Análisis completo de Flutter sin incidencias.


## Corrección de iconos de Mi perfil — 18 de octubre de 2026

Se conectan las seis celdas originales de `profile-menu.png` al menú mediante recorte de la imagen en Flutter: reportes, notificaciones, ubicación, privacidad, ayuda y salida. Se conserva el espacio de 43 × 43 px del diseño, con la disposición original de tres columnas y dos filas. No se regeneran ni sustituyen los dibujos del ZIP. Se mantienen etiquetas, tarjetas, medidas, interruptor, navegación y callbacks.

Análisis sin incidencias, dos pruebas existentes de navegación/perfil aprobadas y revisión visual a 390 × 844 px con datos sintéticos. La captura local `output/figma-renovacion/perfil-iconos-3d.png` acredita los seis recortes visibles; no representa una sesión real.
