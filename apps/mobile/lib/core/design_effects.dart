export 'citizen_icons.dart';
import 'citizen_icons.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum DesignSurface {
  page,
  auth,
  welcome,
  activity,
  tracking,
  zone,
  shell,
  report,
  success,
  editProfile,
}

/// The layered gradients from the exported CSS, painted in the same order.
class DesignBackground extends StatelessWidget {
  const DesignBackground({
    super.key,
    required this.child,
    this.surface = DesignSurface.page,
  });
  final Widget child;
  final DesignSurface surface;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BackgroundPainter(surface), child: child);
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.surface);
  final DesignSurface surface;
  @override
  void paint(Canvas canvas, Size size) {
    final colors = switch (surface) {
      DesignSurface.editProfile => const [Color(0xfff8fcff), Color(0xfff8fcff)],
      DesignSurface.auth => const [Color(0xfff9fdff), Color(0xfff2fbff)],
      DesignSurface.welcome => const [
        Color(0xffeefaff),
        Color(0xfff9fdff),
        Color(0xffe9f7fb),
      ],
      DesignSurface.activity => const [
        Color(0xfff8fcff),
        Color(0xffedf8fd),
        Color(0xfff6fbfe),
      ],
      DesignSurface.tracking => const [
        Color(0xfff8fcff),
        Color(0xffedf8fd),
        Color(0xfff7fbfe),
      ],
      DesignSurface.zone => const [Color(0xfff9fcff), Color(0xfff1f9fd)],
      DesignSurface.report ||
      DesignSurface.success => const [Color(0xfffbfdff), Color(0xfffbfdff)],
      DesignSurface.shell => const [Color(0xffeaf7fc), Color(0xffeaf7fc)],
      DesignSurface.page => const [Color(0xfff4faff), Color(0xfff4faff)],
    };
    final rect = Offset.zero & size;
    final stops = colors.length == 3
        ? [
            0.0,
            surface == DesignSurface.welcome
                ? 0.56
                : surface == DesignSurface.activity
                ? 0.58
                : 0.62,
            1.0,
          ]
        : null;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          colors,
          stops,
        ),
    );
    void glow(double x, double y, double stop, Color color) {
      final center = Offset(size.width * x, size.height * y);
      final far = math.sqrt(
        math.pow(math.max(x, 1 - x) * size.width, 2) +
            math.pow(math.max(y, 1 - y) * size.height, 2),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(center, far * stop, [
            color,
            color.withValues(alpha: 0),
          ]),
      );
    }

    switch (surface) {
      case DesignSurface.editProfile:
        glow(.94, .12, .30, const Color(0x61d2e5ff));
        glow(.04, .78, .32, const Color(0x52c9f3f8));
      case DesignSurface.report:
        glow(1, 0, .35, const Color(0x3dc6edff));
      case DesignSurface.success:
        glow(.52, .19, .32, const Color(0x47c5f5ff));
      case DesignSurface.shell:
        glow(.90, .85, .30, const Color(0x384cd1a3));
        glow(.12, .08, .28, const Color(0x5273d8f7));
      case DesignSurface.welcome:
        glow(.08, .92, .28, const Color(0x1c2bbbe0));
        glow(.5, .34, .34, const Color(0x7a9cecff));
      case DesignSurface.auth:
        glow(.5, .2, .33, const Color(0x5cc8f5ff));
      case DesignSurface.activity:
        glow(.92, .08, .29, const Color(0x4db6e7ff));
      case DesignSurface.tracking:
        glow(.94, .07, .28, const Color(0x4db2e5ff));
      case DesignSurface.zone:
        glow(.95, .08, .28, const Color(0x45b7e7ff));
      case DesignSurface.page:
        glow(1, 0, .35, const Color(0x40c1e8ff));
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.surface != surface;
}

class DesignScaffold extends StatelessWidget {
  const DesignScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.surface = DesignSurface.page,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body, bottomNavigationBar, drawer;
  final Color? backgroundColor;
  final DesignSurface surface;
  @override
  Widget build(BuildContext context) => DesignBackground(
    surface: surface,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    ),
  );
}

/// CSS drop-shadow preserves the transparent silhouette of the original asset.
class DesignDropShadow extends StatelessWidget {
  const DesignDropShadow({
    super.key,
    required this.child,
    this.color = const Color(0x21176890),
    this.blur = 7,
    this.offset = const Offset(0, 5),
  });
  final Widget child;
  final Color color;
  final double blur;
  final Offset offset;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      Positioned.fill(
        child: ExcludeSemantics(
          child: Transform.translate(
            offset: offset,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                child: child,
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

/// Hover lift and press movement match the CSS transitions rather than a ripple.
class DesignInteraction extends StatefulWidget {
  const DesignInteraction({
    super.key,
    required this.child,
    this.lift = 2,
    this.duration = const Duration(milliseconds: 160),
    this.pressOffset = 0,
    this.hoverBrightness = 1,
    this.enabled = true,
  });
  final Widget child;
  final double lift, pressOffset, hoverBrightness;
  final bool enabled;
  final Duration duration;
  @override
  State<DesignInteraction> createState() => _DesignInteractionState();
}

class _DesignInteractionState extends State<DesignInteraction> {
  bool hover = false, pressed = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = widget.enabled),
    onExit: (_) => setState(() => hover = false),
    child: Listener(
      onPointerDown: (_) => setState(() => pressed = widget.enabled),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : widget.duration,
        curve: Curves.ease,
        transform: Matrix4.translationValues(
          0,
          widget.enabled && pressed && widget.pressOffset != 0
              ? widget.pressOffset
              : widget.enabled && hover
              ? -widget.lift
              : 0,
          0,
        ),
        child: widget.enabled && hover && widget.hoverBrightness != 1
            ? ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  widget.hoverBrightness,
                  0,
                  0,
                  0,
                  0,
                  0,
                  widget.hoverBrightness,
                  0,
                  0,
                  0,
                  0,
                  0,
                  widget.hoverBrightness,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: widget.child,
              )
            : widget.child,
      ),
    ),
  );
}

class DesignFilter extends StatelessWidget {
  const DesignFilter(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
    this.activity = false,
  });
  final String label;
  final bool selected, activity;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: DesignInteraction(
      lift: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(activity ? 18 : 16),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff22aff1), Color(0xff1769ed)],
                )
              : null,
          color: selected
              ? null
              : activity
              ? const Color(0xd1ffffff)
              : const Color(0xffedf5fc),
          border: activity && !selected
              ? Border.all(color: const Color(0xa6cfe5f3))
              : null,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x331769ed),
                    blurRadius: 15,
                    offset: Offset(0, 7),
                  ),
                ]
              : activity
              ? const [
                  BoxShadow(
                    color: Color(0x0d1e4b6f),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(activity ? 18 : 16),
            onTap: onTap,
            child: SizedBox(
              height: activity ? 48 : 43,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xff55779e),
                    fontSize: activity ? 11 : 10,
                    fontWeight: FontWeight.w700,
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

/// The two original reset-password eyes crossfade and spring independently.
class DesignPasswordEye extends StatelessWidget {
  const DesignPasswordEye({super.key, required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 24,
      height: 24,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: visible ? 1 : 0),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 220),
        curve: const Cubic(.34, 1.56, .64, 1),
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (final open in [false, true])
              AnimatedOpacity(
                key: ValueKey(open ? 'eye-open' : 'eye-closed'),
                opacity: visible == open ? 1 : 0,
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.ease,
                child: Transform.rotate(
                  angle: (open ? -(1 - value) : value) * math.pi / 15,
                  child: Transform.scale(
                    scale: open ? .55 + .45 * value : 1 - .45 * value,
                    child: CitizenIcon(
                      open ? 'eye' : 'eye-off',
                      size: 24,
                      strokeWidth: 2.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Animate only the address panel; the backdrop stays fixed, as in the CSS.
class DesignPanelEntrance extends StatelessWidget {
  const DesignPanelEntrance({
    super.key,
    required this.animation,
    required this.child,
  });
  final Animation<double> animation;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final value = MediaQuery.disableAnimationsOf(context)
          ? 1.0
          : Curves.easeOut.transform(animation.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - value)),
          child: child,
        ),
      );
    },
  );
}

void showDesignNotice(
  BuildContext context,
  String message, {
  double bottom = 24,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(20, 0, 20, bottom),
      content: DesignToast(message),
    ),
    snackBarAnimationStyle: AnimationStyle.noAnimation,
  );
}

class DesignToast extends StatelessWidget {
  const DesignToast(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - value)),
        child: child,
      ),
    ),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xff092b60),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3d082a54),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
    ),
  );
}

/// Navigation timings from the October 21 v2 export.
class DesignPageRoute<T> extends PageRouteBuilder<T> {
  DesignPageRoute({required WidgetBuilder builder, bool fade = false})
    : super(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, secondary, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curve = CurvedAnimation(
            parent: animation,
            curve: const Cubic(.22, 1, .36, 1),
          );
          final exit = CurvedAnimation(
            parent: secondary,
            curve: const Cubic(.22, 1, .36, 1),
          );
          return AnimatedBuilder(
            animation: Listenable.merge([curve, exit]),
            builder: (context, _) => Opacity(
              opacity: curve.value * (1 - exit.value),
              child: Transform.translate(
                offset: Offset(
                  fade ? 0 : 24 * (1 - curve.value) - 16 * exit.value,
                  0,
                ),
                child: child,
              ),
            ),
          );
        },
      );
}

class DesignScreenEntrance extends StatelessWidget {
  const DesignScreenEntrance({
    super.key,
    required this.child,
    this.fade = false,
    this.success = false,
    this.back = false,
  });
  final Widget child;
  final bool fade, success, back;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: success ? 340 : 260),
    curve: const Cubic(.22, 1, .36, 1),
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: success
            ? Offset(0, 14 * (1 - value))
            : Offset(fade ? 0 : (back ? -24 : 24) * (1 - value), 0),
        child: Transform.scale(
          scale: success ? 0.975 + 0.025 * value : 1,
          child: child,
        ),
      ),
    ),
    child: child,
  );
}
