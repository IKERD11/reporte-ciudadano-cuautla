import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('CitizenMapLibre.create')
external _MapHandle _create(
  web.HTMLElement element,
  JSObject options,
  JSObject handlers,
);
extension type _MapHandle(JSObject _) implements JSObject {
  external void update(JSObject options);
  external void dispose();
}

/// Each Flutter platform view owns exactly one map and releases it on unmount.
class MapLibreSurface extends StatefulWidget {
  const MapLibreSurface({
    super.key,
    required this.options,
    this.onSelected,
    this.onReportSelected,
  });
  final Map<String, dynamic> options;
  final void Function(double, double)? onSelected;
  final ValueChanged<String>? onReportSelected;
  @override
  State<MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<MapLibreSurface> {
  _MapHandle? handle;
  JSObject get options => widget.options.jsify()! as JSObject;
  void created(Object element) {
    if (!mounted) return;
    final host = element as web.HTMLElement;
    host.style.width = '100%';
    host.style.height = '100%';
    handle = _create(
      host,
      options,
      <String, JSFunction>{
            'onSelected': ((double latitude, double longitude) {
              if (mounted) widget.onSelected?.call(latitude, longitude);
            }).toJS,
            'onReportSelected': ((String id) {
              if (mounted) widget.onReportSelected?.call(id);
            }).toJS,
          }.jsify()!
          as JSObject,
    );
  }

  @override
  void didUpdateWidget(covariant MapLibreSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    handle?.update(options);
  }

  @override
  void dispose() {
    handle?.dispose();
    handle = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HtmlElementView.fromTagName(tagName: 'div', onElementCreated: created);
}
