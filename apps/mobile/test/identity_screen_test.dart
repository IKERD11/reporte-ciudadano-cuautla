import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/identity/identity_repository.dart';
import 'package:reporte_ciudadano/features/identity/identity_screen.dart';
import 'fake_auth_repository.dart';

class IdentityFake implements IdentityRepository {
  int begins = 0;
  @override
  Future<Map<String, dynamic>> context() async => {
    'mode': 'synthetic',
    'case': null,
  };
  @override
  Future<Map<String, dynamic>> begin(String requestKey) async {
    begins++;
    return {
      'case': {
        'id': 'case',
        'status': 'PENDING',
        'front_uploaded': false,
        'back_uploaded': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> upload(String id, String side) async => {};
  @override
  Future<Map<String, dynamic>> submit(String id) async => {};
}

void main() {
  testWidgets('consentimiento obligatorio y captura real ausente', (
    tester,
  ) async {
    final repository = IdentityFake();
    final accountRepo = FakeAuthRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(accountRepo);
    await auth.start();
    await tester.pumpWidget(
      MaterialApp(
        home: IdentityScreen(repository: repository, auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    final start = find.widgetWithText(FilledButton, 'Iniciar prueba');
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    expect(find.text('SOLO MUESTRAS SINTÉTICAS'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(repository.begins, 1);
    expect(find.text('Pendiente de muestras'), findsOneWidget);
    expect(find.text('Abrir cámara'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    await accountRepo.events.close();
  });
}
