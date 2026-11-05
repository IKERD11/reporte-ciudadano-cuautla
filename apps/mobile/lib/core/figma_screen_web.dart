import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class FigmaScreen extends StatelessWidget {
  const FigmaScreen({super.key, required this.screen, required this.title});
  final String screen, title;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4faff),
    appBar: AppBar(
      leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      title: const Text('Vista de diseño'),
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Flujo en integración · Datos de muestra',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: HtmlElementView.fromTagName(
            tagName: 'iframe',
            onElementCreated: (element) {
              final frame = element as web.HTMLIFrameElement;
              frame.title = title;
              frame.setAttribute('sandbox', 'allow-scripts allow-same-origin');
              frame.setAttribute('referrerpolicy', 'no-referrer');
              frame.style
                ..width = '100%'
                ..height = '100%'
                ..border = '0';
              frame.src = Uri.parse(web.document.baseURI)
                  .resolve('diseno/')
                  .replace(queryParameters: {'pantalla': screen})
                  .toString();
            },
          ),
        ),
      ],
    ),
  );
}
