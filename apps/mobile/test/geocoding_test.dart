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
    'dirección manual consulta solo al guardar y coloca coordenadas reales',
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
      await tester.ensureVisible(find.text('Centro, Cuautla'));
      await tester.tap(find.text('Centro, Cuautla'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('manual-address-0')),
        'Calle pública',
      );
      await tester.enterText(
        find.byKey(const ValueKey('manual-address-2')),
        'Centro',
      );
      await tester.enterText(
        find.byKey(const ValueKey('manual-address-3')),
        '62740',
      );
      expect(repo.pending, isEmpty);
      await tester.ensureVisible(find.text('Usar dirección'));
      await tester.tap(find.text('Usar dirección'));
      await tester.pump();
      repo.pending.single.complete({
        'results': [
          {
            'address': 'Centro, Cuautla',
            'latitude': 18.81,
            'longitude': -98.95,
          },
        ],
      });
      await tester.pumpAndSettle();
      final map = tester.widget<ReportMap>(find.byType(ReportMap));
      expect(map.point?.latitude, 18.81);
      expect(map.point?.longitude, -98.95);
      expect(find.textContaining('Calle pública'), findsWidgets);
    },
  );
}
