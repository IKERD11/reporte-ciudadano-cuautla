import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'package:reporte_ciudadano/features/reports/report_wizard.dart';

class SearchRepository implements ReportRepository {
  final pending = <Completer<Map<String, dynamic>>>[];
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) {
    expect(action, 'geocode');
    final result = Completer<Map<String, dynamic>>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  testWidgets(
    'busca solo por botón, descarta respuesta antigua y coloca resultado elegido',
    (tester) async {
      final repo = SearchRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportWizard(
                categories: const [
                  {
                    'id': 'test',
                    'name': 'Alumbrado público',
                    'requires_location': true,
                    'requires_photo': false,
                    'subcategories': [],
                    'schema': {'properties': {}},
                  },
                ],
                repository: repo,
                geocode: (q) async {
                  final r = await repo.call('geocode', {'query': q});
                  return (r['results'] as List)
                      .map((v) => Map<String, dynamic>.from(v))
                      .toList();
                },
                onCreated: (_) {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alumbrado público'));
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('incident-address')),
        'Calle pública uno',
      );
      expect(repo.pending, isEmpty);
      await tester.tap(find.text('Buscar'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('incident-address')),
        'Calle pública dos',
      );
      repo.pending.first.complete({
        'results': [
          {
            'address': 'Resultado antiguo',
            'latitude': 18.81,
            'longitude': -98.95,
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('Resultado antiguo'), findsNothing);
      await tester.tap(find.text('Buscar'));
      await tester.pump();
      repo.pending.last.complete({
        'results': [
          {
            'address': 'Centro, Cuautla',
            'latitude': 18.81,
            'longitude': -98.95,
          },
        ],
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ListTile, 'Centro, Cuautla'),
      );
      await tester.tap(find.widgetWithText(ListTile, 'Centro, Cuautla'));
      await tester.pumpAndSettle();
      final map = tester.widget<ReportMap>(find.byType(ReportMap));
      expect(map.point?.latitude, 18.81);
      expect(map.point?.longitude, -98.95);
      expect(find.text('Ubicación seleccionada en el mapa'), findsOneWidget);
    },
  );
}
