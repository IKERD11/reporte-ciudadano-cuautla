import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/citizen_design.dart';
import '../../core/maplibre_surface.dart';

bool isDemonstrationReport(Map<String, dynamic> report) =>
    report['source'] == 'demo' ||
    report['is_demo'] == true ||
    report['demo'] == true;

/// Same map slot and category artwork as the citizen design; only the renderer changes.
class ReportMap extends StatelessWidget {
  const ReportMap({
    super.key,
    this.point,
    this.onSelected,
    this.height = 137,
    this.reports = const [],
    this.onReportSelected,
    this.zoom = 16,
    this.radius = 16,
    this.allow3D = false,
    this.bottomInset = 0,
    this.controlTop = 8,
  });
  final double height, zoom, radius, bottomInset, controlTop;
  final bool allow3D;
  final LatLng? point;
  final ValueChanged<LatLng>? onSelected;
  final List<Map<String, dynamic>> reports;
  final ValueChanged<Map<String, dynamic>>? onReportSelected;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      height: height,
      child: MapLibreSurface(
        options: {
          'point': point == null
              ? null
              : {'latitude': point!.latitude, 'longitude': point!.longitude},
          'editable': onSelected != null,
          'allow3D': allow3D && onSelected == null,
          'zoom': zoom, 'bottomInset': bottomInset, 'controlTop': controlTop,
          // Only account reports are accepted here. Demo fixtures belong in separate test/demo entrypoints.
          'reports': [
            for (final report in reports)
              if (!isDemonstrationReport(report))
                {
                  'id': report['id'].toString(),
                  'latitude': report['latitude'],
                  'longitude': report['longitude'],
                  'title': report['folio'] ?? 'Reporte',
                  'source': 'live',
                  'icon': categoryArtwork(
                    '${report['category'] ?? report['description'] ?? ''}',
                  ).$1,
                },
          ],
        },
        onSelected: (lat, lng) => onSelected?.call(LatLng(lat, lng)),
        onReportSelected: (id) {
          for (final report in reports) {
            if (!isDemonstrationReport(report) &&
                report['id'].toString() == id) {
              onReportSelected?.call(report);
              break;
            }
          }
        },
      ),
    ),
  );
}
