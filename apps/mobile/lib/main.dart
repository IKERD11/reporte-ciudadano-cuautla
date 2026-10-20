import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_config.dart';
import 'core/citizen_theme.dart';
import 'core/citizen_widgets.dart';
import 'core/secure_auth_storage.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/presentation/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthController? controller;
  String? startupError;
  if (AppConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.url,
        publishableKey: AppConfig.publishableKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          localStorage: kIsWeb
              ? const EmptyLocalStorage()
              : const SecureAuthStorage('reporte-ciudadano'),
          pkceAsyncStorage: kIsWeb
              ? null
              : SecurePkceStorage('reporte-ciudadano'),
          detectSessionInUriPredicate: AppConfig.isAuthCallback,
        ),
      );
      controller = AuthController(
        SupabaseAuthRepository(Supabase.instance.client),
      );
    } catch (_) {
      startupError =
          'No se pudo preparar el acceso. Cierra la aplicación e inténtalo nuevamente.';
    }
  }
  runApp(CitizenApp(controller: controller, startupError: startupError));
}

class CitizenApp extends StatelessWidget {
  const CitizenApp({super.key, this.controller, this.startupError});
  final AuthController? controller;
  final String? startupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cuautla Segura',
    debugShowCheckedModeBanner: false,
    theme: citizenTheme(),
    builder: (context, child) => CitizenFrame(child: child!),
    home: controller == null
        ? Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  startupError ??
                      'Falta configurar la conexión del piloto. Consulta la guía de instalación.',
                ),
              ),
            ),
          )
        : AuthScreen(controller: controller!),
  );
}
