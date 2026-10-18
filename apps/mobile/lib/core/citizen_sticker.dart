import 'package:flutter/material.dart';

/// Original artwork exported from the approved Figma Make project.
class CitizenSticker extends StatelessWidget {
  const CitizenSticker(this.name, {super.key, this.size = 48});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/renewal/icons/3d/$name.webp',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}
