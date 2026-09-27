import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/main.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'fake_auth_repository.dart';

void main() {
  testWidgets('registro valida longitud y coincidencia antes de Supabase', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(CitizenApp(controller: AuthController(repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'citizen@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Usa al menos 12 caracteres.'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(repository.signupCalls, 0);
    await tester.pumpWidget(const SizedBox());
    await repository.events.close();
  });
  testWidgets('cuenta lista no ofrece reportes ni identidad verificada', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..current = user
      ..profile = citizen;
    await tester.pumpWidget(CitizenApp(controller: AuthController(repository)));
    await tester.pumpAndSettle();
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(
      find.text('Pendiente · INE real deshabilitada'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await repository.events.close();
  });
}

