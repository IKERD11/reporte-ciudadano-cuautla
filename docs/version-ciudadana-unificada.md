# Versión ciudadana unificada

La aplicación ciudadana oficial es apps/mobile (Flutter). Se conservan Supabase Auth, reportes reales del piloto, comunidad, configuración de zona y Actividad. El historial de la rama de Figma se fusiona sin añadir su app de demostración como segundo frontend.

Para compilar con Web Push, añadir --pwa-strategy=none y --dart-define=VAPID_PUBLIC_KEY=<clave pública> al comando de publicación. La clave privada queda en Supabase. Perfil permite solicitar permiso y registrar la suscripción en server. El service worker abre la app al pulsar el aviso.

Actividad sigue leyendo las notificaciones reales del piloto. El registro de dispositivos y el servicio de envío están disponibles, pero falta conectar los eventos de reportes al envío automático y validar la entrega en un dispositivo con permiso concedido.
