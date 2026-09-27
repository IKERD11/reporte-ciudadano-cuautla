import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;
  static const violet = Color(0xff982aff);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff081329),
    body: LayoutBuilder(
      builder: (context, viewport) {
        final width = viewport.maxWidth.clamp(0.0, 520.0);
        final scale = width / 448;
        final height = viewport.maxHeight < 760 * scale
            ? 760 * scale
            : viewport.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/branding/welcome-cuautla.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.65),
                  excludeFromSemantics: true,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00081329),
                        Color(0x15081329),
                        Color(0xed081329),
                        Color(0xff081329),
                      ],
                      stops: [0, .32, .62, 1],
                    ),
                  ),
                ),
                IgnorePointer(child: CustomPaint(painter: _WelcomeRibbons())),
                SafeArea(
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          37 * scale,
                          30 * scale,
                          37 * scale,
                          24 * scale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/branding/logo-violet.png',
                                  width: 70 * scale,
                                  height: 54 * scale,
                                  semanticLabel: 'Reporte Ciudadano',
                                ),
                                Container(
                                  height: 30 * scale,
                                  width: 1,
                                  color: Colors.white70,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'CUAUTLA, MORELOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11 * scale,
                                      letterSpacing: 2.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 43 * scale,
                                height: 4 * scale,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff7020ff),
                                      Color(0xffba64f6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            Text(
                              'Tu ciudad,',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 46 * scale,
                                height: 1.02,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.4,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xffbd81ff), Color(0xff8515ff)],
                              ).createShader(bounds),
                              child: Text(
                                'Tu voz.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 46 * scale,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.4,
                                ),
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            Text(
                              'Reporte Ciudadano',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3 * scale),
                            Text(
                              'Reporta lo que importa.',
                              style: TextStyle(
                                color: const Color(0xffb2bfdf),
                                fontSize: 16 * scale,
                              ),
                            ),
                            SizedBox(height: 17 * scale),
                            Row(
                              children: [
                                _benefit(
                                  Icons.edit_note_rounded,
                                  'Reporta',
                                  'en segundos',
                                  scale,
                                ),
                                _divider(scale),
                                _benefit(
                                  Icons.forum_rounded,
                                  'Informa',
                                  'a tu ciudad',
                                  scale,
                                ),
                                _divider(scale),
                                _benefit(
                                  Icons.bar_chart_rounded,
                                  'Contribuye',
                                  'al cambio',
                                  scale,
                                ),
                              ],
                            ),
                            SizedBox(height: 28 * scale),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18 * scale),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff7316ff),
                                    Color(0xffac40f8),
                                  ],
                                ),
                              ),
                              child: FilledButton(
                                onPressed: onContinue,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(0, 52 * scale),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      18 * scale,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Comenzar',
                                      style: TextStyle(
                                        fontSize: 19 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 14 * scale),
                                    Icon(Icons.arrow_forward, size: 25 * scale),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15 * scale),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Color(0xff73809e)),
                                ),
                                TextButton(
                                  onPressed: onContinue,
                                  child: Text(
                                    'Ya tengo una cuenta',
                                    style: TextStyle(
                                      color: const Color(0xffb9c6ea),
                                      fontSize: 14 * scale,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Color(0xff73809e)),
                                ),
                              ],
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
      },
    ),
  );
  Widget _divider(double s) =>
      Container(height: 55 * s, width: 1, color: const Color(0xff36496a));
  Widget _benefit(IconData icon, String title, String subtitle, double s) =>
      Expanded(
        child: Column(
          children: [
            Container(
              width: 51 * s,
              height: 51 * s,
              decoration: BoxDecoration(
                color: const Color(0xaa1e2945),
                borderRadius: BorderRadius.circular(13 * s),
                border: Border.all(color: const Color(0xff354061)),
              ),
              child: Icon(icon, color: violet, size: 32 * s),
            ),
            SizedBox(height: 5 * s),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12 * s,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: const Color(0xffc1cbe2),
                fontSize: 10 * s,
              ),
            ),
          ],
        ),
      );
}

class _WelcomeRibbons extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    void shape(List<Offset> points, List<Color> colors) {
      final path = Path()
        ..moveTo(points.first.dx * s.width, points.first.dy * s.height);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx * s.width, p.dy * s.height);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ).createShader(Offset.zero & s),
      );
    }

    shape(
      [
        const Offset(.76, 0),
        const Offset(.82, 0),
        const Offset(1, .19),
        const Offset(1, .26),
      ],
      [const Color(0x858347ff), const Color(0x106c22ee)],
    );
    shape(
      [const Offset(.82, 0), const Offset(1, 0), const Offset(1, .18)],
      [const Color(0x77372399), const Color(0x99252279)],
    );
    shape(
      [
        const Offset(1, .4),
        const Offset(1, .48),
        const Offset(.65, .75),
        const Offset(.57, .69),
      ],
      [const Color(0x109124ff), const Color(0x953f0bac)],
    );
    shape(
      [
        const Offset(0, .66),
        const Offset(.43, 1),
        const Offset(.29, 1),
        const Offset(0, .77),
      ],
      [const Color(0x00260972), const Color(0xaa4207ac)],
    );
    final line = Paint()
      ..color = const Color(0x957a1dff)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(0, s.height * .66),
      Offset(s.width * .43, s.height),
      line,
    );
    canvas.drawLine(
      Offset(s.width, s.height * .4),
      Offset(s.width * .61, s.height * .69),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
