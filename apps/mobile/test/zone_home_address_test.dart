import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/core/zone_storage.dart';
import 'package:reporte_ciudadano/features/auth/application/auth_controller.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_home.dart';
import 'package:reporte_ciudadano/features/auth/presentation/zone_screen.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'fake_auth_repository.dart';
import 'citizen_home_test.dart' show HomeReports;

void main() {
  for (final manual in [false, true]) {
    testWidgets('home address updates and persists, manual=$manual', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      writeZone(user.id, const CitizenZone().encode());
      final repository = FakeAuthRepository()
        ..current = user
        ..profile = citizen;
      final auth = AuthController(repository);
      await auth.start();
      const address = 'Av. Reforma 123, Centro, Cuautla, Morelos';
      final queries = <String>[];
      Widget home() => MaterialApp(
        theme: citizenTheme(),
        home: CitizenHome(
          auth: auth,
          repository: HomeReports(),
          profileBuilder: () => const SizedBox(),
          geocode: (query) async {
            queries.add(query);
            return [
              {'address': address, 'latitude': 18.82, 'longitude': -98.96},
            ];
          },
        ),
      );
      await tester.pumpWidget(home());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cuautla, Morelos'));
      await tester.pumpAndSettle();
      if (manual) {
        await tester.tap(find.text('Cuautla, Morelos'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Av. Reforma');
        await tester.enterText(fields.at(1), '123');
        await tester.enterText(fields.at(2), 'Centro');
        await tester.enterText(fields.at(3), '62740');
        await tester.ensureVisible(find.text('Buscar dirección'));
        await tester.tap(find.text('Buscar dirección'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(ListTile, address));
        await tester.tap(find.widgetWithText(ListTile, address));
        await tester.pumpAndSettle();
      } else {
        tester.widget<ReportMap>(find.byType(ReportMap)).onSelected!(
          const LatLng(18.82, -98.96),
        );
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(queries.single, '18.82000, -98.96000');
      }
      await tester.scrollUntilVisible(
        find.text('Guardar zona'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Guardar zona'));
      await tester.pumpAndSettle();
      expect(find.text(address), findsOneWidget);
      expect(CitizenZone.decode(readZone(user.id)).address, address);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(home());
      await tester.pumpAndSettle();
      expect(find.text(address), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
      await repository.events.close();
    });
  }
}
