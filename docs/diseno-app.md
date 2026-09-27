# Referencia visual de la app

Referencia definitiva del usuario: segunda lámina, con veinte pantallas, recibida el 25 de septiembre de 2026. El diseño objetivo usa azul marino, fondos claros, tarjetas blancas, iconos circulares por categoría, encabezados compactos y navegación inferior con botón central de creación.

Adaptación implementada: bienvenida, acceso/registro, inicio ciudadano, menú lateral, perfil y edición, selección de categoría en tarjetas, cuatro etapas de creación (tipo, ubicación, detalles, confirmación), confirmación de envío, lista y detalle de reportes. El mapa del inicio muestra únicamente hasta veinte reportes propios recientes. Ayuda, condiciones del piloto y acerca de tienen información real del alcance actual.

El usuario proporcionó posteriormente la fotografía de Cuautla y el logotipo RC. Ambos archivos se integran sin modificar en `assets/branding`: fotografía de fondo con ajuste de encuadre y degradado de contraste, y logotipo con transparencia en bienvenida, acceso y menú. No se declara reproducción idéntica de toda la lámina: las métricas tipográficas y funciones pendientes conservan las diferencias documentadas abajo. No se contrataron recursos de pago.

Diferencias funcionales deliberadas: Google/Apple están deshabilitados hasta configurar proveedores; notificaciones y comentarios corresponden a fases futuras; categorías provienen de Supabase, sin copiar catálogos ficticios; prioridad administrativa no es editable por ciudadanos; términos institucionales están pendientes de aprobación. El registro conserva confirmación de correo y contraseña repetida; nombre y teléfono se completan en el perfil. No hay mapa público de incidentes ni datos simulados presentados como reales. La app no permite cambiar foto del perfil todavía.

Los cambios de interfaz no cambian RLS, privilegios ni la condición de PRUEBA PILOTO de los reportes.

Pulido posterior: paginación compacta sin desbordamientos en 390 px, botones adaptables al ancho, mapa con bordes redondeados, etiquetas de estado con texto, aviso compacto del piloto, estado vacío de reportes y confirmación de envío que se restablece al volver al listado. Se conserva navegación accesible mediante etiquetas y ayudas en los botones de icono. La revisión de Dart no encontró incidencias y la prueba específica de navegación móvil pasó.

Validación del pulido anterior: 15/15 pruebas Flutter aprobadas; análisis Dart sin incidencias. Bienvenida y acceso revisados visualmente en el navegador. El acceso social se muestra deshabilitado de forma explícita; no se simulan cuentas ni notificaciones. Para reproducir toda la lámina quedan las funciones pendientes documentadas arriba.

Nueva bienvenida: encabezado horizontal con RC y Cuautla, Morelos; titular Tu ciudad, tu voz.; subtítulo Reporta lo que importa.; acción principal azul. Conserva la fotografía original y el logo a color como archivos independientes, sin incrustar la captura de referencia ni sus botones en el fondo.
