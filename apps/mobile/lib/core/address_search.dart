typedef AddressGeocoder =
    Future<List<Map<String, dynamic>>> Function(String query);

class AddressSearchUnavailable implements Exception {
  const AddressSearchUnavailable();
  @override
  String toString() =>
      'La búsqueda de direcciones aún no tiene un servicio conectado. Marca el lugar en el mapa o usa tu ubicación.';
}

/// Inject a real AddressGeocoder into the screen when an approved service exists.
/// OpenFreeMap supplies map tiles, not address search. Never return sample places.
Future<List<Map<String, dynamic>>> searchAddressNotConnected(
  String query,
) async {
  throw const AddressSearchUnavailable();
}
