# Estado comprobado del piloto — 15 de octubre de 2026

## Implementado en esta revisión

- Administración de roles municipales desde Equipos: busca cuentas registradas del mismo municipio, muestra permisos, exige confirmar el cambio y registra auditoría. No permite editar el acceso propio ni cuentas globales. Rechaza cambios basados en roles antiguos y exige reasignar casos activos antes de retirar acceso operativo. Usa los roles existentes; no permite crear roles globales ni permisos arbitrarios.
- Exportación CSV de todos los resultados filtrados en una única consulta: máximo 5,000 registros, sin truncamiento silencioso. Mantiene también exportación de página. Respeta permisos y neutraliza fórmulas de hojas de cálculo.
- Búsqueda explícita de direcciones públicas con Nominatim, autorizada por el responsable del piloto. Presenta hasta cinco candidatos; la selección coloca el marcador. La escritura sola no consulta al proveedor. Respuestas antiguas se descartan cuando cambia la dirección, se utiliza GPS o se selecciona el mapa.
- Caché compartida por 30 días, sin guardar la consulta en texto ni vincularla a la cuenta; almacena hash y candidatos públicos. Un bloqueo compartido serializa consultas, aplica una pausa de 1.1 segundos tras finalizar y limita a 100 consultas externas diarias para toda la aplicación. Fallos del servidor mantienen una reserva de hasta 60 segundos. La limpieza de entradas vencidas ocurre en la siguiente consulta externa.
- El servidor permite cambiar proveedor compatible mediante `GEOCODING_URL` y desactivar búsquedas mediante `GEOCODING_DISABLED=true`, sin actualizar Flutter. No se registran consultas ni tokens en logs de aplicación.

## Evidencia de validación

- Base existente: 53 pruebas de administración, roles, exportación y notificaciones; 26 de reportes; 12 de identidad sintética; 9 de geocodificación. Todas aprobadas en transacciones revertidas. Esto NO demuestra reconstrucción de una base limpia ni validación visual completa.
- Tres pruebas de normalización, límites geográficos y entradas inválidas del geocodificador aprobadas.
- Prueba Flutter: escribir no envía búsquedas, descarta respuesta atrasada y coloca coordenadas del candidato elegido; aprobada. Suite completa: 23 pruebas aprobadas; análisis Flutter sin incidencias y compilación web de producción aprobada.
- Panel: tres pruebas de fechas/CSV/conteos y compilación de producción aprobadas.
- Consulta pública aislada al proveedor devolvió HTTP 200 sin candidatos. No se declara comprobada cobertura de todas las calles ni recorrido autenticado completo del buscador.
- Migraciones `team_management_export` y `pilot_geocoding` aplicadas; función `report-pilot` actualizada con verificación propia de JWT y sesión activa.

## Pendientes reales

- GPS real y recorrido visual autenticado: se solicitó iniciar sesión al usuario; no hay confirmación todavía. Pruebas simuladas no sustituyen esta comprobación.
- Android/iOS pospuestos por el usuario; alcance actual web.
- Docker local no disponible. Falta reconstruir todas las migraciones desde cero y ensayar restauración. Nunca hacer reset remoto.
- Aplicaciones aún sin publicación pública configurada; solo el atlas está publicado. CI permanece como plantilla sin activar.
- Push con la app cerrada, roles personalizados e invitaciones por correo no implementados. Los avisos internos y roles fijos sí funcionan.
- Avisos institucionales, plazos de conservación y responsables autorizados pendientes: no activar INE reales ni operación municipal.
- [Aviso de contraseñas filtradas desactivadas](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) persiste. [Cuatro tablas privadas sin políticas](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) deniegan acceso directo de clientes intencionalmente. No ampliar permisos para silenciar esos avisos.
- Atlas/PDF existentes describen la versión previa a las nuevas tablas de caché y gestión de roles; deben regenerarse antes de considerarlos documentación actualizada.

## Operación de Nominatim

Uso exclusivo para direcciones públicas del incidente en Cuautla; no nombres, teléfonos, correos ni domicilios privados. Sin autocompletado, consultas periódicas, descarga masiva ni búsquedas automáticas al escribir. No tiene garantía de disponibilidad: se conserva GPS, dirección manual y mapa.

El responsable debe cumplir la [política de Nominatim](https://operations.osmfoundation.org/policies/nominatim/) y la [licencia ODbL / atribución](https://www.openstreetmap.org/copyright). La aplicación muestra atribución al proveedor. El límite gratuito es una restricción operativa, no una garantía comercial.
