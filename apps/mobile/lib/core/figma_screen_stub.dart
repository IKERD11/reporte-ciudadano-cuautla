import 'package:flutter/material.dart';

class FigmaScreen extends StatelessWidget {
  const FigmaScreen({super.key, required this.screen, required this.title});
  final String screen, title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(
      child: Text('Esta pantalla está disponible en la aplicación web.'),
    ),
  );
}
