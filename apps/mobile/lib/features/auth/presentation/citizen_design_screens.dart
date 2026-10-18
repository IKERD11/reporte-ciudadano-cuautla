import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/citizen_design.dart';
import '../../../core/citizen_sticker.dart';

class CitizenContacts extends StatefulWidget {
  const CitizenContacts({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  State<CitizenContacts> createState() => _CitizenContactsState();
}

class _CitizenContactsState extends State<CitizenContacts> {
  bool search = false;
  String query = '';
  static const contacts = [
    ('Emergencias 911', 'Atención inmediata', 'contact-phone', '911'),
    ('Policía Municipal', 'Consultar contacto', 'contact-police', ''),
    ('Denuncia Anónima', 'Consultar contacto', 'contact-anonymous', '089'),
    ('Protección Civil', 'Consultar contacto', 'contact-protection', ''),
    ('Atención a la Mujer', 'Consultar contacto', 'contact-woman', ''),
    ('Atención Ciudadana', 'Consultar contacto', 'contact-citizen', ''),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4faff),
    appBar: DesignHeader(
      'Contactos útiles',
      onBack: widget.onBack,
      action: IconButton(
        tooltip: 'Buscar contacto',
        onPressed: () => setState(() => search = !search),
        icon: const Icon(Icons.search, size: 28),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        if (search) ...[
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              hintText: 'Buscar contacto...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final contact in contacts.where(
          (c) => c.$1.toLowerCase().contains(query.toLowerCase()),
        ))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: contact.$4 == '911'
                  ? const Color(0xffff4e61)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () async {
                  if (contact.$4.isNotEmpty) {
                    await launchUrl(Uri(scheme: 'tel', path: contact.$4));
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${contact.$1}: número pendiente de configuración municipal',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      CitizenSticker(contact.$3, size: 64),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.$1,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: contact.$4 == '911'
                                    ? Colors.white
                                    : const Color(0xff092b60),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              contact.$2,
                              style: TextStyle(
                                fontSize: 12,
                                color: contact.$4 == '911'
                                    ? Colors.white
                                    : const Color(0xff6480a3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: contact.$4 == '911'
                            ? Colors.white
                            : const Color(0xff1769ea),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (contacts
            .where((c) => c.$1.toLowerCase().contains(query.toLowerCase()))
            .isEmpty)
          const Center(child: Text('No encontramos ese contacto.')),
      ],
    ),
  );
}

class CitizenProfileDesign extends StatelessWidget {
  const CitizenProfileDesign({
    super.key,
    required this.name,
    required this.email,
    required this.onReports,
    required this.onLocation,
    required this.onPrivacy,
    required this.onHelp,
    required this.onLogout,
    required this.notifications,
    required this.onNotificationsChanged,
  });
  final String name, email;
  final bool notifications;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onReports, onLocation, onPrivacy, onHelp, onLogout;
  Widget row(
    String label,
    Widget icon, {
    VoidCallback? onTap,
    Widget? trailing,
    bool last = false,
  }) => Container(
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xffe5edf4))),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 53),
          child: Row(
            children: [
              SizedBox(width: 43, height: 43, child: Center(child: icon)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: last
                        ? const Color(0xffff304a)
                        : const Color(0xff092b60),
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else if (!last)
                const Icon(
                  Icons.chevron_right,
                  size: 21,
                  color: Color(0xff55789f),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
    children: [
      DesignCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            Container(
              width: 91,
              height: 91,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xffc6efff), Color(0xff88d7f7)],
                ),
              ),
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: Transform.scale(
                  scale: 1.14,
                  child: const CitizenSticker('user', size: 92),
                ),
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -.76,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff6480a3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      DesignCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          children: [
            row(
              'Mis reportes',
              const CitizenSticker('reports', size: 42),
              onTap: onReports,
            ),
            row(
              'Notificaciones',
              const Icon(
                Icons.notifications_none,
                size: 24,
                color: Color(0xff0d4fa7),
              ),
              trailing: Semantics(
                toggled: notifications,
                label: 'Activar o desactivar notificaciones',
                child: InkWell(
                  onTap: () => onNotificationsChanged(!notifications),
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    width: 57,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 57,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: notifications
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xff27aaf1),
                                    Color(0xff1767eb),
                                  ],
                                )
                              : null,
                          color: notifications ? null : const Color(0xffcbd8e4),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 3,
                              left: notifications ? 28 : 3,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x331f4366),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            row(
              'Ubicación',
              const CitizenSticker('pin', size: 42),
              onTap: onLocation,
            ),
            row(
              'Privacidad',
              const Icon(
                Icons.lock_outline,
                size: 24,
                color: Color(0xff0d4fa7),
              ),
              onTap: onPrivacy,
            ),
            row(
              'Ayuda y soporte',
              const Icon(
                Icons.help_outline,
                size: 25,
                color: Color(0xff0d4fa7),
              ),
              onTap: onHelp,
            ),
            row(
              'Cerrar sesión',
              const Icon(Icons.logout, size: 26, color: Color(0xffff304a)),
              onTap: onLogout,
              last: true,
            ),
          ],
        ),
      ),
    ],
  );
}
