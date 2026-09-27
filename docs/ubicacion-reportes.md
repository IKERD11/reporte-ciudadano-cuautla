# Ubicación del reporte (piloto)

El paso de ubicación permite escribir una dirección (calle, número, colonia y referencia) o pulsar **Usar mi ubicación**. No solicita latitud ni longitud al ciudadano.

- Cuando la categoría requiere ubicación, se exige un punto GPS o una dirección de al menos 10 caracteres, tanto en Flutter como en la función de base de datos.
- La dirección escrita se conserva como texto: no se geocodifica ni se sustituye por el centro de Cuautla. Estos reportes tienen ubicación geográfica nula y no generan un marcador ficticio.
- El GPS se solicita únicamente al pulsar el botón y requiere permiso del dispositivo/navegador. Tiene un límite de espera de 20 segundos; los errores permiten continuar con una dirección.
- El mapa permanece visible para seleccionar, revisar o ajustar el punto; también se puede quitar el punto. El mapa no es necesario para enviar una dirección. Escribir una dirección no coloca un marcador automáticamente.
- La compilación web se regeneró desde cero porque el registrante anterior no incluía `geolocator_web` ni `image_picker_for_web`. Verificar el registrante generado después de añadir complementos Flutter.
- El HTML usa `strict-origin-when-cross-origin`, compatible con la política de teselas de OpenStreetMap: https://operations.osmfoundation.org/policies/tiles/ . No se ha añadido ningún proveedor de pago.

Validación: suite Flutter (21 pruebas), comprobación de reserva/confirmación con dirección y coordenadas nulas en Supabase (26 aserciones con rollback), análisis estático y compilación web.

El asesor de seguridad conserva los avisos previos: dos tablas privadas con RLS sin políticas (acceso directo denegado deliberadamente) y protección contra contraseñas filtradas desactivada. Referencias: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy y https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection . Este cambio no modifica permisos ni autenticación.
