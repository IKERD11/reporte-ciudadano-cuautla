import 'dart:async';
import '../../core/citizen_design.dart';
import '../../core/address_search.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../core/citizen_sticker.dart';
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
    this.geocode = searchAddressNotConnected,
  });
  final List<Map<String, dynamic>> categories;
  final ReportRepository repository;
  final ValueChanged<String> onCreated;
  final VoidCallback onCancel;
  final AddressGeocoder geocode;
  @override
  State<ReportWizard> createState() => _ReportWizardState();
}

class _ReportWizardState extends State<ReportWizard> {
  final description = TextEditingController(),
      address = TextEditingController();
  final form = GlobalKey<FormState>();
  final addressFocus = FocusNode();
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
  void initState() {
    super.initState();
    final initial = resolveCategory(choices.first);
    if (initial != null) {
      category = initial;
      selectedLabel = choices.first;
    }
  }

  @override
  void dispose() {
    for (final c in [description, address]) {
      c.dispose();
    }
    addressFocus.dispose();
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
      final result = await widget
          .geocode(query)
          .timeout(const Duration(seconds: 20));
      if (!mounted || current != searchRequest) return;
      setState(() {
        places = result;
        if (places.isEmpty) {
          error =
              'No encontramos esa dirección. Añade la colonia o marca el lugar en el mapa.';
        }
      });
    } on AddressSearchUnavailable catch (e) {
      if (mounted && current == searchRequest) {
        setState(() => error = e.toString());
      }
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

  Widget photoAction(IconData icon, String label, ImageSource source) =>
      Material(
        color: source == ImageSource.camera
            ? const Color(0xffe4f4fd)
            : const Color(0xffe8ebff),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => run(() => pick(source)),
          child: SizedBox(
            height: 82,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CitizenSticker(
                  source == ImageSource.camera ? 'camera' : 'gallery',
                  size: 43,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: source == ImageSource.camera
                        ? const Color(0xff0f67e8)
                        : const Color(0xff624cf0),
                  ),
                ),
              ],
            ),
          ),
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
    if (step == 1 && description.text.trim().length < 10) {
      issue = 'Escribe al menos 10 caracteres.';
    }
    if (step == 1 &&
        category?['requires_location'] == true &&
        point == null &&
        address.text.trim().length < 10) {
      issue =
          'Escribe una dirección de al menos 10 caracteres o usa tu ubicación.';
    }
    if (step == 1 && category?['requires_photo'] == true && photos.isEmpty) {
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

  static const choices = [
    'Robo / Asalto',
    'Accidente',
    'Vandalismo',
    'Violencia',
    'Alumbrado público',
    'Baches / Vía pública',
    'Maltrato animal',
    'Otro',
  ];
  static const categoryTextColors = [
    Color(0xff092b60),
    Color(0xff1485ed),
    Color(0xff8846ea),
    Color(0xff05aa7d),
    Color(0xff9e5500),
    Color(0xff07675e),
    Color(0xff4266ed),
    Color(0xff6a8dad),
  ];
  String? selectedLabel;
  Map<String, dynamic>? resolveCategory(String label) {
    final art = categoryArtwork(label).$1;
    for (final item in widget.categories) {
      final name = item['name'].toString().toLowerCase();
      if (art == 'more'
          ? ['otro', 'otros'].contains(name)
          : categoryArtwork(name).$1 == art) {
        return item;
      }
    }
    return null;
  }

  Widget heading(String text, {double size = 25}) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: const Color(0xff08295d),
      height: 1.14,
      letterSpacing: -1,
    ),
  );

  Widget progress() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: i == 0
                            ? Colors.transparent
                            : const Color(0xffe2edf7),
                      ),
                    ),
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: i < step
                          ? const Color(0xff05b77e)
                          : i == step
                          ? const Color(0xff5360fa)
                          : const Color(0xffedf5fb),
                      child: i < step
                          ? const Icon(Icons.check, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: i == step
                                    ? Colors.white
                                    : const Color(0xff0b376c),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Divider(
                        color: i == 2
                            ? Colors.transparent
                            : const Color(0xffe2edf7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  const ['Tipo', 'Detalles', 'Confirmar'][i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: i == step
                        ? const Color(0xff393bff)
                        : const Color(0xff718baa),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget locationFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading('Ubicación del incidente', size: 16),
      const SizedBox(height: 8),
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xffdce8f3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => addressFocus.requestFocus(),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  const CitizenSticker('pin', size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.text.isEmpty ? 'Centro, Cuautla' : address.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    size: 23,
                    color: Color(0xff182b88),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Stack(
        children: [
          ReportMap(
            point: point,
            onSelected: selectPoint,
            height: 137,
            controlTop: 48,
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: PointerInterceptor(
              child: Material(
                elevation: 4,
                shadowColor: const Color(0x2417426b),
                borderRadius: BorderRadius.circular(11),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 35,
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Dirección del incidente',
                          child: TextFormField(
                            key: const ValueKey('incident-address'),
                            focusNode: addressFocus,
                            controller: address,
                            maxLength: 200,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff173967),
                            ),
                            onChanged: (_) => setState(() {
                              searchRequest++;
                              searching = false;
                              places = [];
                            }),
                            decoration: const InputDecoration(
                              hintText: 'Buscar dirección',
                              counterText: '',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(56, 35),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: searching || locating ? null : searchAddress,
                        child: Text(
                          searching ? '...' : 'Buscar',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
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
      for (final place in places)
        Card(
          child: ListTile(
            title: Text(place['address'] as String),
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
      const SizedBox(height: 7),
      SizedBox(
        height: 40,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xffeef5fc),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          onPressed: locating ? null : locate,
          icon: const Icon(Icons.my_location, size: 23),
          label: Text(
            locating ? 'Buscando ubicación...' : 'Usar mi ubicación actual',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      if (point != null)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            accuracy != null
                ? 'Ubicación del dispositivo seleccionada'
                : 'Ubicación seleccionada en el mapa',
            style: const TextStyle(fontSize: 11),
          ),
          subtitle: accuracy != null
              ? Text('Precisión aproximada: ±${accuracy!.round()} m')
              : null,
          trailing: IconButton(
            tooltip: 'Quitar ubicación',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() {
              point = null;
              accuracy = null;
              capturedAt = null;
            }),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        progress(),
        SizedBox(height: step == 0 ? 24 : 21),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                heading('¿Qué tipo de incidente quieres reportar?'),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona la categoría que mejor describa la situación.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.3,
                    color: Color(0xff718aa9),
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 15),
                LayoutBuilder(
                  builder: (context, c) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < choices.length; i++)
                        SizedBox(
                          width:
                              (c.maxWidth - (i >= 6 ? 10 : 20)) /
                              (i >= 6 ? 2 : 3),
                          child: Semantics(
                            button: true,
                            selected: selectedLabel == choices[i],
                            child: Material(
                              color: categoryArtwork(choices[i]).$2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                                side: BorderSide(
                                  width: 2,
                                  color: selectedLabel == choices[i]
                                      ? const Color(0xffff4f5d)
                                      : Colors.transparent,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(21),
                                onTap: () {
                                  final match = resolveCategory(choices[i]);
                                  setState(() {
                                    if (match == null) {
                                      error =
                                          'Esta categoría aún no está habilitada en tu municipio.';
                                      return;
                                    }
                                    category = match;
                                    selectedLabel = choices[i];
                                    subcategory = null;
                                    extra.clear();
                                    error = null;
                                  });
                                },
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: i >= 6 ? 108 : 119,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                      horizontal: 6,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CitizenSticker(
                                          categoryArtwork(choices[i]).$1,
                                          size: 58,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          choices[i],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            letterSpacing: -.3,
                                            fontWeight: FontWeight.w800,
                                            color: categoryTextColors[i],
                                            height: 1.16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (step == 1) ...[
                heading('Cuéntanos más', size: 27),
                const SizedBox(height: 4),
                const Text(
                  'Agrega los detalles del incidente.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xff7a91ae),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  height: 106,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffdce8f3)),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Stack(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 20),
                          SizedBox(width: 11),
                          Text(
                            'Descripción del incidente',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 23,
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: TextFormField(
                          key: const ValueKey('incident-description'),
                          controller: description,
                          maxLength: 500,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Describe lo que ocurrió...',
                            counterText: '',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Text(
                          '${description.text.length}/500',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff738cad),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                locationFields(),
                const SizedBox(height: 13),
                heading(
                  'Agregar evidencia${category?['requires_photo'] == true ? ' (requerida)' : ' (opcional)'}',
                  size: 16,
                ),
                const SizedBox(height: 8),
                if (photos.length < 3)
                  Row(
                    children: [
                      Expanded(
                        child: photoAction(
                          Icons.camera_alt,
                          'Cámara',
                          ImageSource.camera,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: photoAction(
                          Icons.photo_library,
                          'Galería',
                          ImageSource.gallery,
                        ),
                      ),
                    ],
                  ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < photos.length; i++)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                photos[i],
                                width: 85,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton.filled(
                                tooltip: 'Quitar foto ${i + 1}',
                                onPressed: () =>
                                    setState(() => photos.removeAt(i)),
                                icon: const Icon(Icons.close, size: 14),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                if ((category?['subcategories'] as List? ?? []).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: subcategory,
                    decoration: const InputDecoration(
                      labelText: 'Subcategoría (opcional)',
                    ),
                    items: [
                      for (final sub in category!['subcategories'])
                        DropdownMenuItem(
                          value: sub['id'] as String,
                          child: Text(sub['name']),
                        ),
                    ],
                    onChanged: (v) => subcategory = v,
                  ),
                ],
                if (fields().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...fields(),
                ],
              ],
              if (step == 2) ...[
                heading('Confirma tu reporte'),
                const SizedBox(height: 16),
                DesignCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CitizenSticker(
                            categoryArtwork(
                              selectedLabel ?? category?['name'] ?? '',
                            ).$1,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: heading(
                              selectedLabel ?? category?['name'] ?? '',
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(description.text),
                      const SizedBox(height: 12),
                      Text(address.text),
                      Text('${photos.length} fotografías adjuntas'),
                      for (final entry in extra.entries)
                        Text(
                          '${(category!['schema']['properties'][entry.key] as Map)['title'] ?? entry.key}: ${entry.value}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: accepted,
                  onChanged: frozen != null
                      ? null
                      : (v) => setState(() => accepted = v ?? false),
                  title: const Text(
                    'Acepto enviar un reporte de prueba',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Se guardarán el reporte, la ubicación y las fotos con tu cuenta. El piloto no tiene atención municipal real.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (busy)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              if (step > 0 && frozen == null) ...[
                TextButton(
                  onPressed: () => setState(() {
                    step--;
                    error = null;
                  }),
                  child: const Text(
                    'Atrás',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DesignButton(
                  step == 2
                      ? (frozen == null ? 'Enviar reporte' : 'Reintentar envío')
                      : 'Siguiente',
                  arrow: step < 2,
                  onPressed: step == 2
                      ? (accepted ? () => run(submit) : null)
                      : () {
                          if (validate()) {
                            setState(() {
                              step++;
                              error = null;
                            });
                          }
                        },
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
