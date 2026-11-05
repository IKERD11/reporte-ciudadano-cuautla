# Renovación ciudadana del 21 de octubre de 2026

Fuente: `Subir carpeta al proyecto (1).zip`. Se extrajo completo en `tmp/figma-renovacion-20261021`; el ZIP interior se extrajo aparte y sus fuentes son idénticas a las exteriores. La referencia React compila. La aplicación conserva Flutter y los servicios existentes.

## Integración

- Los 56 recursos de `public` coinciden por contenido con los integrados. Se incorporan `mourning.png`, `description.png` y `profile-security.png`. Se conserva Manrope, los colores, degradados, ilustraciones, sombras y efectos de interacción existentes. No hay cambios de animaciones CSS en esta exportación: siguen las transiciones de interacción, avisos, paneles y apertura del editor de zona.
- Nueve categorías en tres columnas, incluida Deceso con su lazo original. Se prepara una migración aditiva solo para el piloto de Cuautla; no se aplica remotamente. La interfaz nunca sustituye una categoría deshabilitada por Otro.
- Confirmación con tarjetas de tipo, descripción, ubicación y evidencia; edición directa, mapa de 106 px, fotografías comprimidas, flecha circular y vuelta a detalles. Se conservan borrador, validación, consentimiento explícito del piloto e idempotencia del envío. Éxito conserva el folio real y utiliza shield-header como la nueva referencia.
- Editar mi perfil desde el engrane: tarjeta de saludo, avatar con cámara, nombre completo, correo, teléfono, tarjeta de contraseña, nota de privacidad y guardar/descartar. El enlace Más opciones de mi cuenta conserva los ajustes y acceso a verificación anteriores. Nombre y teléfono usan el contrato existente update_my_profile. Correo usa actualización autenticada con confirmación por correo; no cambia visualmente la cuenta a un correo sin confirmar. Contraseña solicita el enlace real de recuperación.
- La foto se prepara sin metadatos y se guarda en almacenamiento seguro del dispositivo, separada por cuenta. Se informa en pantalla; no se presenta como avatar sincronizado entre dispositivos. Descartar conserva la foto guardada. Límites: 8 MB y 24 megapíxeles antes de preparar, hasta 700 KB después.
- Las actualizaciones de la misma cuenta conservan el editor abierto; cierre de sesión, cambio de cuenta y recuperación siguen sus recorridos respectivos.

## Validación

- 41 pruebas Flutter aprobadas, incluidas edición real de campos mediante repositorio simulado, confirmación de cambio de correo, conservación de sesión y edición del borrador Deceso a 320 px.
- Análisis de lib y test sin incidencias. Parser SQL aprobado para todas las migraciones, incluida la nueva categoría; no acredita ejecución en PostgreSQL/RLS.
- Compilación Flutter web final aprobada (JavaScript, base /reporte-ciudadano-app/). Referencia React compilada. Revisión visual de perfil a 390 px y confirmación a 320 px; capturas locales en output/figma-renovacion/oct21-*.png. El mapa del renderizador de pruebas es un sustituto explícito; la prueba de navegador del puente MapLibre sí comprueba 2D/3D, filtros, categorías, atribución, toque/arrastre, reintento y liberación.
- GPS físico, entrega real de correos y guardado con cuenta autenticada no se acreditan con simulaciones.

## Entrega

Cambios preparados localmente. No se publica ni se aplica la migración remota automáticamente. La categoría Deceso requiere aplicar la migración antes de habilitar su envío en el servicio. Los permisos, restricciones del piloto, INE real deshabilitada y costo cero se conservan.

## Revisión de diseño y movimiento

Se volvió a renderizar la referencia React en navegador a 390 × 844 y se generaron 20 capturas Flutter, con comprobación adicional de confirmación a 320 px. Archivos `verify-reference-*.png` y `verify-flutter-*.png` en output/figma-renovacion. La comparación distingue los datos de ejemplo de la referencia de los datos privados y restricciones del piloto. No certifica igualdad píxel a píxel entre motores de renderizado.

Correcciones: transiciones ease de tarjetas de 160 ms (180 ms en inicio), desplazamiento de botones de envío de 1 px y brillo al pasar el cursor, degradados originales de las nueve categorías, sombra de sus ilustraciones y del progreso, bordes de confirmación, alineación de campos y flecha de acceso, y geometría de la tarjeta de contraseña en el perfil. Los controles deshabilitados no muestran efectos de pulsación.

El panel de dirección anima solamente su contenido desde 22 px con ease-out durante 190 ms; el fondo desenfocado permanece fijo. Los ojos de restablecimiento cruzan opacidad durante 180 ms y escala/rotación con la curva original durante 220 ms. Los avisos recuperan su píldora azul con desplazamiento de 8 px y opacidad durante 180 ms. Se respeta movimiento reducido en estos efectos y en el interruptor del perfil.

Validación: 46 pruebas aprobadas, cinco de ellas sobre cuadros intermedios de hover, pulsación, ojos, panel y avisos; análisis sin incidencias. Las capturas comprueban composición y recursos; las pruebas de movimiento comprueban estados intermedios y finales, sin depender de una imagen estática.

## Corrección de comportamiento respecto a Figma

Se corrigió la adaptación que hacía navegar Ver todos a Mis reportes. Ahora expande el panel en el mismo mapa, restablece el filtro Todos, cambia a Ver menos y contrae el mismo panel, con la transición height de 220 ms y curva ease. Altura inicial 203 px, altura expandida min(560 px, altura de pantalla menos 125 px), posición inferior 82 px. Se contrastaron los rectángulos con el navegador de la referencia a 320×568, 390×844 y 430×932.

El filtro del mapa usa el menú original de 128 px, sus cinco opciones, selección resaltada y botón azul mientras está abierto. Las tarjetas y los marcadores abren directamente el detalle real; Volver regresa al mapa. Se retiran la ficha de mapa y el menú lateral Material agregados por la adaptación. Las pantallas cambian sin transiciones Material; se mantienen las animaciones explícitas del diseño.

Consulta inicia en 3D, zoom 15.2, inclinación 48° y orientación −18°, con cambio 2D/3D de 650 ms y localización de 700 ms. Botones, marcadores con punta, estados de carga/error y posición del panel siguen la referencia. Captura permanece en 2D. Los reportes privados, atribución, filtros de cuenta y exclusión de muestras se conservan.

Se extrajeron los 46 SVG del componente Icon de la exportación, manteniendo sus paths, terminaciones, uniones y grosores. Las cabeceras, controles y formularios usan esos vectores en lugar de equivalentes Material. Renderizador flutter_svg 2.2.3 fijado y lockfile actualizado solamente con sus dependencias necesarias. Una prueba comprueba que un SVG solicitado a 27 px conserve ese tamaño dentro de un control de 49 px.

La referencia tiene un defecto a 320×568: el panel de 443 px empieza en y=43 y su encabezado queda detrás de la cabecera del mapa. Se conserva expresamente esa disposición al pedirse igualdad con el original; no se presenta como una mejora de usabilidad. Volver al inicio y abrir el mapa restablece el panel.

Evidencia: 20 pantallas renovadas en exact-final-*.png y nueve estados de mapa en exact-flutter-mapa-*.png, junto a las capturas de referencia. Los mapas de las pruebas Flutter usan un sustituto explícito; el puente MapLibre se prueba además en navegador con el motor real. Las capturas y comprobaciones geométricas no certifican igualdad píxel a píxel entre CSS y Flutter; los textos de cuenta/reportes y restricciones del piloto siguen usando el servicio real.

Cierre de esta corrección: 51 pruebas automatizadas aprobadas, ocho recorridos de captura visual aprobados, análisis sin incidencias, compilación web aprobada y prueba de navegador MapLibre aprobada. JavaScript y CSS del paquete compilado coinciden con sus fuentes. Validación previa a publicación completada.


Publicación ciudadana autorizada y realizada el 21 de octubre de 2026: commit 7b33564db75a2d1b051a53e74e7a984375c48fbd del repositorio reporte-ciudadano-app. GitHub Pages run 39632950155 completado con éxito. URL: https://ikerd11.github.io/reporte-ciudadano-app/. HTML público referencia el nuevo bootstrap; programa principal, mapa, estilos y recurso Deceso verificados contra el paquete generado (normalizando saltos de línea de Git en textos). Redirección de autenticación configurada a la URL pública. Sin publicación del administrador ni aplicación remota de migraciones.

Comprobación final en Edge: pantalla de bienvenida pública renderizada a 390x844 sin errores JavaScript ni solicitudes fallidas; captura output/figma-renovacion/publicado-7b33564.png. La primera espera automática agotó 30 segundos; el segundo recorrido cargó correctamente.

Corrección posterior de detalle: tarjeta de ubicación ajustada a la exportación (pin y texto horizontales, miniatura 135x86, padding original), fallback explícito cuando falta dirección, validación de ambas coordenadas y folio real visible. Vista previa no interactiva sin zoom; créditos compactos conservados. Siete pruebas de reportes y dos de navegación/distribución aprobadas, análisis de reportes limpio y regresión MapLibre con miniatura aprobada. Publicación commit 33fcc78, Pages run 39634924661.

Corrección de evidencia: se sustituye foto rígida 220x165 sin recorte redondeado por galería adaptable de tres columnas, separación 7, altura 116 y radio 13 conforme al CSS exportado. Se conservan todas las fotos y acceso mediante URL privada del repositorio. Nueve pruebas de reportes/navegación y tres pruebas finales de navegación/miniatura aprobadas; análisis sin incidencias.

Galería publicada: commit 10725a3, Pages run 39635932667. El HTML público referencia flutter_bootstrap.9cec8cc9fcd1.js.

Seguimiento restaurado con resumen compacto, insignia de estado, progreso con gradiente, cinco etapas con conectores continuos/discontinuos, estados pendiente/actual/completo, iconos originales y botón de contorno. El avance se deriva de las cinco etapas reales: Recibido equivale a 20%; no se usan las fechas y porcentajes ficticios del prototipo. Historial ausente no acredita etapas completadas. Pruebas y capturas con Manrope aprobadas a 320/390/430. Análisis sin incidencias.

Seguimiento publicado: commit e3e672b; Pages run 39637318292. Nuevo paquete flutter_bootstrap.6de616dfde60.js.

Avatar de Editar perfil: se reemplaza la imagen de 112 forzada al círculo por el recurso user.webp original centrado a 104 (86 en móvil estrecho), recorte circular propio, escala 1.08 y desplazamiento Y 7 conforme a CSS. Contenedor ocupa toda la caja, borde blanco de 3 y gradiente diagonal. Foto elegida conserva recorte cover. Tres pruebas de perfil aprobadas incluida medida original.

Avatar publicado: commit 92da311, Pages run 39657144372; paquete flutter_bootstrap.23ffbf697af5.js.

Referencia explícita del avatar aplicada: se elimina aro blanco y recorte circular intermedio; escala 1.14 y desplazamiento Y7 del recurso original. Pruebas aprobadas, compilación aprobada, publicación d9fa228 / Pages 39658163168.

Regla visual del usuario: el círculo/radio azul es exclusivo de Configurar mi zona. Se elimina radiusKm del mapa principal y se añade showZoneRadius=false por defecto, activado únicamente en zone_screen. El puente exige habilitación explícita y limpia el círculo al desactivarla incluso conservando centro y radio. Siete pruebas Flutter y regresión de navegador aprobadas.
