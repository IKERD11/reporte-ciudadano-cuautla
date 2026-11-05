import '../../../core/figma_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_config.dart';
import '../../../core/citizen_push.dart';
import 'citizen_map_panels.dart';
import 'edit_profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'zone_screen.dart';
import '../../../core/zone_storage.dart';
import 'dart:async';
import '../../../core/citizen_design.dart';
import '../../../core/address_search.dart';
import 'package:geolocator/geolocator.dart';
import '../../reports/report_map.dart';
import 'citizen_design_screens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'citizen_home_dashboard.dart';
import '../../notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
  int tab = 0, previousTab = 0;
  int unread = 0;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> categories = [], points = [];
  bool mapLoaded = false;
  bool nearbyExpanded = false, nearbyCollapsed = false, mapFilterOpen = false;
  bool mapCovered = false;
  bool notificationIndicators = true;
  bool activityUnreadOnly = false;
  String mapQuery = "";
  String mapFilter = "Todos";
  LatLng? mapFocus;
  bool searchingMap = false;
  int mapSearchRequest = 0;
  final mapCardKey = GlobalKey();
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
      DesignPageRoute(
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

  void info(String title, String body) => showDesignNotice(context, body);

  Future<void> selectTab(int value) async {
    setState(() {
      if (value == 2 && tab != 2) {
        nearbyExpanded = false;
        nearbyCollapsed = false;
        mapFilterOpen = false;
        mapFilter = 'Todos';
      }
      previousTab = tab;
      tab = value;
    });
    unawaited(refreshUnread());
    if (value != 2) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = <Map<String, dynamic>>[];
      for (var page = 0; page < 25; page++) {
        final response = await widget.repository.call('community_list', {
          'offset': page * 20,
        });
        if (!current) return;
        for (final item in response['reports'] as List? ?? []) {
          final report = Map<String, dynamic>.from(item);
          if (report['latitude'] != null &&
              report['longitude'] != null &&
              !isDemonstrationReport(report)) {
            result.add(report);
          }
        }
        if (response['has_more'] != true) break;
        if (page == 24 && mounted) {
          showDesignNotice(
            context,
            'Mostrando los 500 reportes más recientes. Consulta Comunidad para ver más.',
          );
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
      onMenu: () {},
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
      DesignPageRoute(
        builder: (_) => ZoneScreen(initial: zone, geocode: widget.geocode),
      ),
    );
    if (!current) return;
    if (value != null) {
      try {
        writeZone(actor, value.encode());
      } catch (_) {
        if (mounted) {
          showDesignNotice(
            context,
            'La zona se conservará solo durante esta sesión.',
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
  Future<void> openMapReport(Map<String, dynamic> report) async {
    setState(() {
      mapCovered = true;
      mapFilterOpen = false;
    });
    await Navigator.of(context).push(
      DesignPageRoute<void>(
        fade: true,
        builder: (_) => ReportsScreen(
          repository: widget.repository,
          auth: widget.auth,
          initialReportId: report['id'].toString(),
          community: true,
          geocode: widget.geocode,
        ),
      ),
    );
    if (current) {
      setState(() {
        mapCovered = false;
        nearbyExpanded = false;
        nearbyCollapsed = false;
        mapFilter = 'Todos';
      });
    }
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
    return LayoutBuilder(
      builder: (context, c) => Stack(
        clipBehavior: Clip.none,
        children: [
          ReportMap(
            height: c.maxHeight,
            radius: 0,
            zoom: mapFocus == null ? 15.2 : 16,
            cameraDuration: 700,
            allow3D: true,
            initial3D: true,
            showPointMarker: false,
            bottomInset: nearbyCollapsed ? 64 : 203,
            hideControls: nearbyExpanded,
            controlTop: 82,
            reports: points.where(mapMatches).toList(),
            point: mapFocus ?? zone.point,
            onReportSelected: openMapReport,
          ),
          Positioned(
            top: 17,
            left: 20,
            right: 75,
            child: PointerInterceptor(
              child: Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                decoration: BoxDecoration(
                  color: const Color(0xf7ffffff),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x291d4970),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 34,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CitizenIcon(
                          'search',
                          size: 24,
                          color: Color(0xff0a2c6e),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        onSubmitted: searchMap,
                        onChanged: (value) {
                          mapQuery = value;
                          mapSearchRequest++;
                          if (searchingMap) {
                            setState(() => searchingMap = false);
                          }
                        },
                        style: const TextStyle(
                          color: Color(0xff173967),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar en esta zona...',
                          isDense: true,
                          filled: false,
                          hintStyle: TextStyle(
                            color: Color(0xff637fa6),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (searchingMap)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 17,
            right: 18,
            child: PointerInterceptor(
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: mapFilterOpen
                      ? const Color(0xff1769e8)
                      : const Color(0xf7ffffff),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x291d4970),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Filtrar incidentes',
                  onPressed: () =>
                      setState(() => mapFilterOpen = !mapFilterOpen),
                  icon: CitizenIcon(
                    'filter',
                    size: 25,
                    color: mapFilterOpen
                        ? Colors.white
                        : const Color(0xff0b2d73),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
          if (!nearbyExpanded)
            Positioned(
              bottom: nearbyCollapsed ? 68 : 207,
              right: 20,
              child: PointerInterceptor(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x331a4970),
                          blurRadius: 23,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IconButton.filled(
                      tooltip: 'Usar mi ubicación actual',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff1769ea),
                      ),
                      onPressed: locateMap,
                      icon: const CitizenIcon(
                        'crosshair',
                        size: 26,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ),
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
            bottom: -6,
            child: PointerInterceptor(
              child: CitizenNearbySheet(
                key: mapCardKey,
                expanded: nearbyExpanded,
                collapsed: nearbyCollapsed,
                onCollapse: () => setState(() {
                  nearbyCollapsed = !nearbyCollapsed;
                  nearbyExpanded = false;
                }),
                availableHeight: MediaQuery.sizeOf(context).height,
                reports: points.where(mapMatches).toList(),
                onToggle: () => setState(() {
                  mapFilter = 'Todos';
                  nearbyExpanded = !nearbyExpanded;
                }),
                onSelected: openMapReport,
              ),
            ),
          ),
          if (mapFilterOpen)
            Positioned(
              top: 80,
              right: 18,
              child: PointerInterceptor(
                child: CitizenMapFilterMenu(
                  selected: mapFilter,
                  onSelected: (value) => setState(() {
                    mapFilter = value;
                    mapFilterOpen = false;
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Uint8List? profilePhoto;
  String? photoActor;
  void loadProfilePhoto() {
    final actor = widget.auth.account?.id;
    if (actor == null || photoActor == actor) return;
    photoActor = actor;
    profilePhoto = null;
    ProfilePhotoStore.read(actor).then((value) {
      if (mounted && widget.auth.account?.id == actor) {
        setState(() => profilePhoto = value);
      }
    });
  }

  Future<void> editProfile() async {
    await Navigator.of(context).push(
      DesignPageRoute(
        builder: (_) => EditProfileScreen(
          auth: widget.auth,
          photo: profilePhoto,
          accountOptions: (_) => widget.profileBuilder(),
          onPhotoSaved: (bytes) {
            if (mounted) setState(() => profilePhoto = bytes);
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  bool pushEnabled = false, pushBusy = false;
  Future<void> togglePush(bool enabled) async {
    if (pushBusy || !AppConfig.isConfigured) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.user.id != actor) return;
    setState(() => pushBusy = true);
    try {
      final ok = await setCitizenPush(
        '${AppConfig.url}/functions/v1/server/make-server-66389b89',
        session.accessToken,
        enabled,
      );
      if (!current) return;
      if (ok)
        setState(() => pushEnabled = enabled);
      else
        showDesignNotice(
          context,
          'No se pudo cambiar el permiso de notificaciones del navegador.',
        );
    } catch (_) {
      if (current)
        showDesignNotice(context, 'No se pudo actualizar el dispositivo.');
    } finally {
      if (current) setState(() => pushBusy = false);
    }
  }

  Future<void> signOutWithPushCleanup() async {
    await togglePush(false);
    if (current) await widget.auth.logout();
  }

  void openFigmaScreen(String screen, String title) {
    Navigator.of(context).push<void>(
      DesignPageRoute(
        builder: (_) => FigmaScreen(screen: screen, title: title),
      ),
    );
  }

  void openPendingScreens() {
    Navigator.of(context).push<void>(
      DesignPageRoute(
        builder: (context) => DesignScaffold(
          appBar: const DesignHeader('Pantallas en integración'),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Puedes revisar estas pantallas dentro de la app. Sus flujos todavía usan datos de muestra.',
              ),
              for (final item in const [
                ('notifications', 'Bandeja de notificaciones'),
                ('notificationSettings', 'Preferencias de notificaciones'),
                ('privacy', 'Privacidad y seguridad'),
                ('help', 'Ayuda y soporte'),
                ('contacts', 'Contactos útiles'),
                ('contactDetail', 'Detalle de contacto'),
                ('sos', 'Flujo SOS'),
                ('alertDetail', 'Detalle de alerta'),
                ('changePassword', 'Cambiar contraseña'),
              ])
                ListTile(
                  title: Text(item.$2),
                  trailing: const CitizenIcon('chevron'),
                  onTap: () => openFigmaScreen(item.$1, item.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget profile() {
    loadProfilePhoto();
    return CitizenProfileDesign(
      photo: profilePhoto,
      name:
          '${widget.auth.profile!.firstName} ${widget.auth.profile!.lastName}',
      email: widget.auth.account!.email,
      notifications: AppConfig.isConfigured
          ? pushEnabled
          : notificationIndicators,
      onNotificationsChanged: (v) {
        if (AppConfig.isConfigured) {
          unawaited(togglePush(v));
        } else {
          setState(() => notificationIndicators = v);
        }
      },
      onReports: () => selectTab(1),
      onLocation: configureZone,
      onLogout: signOutWithPushCleanup,
      onPrivacy: () => openFigmaScreen('privacy', 'Privacidad y seguridad'),
      onHelp: () => openFigmaScreen('help', 'Ayuda y soporte'),
      onPendingScreens: openPendingScreens,
    );
  }

  @override
  Widget build(BuildContext context) => DesignScaffold(
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
                    tooltip: 'Editar perfil',
                    icon: const CitizenIcon('settings', size: 27),
                    onPressed: editProfile,
                  )
                : null,
          ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: DesignScreenEntrance(
          key: ValueKey(tab),
          fade: tab == 2 || previousTab == 2 || (tab != 0 && previousTab != 0),
          back: tab == 0 && previousTab != 0,
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
    ),
    bottomNavigationBar: homeNavigation(),
  );
}
