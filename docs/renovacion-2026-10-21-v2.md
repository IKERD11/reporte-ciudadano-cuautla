# Actualización del segundo ZIP

Origen: Subir carpeta al proyecto (2).zip. El archivo interno cuautla-segura-avance.zip contiene el mismo App.tsx y CSS. Frente al ZIP anterior cambian esos dos archivos; no hay recursos gráficos nuevos.

Implementado en la aplicación ciudadana:
- Dirección del incidente mediante diálogo con calle, número, colonia, código postal y municipio. Validación, consulta al guardar, conservación del borrador al cerrar y aviso cuando no hay coordenadas. Nunca se reutiliza una posición anterior para una dirección que no pudo localizarse.
- Se retira la búsqueda superpuesta al mapa de captura; mapa de 300 px y confirmación de 180 px.
- Panel de incidentes ocultable a 64 px, expandible y restaurable; botones y atribución acompañan al panel. Controles de zoom, modo y GPS ocultos mientras la lista está expandida.
- Transiciones con curva cubic-bezier(.22,1,.36,1), duración 260 ms, desplazamientos de entrada 24 px y salida 16 px en rutas. Fundidos del mapa y navegación entre pantallas del mismo nivel; confirmación con entrada de 340 ms, 14 px y escala .975. Respeta reducción de movimiento.
- Fondo del diálogo de dirección aparece en 180 ms y panel en 190 ms.
- Se retira la nota de seguridad bajo la sección de contraseña de Editar perfil.

Se conservan el avatar solicitado, los reportes privados, los controles del piloto y el radio azul exclusivo de Configurar mi zona. No se publican cambios del administrador ni de la base de datos.

Validación: 56 pruebas Flutter aprobadas; análisis sin incidencias; regresión de navegador del mapa aprobada. Dos recorridos de captura aprobados a 320 y 390 px, cuatro PNG en output/figma-renovacion/v2-*.png. La captura inicial de 320 puede preceder a la decodificación del pin; el recurso local y la captura de 390 confirman el asset original. Estas comprobaciones no certifican igualdad píxel a píxel entre Flutter y CSS.

Publicación: commit 39f1737 en reporte-ciudadano-app; GitHub Pages 39664204910. HTML público actualizado y programa principal, JavaScript del mapa y CSS comparados con el paquete generado (normalización de saltos de línea de Git en textos). URL: https://ikerd11.github.io/reporte-ciudadano-app/?version=39f1737. Nueve pruebas adicionales de navegación/movimiento y análisis final limpios después del último ajuste de rutas.

Dirección en inicio corregida: selección de mapa y GPS resuelven coordenadas mediante el servicio autenticado existente; debounce 600 ms, descarte de respuestas antiguas, espera antes de guardar y fallback a coordenadas con aviso. Dirección manual elegida y dirección de mapa persisten por cuenta al guardar y al reconstruir CitizenHome. Dos pruebas completas inicio/zona/inicio/recarga, cuatro de zona/actividad y cuatro de geocodificación aprobadas; análisis limpio. report-pilot versión 4 desplegada manteniendo autenticación, caché y límites; solicitud sin sesión comprobada con 401. Publicación web 205a98e.

Referencia de mapas: Configurar mi zona usa ilustración adaptable al 44% del ancho, dirección de altura mínima 68, mapa de 270 con zoom 11.3, pin original y ubicación dentro del mapa. Radio exclusivo de esta pantalla. No se afirma envío de notificaciones automáticas del piloto. Consulta: zoom reubicado al mismo contenedor que 3D y GPS; zoom de ancho42/right26, 3D y GPS de ancho54/right20 comparten eje. Se comprueba en navegador el centro común y que zoom quede encima de modo. Signos aumentados a 22 y divisor restaurado. Se mantiene ocultación de controles con panel expandido. Captura de distribución Flutter usa sustituto de mapa; el puente web real tiene prueba independiente.
