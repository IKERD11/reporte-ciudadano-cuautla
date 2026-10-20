import 'package:flutter/material.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_home.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'fake_auth_repository.dart';

class HomeReports implements ReportRepository {
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async => action == 'context'
      ? {'enabled': true, 'categories': []}
      : action == 'detail'
      ? {
          'id': 'r1',
          'folio': 'REP-TEST-001',
          'latitude': 18.812,
          'longitude': -98.955,
          'status': 'Recibido',
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
  ]) async => action == 'list'
      ? {
          'reports': [
            {'id': 'r1'},
          ],
        }
      : super.call(action, values);
}

void main() {
  testWidgets('marcador muestra ficha sobre mapa y se cierra', (tester) async {
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
    expect(find.text('REP-TEST-001'), findsOneWidget);
    expect(find.text('Recibido'), findsOneWidget);
    expect(find.text('Luminaria de prueba sin luz'), findsOneWidget);
    expect(find.text('Sin fotografía'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Cerrar vista del reporte'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar vista del reporte'), findsNothing);
    expect(find.text('Sin fotografía'), findsNothing);
    expect(find.text('Incidentes cercanos'), findsOneWidget);
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
