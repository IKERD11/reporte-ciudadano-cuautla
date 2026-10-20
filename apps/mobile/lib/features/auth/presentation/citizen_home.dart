import 'zone_screen.dart';
import '../../../core/zone_storage.dart';
import 'dart:async';
import '../../../core/citizen_design.dart';
import '../../../core/citizen_sticker.dart';
import '../../../core/address_search.dart';
import 'package:geolocator/geolocator.dart';
import '../../reports/report_map.dart';
import 'citizen_design_screens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'citizen_home_dashboard.dart';
import '../../notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
    this.geocode = searchAddressNotConnected,
  });
  final AuthController auth;
  final ReportRepository repository;
  final Widget Function() profileBuilder;
  final AddressGeocoder geocode;
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
  bool mapCovered = false;
  bool notificationIndicators = true;
  bool activityUnreadOnly = false;
  String mapQuery = "";
  String mapFilter = "Todos";
  LatLng? mapFocus;
  bool searchingMap = false;
  int mapSearchRequest = 0;
  final mapCardKey = GlobalKey();
  double mapCardHeight = 203;
  Map<String, dynamic>? selectedReport;
  late final String actor;
  CitizenZone zone = const CitizenZone();
  bool zoneConfigured = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    actor = widget.auth.account!.id;
    zone = CitizenZone.decode(readZone(actor));
    zoneConfigured = readZone(actor) != null;
    unawaited(load());
    unawaited(refreshUnread());
  }

  @override
  void dispose() {
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
    activityUnreadOnly = unread > 0;
    await selectTab(5);
  }

  Future<void> reports({bool create = false}) async {
    if (tab == 2) setState(() => mapCovered = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportsScreen(
          repository: widget.repository,
          auth: widget.auth,
          initialCreate: create,
          geocode: widget.geocode,
          onNavigate: (value) {
            Navigator.of(context).pop();
            navigate(value);
          },
        ),
      ),
    );
    if (current) {
      setState(() {
        mapLoaded = false;
        mapCovered = false;
      });
      await refreshUnread();
    }
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
        if (d['latitude'] != null &&
            d['longitude'] != null &&
            !isDemonstrationReport(d)) {
          result.add(d);
        }
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
      unread: notificationIndicators ? unread : 0,
      onMenu: () => Scaffold.of(homeContext).openDrawer(),
      onReport: () => reports(create: true),
      onMap: () => selectTab(2),
      onReports: () => selectTab(1),
      onNotifications: () => selectTab(7),
      onZone: configureZone,
      onActivity: notifications,
      zoneAddress: zone.address,
      onHelp: () => selectTab(6),
    ),
  );

  Future<void> configureZone() async {
    if (tab == 2) setState(() => mapCovered = true);
    final value = await Navigator.of(context).push<CitizenZone>(
      MaterialPageRoute(
        builder: (_) => ZoneScreen(initial: zone, geocode: widget.geocode),
      ),
    );
    if (!current) return;
    if (value != null) {
      try {
        writeZone(actor, value.encode());
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La zona se conservará solo durante esta sesión.'),
            ),
          );
        }
      }
    }
    setState(() {
      mapCovered = false;
      if (value != null) {
        zone = value;
        zoneConfigured = true;
        mapFocus = value.point;
        selectedReport = null;
      }
    });
  }

  void navigate(int value) {
    if (value == 5) activityUnreadOnly = false;
    if (value == 4) {
      reports(create: true);
    } else {
      selectTab(value);
    }
  }

  Widget homeNavigation() => DesignNavigation(
    unread: notificationIndicators ? unread : 0,
    active: tab == 1 || tab == 6 || tab == 7 ? 0 : tab,
    onSelected: navigate,
  );
  Widget reportPreview(Map<String, dynamic> report) {
    final images = report['images'] as List? ?? [];
    return Material(
      color: const Color(0xffffffff),
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
                    color: Color(0xffedf5fc),
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
                      backgroundColor: const Color(0xeef8fcfe),
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
                    color: const Color(0xfffff0bd),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report['status'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff956000),
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
                    color: Color(0xff173967),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> searchMap(String query) async {
    if (query.trim().isEmpty) return;
    final request = ++mapSearchRequest;
    setState(() => searchingMap = true);
    try {
      final results = await widget
          .geocode(query)
          .timeout(const Duration(seconds: 20));
      if (request != mapSearchRequest || tab != 2) return;
      if (!current) return;
      if (results.isEmpty) {
        info('Buscar zona', 'No encontramos esa zona.');
        return;
      }
      setState(
        () => mapFocus = LatLng(
          (results.first['latitude'] as num).toDouble(),
          (results.first['longitude'] as num).toDouble(),
        ),
      );
    } on AddressSearchUnavailable catch (e) {
      if (current && tab == 2 && request == mapSearchRequest) {
        info('Buscar zona', e.toString());
      }
    } catch (_) {
      if (current && tab == 2 && request == mapSearchRequest) {
        info('Buscar zona', 'No fue posible buscar esa zona.');
      }
    } finally {
      if (current && request == mapSearchRequest) {
        setState(() => searchingMap = false);
      }
    }
  }

  Future<void> locateMap() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (current) setState(() => mapFocus = LatLng(p.latitude, p.longitude));
    } catch (_) {
      if (current) info('Ubicación', 'No fue posible obtener tu ubicación.');
    }
  }

  bool mapMatches(Map<String, dynamic> report) {
    if (zoneConfigured &&
        report['latitude'] is num &&
        report['longitude'] is num &&
        const Distance().as(
              LengthUnit.Kilometer,
              zone.point,
              LatLng(
                (report['latitude'] as num).toDouble(),
                (report['longitude'] as num).toDouble(),
              ),
            ) >
            zone.radius) {
      return false;
    }
    final icon = categoryArtwork(
      '${report['category'] ?? report['description'] ?? ''}',
    ).$1;
    return mapFilter == 'Todos' ||
        (mapFilter == 'Seguridad' &&
            ['robbery', 'spray', 'users'].contains(icon)) ||
        (mapFilter == 'Vialidad' && ['car', 'cone'].contains(icon)) ||
        (mapFilter == 'Servicios' && ['bulb', 'more'].contains(icon)) ||
        (mapFilter == 'Animales' && icon == 'paw');
  }

  Widget map() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!current || tab != 2) return;
      final box = mapCardKey.currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          (box.size.height - mapCardHeight).abs() > 1) {
        setState(() => mapCardHeight = box.size.height);
      }
    });
    return LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          ReportMap(
            height: c.maxHeight,
            radius: 0,
            zoom: 14,
            allow3D: true,
            bottomInset: mapCardHeight,
            controlTop: 82,
            reports: points.where(mapMatches).toList(),
            point: mapFocus ?? zone.point,
            radiusKm: zoneConfigured ? zone.radius : null,
            onReportSelected: (r) => setState(() => selectedReport = r),
          ),
          Positioned(
            top: 16,
            left: 18,
            right: 80,
            child: PointerInterceptor(
              child: TextField(
                onSubmitted: searchMap,
                onChanged: (v) {
                  mapQuery = v;
                  mapSearchRequest++;
                  if (searchingMap) setState(() => searchingMap = false);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar en esta zona...',
                  prefixIcon: const Icon(Icons.search, size: 24),
                  suffixIcon: searchingMap
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 18,
            child: PointerInterceptor(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                child: PopupMenuButton<String>(
                  tooltip: 'Filtrar incidentes',
                  icon: const Icon(Icons.filter_list, size: 25),
                  onSelected: (v) => setState(() {
                    mapFilter = v;
                    selectedReport = null;
                  }),
                  itemBuilder: (_) => [
                    for (final f in [
                      'Todos',
                      'Seguridad',
                      'Vialidad',
                      'Servicios',
                      'Animales',
                    ])
                      PopupMenuItem(value: f, child: Text(f)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 82,
            right: 18,
            child: PointerInterceptor(
              child: IconButton.filled(
                tooltip: 'Usar mi ubicación actual',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xff1769ea),
                ),
                onPressed: locateMap,
                icon: const Icon(Icons.my_location, size: 26),
              ),
            ),
          ),
          if (loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (error != null)
            Positioned(
              top: 130,
              left: 18,
              right: 18,
              child: PointerInterceptor(
                child: TextButton(
                  onPressed: () => selectTab(2),
                  child: Text('$error Reintentar'),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PointerInterceptor(
              child: Container(
                key: mapCardKey,
                padding: const EdgeInsets.fromLTRB(19, 18, 19, 14),
                constraints: const BoxConstraints(minHeight: 203),
                decoration: const BoxDecoration(
                  color: Color(0xfffbfdff),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1a123f65),
                      blurRadius: 28,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Incidentes cercanos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff082b65),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => selectTab(1),
                          child: const Text(
                            'Ver todos ›',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedReport != null)
                      reportPreview(selectedReport!)
                    else if (points.where(mapMatches).isNotEmpty)
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          leading: CitizenSticker(
                            categoryArtwork(
                              '${points.where(mapMatches).first['category'] ?? points.where(mapMatches).first['description']}',
                            ).$1,
                            size: 59,
                          ),
                          title: Text(
                            '${points.where(mapMatches).first['category'] ?? points.where(mapMatches).first['folio']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            '${points.where(mapMatches).first['address'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => setState(
                            () =>
                                selectedReport = points.where(mapMatches).first,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Text(
                          'Aún no tienes reportes con ubicación en esta zona.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget profile() => CitizenProfileDesign(
    name: '${widget.auth.profile!.firstName} ${widget.auth.profile!.lastName}',
    email: widget.auth.account!.email,
    notifications: notificationIndicators,
    onNotificationsChanged: (v) => setState(() => notificationIndicators = v),
    onReports: () => selectTab(1),
    onLocation: configureZone,
    onLogout: widget.auth.logout,
    onPrivacy: () => info(
      'Privacidad',
      'Tus reportes y fotografías son privados. Usa datos de prueba durante el piloto. La captura de INE real sigue deshabilitada.',
    ),
    onHelp: () => info(
      'Ayuda y soporte',
      'Piloto de Cuautla, sin atención municipal real. Consulta el estado de tus reportes y sus avisos desde la app. No sustituye los servicios de emergencia.',
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: tab == 0
        ? const Color(0xfff8fcfe)
        : const Color(0xfff4faff),
    appBar: tab == 0 || tab == 1 || tab == 5 || tab == 7 || tab == 6
        ? null
        : DesignHeader(
            const {
                  1: 'Mis reportes',
                  2: 'Mapa de incidentes',
                  3: 'Mi perfil',
                }[tab] ??
                '',
            onBack: () => selectTab(0),
            action: tab == 3
                ? IconButton(
                    tooltip: 'Abrir configuración',
                    icon: const Icon(Icons.settings_outlined, size: 27),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: DesignHeader('Mis datos'),
                          body: widget.profileBuilder(),
                        ),
                      ),
                    ),
                  )
                : null,
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
                iconColor: navy,
                textColor: navy,
                leading: Icon(entry.$2),
                title: Text(entry.$3),
                onTap: () {
                  Navigator.pop(context);
                  selectTab(entry.$1);
                },
              ),
            ListTile(
              iconColor: navy,
              textColor: navy,
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
              iconColor: navy,
              textColor: navy,
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificaciones'),
              onTap: () {
                Navigator.pop(context);
                notifications();
              },
            ),
            const Spacer(),
            ListTile(
              iconColor: navy,
              textColor: navy,
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
        constraints: const BoxConstraints(maxWidth: 430),
        child: switch (tab) {
          0 => home(),
          1 => ReportsScreen(
            repository: widget.repository,
            auth: widget.auth,
            embedded: true,
            geocode: widget.geocode,
          ),
          2 => mapCovered ? const SizedBox() : map(),
          3 => profile(),
          7 => NotificationsScreen(
            repository: widget.repository,
            auth: widget.auth,
            embedded: true,
            onBack: () => selectTab(0),
          ),
          5 => NotificationsScreen(
            key: ValueKey(activityUnreadOnly),
            onRead: () => unawaited(refreshUnread()),
            initialUnreadOnly: activityUnreadOnly,
            activity: true,
            repository: widget.repository,
            auth: widget.auth,
            embedded: true,
            onBack: () => selectTab(0),
          ),
          _ => CitizenContacts(onBack: () => selectTab(0)),
        },
      ),
    ),
    bottomNavigationBar: homeNavigation(),
  );
}
