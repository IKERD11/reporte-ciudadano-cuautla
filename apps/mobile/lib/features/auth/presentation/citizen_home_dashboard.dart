import 'package:flutter/material.dart';
import '../../../core/citizen_sticker.dart';

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
  static const ink = Color(0xff092b60);

  Widget tile(
    String title,
    String subtitle,
    String sticker,
    List<Color> colors,
    VoidCallback onTap, {
    bool large = false,
    Color foreground = ink,
  }) => Material(
    color: Colors.transparent,
    elevation: large ? 6 : 0,
    shadowColor: colors.last.withValues(alpha: .2),
    borderRadius: BorderRadius.circular(large ? 24 : 21),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(large ? 24 : 21),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (large)
                Positioned(
                  top: -30,
                  right: -24,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .13),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: large ? 181 : 135),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: large ? 17 : 12,
                    vertical: large ? 21 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CitizenSticker(sticker, size: large ? 58 : 48),
                      SizedBox(height: large ? 7 : 11),
                      Text(
                        title,
                        style: TextStyle(
                          color: large ? foreground : ink,
                          fontSize: large ? 16 : 12,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: foreground,
                          fontSize: large ? 11 : 9,
                          fontWeight: large ? FontWeight.w500 : FontWeight.w600,
                          height: large ? 1.35 : 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (large)
                Positioned(
                  right: 13,
                  bottom: 13,
                  child: CircleAvatar(
                    radius: 17.5,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.chevron_right,
                      size: 19,
                      color: colors.last,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xfff8fcfe),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: (constraints.maxWidth * .5 + 34).clamp(220, 300),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/renewal/cuautla-cityscape-header.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 29, 25, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: onMenu,
                            tooltip: 'Abrir menú',
                            padding: EdgeInsets.zero,
                            icon: const CitizenSticker(
                              'shield-header',
                              size: 46,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MUNICIPIO DE CUAUTLA',
                                  style: TextStyle(
                                    color: Color(0xff24728b),
                                    fontSize: 8,
                                    letterSpacing: .8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Cuautla Segura',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onNotifications,
                            tooltip: 'Notificaciones',
                            icon: Badge(
                              isLabelVisible: unread > 0,
                              label: Text(unread > 99 ? '99+' : '$unread'),
                              child: const CitizenSticker(
                                'bell-header',
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Hola, $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Tu voz mejora nuestra ciudad',
                        style: TextStyle(
                          color: ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          letterSpacing: -.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0x33125c8d),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: onMap,
                    borderRadius: BorderRadius.circular(22),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          CitizenSticker('pin', size: 53),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tu ubicación',
                                  style: TextStyle(
                                    color: Color(0xff6a82a0),
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Cuautla, Morelos',
                                  style: TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Color(0xff095bc5),
                            size: 22,
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
                          'Realizar reporte',
                          'Comparte lo que ves',
                          'megaphone-white',
                          const [Color(0xffff645f), Color(0xfffb274f)],
                          onReport,
                          large: true,
                          foreground: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: tile(
                          'Mapa de reportes',
                          'Consulta en tu zona',
                          'map-white',
                          const [Color(0xff26b6ed), Color(0xff1769ea)],
                          onMap,
                          large: true,
                          foreground: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: tile(
                          'Mis reportes',
                          'Ver seguimiento',
                          'reports',
                          const [Color(0xffc8f8e7), Color(0xffaff0dc)],
                          onReports,
                          foreground: const Color(0xff00785c),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: tile(
                          'Alertas',
                          'De tu comunidad',
                          'bell',
                          const [Color(0xffeee7ff), Color(0xffddd0fb)],
                          onNotifications,
                          foreground: const Color(0xff6534cf),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: tile(
                          'Emergencias',
                          'Llama o envía SOS',
                          'emergency',
                          const [Color(0xfffff4c6), Color(0xffffe8a4)],
                          onHelp,
                          foreground: const Color(0xffa65b00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
