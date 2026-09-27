import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportMap extends StatelessWidget {
  const ReportMap({super.key, this.point, this.onSelected, this.height = 280});
  final double height;
  final LatLng? point;
  final ValueChanged<LatLng>? onSelected;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      child: FlutterMap(
        key: ValueKey('${point?.latitude}/${point?.longitude}'),
        options: MapOptions(
          initialCenter: point ?? const LatLng(18.812, -98.955),
          initialZoom: 14,
          maxZoom: 19,
          onTap: onSelected == null ? null : (_, p) => onSelected!(p),
        ),
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -.7,
              0,
              0,
              0,
              190,
              0,
              -.7,
              0,
              0,
              186,
              0,
              0,
              -.65,
              0,
              211,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: TileLayer(
              urlTemplate: const String.fromEnvironment(
                'MAP_TILE_URL',
                defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              userAgentPackageName: 'mx.reporteciudadano.piloto',
              maxNativeZoom: 19,
            ),
          ),
          if (point != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: point!,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_pin,
                    color: Color(0xffab54ff),
                    size: 44,
                    semanticLabel: 'Ubicación del reporte',
                  ),
                ),
              ],
            ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
