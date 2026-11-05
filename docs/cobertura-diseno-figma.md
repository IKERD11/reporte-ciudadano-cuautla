# Cobertura de pantallas ciudadanas

La fuente visual completa de la exportación exterior del ZIP está en `design/figma`. El ZIP anidado es anterior: contiene 21 rutas; el exterior contiene 28. Se preservaron JSX, CSS y recursos sin adaptar su diseño. Se excluyeron el ZIP anidado, cachés y archivos de entorno reales.

La aplicación publicada sigue siendo `apps/mobile`. La referencia React puede compilarse con `pnpm install --frozen-lockfile` y `pnpm build`; no es el frontend de producción.

- Con equivalente operativo en Flutter (19): bienvenida, iniciar sesión, recuperar contraseña, restablecer contraseña, registro, inicio, configurar zona, categoría, detalles de captura, confirmación, éxito, mapa, mis reportes, detalle de reporte, seguimiento, actividad, alertas comunitarias, perfil y editar perfil.
- Parciales (3): contactos útiles; detalle de alerta (abre el detalle de reporte); cambiar contraseña (usa recuperación por correo).
- Sin pantalla propia en Flutter (6): detalle de contacto, SOS, bandeja de notificaciones, preferencias de notificaciones, privacidad y seguridad, ayuda y soporte.

No sustituir la versión publicada con el ZIP sin conectar primero el contrato real de reportes, la comunidad y el historial. La exportación inicia con incidentes de demostración y navega a éxito al confirmar sin enviar un reporte. Además usa una ruta de notificaciones anterior a la desplegada. La corrección del backend permanece en `supabase/functions/server`, fuera del directorio de referencia.

## Acceso desde la aplicación unificada

La aplicación web incorpora las nueve pantallas pendientes o parciales en Perfil → Pantallas en integración. Privacidad y Ayuda también abren directamente sus pantallas. Los flujos que ya trabajan con datos reales mantienen sus rutas Flutter. Las pantallas anexadas reutilizan la compilación del diseño en un marco interno con aviso de datos de muestra; no usan autenticación ni escrituras de producción. El acceso directo anterior de revisión redirige a la aplicación principal.
