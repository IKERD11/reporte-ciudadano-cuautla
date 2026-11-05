import 'manual_address_helper.dart';
import 'package:flutter/material.dart';
import 'package:reporte_ciudadano/core/citizen_sticker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/domain/auth_repository.dart';
import 'package:reporte_ciudadano/features/auth/presentation/edit_profile_screen.dart';
import 'package:reporte_ciudadano/features/reports/report_wizard.dart';
import 'fake_auth_repository.dart';
import 'reports_test.dart' show NoCalls;

class EditingRepository extends FakeAuthRepository
    implements AccountEmailRepository {
  List<String?>? saved;
  String? requestedEmail;
  int resets = 0;
  @override
  Future<CitizenProfile> updateProfile(
    String first,
    String last,
    String? phone,
  ) async {
    saved = [first, last, phone];
    return CitizenProfile(
      id: citizen.id,
      municipalityId: citizen.municipalityId,
      firstName: first,
      lastName: last,
      phone: phone,
      identityStatus: 'PENDING',
    );
  }

  @override
  Future<void> changeEmail(String email) async {
    requestedEmail = email;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    resets++;
  }
}

void main() {
  testWidgets('profile saves real fields and requests email confirmation', (
    tester,
  ) async {
    final repo = EditingRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(repo);
    await auth.start();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: citizenTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfileScreen(auth: auth, onPhotoSaved: (_) {}),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final avatar = tester
        .widgetList<CitizenSticker>(find.byType(CitizenSticker))
        .singleWhere((sticker) => sticker.name == 'user');
    expect(avatar.size, 104);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana María Pérez');
    await tester.enterText(fields.at(1), 'nuevo@example.test');
    await tester.enterText(fields.at(2), '+527351234567');
    await tester.scrollUntilVisible(
      find.text('Guardar cambios'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(repo.saved, ['Ana María', 'Pérez', '+527351234567']);
    expect(repo.requestedEmail, 'nuevo@example.test');
    expect(auth.account!.email, user.email);
    expect(
      find.text(
        'Datos guardados. Confirma el cambio en los enlaces enviados a tus correos.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('same-account update preserves ready profile while editing', () async {
    final repo = EditingRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(repo);
    await auth.start();
    final stages = <AuthStage>[];
    auth.addListener(() => stages.add(auth.stage));
    repo.events.add(
      const AuthSignal(Account('citizen-a', 'new@example.test', true)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.stage, AuthStage.ready);
    expect(auth.profile, citizen);
    expect(stages, [AuthStage.ready]);
    auth.dispose();
    await repo.events.close();
  });

  testWidgets('Deceso draft survives edits from confirmation at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: citizenTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: ReportWizard(
              categories: const [
                {
                  'id': 'deceso',
                  'name': 'Deceso',
                  'requires_location': false,
                  'requires_photo': false,
                  'subcategories': [],
                  'schema': {'properties': {}},
                },
              ],
              repository: NoCalls(),
              onCreated: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Deceso'));
    await tester.tap(find.text('Deceso'));
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('incident-description')),
      'Descripción sintética para la revisión.',
    );
    await enterManualReportAddress(
      tester,
      'Dirección pública de prueba, Cuautla',
    );
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Revisa tu reporte'), findsOneWidget);
    expect(
      find.text('Descripción sintética para la revisión.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Editar').first);
    await tester.tap(find.text('Editar').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('incident-description')),
          )
          .controller!
          .text,
      'Descripción sintética para la revisión.',
    );
    expect(
      find.textContaining('Dirección pública de prueba, Cuautla'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
