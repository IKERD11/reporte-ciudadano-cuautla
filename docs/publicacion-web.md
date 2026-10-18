# Publicación del piloto web — 17 de octubre de 2026

- App ciudadana: https://ikerd11.github.io/reporte-ciudadano-app/
- Panel administrativo: https://ikerd11.github.io/reporte-ciudadano-dashboard/

Ambos sitios están publicados en GitHub Pages con HTTPS. Son páginas de prueba
conectadas al proyecto Supabase existente. No representan atención municipal real.
El panel requiere una cuenta con permisos; publicar su login no concede acceso
a reportes. Se mantienen INE reales bloqueadas y la demostración deshabilitada
en la compilación de producción.

El código fuente de trabajo sigue en el repositorio privado. Los repositorios
públicos `IKERD11/reporte-ciudadano-app` y `IKERD11/reporte-ciudadano-dashboard`
contienen los archivos compilados que descarga el navegador, no respaldos,
evidencias, sesiones ni claves de servidor. La clave publicable de Supabase
forma parte del cliente; la autorización se aplica en el backend.

## Configuración aplicada

- Pages: rama `main`, raíz `/`, HTTPS obligatorio en ambos repositorios.
- Flutter: base `/reporte-ciudadano-app/` y `AUTH_REDIRECT_URL` con la URL pública.
- Next.js: exportación estática opcional mediante `STATIC_EXPORT=true`, base
  `/reporte-ciudadano-dashboard` y recuperación enlazada a la app pública.
- Supabase Auth: Site URL y retorno permitido exacto de la app pública;
  se conservaron los retornos locales y el esquema nativo anteriores.
- Funciones `report-pilot` e `identity-pilot`: versión 3, permiten el origen
  `https://ikerd11.github.io`, conservando comprobación de usuario y sesión.
  CORS identifica el origen, no rutas: no sustituye autenticación o permisos.
- `robots.txt` y metadatos solicitan no indexar el piloto; no son control de acceso.

## Volver a compilar

Desde `apps/mobile`, con Flutter instalado y `config/pilot.json` local:

```powershell
flutter build web --release --base-href=/reporte-ciudadano-app/ --dart-define-from-file=config/pilot.json --dart-define=AUTH_REDIRECT_URL=https://ikerd11.github.io/reporte-ciudadano-app/
```

Desde `apps/admin`, con dependencias instaladas y `.env.local` que contenga
solo URL y clave pública para las variables `NEXT_PUBLIC_SUPABASE_*`:

```powershell
$env:STATIC_EXPORT='true'
$env:NEXT_PUBLIC_BASE_PATH='/reporte-ciudadano-dashboard'
$env:NEXT_PUBLIC_CITIZEN_APP_URL='https://ikerd11.github.io/reporte-ciudadano-app/'
npm run build
```

Copiar exclusivamente el contenido de `apps/mobile/build/web/` o
`apps/admin/out/` a su repositorio de publicación respectivo; preservar
`.git`, `.nojekyll`, `robots.txt` y README. Revisar archivos antes del commit,
retirar únicamente recursos obsoletos comprobados y subir a `main`.
No copiar `.env`, fuentes de servidor, mapas de fuentes, respaldos ni
directorios completos del proyecto. Esperar el despliegue Pages exitoso y
verificar las URLs públicas después de cada actualización.

Los cambios futuros en Supabase se despliegan por separado. Subir cambios al
repositorio privado no actualiza automáticamente ninguno de los sitios.

## Comprobaciones realizadas

- Compilaciones de producción de Flutter web y exportación Next.js aprobadas.
- Tres pruebas del panel aprobadas.
- Despliegues Pages completados con éxito; HTTPS habilitado.
- Páginas principales, JavaScript de Flutter y recursos de marca: HTTP 200.
- Bienvenida ciudadana y login administrativo visibles en navegador público.
- En ambas funciones: OPTIONS del origen público responde 204; origen ajeno
  responde 403; solicitud sin sesión responde 401.
- Site URL y lista de retornos de Supabase confirmados en su configuración.
- Solo claves publicables en clientes; paquetes revisados antes de entrega.

## Límites y pruebas pendientes

No se ha acreditado aquí el recorrido autenticado completo, el GPS real ni
la entrega de correos. Probar con cuentas existentes del piloto; el correo
incluido de Supabase tiene restricciones de destinatarios y cuota. No se
contrató SMTP externo ni se desactivó la confirmación de correo.

GitHub Pages no aplica los encabezados personalizados configurados para
el servidor Next.js; la exportación los omite y conserva la política de
referencia en metadatos. No atribuir a este alojamiento soporte de
`X-Frame-Options` o políticas HTTP personalizadas. Revisar un alojamiento
con esos controles antes de una operación real.

No se activó facturación. Pages usa repositorios públicos gratuitos y
Supabase conserva el plan del piloto y sus cuotas. La publicación automática
de archivos de Pages sí está activa; la plantilla CI de pruebas del código
y base de datos continúa pendiente.

Referencias: [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages),
[exportación Next.js](https://nextjs.org/docs/app/guides/static-exports),
[retornos Supabase](https://supabase.com/docs/guides/auth/redirect-urls).
