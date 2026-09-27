import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../auth/application/auth_controller.dart';
import 'report_repository.dart';
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
  });
  final ReportRepository repository;
  final AuthController auth;
  final bool initialCreate, embedded;
  final String? initialReportId;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppBar(
            title: Text(
              creating
                  ? 'Crear reporte'
                  : detail != null
                  ? 'Detalle del reporte'
                  : 'Mis reportes',
            ),
          ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PilotNotice(),
              const SizedBox(height: 20),
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : (detail != null ? () => open(detail!['id']) : load),
                  child: const Text('Reintentar'),
                ),
              ],
              if (busy)
                const Center(child: CircularProgressIndicator())
              else if (creating)
                ReportWizard(
                  categories: categories,
                  repository: widget.repository,
                  onCreated: (id) {
                    justCreated = true;
                    open(id);
                  },
                  onCancel: load,
                )
              else if (detail != null) ...[
                if (justCreated) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xffa4e1ad),
                      child: Icon(
                        Icons.check,
                        color: Color(0xff082c47),
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '¡Reporte enviado!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Tu reporte de prueba ha sido registrado correctamente.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                ],
                Text(
                  detail!['folio'],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${detail!['category']} · ${detail!['status']} · Prioridad ${detail!['priority']}',
                ),
                Text(date(detail!['created_at'])),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ReportStatusBadge(detail!['status']),
                ),
                const SizedBox(height: 20),
                SelectableText(detail!['description']),
                const SizedBox(height: 16),
                Text(detail!['address'] ?? ''),
                if (detail!['latitude'] != null)
                  ReportMap(
                    point: LatLng(
                      (detail!['latitude'] as num).toDouble(),
                      (detail!['longitude'] as num).toDouble(),
                    ),
                  ),
                for (final entry in (detail!['additional_data'] as Map).entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${detail!['schema']?['properties']?[entry.key]?['title'] ?? entry.key}: ${entry.value}',
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
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
                const SizedBox(height: 20),
                Text(
                  'Historial',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final item in detail!['timeline'])
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(item['status']),
                    subtitle: Text(date(item['created_at'])),
                  ),
                OutlinedButton(
                  onPressed: () => open(detail!['id']),
                  child: const Text('Actualizar estado'),
                ),
                TextButton(
                  onPressed: load,
                  child: const Text('Volver a mis reportes'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: enabled && categories.isNotEmpty
                      ? () => setState(() => creating = true)
                      : null,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Crear reporte de prueba'),
                ),
                if (!enabled)
                  const Text(
                    'El envío de reportes está deshabilitado en este municipio.',
                  ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: filter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por estado',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'PENDING',
                      child: Text('Pendientes'),
                    ),
                    DropdownMenuItem(
                      value: 'EN_ATENCION',
                      child: Text('En atención'),
                    ),
                    DropdownMenuItem(
                      value: 'RESUELTO',
                      child: Text('Resueltos'),
                    ),
                    DropdownMenuItem(value: 'CERRADO', child: Text('Cerrados')),
                  ],
                  onChanged: (v) {
                    filter = v!;
                    offset = 0;
                    unawaited(load());
                  },
                ),
                const SizedBox(height: 16),
                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 38, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 52,
                          color: Color(0xff92aabd),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay reportes en esta página. Puedes crear tu primera prueba.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                for (final r in reports)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: r['image_id'] == null
                          ? const Icon(Icons.description_outlined)
                          : PrivateReportImage(
                              key: ValueKey(r['image_id']),
                              repository: widget.repository,
                              reportId: r['id'],
                              imageId: r['image_id'],
                            ),
                      title: Text('${r['folio']} · ${r['category']}'),
                      subtitle: Text(
                        '${r['status']} · Prioridad ${r['priority']}\n${date(r['created_at'])}\n${r['address'] ?? ''}${r['is_pilot'] == true ? '\nPRUEBA PILOTO' : ''}',
                      ),
                      isThreeLine: true,
                      onTap: () => open(r['id']),
                    ),
                  ),
                Row(
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
                    const Spacer(),
                    Text('Página ${offset ~/ 20 + 1}'),
                    const Spacer(),
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
                TextButton(
                  onPressed: load,
                  child: const Text('Actualizar reportes'),
                ),
              ],
            ],
          ),
        ),
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
