import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_home.dart';
import 'package:reporte_ciudadano/features/reports/reports_screen.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'fake_auth_repository.dart';

class CommunityRepository implements ReportRepository {
  final calls = <String>[];
  Map<String, dynamic> report(String id) => {
    'id': id,
    'folio': id,
    'category': id == 'OTRO-002' ? 'Alumbrado público' : 'Baches',
    'status': 'Recibido',
    'created_at': '2026-10-21T10:00:00Z',
    'latitude': 18.812,
    'longitude': -98.955,
    'description': 'Reporte comunitario de prueba',
    'address': 'Zona aproximada, Cuautla',
    'images': [],
    'additional_data': {},
    'schema': {},
    'timeline': [],
    'community': true,
  };
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    calls.add(action);
    if (action == 'context') return {'enabled': true, 'categories': []};
    if (action == 'community_list') {
      return {
        'reports': [report('MIO-001'), report('OTRO-002')],
        'has_more': false,
      };
    }
    if (action == 'list') {
      return {
        'reports': [report('MIO-001')],
      };
    }
    if (action == 'community_detail') return report('${values['report_id']}');
    if (action == 'notifications_count') return {'unread': 0};
    throw StateError('Unexpected $action');
  }
}

void main() {
  testWidgets(
    'personal and community scopes stay separate and other detail uses safe endpoint',
    (tester) async {
      final fake = FakeAuthRepository()
        ..current = user
        ..profile = citizen;
      final auth = AuthController(fake);
      await auth.start();
      final repo = CommunityRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: ReportsScreen(repository: repo, auth: auth),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alumbrado público'), findsNothing);
      await tester.tap(find.text('Comunidad'));
      await tester.pumpAndSettle();
      expect(find.text('Alumbrado público'), findsOneWidget);
      await tester.ensureVisible(find.text('Alumbrado público'));
      await tester.tap(find.text('Alumbrado público'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('community_detail'));
      expect(repo.calls, isNot(contains('detail')));
      expect(find.text('Reporte comunitario de prueba'), findsOneWidget);
      expect(
        find.textContaining('Las evidencias y datos privados no se comparten'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await fake.events.close();
    },
  );
  testWidgets(
    'community map loads other accounts without private detail requests',
    (tester) async {
      final fake = FakeAuthRepository()
        ..current = user
        ..profile = citizen;
      final auth = AuthController(fake);
      await auth.start();
      final repo = CommunityRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: CitizenHome(
            auth: auth,
            repository: repo,
            profileBuilder: () => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mapa').last);
      await tester.pumpAndSettle();
      final map = tester.widget<ReportMap>(find.byType(ReportMap));
      expect(map.reports.map((r) => r['id']), contains('OTRO-002'));
      expect(repo.calls, isNot(contains('detail')));
      expect(map.showZoneRadius, isFalse);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await fake.events.close();
    },
  );
}
