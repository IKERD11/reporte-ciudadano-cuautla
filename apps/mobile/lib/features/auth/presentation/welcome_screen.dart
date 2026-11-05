import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/citizen_design.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;
  double cityHeight(BoxConstraints viewport) {
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontFamily: 'Manrope'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: viewport.maxWidth - 50);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final title = measure(
      'Una ciudad más segura empieza contigo',
      const TextStyle(
        fontSize: 31,
        height: 1.12,
        letterSpacing: -1.55,
        fontWeight: FontWeight.w800,
      ),
    );
    final subtitle = measure(
      'Reporta incidentes, recibe alertas y cuida de tu comunidad.',
      const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700),
    );
    // The original grid gives the remaining vertical space to the city row.
    return math.max(
      290,
      viewport.maxHeight - 60 - 82 - title - 17 - subtitle - 24 - 65 - 17 - 18,
    );
  }

  @override
  Widget build(BuildContext context) => DesignScaffold(
    surface: DesignSurface.welcome,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 33, 25, 27),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 82,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/renewal/auth/logo.webp',
                          width: 113,
                          height: 78,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 5),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Ciudad Segura',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff092b60),
                                letterSpacing: -1.08,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: cityHeight(viewport),
                    child: OverflowBox(
                      maxWidth: (viewport.maxWidth - 50) * 1.28,
                      child: DesignDropShadow(
                        blur: 22,
                        offset: const Offset(0, 15),
                        color: const Color(0x21176890),
                        child: Image.asset(
                          'assets/renewal/auth/city.webp',
                          width: (viewport.maxWidth - 50) * 1.28,
                          height: 355,
                          fit: BoxFit.contain,
                          semanticLabel: 'Ciudad con parques y edificios',
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Una ciudad más segura empieza contigo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 31,
                      height: 1.12,
                      letterSpacing: -1.55,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff092b60),
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Reporta incidentes, recibe alertas y cuida de tu comunidad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff6783a4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DesignButton(
                    'Comenzar',
                    onPressed: onContinue,
                    arrow: true,
                    auth: true,
                    height: 65,
                  ),
                  const SizedBox(height: 17),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 17,
                        color: Color(0xff6380a3),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Juntos cuidamos nuestra comunidad',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff6380a3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
