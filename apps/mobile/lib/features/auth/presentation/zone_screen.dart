import 'dart:async';
import 'dart:ui' as ui;
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
  void notice(String value) => showDesignNotice(context, value);
  Timer? addressTimer;
  int addressRequest = 0;
  bool resolvingAddress = false;
  @override
  void dispose() {
    addressTimer?.cancel();
    addressRequest++;
    super.dispose();
  }

  void selectZonePoint(LatLng selected) {
    addressTimer?.cancel();
    final request = ++addressRequest;
    setState(() {
      point = selected;
      address = 'Buscando dirección…';
      resolvingAddress = true;
    });
    addressTimer = Timer(const Duration(milliseconds: 600), () async {
      final coordinates =
          '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}';
      String? resolved;
      try {
        final results = await widget
            .geocode(coordinates)
            .timeout(const Duration(seconds: 10));
        if (results.isNotEmpty) resolved = results.first['address'] as String?;
      } catch (_) {
        /* Show the actual selected coordinates if lookup is unavailable. */
      }
      if (!mounted || request != addressRequest) return;
      setState(() {
        address = resolved?.trim().isNotEmpty == true
            ? resolved!
            : 'Punto en el mapa ($coordinates)';
        resolvingAddress = false;
      });
      if (resolved == null) {
        notice(
          'No pudimos obtener la dirección de este punto. Puedes escribirla manualmente.',
        );
      }
    });
  }

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
        selectZonePoint(LatLng(p.latitude, p.longitude));
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
    final result = await showGeneralDialog<CitizenZone>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar captura de dirección',
      barrierColor: Colors.transparent,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 190),
      pageBuilder: (dialog, animation, _) => Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0, .95, curve: Curves.easeOut),
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(dialog),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: const ColoredBox(color: Color(0x6108234d)),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DesignPanelEntrance(
              animation: animation,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Material(
                    color: const Color(0xfff9fcff),
                    borderRadius: BorderRadius.circular(27),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 394,
                        maxHeight: MediaQuery.sizeOf(dialog).height - 76,
                      ),
                      child: _ZoneAddressEditor(
                        geocode: widget.geocode,
                        radius: radius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      covered = false;
      if (result != null) {
        addressTimer?.cancel();
        addressRequest++;
        resolvingAddress = false;
        address = result.address;
        point = result.point;
      }
    });
  }

  bool covered = false;
  @override
  Widget build(BuildContext context) => DesignScaffold(
    surface: DesignSurface.zone,
    backgroundColor: const Color(0xfff4faff),
    appBar: const DesignHeader('Configurar mi zona'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        Row(
          children: [
            Image.asset(
              'assets/renewal/icons/3d/zone-location.png',
              width:
                  (MediaQuery.sizeOf(context).width.clamp(320.0, 430.0) - 36) *
                  .44,
              height: 138,
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
                    'Consulta los incidentes en la zona que te interesa de Cuautla, Morelos.',
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
            minTileHeight: 68,
            leading: const CitizenSticker('pin', size: 44),
            title: Text(
              address,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            trailing: const CitizenIcon('chevron', strokeWidth: 2.4),
            onTap: editAddress,
          ),
        ),
        const SizedBox(height: 12),
        if (!covered)
          Stack(
            children: [
              ReportMap(
                height: 270,
                radius: 21,
                zoom: 11.3,
                point: point,
                radiusKm: radius,
                showZoneRadius: true,
                hideControls: true,
                onSelected: selectZonePoint,
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.filled(
                    tooltip: 'Usar mi ubicación',
                    onPressed: locating ? null : locate,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff0865df),
                    ),
                    icon: const CitizenIcon(
                      'crosshair',
                      size: 26,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
            ],
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
          resolvingAddress ? 'Obteniendo dirección…' : 'Guardar zona',
          onPressed: resolvingAddress
              ? null
              : () => Navigator.pop(
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
                  icon: const CitizenIcon('close'),
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
                trailing: const CitizenIcon('chevron', strokeWidth: 2.4),
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
