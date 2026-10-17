# Continuar el desarrollo

Piloto de Reporte Ciudadano para Cuautla, Morelos. Mantener costo cero, reportes de prueba e INE exclusivamente sintéticas. No habilitar atención municipal ni subir documentos reales.

## Preparación

Instalar Git, Node.js 22.18 o posterior (las pruebas usan TypeScript nativo), Flutter compatible con Dart 3.10.4 y, para la base local, Docker Desktop. Los lockfiles fijan las dependencias; usar `npm ci` y `flutter pub get`, sin actualizaciones masivas.

1. Clonar el repositorio e instalar las herramientas raíz con `npm ci`.
2. Copiar `apps/mobile/config/pilot.example.json` a `apps/mobile/config/pilot.json`.
3. Copiar `apps/admin/.env.example` a `apps/admin/.env.local`.
4. Configurar URL y clave pública del proyecto de desarrollo. Solicitar acceso al responsable por un canal privado; nunca copiar una clave service_role al frontend.

## Ejecutar

App ciudadana, desde `apps/mobile`:

```powershell
flutter pub get
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 --dart-define-from-file=config/pilot.json
```

Panel, desde `apps/admin`:

```powershell
npm ci
npm run dev
```

Panel en http://127.0.0.1:3001. Los roles administrativos se validan en servidor; clonar el código no concede acceso administrativo.

## Verificaciones

- Flutter: `flutter analyze` y `flutter test` desde `apps/mobile`.
- Panel: `npm run typecheck` y `npm run build` desde `apps/admin`.
- SQL: `npm run db:syntax` desde la raíz. Para pgTAP, seguir el README y ejecutar la base **local**; `db:reset` borra los datos locales.
- La plantilla `docs/ci/database-workflow.yml` contiene el workflow manual de base de datos. No está activo: la conexión usada para subir el proyecto no tiene el permiso `workflow`. Si el propietario decide habilitarlo, puede copiarlo a `.github/workflows/database.yml` con una cuenta autorizada, después de revisar la cuota gratuita. No activar facturación ni servicios de pago.

## Contenido y estado

Incluye código Flutter y Next.js, recursos gráficos, migraciones, funciones, fixtures sintéticos, pruebas y documentación de fases 1–6. Consultar `docs/fase-6-notificaciones.md`, `docs/fase-5-administracion.md`, `docs/ubicacion-reportes.md` y `docs/piloto-costo-cero.md`.

No es un respaldo de datos de producción: las cuentas, reportes, archivos privados de Storage y secretos permanecen en Supabase. Tampoco se versionan dependencias descargadas, compilaciones, cachés ni configuraciones propias de cada equipo; se regeneran con los comandos indicados.

## Colaboración

Crear una rama desde `main`, realizar cambios acotados y abrir un pull request. Mantener las migraciones existentes; añadir una migración nueva para cada modificación de base. No aplicar cambios remotos ni desplegar automáticamente desde una rama de trabajo. El propietario debe invitar a los colaboradores al repositorio privado y conceder separadamente los accesos necesarios a Supabase.
