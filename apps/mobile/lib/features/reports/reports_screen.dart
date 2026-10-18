import '../../core/citizen_sticker.dart';
import '../../core/address_search.dart';
import '../../core/citizen_design.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../auth/application/auth_controller.dart';
import 'report_repository.dart';
import 'report_address_search.dart';
import 'report_wizard.dart';
import 'report_map.dart';
import '../../core/citizen_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.repository,
    required this.auth,
    this.initialCreate = false,
    this.initialReportId,
    this.embedded = false,
    this.onNavigate,
    this.geocode,
  });
  final ReportRepository repository;
  final AuthController auth;
  final bool initialCreate, embedded;
  final String? initialReportId;
  final ValueChanged<int>? onNavigate;
  final AddressGeocoder? geocode;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final String actor;
  bool busy = true, creating = false, enabled = false;
  String? error;
  String filter = 'ALL';
  int offset = 0;
  bool firstLoad = true;
  bool justCreated = false;
  List<Map<String, dynamic>> categories = [], reports = [];
  Map<String, dynamic>? detail;
  @override
  void initState() {
    super.initState();
    actor = widget.auth.account!.id;
    widget.auth.addListener(authChanged);
    unawaited(
      widget.initialReportId == null ? load() : open(widget.initialReportId!),
    );
  }

  void authChanged() {
    if (mounted && widget.auth.account?.id != actor) {
      if (!widget.embedded) Navigator.of(context).pop();
    }
  }

  bool get current => mounted && widget.auth.account?.id == actor;
  @override
  void dispose() {
    widget.auth.removeListener(authChanged);
    super.dispose();
  }

  Future<void> run(Future<void> Function() fn) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await fn();
    } catch (e) {
      if (current) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (current) setState(() => busy = false);
    }
  }

  Future<void> load() => run(() async {
    final c = await widget.repository.call('context');
    final r = await widget.repository.call('list', {
      'offset': offset,
      'filter': filter,
    });
    if (current) {
      setState(() {
        categories = (c['categories'] as List)
            .map((v) => Map<String, dynamic>.from(v))
            .toList();
        enabled = c['enabled'] == true;
        reports = (r['reports'] as List)
            .map((v) => Map<String, dynamic>.from(v))
            .toList();
        detail = null;
        justCreated = false;
        creating = firstLoad && widget.initialCreate && enabled;
        firstLoad = false;
      });
    }
  });
  Future<void> open(String id) => run(() async {
    final r = await widget.repository.call('detail', {'report_id': id});
    if (current) {
      setState(() {
        detail = r;
        creating = false;
      });
    }
  });
  String date(dynamic value) {
    final d = DateTime.tryParse(value.toString())?.toLocal();
    return d == null
        ? ''
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void back() {
    if (detail != null || creating) {
      unawaited(load());
    } else {
      Navigator.maybePop(context);
    }
  }

  Widget sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: Color(0xff092b60),
    ),
  );

  Widget reportList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            for (final option in [
              ('ALL', 'Todos'),
              ('PENDING', 'En revisión'),
              ('EN_ATENCION', 'En atención'),
              ('RESUELTO', 'Resuelto'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: filter == option.$1
                        ? const Color(0xff1769ed)
                        : const Color(0xffedf5fc),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        filter = option.$1;
                        offset = 0;
                        unawaited(load());
                      },
                      child: SizedBox(
                        height: 43,
                        child: Center(
                          child: Text(
                            option.$2,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: filter == option.$1
                                  ? Colors.white
                                  : const Color(0xff55779e),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (reports.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 70, horizontal: 20),
          child: Text(
            'No hay reportes con este estado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff6c86a5), fontSize: 13),
          ),
        ),
      for (final r in reports)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => open(r['id']),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 79),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: categoryArtwork('${r['category']}').$2,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: CitizenSticker(
                          categoryArtwork('${r['category']}').$1,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r['category']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff092b60),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${r['address'] ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff6480a3),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              date(r['created_at']),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff6480a3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ReportStatusBadge('${r['status']}'),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xff5879a0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      if (offset > 0 || reports.length == 20)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Página anterior',
              onPressed: offset > 0
                  ? () {
                      offset -= 20;
                      unawaited(load());
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Página ${offset ~/ 20 + 1}'),
            IconButton(
              tooltip: 'Página siguiente',
              onPressed: reports.length == 20
                  ? () {
                      offset += 20;
                      unawaited(load());
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
    ],
  );

  Widget reportDetail() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DesignCard(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: categoryArtwork('${detail!['category']}').$2,
                borderRadius: BorderRadius.circular(18),
              ),
              child: CitizenSticker(
                categoryArtwork('${detail!['category']}').$1,
                size: 58,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle('${detail!['category']}'),
                  const SizedBox(height: 5),
                  Text(
                    date(detail!['created_at']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff6480a3),
                    ),
                  ),
                ],
              ),
            ),
            ReportStatusBadge('${detail!['status']}'),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DesignCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CitizenSticker('pin', size: 32),
                  const SizedBox(height: 6),
                  sectionTitle('Ubicación'),
                  const SizedBox(height: 7),
                  Text(
                    '${detail!['address'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff5f7da1),
                    ),
                  ),
                ],
              ),
            ),
            if (detail!['latitude'] != null)
              SizedBox(
                width: 125,
                child: ReportMap(
                  height: 110,
                  point: LatLng(
                    (detail!['latitude'] as num).toDouble(),
                    (detail!['longitude'] as num).toDouble(),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('Descripción'),
            const SizedBox(height: 10),
            SelectableText(
              '${detail!['description'] ?? ''}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff567397),
                height: 1.5,
              ),
            ),
            for (final entry
                in (detail!['additional_data'] as Map? ?? {}).entries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${detail!['schema']?['properties']?[entry.key]?['title'] ?? entry.key}: ${entry.value}',
                ),
              ),
            if ((detail!['images'] as List? ?? []).isNotEmpty) ...[
              const SizedBox(height: 16),
              sectionTitle('Evidencia'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final image in detail!['images'])
                    PrivateReportImage(
                      key: ValueKey(image['id']),
                      repository: widget.repository,
                      reportId: detail!['id'],
                      imageId: image['id'],
                      large: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle('Historial'),
            for (final item in detail!['timeline'] as List? ?? [])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text('${item['status']}'),
                subtitle: Text(date(item['created_at'])),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: '${detail!['folio']} · ${detail!['status']}',
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folio copiado')),
                  );
                }
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => open(detail!['id']),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ),
        ],
      ),
    ],
  );

  Widget success() => Column(
    children: [
      const SizedBox(height: 63),
      SizedBox(
        height: 220,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Positioned(
                top: 28,
                left: (c.maxWidth - 174) / 2,
                child: Container(
                  width: 174,
                  height: 174,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x4d75edcd),
                  ),
                ),
              ),
              Positioned(
                top: 35,
                left: (c.maxWidth - 166) / 2,
                child: const CitizenSticker('shield', size: 166),
              ),
              for (final piece in [
                (0.17, 54.0, 0xffffc315),
                (0.10, 102.0, 0xff0bc893),
                (0.25, 160.0, 0xff34a8ee),
                (0.19, 132.0, 0xffa267a9),
                (0.76, 30.0, 0xff268df2),
                (0.88, 76.0, 0xff6bd82b),
                (0.91, 130.0, 0xff268df2),
                (0.79, 166.0, 0xffffae0c),
              ])
                Positioned(
                  left: c.maxWidth * piece.$1,
                  top: piece.$2,
                  child: Transform.rotate(
                    angle: .78,
                    child: Container(
                      width: 9,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Color(piece.$3),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const Text(
        '¡Reporte enviado!',
        style: TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          color: Color(0xff0b2d73),
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Tu reporte ha sido registrado correctamente.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 17, color: Color(0xff718bab), height: 1.3),
      ),
      const SizedBox(height: 23),
      DesignCard(
        color: const Color(0xffedf5fc),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Folio del reporte',
                    style: TextStyle(fontSize: 14, color: Color(0xff637d9e)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${detail!['folio']}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff0c2b70),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copiar folio',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: '${detail!['folio']}')),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
      ),
      ListTile(
        minTileHeight: 67,
        leading: const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xffffbd12),
          child: Icon(Icons.schedule, color: Colors.white, size: 18),
        ),
        title: const Text(
          'Estado actual',
          style: TextStyle(fontSize: 13, color: Color(0xff627b9c)),
        ),
        trailing: ReportStatusBadge('${detail!['status']}'),
      ),
      ListTile(
        leading: const Icon(Icons.calendar_month, color: Color(0xff1766df)),
        minTileHeight: 67,
        title: const Text(
          'Fecha y hora',
          style: TextStyle(fontSize: 13, color: Color(0xff627b9c)),
        ),
        subtitle: Text(date(detail!['created_at'])),
      ),
      const SizedBox(height: 15),
      SizedBox(
        width: double.infinity,
        child: DesignButton('Ver mis reportes', onPressed: load),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 57),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            side: const BorderSide(color: Color(0xff075ed9), width: 2),
          ),
          onPressed: () => setState(() {
            justCreated = false;
            detail = null;
            creating = enabled && categories.isNotEmpty;
          }),
          child: const Text(
            'Enviar otro reporte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: creating || justCreated
        ? const Color(0xfffbfdff)
        : const Color(0xfff4faff),
    appBar: justCreated
        ? null
        : DesignHeader(
            creating
                ? 'Nuevo reporte'
                : detail != null
                ? 'Detalle del reporte'
                : 'Mis reportes',
            onBack: back,
          ),
    bottomNavigationBar:
        !widget.embedded && !creating && detail == null && !busy
        ? DesignNavigation(
            active: 0,
            onSelected: (value) {
              if (value == 4) {
                if (enabled && categories.isNotEmpty) {
                  setState(() => creating = true);
                }
              } else if (widget.onNavigate != null) {
                widget.onNavigate!(value);
              } else {
                Navigator.maybePop(context);
              }
            },
          )
        : null,
    body: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        creating ? 21 : 18,
        creating ? 7 : 8,
        creating ? 21 : 18,
        25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            TextButton(
              onPressed: busy
                  ? null
                  : (detail != null ? () => open(detail!['id']) : load),
              child: Text('$error Reintentar'),
            ),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else if (creating)
            ReportWizard(
              categories: categories,
              repository: widget.repository,
              geocode:
                  widget.geocode ??
                  ReportAddressSearch(widget.repository).search,
              onCreated: (id) {
                justCreated = true;
                open(id);
              },
              onCancel: load,
            )
          else if (detail != null)
            (justCreated ? success() : reportDetail())
          else
            reportList(),
        ],
      ),
    ),
  );
}

class PrivateReportImage extends StatefulWidget {
  const PrivateReportImage({
    super.key,
    required this.repository,
    required this.reportId,
    required this.imageId,
    this.large = false,
  });
  final ReportRepository repository;
  final String reportId, imageId;
  final bool large;
  @override
  State<PrivateReportImage> createState() => _PrivateReportImageState();
}

class _PrivateReportImageState extends State<PrivateReportImage> {
  String? url;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final r = await widget.repository.call('image', {
        'report_id': widget.reportId,
        'image_id': widget.imageId,
      });
      if (mounted) {
        setState(() {
          url = r['url'];
          failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.large ? 220 : 48,
    height: widget.large ? 165 : 48,
    child: failed
        ? IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reintentar foto',
          )
        : url == null
        ? const Center(child: CircularProgressIndicator())
        : Image.network(
            url!,
            fit: BoxFit.cover,
            cacheWidth: widget.large ? 440 : 96,
            errorBuilder: (_, e, s) => IconButton(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Renovar acceso a foto',
            ),
          ),
  );
}
