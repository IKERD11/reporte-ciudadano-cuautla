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
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(25, 43, 25, 20),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back,
                size: 29,
                color: Color(0xff0b2d73),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xff0b2d73),
                fontSize: title == 'Alertas comunitarias'
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
          SizedBox(width: 42, height: 42, child: action),
        ],
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
  });
  final String label;
  final VoidCallback? onPressed;
  final bool arrow;
  final bool auth;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .5 : 1,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
            constraints: BoxConstraints(minHeight: auth ? 70 : 58),
            child: Padding(
              padding: auth
                  ? const EdgeInsets.fromLTRB(42, 10, 10, 10)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                    if (auth)
                      const CircleAvatar(
                        radius: 23,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Color(0xff1268e4),
                          size: 22,
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 25,
                      ),
                  ],
                ],
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
  if (n.contains('animal')) {
    return ('paw', const Color(0xffe3e5ff));
  }
  return ('more', const Color(0xffe2f0fb));
}

class DesignCard extends StatelessWidget {
  const DesignCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
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
