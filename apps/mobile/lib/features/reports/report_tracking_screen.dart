import 'package:flutter/material.dart';
import '../../core/citizen_design.dart';
import '../../core/citizen_sticker.dart';

/// Progress is derived only from recorded events, never from prototype timestamps.
class ReportTrackingScreen extends StatelessWidget {
  const ReportTrackingScreen({super.key, required this.report});
  final Map<String, dynamic> report;
  String date(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    return d == null
        ? 'Sin fecha registrada'
        : '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final events = (report['timeline'] as List? ?? [])
        .whereType<Map>()
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xfff4faff),
      appBar: const DesignHeader('Seguimiento del reporte'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
        children: [
          DesignCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CitizenSticker(
                  categoryArtwork('${report['category']}').$1,
                  size: 58,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report['category'] ?? 'Reporte'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text('Folio: ${report['folio'] ?? ''}'),
                      Text(
                        '${report['address'] ?? ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        date(report['created_at']),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DesignCard(
            child: Row(
              children: [
                Image.asset(
                  'assets/renewal/icons/3d/tracking-progress.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report['status'] ?? 'Recibido'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Consulta aquí cada actualización.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff6480a3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (events.isEmpty)
            const DesignCard(
              child: Text('Todavía no hay cambios de estado registrados.'),
            ),
          for (var i = 0; i < events.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/renewal/icons/3d/tracking-${i == events.length - 1 ? 'current' : 'complete'}.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DesignCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${events[i]['status'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date(events[i]['created_at']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff6480a3),
                            ),
                          ),
                          if ('${events[i]['note'] ?? ''}'.isNotEmpty)
                            Text('${events[i]['note']}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset(
                'assets/renewal/icons/3d/tracking-notification.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Consulta las novedades en Actividad.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DesignButton(
            'Ver mi reporte',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
