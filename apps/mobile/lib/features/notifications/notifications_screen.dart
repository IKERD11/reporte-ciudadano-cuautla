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
  });
  final ReportRepository repository;
  final AuthController auth;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final String actor;
  List<Map<String, dynamic>> items = [];
  int offset = 0, total = 0;
  bool busy = false;
  String? error;
  bool get current => mounted && widget.auth.account?.id == actor;
  @override
  void initState() {
    super.initState();
    actor = widget.auth.account!.id;
    widget.auth.addListener(authChanged);
    unawaited(load());
  }

  void authChanged() {
    if (mounted && widget.auth.account?.id != actor) {
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
      final data = await widget.repository.call('notifications_list', {
        'offset': page ?? offset,
      });
      if (current) {
        setState(() {
          items = (data['items'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
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
      if (item['report_id'] != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportsScreen(
              repository: widget.repository,
              auth: widget.auth,
              initialReportId: item['report_id'] as String,
            ),
          ),
        );
      }
    } catch (_) {
      if (current) {
        setState(() => error = 'No pudimos abrir el aviso. Reintenta.');
      }
    } finally {
      if (current) setState(() => busy = false);
    }
  }

  String date(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    return d == null
        ? ''
        : '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notificaciones'),
      actions: [
        IconButton(
          tooltip: 'Actualizar avisos',
          onPressed: busy ? null : () => load(page: 0),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: RefreshIndicator(
          onRefresh: () => load(page: 0),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'PRUEBA PILOTO · Avisos dentro de la app',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Se actualizan al abrir esta pantalla o al deslizar hacia abajo.',
              ),
              const SizedBox(height: 16),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                TextButton(
                  onPressed: busy ? null : () => load(),
                  child: Text(error!),
                ),
              if (!busy && error == null && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Aún no tienes notificaciones.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final item in items)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: item['read_at'] == null
                          ? const Color(0xff452077)
                          : const Color(0xff29243e),
                      child: Icon(
                        item['read_at'] == null
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none,
                      ),
                    ),
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
                        '${item['body']}\n${date(item['created_at'])}',
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
                    Text('${offset + 1}–${offset + items.length} de $total'),
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
