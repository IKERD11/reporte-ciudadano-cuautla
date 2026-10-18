import 'package:flutter/material.dart';

/// The light dashboard is scoped to home; report and account flows keep their theme.
class CitizenHomeDashboard extends StatelessWidget {
  const CitizenHomeDashboard({
    super.key,
    required this.name,
    required this.unread,
    required this.onMenu,
    required this.onReport,
    required this.onMap,
    required this.onReports,
    required this.onNotifications,
    required this.onHelp,
  });
  final String name;
  final int unread;
  final VoidCallback onMenu,
      onReport,
      onMap,
      onReports,
      onNotifications,
      onHelp;
  static const ink = Color(0xff092254);

  Widget tile(
    String title,
    String subtitle,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap, {
    bool large = false,
    Color foreground = ink,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: .8)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: EdgeInsets.all(large ? 18 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: large ? 38 : 30, color: foreground),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: large ? 18 : 15,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: foreground,
                    fontSize: large ? 14 : 12,
                    height: 1.35,
                  ),
                ),
                if (large) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: colors.last,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xffedf9ff),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/branding/city-home.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xffb9edff).withValues(alpha: .4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onMenu,
                        tooltip: 'Abrir menú',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .85),
                        ),
                        icon: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xff00ad88),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Reporte Ciudadano',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onNotifications,
                        tooltip: 'Notificaciones',
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text(unread > 99 ? '99+' : '$unread'),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: ink,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Hola, $name',
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu voz también\nconstruye una mejor ciudad',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xffb6dcef).withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: onMap,
                    borderRadius: BorderRadius.circular(24),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Color(0xff0961d8),
                            size: 42,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Municipio del piloto',
                                  style: TextStyle(
                                    color: Color(0xff52759c),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Cuautla, Morelos',
                                  style: TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xff0860ed),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: tile(
                          'Reportar incidente',
                          'Haz un reporte rápido',
                          Icons.campaign_rounded,
                          const [Color(0xffff8580), Color(0xffff315a)],
                          onReport,
                          large: true,
                          foreground: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: tile(
                          'Mapa de incidentes',
                          'Consulta tus reportes',
                          Icons.map_rounded,
                          const [Color(0xff42c8ff), Color(0xff2764ff)],
                          onMap,
                          large: true,
                          foreground: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: tile(
                          'Mis reportes',
                          'Ver seguimiento',
                          Icons.assignment_rounded,
                          const [Color(0xffc7ffed), Color(0xffa9f5df)],
                          onReports,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tile(
                          'Avisos',
                          'De tus reportes',
                          Icons.notifications_active_rounded,
                          const [Color(0xffede4ff), Color(0xffded4ff)],
                          onNotifications,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tile(
                          'Ayuda',
                          'Información del piloto',
                          Icons.support_agent_rounded,
                          const [Color(0xfffff2b7), Color(0xffffe798)],
                          onHelp,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 18,
                      color: Color(0xff52759c),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PRUEBA PILOTO · Sin atención municipal real.\nNo sustituye a los servicios de emergencia.',
                        style: TextStyle(
                          color: Color(0xff52759c),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
