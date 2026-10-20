import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/address_search.dart';
import '../../../core/citizen_design.dart';
import '../../../core/citizen_sticker.dart';
import '../../reports/report_map.dart';

class CitizenZone {
  const CitizenZone({
    this.address = 'Cuautla, Morelos',
    this.point = const LatLng(18.8126, -98.9548),
    this.radius = 3,
  });
  final String address;
  final LatLng point;
  final double radius;
  String encode() => jsonEncode({
    'address': address,
    'lat': point.latitude,
    'lng': point.longitude,
    'radius': radius,
  });
  static CitizenZone decode(String? value) {
    try {
      final v = jsonDecode(value!) as Map;
      final lat = (v['lat'] as num).toDouble(),
          lng = (v['lng'] as num).toDouble(),
          r = (v['radius'] as num).toDouble();
      if (!lat.isFinite ||
          !lng.isFinite ||
          lat.abs() > 90 ||
          lng.abs() > 180 ||
          !r.isFinite ||
          r < 1 ||
          r > 10) {
        return const CitizenZone();
      }
      final address = v['address'] as String;
      if (address.trim().isEmpty || address.length > 500) {
        return const CitizenZone();
      }
      return CitizenZone(address: address, point: LatLng(lat, lng), radius: r);
    } catch (_) {
      return const CitizenZone();
    }
  }
}

class ZoneScreen extends StatefulWidget {
  const ZoneScreen({super.key, required this.initial, required this.geocode});
  final CitizenZone initial;
  final AddressGeocoder geocode;
  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen> {
  late LatLng point = widget.initial.point;
  late String address = widget.initial.address;
  late double radius = widget.initial.radius;
  bool locating = false;
  void notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<void> locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (mounted) {
        setState(() {
          point = LatLng(p.latitude, p.longitude);
          address = 'Ubicación seleccionada en el mapa';
        });
      }
    } catch (_) {
      if (mounted) {
        notice(
          'No fue posible obtener tu ubicación. Puedes seleccionarla en el mapa.',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> editAddress() async {
    // Removing the platform view prevents the map from intercepting dialog taps.
    setState(() => covered = true);
    final result = await showModalBottomSheet<CitizenZone>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _ZoneAddressEditor(geocode: widget.geocode, radius: radius),
    );
    if (!mounted) return;
    setState(() {
      covered = false;
      if (result != null) {
        address = result.address;
        point = result.point;
      }
    });
  }

  bool covered = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4faff),
    appBar: const DesignHeader('Configurar mi zona'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        Row(
          children: [
            Image.asset(
              'assets/renewal/icons/3d/zone-location.png',
              width: 145,
              height: 132,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Define tu zona',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Selecciona la zona de Cuautla que te interesa consultar.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xff5f7fa6),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          child: ListTile(
            leading: const CitizenSticker('pin', size: 44),
            title: Text(
              address,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: editAddress,
          ),
        ),
        const SizedBox(height: 12),
        if (!covered)
          ReportMap(
            height: 270,
            point: point,
            radiusKm: radius,
            onSelected: (p) => setState(() {
              point = p;
              address = 'Ubicación seleccionada en el mapa';
            }),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: locating ? null : locate,
            icon: const Icon(Icons.my_location),
            label: Text(
              locating ? 'Obteniendo ubicación…' : 'Usar mi ubicación',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Radio de notificaciones: ${radius.round()} km',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Slider(
          value: radius,
          min: 1,
          max: 10,
          divisions: 9,
          label: '${radius.round()} km',
          onChanged: (v) => setState(() => radius = v),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('1 km'), Text('10 km')],
        ),
        const SizedBox(height: 18),
        DesignButton(
          'Guardar zona',
          onPressed: () => Navigator.pop(
            context,
            CitizenZone(address: address, point: point, radius: radius),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Se guarda en este navegador para tu cuenta. El radio delimita la consulta del mapa; no activa alertas automáticas ni notificaciones con la app cerrada.',
          style: TextStyle(fontSize: 11, color: Color(0xff5f7fa6), height: 1.5),
        ),
      ],
    ),
  );
}

class _ZoneAddressEditor extends StatefulWidget {
  const _ZoneAddressEditor({required this.geocode, required this.radius});
  final AddressGeocoder geocode;
  final double radius;
  @override
  State<_ZoneAddressEditor> createState() => _ZoneAddressEditorState();
}

class _ZoneAddressEditorState extends State<_ZoneAddressEditor> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(5, (_) => TextEditingController());
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> results = [];
  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> search() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
      results = [];
    });
    try {
      final r = await widget.geocode(
        [
          fields[0].text,
          fields[1].text,
          fields[2].text,
          fields[3].text,
          fields[4].text,
        ].where((v) => v.trim().isNotEmpty).join(', '),
      );
      if (mounted) {
        setState(() {
          results = r;
          if (r.isEmpty) {
            error =
                'No encontramos esa dirección. Ajusta los datos o selecciona el punto en el mapa.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'No pudimos buscar la dirección. Reintenta.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CitizenSticker('pin', size: 50),
                const Expanded(
                  child: Text(
                    'Escribe tu dirección',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            for (var i = 0; i < fields.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextFormField(
                  controller: fields[i],
                  enabled: !busy,
                  maxLength: i == 3 ? 5 : 120,
                  keyboardType: i == 3
                      ? TextInputType.number
                      : TextInputType.streetAddress,
                  decoration: InputDecoration(
                    labelText: [
                      'Calle',
                      'Número (opcional)',
                      'Colonia o localidad',
                      'Código postal',
                      'Municipio o zona (Cuautla)',
                    ][i],
                    counterText: '',
                  ),
                  validator: (v) {
                    if (i != 1 && i != 4 && (v ?? '').trim().isEmpty) {
                      return 'Completa este campo.';
                    }
                    if (i == 3 && !RegExp(r'^\d{5}$').hasMatch(v ?? '')) {
                      return 'Escribe cinco dígitos.';
                    }
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            DesignButton(
              busy ? 'Buscando…' : 'Buscar dirección',
              onPressed: busy ? null : search,
            ),
            if (error != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
            for (final r in results)
              ListTile(
                title: Text('${r['address']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(
                  context,
                  CitizenZone(
                    address: r['address'] as String,
                    point: LatLng(
                      (r['latitude'] as num).toDouble(),
                      (r['longitude'] as num).toDouble(),
                    ),
                    radius: widget.radius,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
