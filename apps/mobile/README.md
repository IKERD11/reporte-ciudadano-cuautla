# Aplicación Flutter

Fase 2: registro, login, confirmación de correo, recuperación y perfil ciudadano con Supabase real.

Ver [ejecución, pruebas y limitaciones](../../docs/fase-2-autenticacion.md). Configuración publicable del piloto en `config/pilot.json`.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000 --dart-define-from-file=config/pilot.json
```

Android/iOS usan almacenamiento seguro. La vista web del piloto no persiste sesiones. No incluir claves service_role ni contraseñas en la aplicación.
