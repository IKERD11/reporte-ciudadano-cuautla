import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/address_search.dart';
import 'package:reporte_ciudadano/features/reports/report_address_search.dart';
import 'package:reporte_ciudadano/features/reports/report_repository.dart';

class SearchService implements ReportRepository {
  int calls = 0;
  Map<String, dynamic> response = {'results': []};
  @override
  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> values = const {},
  ]) async {
    calls++;
    expect(action, 'geocode');
    expect(values['query'], 'Plaza pública Cuautla');
    return response;
  }
}

void main() {
  test(
    'consulta el servicio autenticado y conserva candidatos válidos del municipio',
    () async {
      final repository = SearchService()
        ..response = {
          'results': [
            {
              'address': 'Lugar público de prueba',
              'latitude': 18.812,
              'longitude': -98.954,
            },
            {
              'address': 'Fuera de cobertura',
              'latitude': 19.4,
              'longitude': -99.4,
            },
            {
              'address': 'Inválido',
              'latitude': double.nan,
              'longitude': -98.954,
            },
          ],
        };
      final results = await ReportAddressSearch(
        repository,
      ).search('  Plaza   pública Cuautla  ');
      expect(repository.calls, 1);
      expect(results, hasLength(1));
      expect(results.first['latitude'], 18.812);
    },
  );
  test('entrada privada no se envía al servicio', () async {
    final repository = SearchService();
    await expectLater(
      ReportAddressSearch(repository).search('persona@example.test'),
      throwsFormatException,
    );
    expect(repository.calls, 0);
  });
  test(
    'vacío real no inventa candidatos y respuesta inválida informa indisponibilidad',
    () async {
      final repository = SearchService();
      expect(
        await ReportAddressSearch(repository).search('Plaza pública Cuautla'),
        isEmpty,
      );
      repository.response = {};
      await expectLater(
        ReportAddressSearch(repository).search('Plaza pública Cuautla'),
        throwsA(isA<AddressSearchUnavailable>()),
      );
    },
  );
}
