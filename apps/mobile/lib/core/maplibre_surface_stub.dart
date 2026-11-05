import 'package:flutter/material.dart';

class MapLibreSurface extends StatelessWidget {
  const MapLibreSurface({
    super.key,
    required this.options,
    this.onSelected,
    this.onReportSelected,
  });
  final Map<String, dynamic> options;
  final void Function(double, double)? onSelected;
  final ValueChanged<String>? onReportSelected;
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xffedf4f8),
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Mapa disponible en la versión web del piloto.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xff52718f), fontSize: 12),
        ),
      ),
    ),
  );
}
