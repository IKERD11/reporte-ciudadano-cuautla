import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/features/reports/report_tracking_screen.dart';

void main() {
  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('tracking layout and truthful pending stages at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportTrackingScreen(
            report: {
              'category': 'Baches',
              'folio': 'REP-2026-000035',
              'status': 'Recibido',
              'created_at': '2026-09-27T13:38:00Z',
              'timeline': [
                {'status': 'Recibido', 'created_at': '2026-09-27T13:38:00Z'},
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('Pendiente'), findsWidgets);
      expect(find.text('En revisión'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Resuelto'), 200);
      expect(find.text('Resuelto'), findsOneWidget);
      expect(find.textContaining('12:05'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
