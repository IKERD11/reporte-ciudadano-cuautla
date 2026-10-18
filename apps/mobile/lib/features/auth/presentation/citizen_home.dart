import 'dart:async';
import 'citizen_home_dashboard.dart';
import '../../notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/citizen_theme.dart';
import '../../reports/report_repository.dart';
import '../../reports/reports_screen.dart';
import '../application/auth_controller.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({
    super.key,
    required this.auth,
    required this.repository,
    required this.profileBuilder,
  });
  final AuthController auth;
  final ReportRepository repository;
  final Widget Function() profileBuilder;
  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> with WidgetsBindingObserver {
  int tab = 0;
  int unread = 0;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> categories = [], points = [];
  bool mapLoaded = false;
  final mapController = MapController();
  Map<String, dynamic>? selectedReport;
  late final String actor;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    actor = widget.auth.account!.id;
    unawaited(load());
    unawaited(refreshUnread());
  }

  @override
  void dispose() {
    mapController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && current) {
      unawaited(refreshUnread());
    }
  }

  bool get current => mounted && widget.auth.account?.id == actor;
  Future<void> load() async {
    try {
      final c = await widget.repository.call('context');
      if (current) {
        setState(() {
          categories = (c['categories'] as List)
              .map((v) => Map<String, dynamic>.from(v))
              .toList();
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (current) {
        setState(() {
          loading = false;
          error = 'No pudimos cargar las categorías.';
        });
      }
    }
  }

  Future<void> refreshUnread() async {
    try {
      final data = await widget.repository.call('notifications_count');
      if (current) setState(() => unread = (data['unread'] as num).toInt());
    } catch (_) {
      /* Keep the home usable offline. */
    }
  }

  Future<void> notifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          repository: widget.repository,
          auth: widget.auth,
        ),
      ),
    );
    if (current) await refreshUnread();
  }

  Future<void> reports({bool create = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(
          repository: widget.repository,
          auth: widget.auth,
          initialCreate: create,
        ),
      ),
    );
    if (current) await refreshUnread();
  }

  void info(String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(body),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> selectTab(int value) async {
    setState(() => tab = value);
    unawaited(refreshUnread());
    if (value != 2 || mapLoaded) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await widget.repository.call('list');
      final result = <Map<String, dynamic>>[];
      // Paginación acotada: solo los 20 reportes propios más recientes.
      for (final r in list['reports']) {
        if (!current) return;
        final d = await widget.repository.call('detail', {
          'report_id': r['id'],
        });
        if (d['latitude'] != null) result.add(d);
      }
      if (current) {
        setState(() {
          points = result;
          mapLoaded = true;
        });
      }
    } catch (_) {
      if (current) setState(() => error = 'No pudimos cargar tus ubicaciones.');
    } finally {
      if (current) setState(() => loading = false);
    }
  }

  Widget home() => Builder(
    builder: (homeContext) => CitizenHomeDashboard(
      name: widget.auth.profile!.firstName,
      unread: unread,
      onMenu: () => Scaffold.of(homeContext).openDrawer(),
      onReport: () => reports(create: true),
      onMap: () => selectTab(2),
      onReports: () => selectTab(1),
      onNotifications: notifications,
      onHelp: () => info(
        'Ayuda del piloto',
        'Consulta tus reportes y sus avisos desde esta aplicación. Las pruebas no envían solicitudes de emergencia ni tienen atención municipal real.',
      ),
    ),
  );

  Widget homeNavigation() => SafeArea(
    top: false,
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        children: [
          for (final entry in [
            (0, Icons.home_rounded, 'Inicio'),
            (2, Icons.map_outlined, 'Mapa'),
            (4, Icons.add, 'Reportar'),
            (1, Icons.history_rounded, 'Actividad'),
            (3, Icons.person_rounded, 'Perfil'),
          ])
            Expanded(
              child: Semantics(
                selected: entry.$1 == 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => entry.$1 == 4
                      ? reports(create: true)
                      : selectTab(entry.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.$1 == 4)
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xff00b995),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 34,
                            ),
                          )
                        else
                          Icon(
                            entry.$2,
                            size: 28,
                            color: entry.$1 == 0
                                ? const Color(0xff0755d9)
                                : const Color(0xff6387af),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          entry.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: entry.$1 == 0
                                ? const Color(0xff0755d9)
                                : const Color(0xff52759c),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  Widget reportPreview(Map<String, dynamic> report) {
    final images = report['images'] as List? ?? [];
    return Material(
      color: const Color(0xff191431),
      elevation: 10,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 86,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isNotEmpty)
                  PrivateReportImage(
                    key: ValueKey('${report['id']}/${images.first['id']}'),
                    repository: widget.repository,
                    reportId: report['id'],
                    imageId: images.first['id'],
                    large: true,
                  )
                else
                  const ColoredBox(
                    color: Color(0xff292044),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_outlined, size: 20, color: muted),
                          SizedBox(width: 8),
                          Text(
                            'Sin fotografía',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filled(
                    tooltip: 'Cerrar vista del reporte',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xcc171337),
                    ),
                    onPressed: () => setState(() => selectedReport = null),
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['folio'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff37205a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report['status'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xffd9b8ff),
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Color(0xffd5cee8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget map() => Column(
    children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Tus 20 reportes más recientes · Solo visibles para tu cuenta',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ),
      if (loading) const LinearProgressIndicator(),
      if (error != null)
        TextButton(
          onPressed: () => selectTab(2),
          child: Text('$error Reintentar'),
        ),
      Expanded(
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            onTap: (_, _) => setState(() => selectedReport = null),
            initialCenter: points.isEmpty
                ? const LatLng(18.812, -98.955)
                : LatLng(
                    (points.first['latitude'] as num).toDouble(),
                    (points.first['longitude'] as num).toDouble(),
                  ),
            initialZoom: 13,
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
                  defaultValue:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                userAgentPackageName: 'mx.reporteciudadano.piloto',
              ),
            ),
            MarkerLayer(
              markers: [
                for (final p in points)
                  Marker(
                    point: LatLng(
                      (p['latitude'] as num).toDouble(),
                      (p['longitude'] as num).toDouble(),
                    ),
                    width: 46,
                    height: 46,
                    child: IconButton(
                      tooltip: p['folio'],
                      onPressed: () {
                        setState(() => selectedReport = p);
                        mapController.move(
                          LatLng(
                            (p['latitude'] as num).toDouble(),
                            (p['longitude'] as num).toDouble(),
                          ),
                          mapController.camera.zoom,
                          offset: const Offset(0, 100),
                        );
                      },
                      icon: const Icon(
                        Icons.location_on,
                        color: Color(0xffab54ff),
                        size: 38,
                      ),
                    ),
                  ),
              ],
            ),
            if (selectedReport != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      (selectedReport!['latitude'] as num).toDouble(),
                      (selectedReport!['longitude'] as num).toDouble(),
                    ),
                    width:
                        MediaQuery.sizeOf(
                          context,
                        ).width.clamp(200, 290).toDouble() -
                        24,
                    height: 234,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: reportPreview(selectedReport!),
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
      if (!loading && points.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Aún no tienes reportes con ubicación.'),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: tab == 0 ? const Color(0xffedf9ff) : citizenBackground,
    appBar: tab == 0
        ? null
        : AppBar(
            title: Text(
              const [
                'Reporte Ciudadano',
                'Mis reportes',
                'Mapa de reportes',
                'Mi perfil',
              ][tab],
            ),
            actions: [
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: notifications,
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ],
          ),
    drawer: Drawer(
      backgroundColor: citizenBackground,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: CitizenBrand(light: true),
            ),
            for (final entry in [
              (0, Icons.home_outlined, 'Inicio'),
              (1, Icons.assignment_outlined, 'Mis reportes'),
              (2, Icons.map_outlined, 'Mapa'),
              (3, Icons.person_outline, 'Perfil'),
            ])
              ListTile(
                iconColor: Colors.white,
                textColor: Colors.white,
                leading: Icon(entry.$2),
                title: Text(entry.$3),
                onTap: () {
                  Navigator.pop(context);
                  selectTab(entry.$1);
                },
              ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: const Icon(Icons.help_outline),
              title: const Text('Ayuda y soporte'),
              onTap: () {
                Navigator.pop(context);
                info(
                  'Acerca del piloto',
                  'Usa fotografías y descripciones de prueba sin datos personales. Esta aplicación no sustituye a los servicios de emergencia. La verificación de INE real sigue deshabilitada.',
                );
              },
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                notifications();
              },
            ),
            const Spacer(),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: widget.auth.logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: switch (tab) {
          0 => home(),
          1 => ReportsScreen(
            repository: widget.repository,
            auth: widget.auth,
            embedded: true,
          ),
          2 => map(),
          _ => widget.profileBuilder(),
        },
      ),
    ),
    bottomNavigationBar: tab == 0
        ? homeNavigation()
        : NavigationBar(
            selectedIndex: tab < 2 ? tab : tab + 1,
            onDestinationSelected: (index) {
              if (index == 2) {
                reports(create: true);
              } else {
                selectTab(index > 2 ? index - 1 : index);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment),
                label: 'Mis reportes',
              ),
              NavigationDestination(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: citizenAccent,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                label: 'Crear',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
  );
}
