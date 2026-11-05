import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_home.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_map_panels.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'fake_auth_repository.dart';
import 'citizen_home_test.dart' show MapReports;

void main() {
  testWidgets('nearby panel collapses to 64 and reopens', (tester) async {
    bool collapsed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CitizenNearbySheet(
              expanded: false,
              collapsed: collapsed,
              availableHeight: 844,
              reports: const [],
              onToggle: () {},
              onSelected: (_) {},
              onCollapse: () => setState(() => collapsed = !collapsed),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Ocultar incidentes cercanos'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('nearby-sheet'))).height,
      64,
    );
    expect(find.text('Ver todos'), findsNothing);
    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('nearby-sheet'))).height,
      203,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'nearby panel uses the CSS height curve and keeps its list scrollable',
    (tester) async {
      var expanded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Align(
                alignment: Alignment.bottomCenter,
                child: CitizenNearbySheet(
                  expanded: expanded,
                  availableHeight: 844,
                  reports: [
                    for (var i = 0; i < 8; i++)
                      {
                        'id': '$i',
                        'category': 'Alumbrado público',
                        'address': 'Dirección de prueba $i',
                      },
                  ],
                  onToggle: () => setState(() => expanded = !expanded),
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final sheet = find.byKey(const ValueKey('nearby-sheet'));
      expect(tester.getSize(sheet).height, 203);
      await tester.tap(find.text('Ver todos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      expect(
        tester.getSize(sheet).height,
        closeTo(203 + (560 - 203) * Curves.ease.transform(.5), .1),
      );
      await tester.pump(const Duration(milliseconds: 110));
      expect(tester.getSize(sheet).height, 560);
      await tester.drag(find.byType(ListView), const Offset(0, -650));
      await tester.pumpAndSettle();
      expect(find.text('Dirección de prueba 7').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Ver menos'));
      await tester.pumpAndSettle();
      expect(tester.getSize(sheet).height, 203);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('map menu and Ver todos keep map open at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
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
      expect(
        tester.widget<ReportMap>(find.byType(ReportMap)).initial3D,
        isTrue,
      );
      expect(
        tester.widget<ReportMap>(find.byType(ReportMap)).showPointMarker,
        isFalse,
      );
      await tester.tap(find.byTooltip('Filtrar incidentes'));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(tester.getSize(find.byType(CitizenMapFilterMenu)).width, 128);
      await tester.tap(find.text('Servicios'));
      await tester.pumpAndSettle();
      expect(find.byType(CitizenMapFilterMenu), findsNothing);
      await tester.tap(find.byTooltip('Filtrar incidentes'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CitizenMapFilterMenu>(find.byType(CitizenMapFilterMenu))
            .selected,
        'Servicios',
      );
      await tester.tap(find.byTooltip('Filtrar incidentes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver todos'));
      await tester.pumpAndSettle();
      expect(find.text('Mapa de incidentes'), findsOneWidget);
      expect(find.byType(ReportMap), findsOneWidget);
      expect(find.text('Ver menos'), findsOneWidget);
      expect(
        tester
            .widget<CitizenNearbySheet>(find.byType(CitizenNearbySheet))
            .expanded,
        isTrue,
      );
      if (size.height < 650) {
        // The reference's 443px panel overlaps its header on a 568px viewport.
        // Back/Home and reopening the map restores the collapsed source state.
        expect(find.text('Ver menos').hitTestable(), findsNothing);
        await tester.tap(find.byTooltip('Volver').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mapa').last);
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.text('Ver menos'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Ver todos'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await repo.events.close();
    });
  }

  testWidgets('reduced motion changes nearby height immediately', (
    tester,
  ) async {
    var expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Align(
                alignment: Alignment.bottomCenter,
                child: CitizenNearbySheet(
                  expanded: expanded,
                  availableHeight: 844,
                  reports: const [],
                  onToggle: () => setState(() => expanded = !expanded),
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver todos'));
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('nearby-sheet'))).height,
      560,
    );
    expect(tester.takeException(), isNull);
  });
}
