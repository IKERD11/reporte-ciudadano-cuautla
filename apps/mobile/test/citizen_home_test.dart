import 'package:flutter/material.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_home.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'fake_auth_repository.dart';
import 'package:reporte_ciudadano/features/reports/reports_screen.dart';

class HomeReports implements ReportRepository {
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async => action == 'context'
      ? {'enabled': true, 'categories': []}
      : (action == 'detail' || action == 'community_detail')
      ? {
          'id': 'r1',
          'folio': 'REP-TEST-001',
          'latitude': 18.812,
          'longitude': -98.955,
          'status': 'Recibido',
          'category': 'Alumbrado público',
          'address': 'Parque público, Cuautla',
          'created_at': '2026-10-21T10:00:00Z',
          'schema': {'properties': {}},
          'additional_data': {},
          'timeline': [],
          'description': 'Luminaria de prueba sin luz',
          'images': [],
        }
      : action == 'notifications_list'
      ? {'items': [], 'total': 0}
      : {'reports': []};
}

class MapReports extends HomeReports {
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async => (action == 'list' || action == 'community_list')
      ? {
          'reports': [
            {
              'id': 'r1',
              'latitude': 18.812,
              'longitude': -98.955,
              'category': 'Alumbrado público',
              'status': 'Recibido',
              'address': 'Zona de prueba',
              'folio': 'REP-TEST-001',
            },
          ],
        }
      : super.call(action, values);
}

class UnavailableImage implements ReportRepository {
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async => throw Exception('Sin acceso');
}

void main() {
  testWidgets('evidence thumbnail keeps original height and rounded corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            child: PrivateReportImage(
              repository: UnavailableImage(),
              reportId: 'private-report',
              imageId: 'private-image',
              large: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(PrivateReportImage)),
      const Size(100, 116),
    );
    final clip = tester.widget<ClipRRect>(
      find
          .descendant(
            of: find.byType(PrivateReportImage),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    expect(clip.borderRadius, BorderRadius.circular(13));
    expect(find.byTooltip('Reintentar foto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map marker opens the original detail route and returns to map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeAuthRepository()
      ..current = user
      ..profile = citizen;
    final auth = AuthController(repo);
    await auth.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: citizenTheme(),
        home: CitizenHome(
          auth: auth,
          repository: MapReports(),
          profileBuilder: () => const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa').last);
    await tester.pumpAndSettle();
    final map = tester.widget<ReportMap>(find.byType(ReportMap));
    map.onReportSelected!(map.reports.first);
    await tester.pumpAndSettle();
    expect(find.text('Detalle del reporte'), findsOneWidget);
    expect(find.text('Recibido'), findsOneWidget);
    expect(find.text('Folio: REP-TEST-001'), findsOneWidget);
    final preview = tester.widget<ReportMap>(find.byType(ReportMap).last);
    expect(preview.preview, isTrue);
    expect(preview.height, 86);
    expect(tester.getSize(find.byType(ReportMap).last).width, 135);
    expect(find.text('Luminaria de prueba sin luz'), findsOneWidget);
    expect(
      tester
          .widgetList<ReportMap>(find.byType(ReportMap))
          .every((map) => !map.allow3D),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Volver').first);
    await tester.pumpAndSettle();
    expect(find.text('Incidentes cercanos'), findsOneWidget);
    expect(tester.widget<ReportMap>(find.byType(ReportMap)).allow3D, isTrue);
    // A pushed report route must release the map even while the home route remains mounted.
    await tester.tap(find.text('Reportar').last);
    await tester.pumpAndSettle();
    expect(find.byType(ReportMap, skipOffstage: false), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ReportMap), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
    await repo.events.close();
  });
  testWidgets(
    'inicio móvil navega al perfil y a reportes sin desbordamientos',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeAuthRepository()
        ..current = user
        ..profile = citizen;
      final auth = AuthController(repo);
      await auth.start();
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: CitizenHome(
            auth: auth,
            repository: HomeReports(),
            profileBuilder: () => const Text('Perfil de prueba'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Pérez'), findsOneWidget);
      await tester.tap(find.text('Mis reportes'));
      await tester.pumpAndSettle();
      expect(find.text('No hay reportes con este estado.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await repo.events.close();
    },
  );
}
