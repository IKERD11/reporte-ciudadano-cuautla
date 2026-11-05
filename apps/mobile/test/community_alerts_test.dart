import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/notifications/notifications_screen.dart';
import 'fake_auth_repository.dart';
import 'community_reports_test.dart' show CommunityRepository;

class AlertReports extends CommunityRepository {
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (action == 'community_list') {
      calls.add(action);
      final first = (values['offset'] ?? 0) == 0;
      return {
        'reports': first
            ? List.generate(
                20,
                (i) => report('service-$i')..['category'] = 'Alumbrado público',
              )
            : [report('other-account')..['category'] = 'Robo'],
        'has_more': first,
      };
    }
    if (action == 'community_detail') {
      calls.add(action);
      return report('other-account')..['category'] = 'Robo';
    }
    return super.call(action, values);
  }
}

void main() {
  testWidgets(
    'community alerts filter all pages and open other citizen report',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAuthRepository()
        ..current = user
        ..profile = citizen;
      final auth = AuthController(fake);
      await auth.start();
      final repo = AlertReports();
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: NotificationsScreen(repository: repo, auth: auth),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alertas comunitarias'), findsOneWidget);
      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();
      expect(find.text('Robo'), findsOneWidget);
      expect(find.text('Alumbrado público'), findsNothing);
      await tester.tap(find.text('Robo'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('community_detail'));
      expect(repo.calls, isNot(contains('notifications_list')));
      expect(repo.calls, isNot(contains('notifications_read')));
      expect(find.text('Detalle del reporte'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await fake.events.close();
    },
  );
}
