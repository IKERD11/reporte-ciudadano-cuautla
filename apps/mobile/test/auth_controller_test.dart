import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/domain/auth_repository.dart';
import 'fake_auth_repository.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);
void main() {
  late FakeAuthRepository repository;
  late AuthController controller;
  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository);
  });
  tearDown(() async {
    controller.dispose();
    await repository.events.close();
  });
  test('registro requiere confirmar correo antes del perfil', () async {
    await controller.start();
    await controller.register('citizen@example.test', 'a-long-password');
    expect(controller.stage, AuthStage.confirmation);
    expect(controller.profile, isNull);
  });
  test('login confirmado sin perfil muestra municipios habilitados', () async {
    await controller.start();
    await controller.login('citizen@example.test', 'a-long-password');
    await settle();
    expect(controller.stage, AuthStage.profileSetup);
    expect(controller.municipalities.single.name, 'Cuautla');
    await controller.complete('cuautla', 'Ana', 'Pérez');
    expect(controller.stage, AuthStage.ready);
  });
  test('login sin confirmar permite reenviar enlace', () async {
    repository.loginError = const AuthException(
      'Not confirmed',
      code: 'email_not_confirmed',
    );
    await controller.start();
    await controller.login('citizen@example.test', 'a-long-password');
    expect(controller.stage, AuthStage.confirmation);
    expect(controller.pendingEmail, 'citizen@example.test');
  });
  test(
    'recuperación persiste ante eventos y cierra sesión al guardar',
    () async {
      await controller.start();
      repository.events.add(const AuthSignal(user, recovery: true));
      repository.events.add(const AuthSignal(user));
      expect(controller.stage, AuthStage.recovery);
      await controller.savePassword('another-long-password');
      expect(repository.updatePasswordCalls, 1);
      expect(repository.logoutCalls, 1);
      expect(controller.stage, AuthStage.signedOut);
    },
  );
  test('respuesta tardía de perfil no restaura una sesión cerrada', () async {
    await controller.start();
    repository.pendingProfile = Completer<CitizenProfile?>();
    repository.events.add(const AuthSignal(user));
    await controller.logout();
    repository.pendingProfile!.complete(citizen);
    await settle();
    expect(controller.stage, AuthStage.signedOut);
    expect(controller.profile, isNull);
  });
  test('error de red no presenta un perfil como cargado', () async {
    await controller.start();
    repository.pendingProfile = Completer<CitizenProfile?>();
    repository.events.add(const AuthSignal(user));
    repository.events.addError(Exception('offline'));
    repository.pendingProfile!.complete(citizen);
    await settle();
    expect(controller.stage, AuthStage.unavailable);
    expect(controller.profile, isNull);
    expect(controller.message, isNotNull);
  });
}
