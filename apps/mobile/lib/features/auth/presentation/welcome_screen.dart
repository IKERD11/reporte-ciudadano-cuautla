import 'package:flutter/material.dart';
import '../../../core/citizen_design.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4faff),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/renewal/auth/logo.webp',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ciudad Segura',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff0b2d73),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Image.asset(
                  'assets/renewal/auth/city.webp',
                  height: 280,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ciudad con parques y edificios',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Una ciudad más segura empieza contigo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff0b2d73),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Reporta incidentes, recibe alertas y cuida de tu comunidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 30),
                DesignButton('Comenzar', onPressed: onContinue, arrow: true),
                TextButton(
                  onPressed: onContinue,
                  child: const Text('Ya tengo una cuenta'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Juntos cuidamos nuestra comunidad',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
