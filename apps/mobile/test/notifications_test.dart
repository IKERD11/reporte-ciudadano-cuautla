import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/notifications/notifications_screen.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'fake_auth_repository.dart';

class Notices implements ReportRepository {
  bool fail = false;
  int reads = 0;
  final offsets = <int>[];
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (fail) throw Exception('offline');
    if (action == 'notifications_read') {
      reads++;
      return {'saved': true};
    }
    offsets.add(values['offset'] as int);
    return {
      'total': 21,
      'items': List.generate(
        values['offset'] == 0 ? 20 : 1,
        (i) => {
          'id': 'n$i',
          'report_id': null,
          'title': 'Aviso $i',
          'body': 'PRUEBA PILOTO',
          'created_at': '2026-09-26T12:00:00Z',
          'read_at': null,
        },
      ),
    };
  }
}

void main() {
  testWidgets('acknowledges once and paginates notifications', (tester) async {
    final repo = FakeAuthRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(repo);
    await auth.start();
    final notices = Notices();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(repository: notices, auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aviso 0'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de alerta'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aviso 0'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de alerta'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(notices.reads, 1);
    await tester.scrollUntilVisible(find.text('Siguiente'), 500);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(notices.offsets, [0, 20]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    await repo.events.close();
  });
  testWidgets('network failure can retry without losing the screen', (
    tester,
  ) async {
    final repo = FakeAuthRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(repo);
    await auth.start();
    final notices = Notices()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(repository: notices, auth: auth),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No pudimos cargar los avisos. Reintenta.'),
      findsOneWidget,
    );
    notices.fail = false;
    await tester.tap(find.text('No pudimos cargar los avisos. Reintenta.'));
    await tester.pumpAndSettle();
    expect(find.text('Aviso 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    await repo.events.close();
  });
}
