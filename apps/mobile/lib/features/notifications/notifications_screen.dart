import '../../core/citizen_design.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../reports/report_map.dart';
import '../../core/citizen_sticker.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/application/auth_controller.dart';
import '../reports/report_repository.dart';
import '../reports/reports_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    required this.auth,
    this.embedded = false,
    this.activity = false,
    this.initialUnreadOnly = false,
    this.onBack,
    this.onRead,
  });
  final ReportRepository repository;
  final AuthController auth;
  final bool embedded, activity, initialUnreadOnly;
  final VoidCallback? onBack;
  final VoidCallback? onRead;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final String actor;
  List<Map<String, dynamic>> items = [];
  int offset = 0, total = 0;
  bool busy = false;
  String? error;
  String categoryFilter = 'Todas';
  String activityFilter = 'Todo', query = '';
  bool searchOpen = false;
  late bool unreadOnly = widget.initialUnreadOnly;
  Map<String, dynamic>? selectedAlert, alertReport;
  bool get current => mounted && widget.auth.account?.id == actor;
  @override
  void initState() {
    super.initState();
    actor = widget.auth.account!.id;
    widget.auth.addListener(authChanged);
    unawaited(load());
  }

  void authChanged() {
    if (mounted && !widget.embedded && widget.auth.account?.id != actor) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.auth.removeListener(authChanged);
    super.dispose();
  }

  Future<void> load({int? page}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!widget.activity) {
        final reports = <Map<String, dynamic>>[];
        for (var pageIndex = 0; pageIndex < 25; pageIndex++) {
          final response = await widget.repository.call('community_list', {
            'offset': pageIndex * 20,
          });
          if (!current) return;
          for (final value in response['reports'] as List? ?? []) {
            final report = Map<String, dynamic>.from(value);
            reports.add({
              ...report,
              'report_id': report['id'],
              'title': report['category'] ?? 'Reporte de la comunidad',
              'body':
                  '${report['description'] ?? ''}\nEstado: ${report['status'] ?? ''} · ${report['address'] ?? 'Ubicación aproximada'}',
              'read_at': report['created_at'],
            });
          }
          if (response['has_more'] != true) break;
        }
        final filtered = reports
            .where(
              (item) =>
                  categoryFilter == 'Todas' ||
                  alertCategory(item) == categoryFilter,
            )
            .toList();
        if (current) {
          setState(() {
            total = filtered.length;
            offset = page ?? offset;
            items = filtered.skip(offset).take(20).toList();
          });
        }
        return;
      }
      final data = await widget.repository.call('notifications_list', {
        'offset': page ?? offset,
      });
      if (current) {
        setState(() {
          items = (data['items'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (widget.activity) {
            items.sort(
              (a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'),
            );
          }
          total = (data['total'] as num).toInt();
          offset = page ?? offset;
        });
      }
    } catch (_) {
      if (current) {
        setState(() => error = 'No pudimos cargar los avisos. Reintenta.');
      }
    } finally {
      if (current) setState(() => busy = false);
    }
  }

  Future<void> open(Map<String, dynamic> item) async {
    if (busy) return;
    if (!widget.activity) {
      await Navigator.of(context).push(
        DesignPageRoute(
          builder: (_) => ReportsScreen(
            repository: widget.repository,
            auth: widget.auth,
            community: true,
            initialReportId: '${item['report_id'] ?? item['id']}',
          ),
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (item['read_at'] == null) {
        await widget.repository.call('notifications_read', {'id': item['id']});
      }
      if (!mounted || !current) return;
      setState(() => item['read_at'] = DateTime.now().toIso8601String());
      widget.onRead?.call();
      Map<String, dynamic>? report;
      if (widget.activity && item['report_id'] != null) {
        await Navigator.of(context).push(
          DesignPageRoute(
            builder: (_) => ReportsScreen(
              repository: widget.repository,
              auth: widget.auth,
              initialReportId: item['report_id'] as String,
            ),
          ),
        );
        return;
      }
      if (item['report_id'] != null) {
        report = await widget.repository.call('detail', {
          'report_id': item['report_id'],
        });
      }
      if (current) {
        setState(() {
          selectedAlert = item;
          alertReport = report;
        });
      }
    } catch (_) {
      if (current) {
        setState(() => error = 'No pudimos abrir el aviso. Reintenta.');
      }
    } finally {
      if (current) setState(() => busy = false);
    }
  }

  String kind(Map<String, dynamic> item) {
    final type = '${item['type'] ?? item['kind'] ?? ''}'.toLowerCase();
    if (type.contains('comment')) return 'Comentarios';
    return item['report_id'] != null ? 'Reportes' : 'Alertas';
  }

  String activityArtwork(Map<String, dynamic> item) {
    if (kind(item) == 'Comentarios') return 'activity-comment';
    if (kind(item) == 'Alertas') return 'activity-alert';
    final text = '${item['title']} ${item['body']}'.toLowerCase();
    if (text.contains('rechaz') || text.contains('cerrado')) {
      return 'activity-rejected';
    }
    if (text.contains('resuelto') || text.contains('acept')) {
      return 'activity-accepted';
    }
    return 'activity-pending';
  }

  bool matches(Map<String, dynamic> item) => widget.activity
      ? (activityFilter == 'Todo' || kind(item) == activityFilter) &&
            (!unreadOnly || item['read_at'] == null) &&
            '${item['title']} ${item['body']}'.toLowerCase().contains(
              query.trim().toLowerCase(),
            )
      : (categoryFilter == 'Todas' || alertCategory(item) == categoryFilter);

  String dayLabel(Map<String, dynamic> item) {
    final value = DateTime.tryParse('${item['created_at']}')?.toLocal();
    if (value == null) return 'Sin fecha';
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(value.year, value.month, value.day)).inDays;
    return days == 0
        ? 'Hoy'
        : days == 1
        ? 'Ayer'
        : '${value.day}/${value.month}/${value.year}';
  }

  String date(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    return d == null
        ? ''
        : '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String alertIcon(Map<String, dynamic> item) => categoryArtwork(
    item['category'] is String
        ? item['category'] as String
        : '${item['title']} ${item['body']}',
  ).$1;
  String alertCategory(Map<String, dynamic> item) {
    final icon = alertIcon(item);
    return ['robbery', 'users', 'spray'].contains(icon)
        ? 'Seguridad'
        : ['car', 'cone'].contains(icon)
        ? 'Tránsito'
        : 'Servicios';
  }

  Widget alertDetail() => DesignScaffold(
    backgroundColor: const Color(0xfff4faff),
    appBar: DesignHeader(
      'Detalle de alerta',
      onBack: () => setState(() => selectedAlert = null),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
      children: [
        DesignCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: categoryArtwork('${selectedAlert!['title']}').$2,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: CitizenSticker(alertIcon(selectedAlert!), size: 58),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedAlert!['title']}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff092b60),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date(selectedAlert!['created_at']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff6480a3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (alertReport != null) ...[
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
                      const Text(
                        'Ubicación',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${alertReport!['address'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff5f7da1),
                        ),
                      ),
                    ],
                  ),
                ),
                if (alertReport!['latitude'] != null)
                  SizedBox(
                    width: 125,
                    child: ReportMap(
                      height: 110,
                      point: LatLng(
                        (alertReport!['latitude'] as num).toDouble(),
                        (alertReport!['longitude'] as num).toDouble(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descripción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 9),
              Text(
                '${selectedAlert!['body']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff567397),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if ((alertReport?['images'] as List? ?? []).isNotEmpty) ...[
          const SizedBox(height: 12),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evidencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final image in alertReport!['images'])
                      PrivateReportImage(
                        repository: widget.repository,
                        reportId: alertReport!['id'],
                        imageId: image['id'],
                        large: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (selectedAlert!['recommendations'] is List) ...[
          const SizedBox(height: 12),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recomendaciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                for (final recommendation in selectedAlert!['recommendations'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.check_circle,
                      color: Color(0xff14b98d),
                    ),
                    title: Text(
                      '$recommendation',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff567397),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Clipboard.setData(
                  ClipboardData(
                    text:
                        '${selectedAlert!['title']}\n${selectedAlert!['body']}',
                  ),
                ),
                icon: const CitizenIcon('share'),
                label: const Text('Compartir'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: DesignButton(
                'Reportar',
                onPressed: () => Navigator.of(context).push(
                  DesignPageRoute(
                    builder: (_) => ReportsScreen(
                      repository: widget.repository,
                      auth: widget.auth,
                      initialCreate: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => selectedAlert != null
      ? alertDetail()
      : DesignScaffold(
          surface: widget.activity
              ? DesignSurface.activity
              : DesignSurface.page,
          backgroundColor: const Color(0xfff4faff),
          appBar: DesignHeader(
            widget.activity ? 'Actividad' : 'Alertas comunitarias',
            onBack: widget.onBack,
            action: IconButton(
              tooltip: widget.activity
                  ? 'Buscar en actividad'
                  : 'Actualizar avisos',
              onPressed: busy
                  ? null
                  : widget.activity
                  ? () => setState(() => searchOpen = !searchOpen)
                  : () => load(page: 0),
              icon: Icon(
                widget.activity ? Icons.search : Icons.notifications_none,
                size: 25,
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: RefreshIndicator(
                onRefresh: () => load(page: 0),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    if (widget.activity && searchOpen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          onChanged: (v) => setState(() => query = v),
                          decoration: const InputDecoration(
                            hintText: 'Buscar reporte, estado o colonia',
                            prefixIcon: CitizenIcon('search'),
                          ),
                        ),
                      ),
                    if (widget.activity)
                      Row(
                        children: [
                          for (final entry in const {
                            'Todo': 85,
                            'Reportes': 100,
                            'Comentarios': 120,
                            'Alertas': 90,
                          }.entries)
                            Expanded(
                              flex: entry.value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: DesignFilter(
                                  entry.key,
                                  activity: true,
                                  selected: activityFilter == entry.key,
                                  onTap: () => setState(
                                    () => activityFilter = entry.key,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (widget.activity && unreadOnly)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.fromLTRB(12, 7, 9, 7),
                        decoration: BoxDecoration(
                          color: const Color(0xc7ffffff),
                          border: Border.all(color: const Color(0xffd9eaf5)),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Mostrando ${items.where((i) => i['read_at'] == null).length} actividades no leídas',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff4e7198),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => unreadOnly = false),
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                      ),
                    if (!widget.activity)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            for (final label in [
                              'Todas',
                              'Seguridad',
                              'Tránsito',
                              'Servicios',
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: DesignFilter(
                                    label,
                                    selected: categoryFilter == label,
                                    onTap: () {
                                      if (busy) return;
                                      setState(() => categoryFilter = label);
                                      unawaited(load(page: 0));
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 17),
                    if (busy) const LinearProgressIndicator(),
                    if (error != null)
                      TextButton(
                        onPressed: busy ? null : () => load(),
                        child: Text(error!),
                      ),
                    if (!busy && error == null && items.where(matches).isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 48),
                            SizedBox(height: 16),
                            Text(
                              widget.activity
                                  ? 'No encontramos actividad con estos criterios.'
                                  : 'No hay alertas en esta categoría.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    for (final (index, item)
                        in items.where(matches).indexed) ...[
                      if (widget.activity &&
                          (index == 0 ||
                              dayLabel(
                                    items.where(matches).elementAt(index - 1),
                                  ) !=
                                  dayLabel(item)))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 15, 2, 8),
                          child: Text(
                            dayLabel(item),
                            style: const TextStyle(
                              fontSize: 23,
                              letterSpacing: -.92,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      DesignInteraction(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: widget.activity && item['read_at'] == null
                                ? Border.all(color: const Color(0x29217eeb))
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    widget.activity && item['read_at'] == null
                                    ? const Color(0x1a1965b7)
                                    : const Color(0x0f194368),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 12,
                            ),
                            minTileHeight: 118,
                            leading: widget.activity
                                ? Image.asset(
                                    'assets/renewal/icons/3d/${activityArtwork(item)}.png',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.contain,
                                  )
                                : CitizenSticker(alertIcon(item), size: 58),
                            title: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontWeight: item['read_at'] == null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${item['body']}\n${date(item['created_at'])}${widget.activity
                                    ? item['read_at'] == null
                                          ? ' · No leída'
                                          : ' · Leída'
                                    : ''}',
                              ),
                            ),
                            trailing: Icon(
                              item['read_at'] == null
                                  ? Icons.circle
                                  : Icons.chevron_right,
                              size: item['read_at'] == null ? 9 : 20,
                            ),
                            onTap: busy ? null : () => open(item),
                          ),
                        ),
                      ),
                    ],
                    if (total > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: busy || offset == 0
                                ? null
                                : () => load(page: offset - 20),
                            child: const Text('Anterior'),
                          ),
                          Expanded(
                            child: Text(
                              '${offset + 1}–${offset + items.length} de $total',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: busy || offset + items.length >= total
                                ? null
                                : () => load(page: offset + 20),
                            child: const Text('Siguiente'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
}
