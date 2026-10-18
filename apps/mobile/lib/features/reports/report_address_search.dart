import '../../core/address_search.dart';
import 'report_repository.dart';

/// Authenticated, cached and rate-limited address search, independent of MapLibre.
class ReportAddressSearch {
  const ReportAddressSearch(this.repository);
  final ReportRepository repository;

  Future<List<Map<String, dynamic>>> search(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 5 ||
        normalized.length > 200 ||
        RegExp(r'@|https?:|[\r\n]', caseSensitive: false).hasMatch(query)) {
      throw const FormatException(
        'Usa una dirección pública de 5 a 200 caracteres, sin correos ni enlaces.',
      );
    }
    final response = await repository.call('geocode', {'query': normalized});
    final results = response['results'];
    if (results is! List) throw const AddressSearchUnavailable();
    return results
        .take(5)
        .whereType<Map>()
        .where((result) {
          final lat = result['latitude'];
          final lng = result['longitude'];
          return result['address'] is String &&
              lat is num &&
              lng is num &&
              lat.isFinite &&
              lng.isFinite &&
              lat >= 18.6 &&
              lat <= 19 &&
              lng >= -99.1 &&
              lng <= -98.8;
        })
        .map(
          (result) => <String, dynamic>{
            'address': (result['address'] as String).substring(
              0,
              (result['address'] as String).length.clamp(0, 500),
            ),
            'latitude': (result['latitude'] as num).toDouble(),
            'longitude': (result['longitude'] as num).toDouble(),
          },
        )
        .toList();
  }
}
