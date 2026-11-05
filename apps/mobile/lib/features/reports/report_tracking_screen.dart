import 'package:flutter/material.dart';
import '../../core/citizen_design.dart';
import '../../core/citizen_sticker.dart';
import '../../core/citizen_widgets.dart';

class ReportTrackingScreen extends StatelessWidget {
  const ReportTrackingScreen({super.key, required this.report});
  final Map<String, dynamic> report;
  static const stages = [
    'Recibido',
    'En revisión',
    'Asignado',
    'En atención',
    'Resuelto',
  ];
  String date(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    return d == null
        ? 'Sin fecha registrada'
        : '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget icon(String name, [double size = 72]) => Image.asset(
    'assets/renewal/icons/3d/tracking-$name.png',
    width: size,
    height: size,
  );
  TextStyle title([double size = 16]) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: const Color(0xff082b65),
    letterSpacing: -.5,
  );
  static const copy = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xff6480a3),
    height: 1.35,
  );
  int stageIndex(String status) => switch (status) {
    'En proceso' => 3,
    'Cerrado' => 4,
    _ => stages.indexOf(status),
  };
  @override
  Widget build(BuildContext context) {
    final events = (report['timeline'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final current = stageIndex('${report['status']}');
    final progress = current < 0 ? 0.0 : (current + 1) / stages.length;
    final heading = current == 4
        ? 'Tu reporte fue resuelto'
        : current == 3
        ? 'Estamos atendiendo tu reporte'
        : current == 0
        ? 'Recibimos tu reporte'
        : 'Estamos revisando tu reporte';
    Map? eventFor(int index) {
      for (final event in events.reversed) {
        if (stageIndex('${event['status']}') == index) return event;
      }
      return null;
    }

    return DesignScaffold(
      surface: DesignSurface.tracking,
      backgroundColor: const Color(0xfff4faff),
      appBar: const DesignHeader('Seguimiento del reporte'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
        children: [
          DesignCard(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 102),
              child: Row(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: categoryArtwork('${report['category']}').$2,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: CitizenSticker(
                      categoryArtwork('${report['category']}').$1,
                      size: 68,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report['category'] ?? 'Reporte'}',
                          style: title(),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Folio: ${report['folio'] ?? ''}',
                          style: copy.copyWith(fontSize: 11),
                        ),
                        if ('${report['address'] ?? ''}'.trim().isNotEmpty)
                          Text(
                            '${report['address']}',
                            style: copy.copyWith(fontSize: 11),
                          ),
                        Text(
                          date(report['created_at']),
                          style: copy.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ReportStatusBadge('${report['status'] ?? 'Sin estado'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 11),
          DesignCard(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: Row(
                children: [
                  icon('progress'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(heading, style: title()),
                        const SizedBox(height: 5),
                        const Text(
                          'Consulta aquí cada actualización.',
                          style: copy,
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: Container(
                                  height: 13,
                                  color: const Color(0xffd9ebf8),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xff258cf2),
                                            Color(0xff20d7bd),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              '${(progress * 100).round()}%',
                              style: title(
                                13,
                              ).copyWith(color: const Color(0xff0865e0)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < stages.length; i++)
            Builder(
              builder: (context) {
                final event = eventFor(i);
                final reached = event != null || i == current;
                final complete =
                    event != null && i != current || i == 4 && current == 4;
                final active = i == current && !complete;
                final time =
                    event?['created_at'] ??
                    (i == 0 ? report['created_at'] : null);
                return Container(
                  constraints: const BoxConstraints(minHeight: 116),
                  padding: EdgeInsets.symmetric(vertical: active ? 10 : 0),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xc7e2f2fd) : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 84,
                          child: Column(
                            children: [
                              icon(
                                complete
                                    ? 'complete'
                                    : active
                                    ? 'current'
                                    : 'pending',
                              ),
                              if (i < stages.length - 1)
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: 4,
                                      height: double.infinity,
                                      child: CustomPaint(
                                        painter: _TrackingConnector(complete),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              right: 5,
                              bottom: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stages[i],
                                  style: title(17).copyWith(
                                    color: reached
                                        ? const Color(0xff082b65)
                                        : const Color(0xff6d82a0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time == null
                                      ? (reached
                                            ? 'Sin fecha registrada'
                                            : 'Pendiente')
                                      : date(time),
                                  style: copy.copyWith(
                                    color: reached
                                        ? const Color(0xff5f7fa6)
                                        : const Color(0xff879bb2),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${event?['note'] ?? (reached ? (i == 0 ? 'Recibimos tu reporte correctamente.' : 'Estado registrado por el municipio.') : 'Te avisaremos cuando haya una actualización.')}',
                                  style: copy.copyWith(
                                    color: reached
                                        ? const Color(0xff5f7fa6)
                                        : const Color(0xff879bb2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 3),
          const Divider(color: Color(0xffdbe9f2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon('notification', 32),
              const SizedBox(width: 5),
              const Flexible(
                child: Text(
                  'Te notificaremos cuando haya novedades.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff0b68df),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 58,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff0865df),
                side: const BorderSide(color: Color(0xff1677f1), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Ver mi reporte',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingConnector extends CustomPainter {
  const _TrackingConnector(this.complete);
  final bool complete;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = complete ? const Color(0xff13cfa2) : const Color(0xffbdd2e6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (complete) {
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    } else {
      for (double y = 0; y < size.height; y += 14) {
        canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, (y + 8).clamp(0, size.height)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrackingConnector oldDelegate) =>
      oldDelegate.complete != complete;
}
