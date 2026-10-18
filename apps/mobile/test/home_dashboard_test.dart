import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/citizen_theme.dart';
import 'package:reporte_ciudadano/core/citizen_widgets.dart';
import 'package:reporte_ciudadano/features/auth/presentation/citizen_home_dashboard.dart';

void main() {
  for (final width in [320.0, 390.0, 760.0]) {
    testWidgets('inicio claro adaptable a $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reports = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: citizenTheme(),
          home: CitizenFrame(
            child: Scaffold(
              body: CitizenHomeDashboard(
                name: 'Ana',
                unread: 0,
                onMenu: () {},
                onReport: () {
                  reports++;
                },
                onMap: () {},
                onReports: () {},
                onNotifications: () {},
                onHelp: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cuautla, Morelos'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      await tester.tap(find.text('Realizar reporte'));
      expect(reports, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
