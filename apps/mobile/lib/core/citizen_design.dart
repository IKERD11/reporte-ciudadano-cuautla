export 'design_effects.dart';
import 'design_effects.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'citizen_sticker.dart';
import 'citizen_theme.dart';

class DesignHeader extends StatelessWidget implements PreferredSizeWidget {
  const DesignHeader(this.title, {super.key, this.onBack, this.action});
  final String title;
  final VoidCallback? onBack;
  final Widget? action;
  @override
  Size get preferredSize => const Size.fromHeight(105);
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: title == 'Mapa de incidentes'
        ? const Color(0xf7fbfdff)
        : Colors.transparent,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 43, 25, 20),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: title == 'Actividad'
                  ? const SizedBox()
                  : IconButton(
                      tooltip: 'Volver',
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const CitizenIcon(
                        'arrow-left',
                        size: 29,
                        color: Color(0xff0b2d73),
                        strokeWidth: 2.4,
                      ),
                    ),
            ),
            Expanded(
              child: SizedBox(
                height: 42,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xff0b2d73),
                        fontSize: title == 'Actividad'
                            ? 30
                            : title == 'Alertas comunitarias'
                            ? 20
                            : title == 'Mapa de incidentes'
                            ? 21
                            : 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -.88,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 42, height: 42, child: action),
          ],
        ),
      ),
    ),
  );
}

class DesignButton extends StatelessWidget {
  const DesignButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.arrow = false,
    this.auth = false,
    this.height,
    this.circleArrow = false,
    this.check = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool arrow;
  final bool auth;
  final bool circleArrow, check;
  final double? height;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .5 : 1,
    child: DesignInteraction(
      enabled: onPressed != null,
      pressOffset: auth || check ? 0 : 1,
      hoverBrightness: auth || check ? 1 : 1.04,
      duration: Duration.zero,
      lift: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: auth
              ? const [
                  BoxShadow(
                    color: Color(0x33176ce1),
                    blurRadius: 25,
                    offset: Offset(0, 12),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x33394ce6),
                    blurRadius: 27,
                    offset: Offset(0, 13),
                  ),
                  BoxShadow(
                    color: Color(0x211e99eb),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-.985, -.174),
                end: const Alignment(.985, .174),
                stops: auth ? const [0, .55, 1] : const [0, .52, 1],
                colors: auth
                    ? const [
                        Color(0xff20a9ed),
                        Color(0xff176cef),
                        Color(0xff16d6bd),
                      ]
                    : const [
                        Color(0xff20a9ed),
                        Color(0xff3156ee),
                        Color(0xff8e35ef),
                      ],
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: height ?? (auth ? 70 : 58),
                ),
                child: Padding(
                  padding: auth
                      ? const EdgeInsets.fromLTRB(42, 10, 10, 10)
                      : const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (check) ...[
                        const CircleAvatar(
                          radius: 18.5,
                          backgroundColor: Colors.white,
                          child: CitizenIcon(
                            'check',
                            color: Color(0xff2565e8),
                            size: 23,
                            strokeWidth: 2.8,
                          ),
                        ),
                        const SizedBox(width: 13),
                      ],
                      Flexible(
                        fit: auth ? FlexFit.tight : FlexFit.loose,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: auth ? 22 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (arrow) ...[
                        const SizedBox(width: 14),
                        if (auth || circleArrow)
                          const CircleAvatar(
                            radius: 23,
                            backgroundColor: Colors.white,
                            child: CitizenIcon(
                              'arrow-right',
                              color: Color(0xff1268e4),
                              size: 22,
                              strokeWidth: 2.5,
                            ),
                          )
                        else
                          const CitizenIcon(
                            'arrow-right',
                            color: Colors.white,
                            size: 25,
                            strokeWidth: 2.5,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DesignNavigation extends StatelessWidget {
  const DesignNavigation({
    super.key,
    required this.active,
    required this.onSelected,
    this.unread = 0,
  });
  final int active;
  final int unread;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 88,
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
          decoration: const BoxDecoration(
            color: Color(0xf2ffffff),
            border: Border(top: BorderSide(color: Color(0x0f134b75))),
            boxShadow: [
              BoxShadow(
                color: Color(0x140d406a),
                blurRadius: 28,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final item in [
                (0, 'home', 'Inicio'),
                (2, 'map', 'Mapa'),
                (4, 'plus', 'Reportar'),
                (5, 'activity', 'Actividad'),
                (3, 'user', 'Perfil'),
              ])
                Expanded(
                  child: Semantics(
                    selected: active == item.$1,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelected(item.$1),
                      child: SizedBox(
                        height: 68,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Badge(
                              isLabelVisible: item.$1 == 5 && unread > 0,
                              label: Text(unread > 99 ? '99+' : '$unread'),
                              child: CitizenSticker(
                                item.$2,
                                size: item.$1 == 4 ? 52 : 32,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.$3,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9,
                                height: 1,
                                letterSpacing: 0,
                                fontWeight: active == item.$1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: item.$1 == 4
                                    ? const Color(0xff13806b)
                                    : active == item.$1
                                    ? const Color(0xff0a65d8)
                                    : const Color(0xff6f88a5),
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
      ),
    ),
  );
}

(String, Color) categoryArtwork(String name) {
  final n = name.toLowerCase();
  if (n.contains('robo') || n.contains('asalto') || n.contains('seguridad')) {
    return ('robbery', const Color(0xfffff5f5));
  }
  if (n.contains('accidente') || n.contains('tránsito')) {
    return ('car', const Color(0xffe3f4fe));
  }
  if (n.contains('vandal')) {
    return ('spray', const Color(0xffeee6ff));
  }
  if (n.contains('violencia')) {
    return ('users', const Color(0xffdef8ef));
  }
  if (n.contains('alumbr') || n.contains('lumin') || n.contains('servicio')) {
    return ('bulb', const Color(0xfffff3d2));
  }
  if (n.contains('bache') || n.contains('vial')) {
    return ('cone', const Color(0xffd7f6f1));
  }
  if (n.contains('deceso')) {
    return ('mourning', const Color(0xffe6e8ee));
  }
  if (n.contains('animal')) {
    return ('paw', const Color(0xffe3e5ff));
  }
  return ('more', const Color(0xffe2f0fb));
}

LinearGradient categoryGradient(String name) {
  final colors = switch (categoryArtwork(name).$1) {
    'robbery' => const [Color(0xfffff5f5), Color(0xfffffafa)],
    'car' => const [Color(0xffeffaff), Color(0xffe3f4fe)],
    'spray' => const [Color(0xfff5efff), Color(0xffeee6ff)],
    'users' => const [Color(0xffe8fbf5), Color(0xffdef8ef)],
    'bulb' => const [Color(0xfffff9e8), Color(0xfffff3d2)],
    'cone' => const [Color(0xffe7fbf8), Color(0xffd7f6f1)],
    'paw' => const [Color(0xfff0f1ff), Color(0xffe3e5ff)],
    'mourning' => const [Color(0xfff2f3f6), Color(0xffe6e8ee)],
    _ => const [Color(0xffeff7fd), Color(0xffe2f0fb)],
  };
  return LinearGradient(
    begin: const Alignment(-.574, -.819),
    end: const Alignment(.574, .819),
    colors: colors,
  );
}

class DesignCard extends StatelessWidget {
  const DesignCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.color = Colors.white,
    this.border,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final BoxBorder? border;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: border,
      borderRadius: BorderRadius.circular(21),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0a194368),
          blurRadius: 20,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: navy),
      child: child,
    ),
  );
}
