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

void main() {
  testWidgets('acepta dirección sin GPS y no muestra campos de coordenadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportWizard(
              categories: const [
                {
                  'id': 'test',
                  'name': 'Servicios',
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
    await tester.tap(find.text('Servicios'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Latitud'), findsNothing);
    expect(find.text('Longitud'), findsNothing);
    expect(find.text('Usar mi ubicación'), findsOneWidget);
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      throw MissingPluginException();
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.tap(find.text('Usar mi ubicación'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'La ubicación no está disponible. Recarga la app o escribe la dirección.',
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Escribe una dirección de al menos 10 caracteres o usa tu ubicación.',
      ),
      findsOneWidget,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'isLocationServiceEnabled') return true;
      if (call.method == 'checkPermission') return 3;
      if (call.method == 'getCurrentPosition') {
        return {
          'latitude': 18.812,
          'longitude': -98.955,
          'accuracy': 15.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }
      throw MissingPluginException();
    });
    await tester.ensureVisible(find.text('Usar mi ubicación'));
    await tester.tap(find.text('Usar mi ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Ubicación del dispositivo seleccionada'), findsOneWidget);
    expect(find.text('Precisión aproximada: ±15 m'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Quitar ubicación'));
    await tester.tap(find.byTooltip('Quitar ubicación'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Calle de prueba 123, Centro, Cuautla',
    );
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Describe el problema'), findsOneWidget);
  });
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
          body: ReportWizard(
            categories: const [],
            repository: NoCalls(),
            onCreated: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(find.text('Selecciona una categoría.'), findsOneWidget);
    expect(find.text('Paso 1 de 4 · Categoría'), findsOneWidget);
  });
}
