# Fase 5 — Panel administrativo del piloto

Panel Next.js en http://127.0.0.1:3001, separado de Flutter en el puerto 3000. Mantiene costo cero: ejecución local y Supabase existente; no se contrató hosting ni se publicó en Internet.

## Uso

Desde la raíz: `npm run dev --prefix apps/admin`. Para versión compilada: `npm run build --prefix apps/admin`, luego `npm run start --prefix apps/admin`. Las variables públicas de Supabase están en `.env.local` ignorado; nunca usar claves service role en el panel.

La cuenta autorizada por el usuario tiene rol MUNICIPAL_ADMIN para Cuautla. Iniciar sesión con la contraseña existente; no se creó ni cambió contraseña. El acceso ciudadano conserva su función original.

Incluye acceso, resumen, listado paginado de 20, búsqueda por folio/descripción/dirección, filtros por categoría/estado/fecha, mapa de la página, detalle con imágenes privadas firmadas por 60 segundos, historial, prioridad, asignación, métricas básicas, consulta de equipos y configuración. Configuración permite crear departamentos; no se inventaron departamentos institucionales. Crear el departamento antes de asignar.

Flujo: Recibido → En revisión → Validado → asignación → Asignado → En atención → Resuelto → Cerrado. Rechazo/duplicado desde recepción o revisión. Resuelto puede volver a atención. Estados terminales bloquean cambios. Permisos y versión del reporte se validan en PostgreSQL; cambios concurrentes requieren recargar. Auditoría registra actor, prioridad y asignación.

Solo reportes `is_pilot=true` del municipio y alcance autorizados. Operador/supervisor ven asignados; administrador/viewer ven el municipio. Viewer no escribe; operador no cierra ni asigna. Cada RPC comprueba sesión activa, correo confirmado, perfil y permisos almacenados. Ningún nuevo permiso directo de escritura sobre tablas.

## Referencia visual

Adaptación de la lámina de ocho pantallas: barra marina, botones azules, tarjetas claras, tabla, mapa y gráficas. Se conserva fotografía original disponible y logo RC a color. No es una copia píxel por píxel. La opción Explorar diseño usa ocho datos sintéticos en memoria, identificados como DEMOSTRACIÓN, y desactiva guardado; no crea reportes en Supabase.

## Validación y límites

29/29 pruebas SQL transaccionales en Supabase con rollback: separación municipal, denegación de ciudadano/anon, asignación, transiciones, control de versión, historial, fechas de resolución, departamentos y revocación de sesión. Compilación Next.js y TypeScript aprobadas. Revisión visual de acceso, resumen y navegación con datos sintéticos. El ingreso real con contraseña y una gestión completa por navegador quedan para la sesión del usuario; no se obtuvo su contraseña.

Pendientes: notificaciones/realtime fase 6; SLA, exportación y analítica avanzada fase 7. No hay edición de roles ni categorías desde la interfaz. La cuenta administrativa no habilita INE reales. El mapa consulta OpenStreetMap y no descarga mapas offline; solo muestra la página actual de hasta 20 registros. Equipo limitado a 200 perfiles activos.

Asesor de seguridad conserva dos avisos informativos por tablas privadas con denegación intencional y el aviso preexistente de protección de contraseñas filtradas desactivada: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection . No se activaron servicios de pago.

Actualización visual: paleta nocturna con acentos cian, violeta y menta. Login conserva distribución con nuevos colores y radios. Métricas SVG locales: tendencia semanal con área y puntos consultables, distribución por categoría con anillo y porcentajes, barras proporcionales por estado. No se modifican consultas, permisos ni datos. Compilación y TypeScript aprobados; login y métricas revisados en navegador con demostración.

Controles visuales unificados: selectores personalizados con teclado, calendarios en español, tarjetas de seguimiento, filtros, estados deshabilitados y controles de mapa con tema oscuro. Verificación: compilación de producción correcta; apertura del calendario, selección de fecha y selección de categoría por teclado comprobadas en la demostración. Sin cambios de datos ni servicios adicionales.

