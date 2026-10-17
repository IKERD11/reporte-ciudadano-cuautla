import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'report_map.dart';
import 'report_repository.dart';

Uint8List compressReportPhoto(Uint8List bytes) {
  try {
    return _compressReportPhoto(bytes);
  } catch (_) {
    throw Exception(
      'No se pudo preparar la imagen. Usa una foto válida de hasta 8 MB y 24 megapíxeles.',
    );
  }
}

Uint8List _compressReportPhoto(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null || info.width * info.height > 24000000) {
    throw Exception('Imagen demasiado grande o no compatible.');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('No se pudo abrir la imagen.');
  final oriented = img.bakeOrientation(decoded);
  final scaled = img.copyResize(
    oriented,
    width: oriented.width >= oriented.height ? 1280 : null,
    height: oriented.height > oriented.width ? 1280 : null,
  );
  final clean = img.Image(width: scaled.width, height: scaled.height);
  img.compositeImage(clean, scaled);
  final out = img.encodeJpg(clean, quality: 70);
  if (out.length > 700000) {
    throw Exception('La foto es demasiado pesada. Elige otra.');
  }
  return out;
}

class ReportWizard extends StatefulWidget {
  const ReportWizard({
    super.key,
    required this.categories,
    required this.repository,
    required this.onCreated,
    required this.onCancel,
  });
  final List<Map<String, dynamic>> categories;
  final ReportRepository repository;
  final ValueChanged<String> onCreated;
  final VoidCallback onCancel;
  @override
  State<ReportWizard> createState() => _ReportWizardState();
}

class _ReportWizardState extends State<ReportWizard> {
  final description = TextEditingController(),
      address = TextEditingController();
  final form = GlobalKey<FormState>();
  final key = reportRequestKey();
  Map<String, dynamic>? category;
  String? subcategory, error, capturedAt;
  final Map<String, dynamic> extra = {};
  final List<Uint8List> photos = [];
  LatLng? point;
  double? accuracy;
  int step = 0;
  bool busy = false, accepted = false, locating = false;
  int locationRequest = 0;
  bool searching = false;
  int searchRequest = 0;
  List<Map<String, dynamic>> places = [];
  Map<String, dynamic>? frozen;
  @override
  void dispose() {
    for (final c in [description, address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void selectPoint(LatLng p, {double? gps}) {
    searchRequest++;
    locationRequest++;
    setState(() {
      searching = false;
      places = [];
      point = p;
      error = null;
      locating = false;
      accuracy = gps;
      capturedAt = DateTime.now().toUtc().toIso8601String();
    });
  }

  Future<void> searchAddress() async {
    final query = address.text.trim();
    if (query.length < 5 || query.length > 200) {
      setState(
        () => error =
            'Escribe una dirección pública de 5 a 200 caracteres para buscar.',
      );
      return;
    }
    final current = ++searchRequest;
    locationRequest++;
    setState(() {
      searching = true;
      locating = false;
      error = null;
      places = [];
    });
    try {
      final result = await widget.repository
          .call('geocode', {'query': query})
          .timeout(const Duration(seconds: 20));
      if (!mounted || current != searchRequest) return;
      setState(() {
        places = (result['results'] as List)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
        if (places.isEmpty) {
          error =
              'No encontramos esa dirección. Añade la colonia o marca el lugar en el mapa.';
        }
      });
    } catch (_) {
      if (mounted && current == searchRequest) {
        setState(
          () => error =
              'La búsqueda no está disponible ahora. Intenta más tarde o marca el lugar en el mapa.',
        );
      }
    } finally {
      if (mounted && current == searchRequest) {
        setState(() => searching = false);
      }
    }
  }

  Future<void> locate() async {
    searchRequest++;
    final request = locationRequest + 1;
    setState(() {
      searching = false;
      places = [];
      locating = true;
      error = null;
    });
    try {
      await gps();
    } catch (e) {
      if (mounted && locationRequest == request) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted && locationRequest == request) {
        setState(() => locating = false);
      }
    }
  }

  Future<void> gps() async {
    final request = ++locationRequest;
    try {
      if (!kIsWeb) {
        if (!await Geolocator.isLocationServiceEnabled().timeout(
          const Duration(seconds: 10),
        )) {
          throw Exception(
            'Activa la ubicación del dispositivo o escribe la dirección.',
          );
        }
        var permission = await Geolocator.checkPermission().timeout(
          const Duration(seconds: 10),
        );
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission().timeout(
            const Duration(seconds: 60),
          );
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception(
            'Permite el acceso a tu ubicación o escribe la dirección del incidente.',
          );
        }
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      ).timeout(const Duration(seconds: 20));
      if (mounted && request == locationRequest) {
        selectPoint(LatLng(p.latitude, p.longitude), gps: p.accuracy);
      }
    } on PermissionDeniedException {
      throw Exception(
        'Permite el acceso a tu ubicación en el navegador o escribe la dirección.',
      );
    } on TimeoutException {
      throw Exception(
        'El navegador no respondió. Revisa el permiso de ubicación del sitio y del dispositivo, o marca el lugar en el mapa.',
      );
    } on MissingPluginException {
      throw Exception(
        'La ubicación no está disponible. Recarga la app o escribe la dirección.',
      );
    } on LocationServiceDisabledException {
      throw Exception(
        'Activa la ubicación del dispositivo o escribe la dirección.',
      );
    } on PositionUpdateException {
      throw Exception(
        'No pudimos localizarte. Intenta de nuevo o escribe la dirección.',
      );
    }
  }

  Widget sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff12122e),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xff30274e)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xff302054),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xffc49aff), size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xffb1add0),
          ),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );

  Widget photoAction(
    IconData icon,
    String label,
    ImageSource source,
  ) => OutlinedButton(
    onPressed: () => run(() => pick(source)),
    style: OutlinedButton.styleFrom(
      backgroundColor: const Color(0xff20173e),
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    child: Column(
      children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(label)],
    ),
  );

  Future<void> pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    if (file == null) return;
    if (await file.length() > 8000000) {
      throw Exception('El archivo excede 8 MB.');
    }
    final bytes = await compute(compressReportPhoto, await file.readAsBytes());
    if (mounted) setState(() => photos.add(bytes));
  }

  bool validate() {
    if (!(form.currentState?.validate() ?? true)) return false;
    String? issue;
    if (step == 0 && category == null) issue = 'Selecciona una categoría.';
    if (step == 1 &&
        category?['requires_location'] == true &&
        point == null &&
        address.text.trim().length < 10) {
      issue =
          'Escribe una dirección de al menos 10 caracteres o usa tu ubicación.';
    }
    if (step == 2 && category?['requires_photo'] == true && photos.isEmpty) {
      issue = 'Esta categoría requiere al menos una foto.';
    }
    if (issue != null) {
      setState(() => error = issue);
      return false;
    }
    return true;
  }

  List<Widget> fields() {
    final schema = category?['schema'] as Map? ?? {};
    final properties = schema['properties'] as Map? ?? {};
    final requiredFields = schema['required'] as List? ?? [];
    return properties.entries.map<Widget>((entry) {
      final name = entry.key.toString(), spec = entry.value as Map;
      final label =
          '${spec['title'] ?? name}${requiredFields.contains(name) ? ' *' : ''}';
      if (spec['type'] == 'boolean') {
        return CheckboxListTile(
          title: Text(label),
          value: extra[name] == true,
          onChanged: (v) => setState(() => extra[name] = v ?? false),
        );
      }
      if (spec['enum'] is List) {
        return DropdownButtonFormField<String>(
          initialValue: extra[name] as String?,
          decoration: InputDecoration(labelText: label),
          items: (spec['enum'] as List)
              .map(
                (v) => DropdownMenuItem(
                  value: v.toString(),
                  child: Text(v.toString()),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => extra[name] = v),
          validator: (v) => requiredFields.contains(name) && v == null
              ? 'Selecciona una opción.'
              : null,
        );
      }
      final numeric = ['integer', 'number'].contains(spec['type']);
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          key: ValueKey(name),
          initialValue: extra[name]?.toString(),
          decoration: InputDecoration(labelText: label),
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          maxLength: numeric ? null : (spec['maxLength'] as int? ?? 200),
          onChanged: (v) {
            if (v.isEmpty) {
              extra.remove(name);
            } else {
              extra[name] = numeric
                  ? (spec['type'] == 'integer'
                        ? int.tryParse(v)
                        : double.tryParse(v))
                  : v;
            }
          },
          validator: (v) {
            if ((v ?? '').isEmpty) {
              return requiredFields.contains(name)
                  ? 'Completa este campo.'
                  : null;
            }
            if (numeric) {
              final n = num.tryParse(v!);
              if (n == null ||
                  !n.isFinite ||
                  (spec['type'] == 'integer' && n != n.roundToDouble()) ||
                  (spec['minimum'] != null && n < spec['minimum']) ||
                  (spec['maximum'] != null && n > spec['maximum'])) {
                return 'Número fuera del rango permitido.';
              }
            }
            return null;
          },
        ),
      );
    }).toList();
  }

  Future<void> submit() async {
    if (!accepted) throw Exception('Acepta las condiciones del piloto.');
    frozen ??= reportSubmission(key, {
      'category_id': category!['id'],
      'subcategory_id': subcategory,
      'description': description.text.trim(),
      'address': address.text.trim(),
      'latitude': point?.latitude,
      'longitude': point?.longitude,
      'gps_accuracy': accuracy,
      'captured_at': capturedAt,
      'additional_data': Map.of(extra),
      'consent': true,
    }, List.of(photos));
    final result = await widget.repository.call('submit', frozen!);
    if (mounted) widget.onCreated(result['id'] as String);
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Categoría', 'Ubicación', 'Detalles', 'Confirmación'];
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paso ${step + 1} de 4 · ${titles[step]}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: i == 0
                                  ? Colors.transparent
                                  : const Color(0xff453462),
                            ),
                          ),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: i <= step
                                ? const Color(0xff982aff)
                                : const Color(0xff211b3b),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: i <= step
                                    ? Colors.white
                                    : const Color(0xffbbb0d7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: i == 3
                                  ? Colors.transparent
                                  : const Color(0xff453462),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        const ['Tipo', 'Ubicación', 'Detalles', 'Confirmar'][i],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          AbsorbPointer(
            absorbing: busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (step == 0) ...[
                  const Text(
                    'Selecciona el tipo de reporte',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < widget.categories.length; i++)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const [
                            Color(0xfff59e35),
                            Color(0xff2198ee),
                            Color(0xff3d9d51),
                            Color(0xff8e50e7),
                          ][i % 4],
                          child: Icon(
                            const [
                              Icons.construction,
                              Icons.lightbulb_outline,
                              Icons.eco_outlined,
                              Icons.category_outlined,
                            ][i % 4],
                            color: const Color(0xff211b3b),
                          ),
                        ),
                        title: Text(
                          widget.categories[i]['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          widget.categories[i]['requires_photo'] == true
                              ? 'Ubicación y fotografía'
                              : 'Ubicación y descripción',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          category?['id'] == widget.categories[i]['id']
                              ? Icons.check_circle
                              : Icons.chevron_right,
                        ),
                        selected: category?['id'] == widget.categories[i]['id'],
                        onTap: () => setState(() {
                          category = widget.categories[i];
                          subcategory = null;
                          extra.clear();
                        }),
                      ),
                    ),
                  if (category != null) ...[
                    const SizedBox(height: 16),
                    Text(category!['description'] as String? ?? ''),
                    if ((category!['subcategories'] as List).isNotEmpty)
                      DropdownButtonFormField<String>(
                        key: ValueKey(category!['id']),
                        decoration: const InputDecoration(
                          labelText: 'Subcategoría (opcional)',
                        ),
                        items: (category!['subcategories'] as List)
                            .map(
                              (s) => DropdownMenuItem(
                                value: s['id'] as String,
                                child: Text(s['name'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => subcategory = v,
                      ),
                  ],
                ],
                if (step == 1) ...[
                  OutlinedButton.icon(
                    onPressed: locating ? null : locate,
                    icon: locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 19),
                    label: Text(
                      locating ? 'Buscando ubicación…' : 'Usar mi ubicación',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: address,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14),
                    keyboardType: TextInputType.streetAddress,
                    onChanged: (_) => setState(() {
                      searchRequest++;
                      searching = false;
                      places = [];
                    }),
                    decoration: const InputDecoration(
                      labelText: 'Dirección del incidente',
                      hintText:
                          'Calle, número, colonia y referencia en Cuautla',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      counterText: '',
                      labelStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: searching || locating ? null : searchAddress,
                    icon: const Icon(Icons.search, size: 18),
                    label: Text(
                      searching
                          ? 'Buscando dirección…'
                          : 'Buscar dirección en el mapa',
                    ),
                  ),
                  const Text(
                    'Se enviará la dirección pública a OpenStreetMap. No incluyas nombres ni datos personales.',
                    style: TextStyle(fontSize: 12),
                  ),
                  for (final place in places)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          place['address'] as String,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text(
                          'Seleccionar y verificar en el mapa',
                        ),
                        onTap: () {
                          address.text = place['address'] as String;
                          selectPoint(
                            LatLng(
                              (place['latitude'] as num).toDouble(),
                              (place['longitude'] as num).toDouble(),
                            ),
                          );
                        },
                      ),
                    ),
                  const Text(
                    'Búsqueda: © OpenStreetMap contributors · ODbL',
                    style: TextStyle(fontSize: 11),
                  ),
                  if (point != null) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(
                        accuracy != null
                            ? 'Ubicación del dispositivo seleccionada'
                            : 'Ubicación seleccionada en el mapa',
                      ),
                      subtitle: Text(
                        accuracy != null
                            ? 'Precisión aproximada: ±${accuracy!.round()} m'
                            : 'Puedes añadir una dirección como referencia.',
                      ),
                      trailing: IconButton(
                        tooltip: 'Quitar ubicación',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          point = null;
                          accuracy = null;
                          capturedAt = null;
                        }),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ReportMap(point: point, onSelected: selectPoint, height: 230),
                  const SizedBox(height: 10),
                  Text(
                    point == null
                        ? 'Toca el mapa para marcar el lugar del incidente.'
                        : 'Toca el mapa para ajustar el marcador.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (step == 2) ...[
                  sectionCard(
                    icon: Icons.edit_note_rounded,
                    title: '¿Qué está pasando?',
                    subtitle:
                        'Cuéntanos lo necesario para entender el incidente.',
                    children: [
                      TextFormField(
                        controller: description,
                        minLines: 4,
                        maxLines: 8,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          labelText: 'Describe el problema',
                          alignLabelWithHint: true,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText:
                              'Por ejemplo: la luminaria no enciende desde ayer, frente al parque.',
                          contentPadding: EdgeInsets.all(18),
                        ),
                        validator: (v) => (v ?? '').trim().length < 10
                            ? 'Escribe al menos 10 caracteres.'
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  sectionCard(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'Fotos del incidente',
                    subtitle:
                        '${photos.length} de 3 fotos · ${category?['requires_photo'] == true ? 'Requeridas' : 'Opcionales'}',
                    children: [
                      if (photos.isNotEmpty) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < photos.length; i++)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      photos[i],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton.filled(
                                      tooltip: 'Quitar foto ${i + 1}',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          setState(() => photos.removeAt(i)),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (photos.length < 3)
                        Row(
                          children: [
                            Expanded(
                              child: photoAction(
                                Icons.camera_alt_outlined,
                                'Cámara',
                                ImageSource.camera,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: photoAction(
                                Icons.photo_library_outlined,
                                'Galería',
                                ImageSource.gallery,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'Para este piloto, usa fotos de prueba sin rostros, placas ni datos personales.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xffb1add0),
                        ),
                      ),
                    ],
                  ),
                  if (fields().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    sectionCard(
                      icon: Icons.notes_rounded,
                      title: 'Información adicional',
                      subtitle:
                          'Añade referencias que ayuden a identificar el incidente.',
                      children: fields(),
                    ),
                  ],
                ],
                if (step == 3) ...[
                  Text(
                    category?['name'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(description.text),
                  Text(
                    point == null
                        ? 'Ubicación por dirección'
                        : 'Ubicación del reporte seleccionada',
                  ),
                  Text(address.text),
                  Text('${photos.length} fotografías privadas'),
                  for (final entry in extra.entries)
                    Text(
                      '${(category!['schema']['properties'][entry.key] as Map)['title'] ?? entry.key}: ${entry.value}',
                    ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: accepted,
                    onChanged: frozen != null
                        ? null
                        : (v) => setState(() => accepted = v ?? false),
                    title: const Text('Acepto enviar un reporte de prueba'),
                    subtitle: const Text(
                      'Se guardará en Supabase con mi cuenta, ubicación y fotos. No recibirá atención municipal ni acredita mi identidad. No incluiré información personal en el contenido.',
                    ),
                  ),
                  if (frozen != null)
                    const Text(
                      'El envío conserva los datos originales para evitar duplicados. Puedes reintentar o salir y consultar Mis reportes.',
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (busy)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                if (step > 0 && frozen == null)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 46),
                    ),
                    onPressed: () => setState(() {
                      step--;
                      error = null;
                    }),
                    child: const Text('Atrás'),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: step == 3
                        ? (accepted ? () => run(submit) : null)
                        : () {
                            if (validate()) {
                              setState(() {
                                step++;
                                error = null;
                              });
                            }
                          },
                    child: Text(
                      step == 3
                          ? (frozen == null
                                ? 'Enviar reporte'
                                : 'Reintentar envío')
                          : 'Continuar',
                    ),
                  ),
                ),
              ],
            ),
          TextButton(
            onPressed: busy ? null : widget.onCancel,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xffa9a3bf),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Cancelar reporte'),
          ),
        ],
      ),
    );
  }
}
