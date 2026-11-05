import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:reporte_ciudadano/core/maplibre_surface.dart';
import 'package:reporte_ciudadano/core/address_search.dart';
import 'package:reporte_ciudadano/features/reports/report_map.dart';

void main() {
  test(
    'sin geocodificador conectado informa indisponibilidad sin devolver muestras',
    () async {
      await expectLater(
        searchAddressNotConnected('Centro, Cuautla'),
        throwsA(isA<AddressSearchUnavailable>()),
      );
    },
  );
  testWidgets(
    'mapa real excluye demostraciones y conserva callbacks de categoría',
    (tester) async {
      const real = {
        'id': 'r1',
        'folio': 'REP-TEST',
        'category': 'Alumbrado público',
        'latitude': 18.8126,
        'longitude': -98.9548,
      };
      Map<String, dynamic>? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: ReportMap(
            allow3D: true,
            reports: [
              real,
              {...real, 'id': 'demo1', 'source': 'demo'},
              {...real, 'id': 'demo2', 'is_demo': true},
            ],
            onReportSelected: (report) => selected = report,
          ),
        ),
      );
      final surface = tester.widget<MapLibreSurface>(
        find.byType(MapLibreSurface),
      );
      final reports = surface.options['reports'] as List;
      expect(reports, hasLength(1));
      expect(reports.first['icon'], 'bulb');
      expect(reports.first['source'], 'live');
      surface.onReportSelected!('r1');
      expect(selected, real);
    },
  );
  testWidgets('captura fuerza 2D y devuelve coordenadas del toque o arrastre', (
    tester,
  ) async {
    LatLng? point;
    await tester.pumpWidget(
      MaterialApp(
        home: ReportMap(allow3D: true, onSelected: (value) => point = value),
      ),
    );
    final surface = tester.widget<MapLibreSurface>(
      find.byType(MapLibreSurface),
    );
    expect(surface.options['allow3D'], false);
    expect(surface.options['editable'], true);
    surface.onSelected!(18.813, -98.955);
    expect(point?.latitude, 18.813);
    expect(point?.longitude, -98.955);
  });
}
