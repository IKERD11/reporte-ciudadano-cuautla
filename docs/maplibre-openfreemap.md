# MapLibre GL JS y OpenFreeMap — piloto web

Integración del 18 de octubre de 2026. Sustituye la integración Google Maps anterior. No requiere claves, facturación ni un servicio de geocodificación para ver o seleccionar el mapa. El resto del diseño ciudadano se conserva.

## Implementación

- `apps/mobile/lib/features/reports/report_map.dart`: conserva la API de coordenadas, iconos por categoría, selección de reportes y dimensiones; excluye muestras marcadas como `source: demo`, `is_demo: true` o `demo: true` de los mapas reales.
- `apps/mobile/lib/core/maplibre_surface.dart`, `maplibre_surface_web.dart` y `maplibre_surface_stub.dart`: vista HTML por instancia, actualización de coordenadas y callbacks Flutter; al desmontar llama a `dispose` del puente. El piloto es web; otras plataformas muestran un estado explícito, sin simular un mapa.
- `apps/mobile/web/maps/citizen-map.js` y `citizen-map.css`: renderizador, estados de carga/error/reintento, controles y marcadores. Centro inicial: longitud −98.9548, latitud 18.8126, Cuautla, Morelos. Se descarga el estilo Liberty real de OpenFreeMap.
- `apps/mobile/web/vendor/maplibre-gl-4.7.1/`: biblioteca y CSS oficiales fijados a la versión usada por el prototipo, con licencia BSD incluida. Se sirven desde el propio sitio; la biblioteca se carga solo al abrir un mapa.
- `apps/mobile/web/index.html`: hojas de estilo del mapa y puente local.
- `apps/mobile/lib/features/auth/presentation/citizen_home.dart`: activa 2D/3D en consulta, conserva filtros y tarjetas, mide la tarjeta para colocar la atribución por encima y reserva espacio para los controles existentes. Cambiar filtros cierra la ficha anterior.
- `apps/mobile/lib/features/reports/report_wizard.dart`: captura 2D por toque o arrastre del marcador, preservando GPS, dirección escrita, validación y envío existentes.
- `apps/mobile/lib/core/address_search.dart` y `apps/mobile/lib/features/reports/reports_screen.dart`: contrato independiente del mapa para inyectar un geocodificador real; sin conexión informa indisponibilidad sin devolver resultados de ejemplo. El servicio se propaga desde CitizenHome hasta el formulario.
- `apps/mobile/pubspec.yaml`, `pubspec.lock` y `config/pilot.example.json`: retiran la dependencia y la configuración de Google Maps. Los antiguos `google_maps_loader.dart`, `google_maps_web.dart` y `google_maps_stub.dart` se eliminan.

## Controles y atribución

La consulta empieza en 2D y permite alternar edificios por extrusión y cámara inclinada. Al activar 3D se acerca al nivel donde existen edificios. Sus geometrías/alturas dependen de los datos cartográficos disponibles; no se inventan edificios. En captura y fichas se fuerza 2D y se deshabilita la rotación/inclinación con gestos.

Los controles del mapa usan Manrope, blanco, azul y bordes del diseño. En consulta van debajo del buscador y a la izquierda del botón GPS; en captura quedan debajo del campo de dirección. Las tarjetas y la navegación mantienen sus medidas y estilos. La atribución enlazada a OpenFreeMap, OpenMapTiles y OpenStreetMap ocupa una franja siempre visible, fuera del lienzo y por encima de la tarjeta. Sigue visible durante carga/error.

La salida de pantalla elimina mapa, marcadores, listeners y observador de tamaño. El reintento elimina la instancia anterior antes de crear otra. También se evita crear una instancia tardía si el usuario sale durante la descarga de la biblioteca. Los errores de red o pérdida de contexto WebGL permiten reintentar.

## Conexiones y validaciones pendientes

1. **Búsqueda de direcciones conectada:** `ReportAddressSearch` enlaza el cliente autenticado con `report-pilot`, acción `geocode`. La conexión se aplica desde AuthScreen y desde cualquier ruta a ReportsScreen, incluidas notificaciones. Usa el servicio Nominatim previamente implantado en el servidor, con caché de 30 días, límite global de 100 búsquedas nuevas al día y separación mínima de 1.1 segundos. El proveedor se puede sustituir o desactivar en servidor. No hay autocompletado ni solicitudes automáticas al escribir. Solo se consultan direcciones públicas; se rechazan correos/enlaces y resultados inválidos o fuera de la cobertura del piloto. La política aplicable está en https://operations.osmfoundation.org/policies/nominatim/ . Falta el recorrido completo con una sesión real del usuario; las pruebas no sustituyen esa validación.
2. **Datos de reportes:** se conservan las llamadas existentes `list`/`detail` del repositorio autenticado y el contrato de envío. No se crean cuentas, tablas, políticas ni registros remotos. El mapa muestra los 20 reportes propios más recientes que devuelve el flujo existente, no un feed municipal público. Validar el recorrido autenticado contra el entorno de piloto antes de publicar.
3. **GPS:** se conserva Geolocator. Probar permisos y precisión en un teléfono real con HTTPS; la selección manual funciona sin GPS.
4. **Publicación:** actualización del 18 de octubre publicada en la URL existente de GitHub Pages; evidencia en `docs/publicacion-web.md`. Permitir HTTPS hacia `tiles.openfreemap.org` y sus recursos de estilos, fuentes, sprites y teselas. Si se impone una CSP, permitir también el worker blob de esta distribución de MapLibre.

## Demostraciones

No se importan al repositorio ni se mezclan en mapas operativos los reportes del ZIP. El puente admite muestras exclusivamente en un entorno separado: `source: 'demo'` añade etiqueta accesible «Reporte de demostración», borde discontinuo y aviso «Datos de demostración». Los tests las crean dentro de su página de prueba, nunca en la app real.

## Verificación reproducible

- `flutter analyze --no-pub`, `flutter test --no-pub` y compilación web con el archivo local de configuración habitual.
- `node scripts/test-maplibre.cjs`: navegador Edge/Chromium mediante Playwright, con un estilo vectorial de prueba interceptado únicamente en esa página. Verifica centro, 2D/3D, categoría, etiquetas de muestra, actualización de filtros, atribución a 320 px, selección táctil/arrastre, error/reintento y limpieza al salir/incluso durante la carga. Playwright debe estar disponible; se puede indicar su carpeta con `CODEX_NODE_MODULES`.
- Con `MAPLIBRE_LIVE=1`, añade una página independiente sin interceptar OpenFreeMap: carga teselas reales en Cuautla, activa 3D y comprueba geometría `building`. Las pruebas no inician sesión ni escriben datos remotos.
- `apps/mobile/test/maplibre_test.dart`: verifica aislamiento de demostraciones, callbacks y búsqueda sin servicio; las pruebas anteriores de filtros/fichas y geocodificación inyectada se conservan.

Fuentes: [OpenFreeMap](https://openfreemap.org/quick_start/), [edificios 3D en MapLibre](https://maplibre.org/maplibre-gl-js/docs/examples/display-buildings-in-3d/), [ciclo de vida de MapLibre](https://maplibre.org/maplibre-gl-js/docs/API/classes/Map/), [HtmlElementView](https://api.flutter.dev/flutter/widgets/HtmlElementView-class.html).

## Resultado de esta revisión

31 pruebas Flutter aprobadas y análisis completo sin incidencias. El navegador comprobó toque táctil, arrastre real del marcador, alternancia de capa/cámara 2D/3D, filtros, atribución a 320 px, error/reintento, salida y desmontaje durante descarga. La consulta real a OpenFreeMap cargó 13 geometrías de edificios en la vista de Cuautla usada para la captura.

También se abrió una compilación Flutter con repositorio de prueba local sin sesión ni escrituras remotas: el mapa real y el control 2D/3D funcionaron dentro del diseño, la atribución quedó por encima de la tarjeta y navegar a Inicio eliminó la vista HTML. Capturas: `output/figma-renovacion/maplibre-flutter-2d.png` y `maplibre-flutter-3d.png`. El punto de entrada temporal de esa prueba se retiró. Se añade regresión de la liberación al abrir Reportar mediante una ruta y la reconstrucción al volver.

Estas pruebas no acreditan GPS en teléfono físico ni un nuevo recorrido autenticado en producción.

## Conexión del buscador — 18 de octubre de 2026

Se recupera el servicio real ya desplegado. La app no llama directamente a Nominatim ni usa Google Geocoding. `report_address_search.dart` valida la consulta y los candidatos del servidor; resultados vacíos permanecen vacíos. Sin sesión, `report-pilot` devuelve 401; conserva CORS restringido al sitio del piloto. La firma de `pilot_geocode_service` y la función activa `report-pilot` versión 3 se comprobaron de forma no destructiva. No se cambiaron tablas, permisos ni la configuración de Auth.

Validación adicional: 34 pruebas Flutter y 3 pruebas del normalizador del servidor aprobadas; análisis sin incidencias. Una consulta aislada al proveedor real devolvió HTTP 200 y un candidato para el lugar público «Parque Revolución del Sur, Cuautla». Esto acredita respuesta del proveedor para ese lugar, no el recorrido autenticado de la app ni cobertura de todas las calles.

La publicación incluye URLs de arranque versionadas para evitar ejecutar JavaScript de entregas anteriores conservado en caché. El código se guarda en el PR #1; no se modifican sesiones ni datos remotos.
