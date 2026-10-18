import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:reporte_ciudadano/features/reports/report_repository.dart';
import 'package:reporte_ciudadano/features/reports/report_wizard.dart';

class NoCalls implements ReportRepository {
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async => throw StateError('No debe llamar al servidor');
}

class RetryReports implements ReportRepository {
  final calls = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    if (action != 'submit') throw StateError('Solicitud inesperada');
    calls.add(values);
    if (calls.length == 1) throw Exception('Fallo temporal');
    return {'id': 'report-created'};
  }
}

void main() {
  testWidgets(
    'tres pasos validan descripción, dirección y confirmación sin GPS',
    (tester) async {
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
                repository: NoCalls(),
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
      expect(find.text('Cuéntanos más'), findsOneWidget);
      expect(find.text('Latitud'), findsNothing);
      expect(find.text('Longitud'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('incident-description')),
        'Luminaria de prueba sin encender.',
      );
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Escribe una dirección de al menos 10 caracteres o usa tu ubicación.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Usar mi ubicación actual'));
      const channel = MethodChannel('flutter.baseflow.com/geolocator');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => throw MissingPluginException(),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.tap(find.text('Usar mi ubicación actual'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'La ubicación no está disponible. Recarga la app o escribe la dirección.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('incident-address')),
        'Calle de prueba 123, Centro, Cuautla',
      );
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Confirma tu reporte'), findsOneWidget);
      expect(find.text('Acepto enviar un reporte de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('prepara fotografía JPEG acotada', () {
    final input = img.encodePng(img.Image(width: 1800, height: 1200));
    final output = compressReportPhoto(input);
    final photo = img.decodeJpg(output)!;
    expect(photo.width, 1280);
    expect(photo.height, lessThanOrEqualTo(1280));
    expect(output.length, lessThanOrEqualTo(700000));
  });
  test('rechaza archivo que no contiene imagen', () {
    expect(
      () => compressReportPhoto(Uint8List.fromList([1, 2, 3])),
      throwsException,
    );
  });
  test('envío conserva clave y bytes para reintento', () {
    final key = reportRequestKey();
    expect(
      key,
      matches(
        RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ),
      ),
    );
    final body = reportSubmission(
      key,
      {'description': 'Prueba'},
      [
        Uint8List.fromList([1, 2, 3]),
      ],
    );
    expect(body['request_key'], key);
    expect(base64Decode((body['photos'] as List).single), [1, 2, 3]);
  });
  testWidgets('wizard exige categoría antes de avanzar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportWizard(
              categories: const [],
              repository: NoCalls(),
              onCreated: (_) {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Siguiente'));
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Selecciona una categoría.'), findsOneWidget);
    expect(find.text('Tipo'), findsOneWidget);
    expect(find.text('Detalles'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
  });
  testWidgets(
    'categoría nueva sin habilitar no se envía con otro identificador',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportWizard(
                categories: const [
                  {
                    'id': 'other',
                    'name': 'Otro',
                    'requires_location': false,
                    'requires_photo': false,
                    'subcategories': [],
                    'schema': {'properties': {}},
                  },
                ],
                repository: NoCalls(),
                onCreated: (_) {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Robo / Asalto'));
      await tester.pump();
      expect(
        find.text('Esta categoría aún no está habilitada en tu municipio.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      expect(find.text('Selecciona una categoría.'), findsOneWidget);
    },
  );
  testWidgets(
    'reintentar envío conserva el folio de solicitud y todos los datos',
    (tester) async {
      final repo = RetryReports();
      String? created;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReportWizard(
                categories: const [
                  {
                    'id': 'other',
                    'name': 'Otro',
                    'requires_location': false,
                    'requires_photo': false,
                    'subcategories': [],
                    'schema': {'properties': {}},
                  },
                ],
                repository: repo,
                onCreated: (id) => created = id,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Otro'));
      await tester.tap(find.text('Otro'));
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('incident-description')),
        'Descripción de prueba sin datos privados.',
      );
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text('Enviar reporte'));
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      expect(repo.calls.length, 1);
      expect(created, isNull);
      await tester.ensureVisible(find.text('Reintentar envío'));
      await tester.tap(find.text('Reintentar envío'));
      await tester.pumpAndSettle();
      expect(created, 'report-created');
      expect(repo.calls.length, 2);
      expect(repo.calls[1], repo.calls[0]);
      expect((repo.calls.last['payload'] as Map)['category_id'], 'other');
      expect(tester.takeException(), isNull);
    },
  );
}
