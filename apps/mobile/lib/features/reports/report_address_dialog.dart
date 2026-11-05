import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/citizen_design.dart';
import '../../core/citizen_sticker.dart';
import '../../core/address_search.dart';

Future<Map<String, dynamic>?> showReportAddressDialog(
  BuildContext context,
  AddressGeocoder? geocode, {
  List<String>? initial,
  ValueChanged<List<String>>? onChanged,
}) => showGeneralDialog<Map<String, dynamic>>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Cerrar captura de dirección',
  barrierColor: Colors.transparent,
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 190),
  pageBuilder: (dialog, animation, _) => Stack(
    children: [
      Positioned.fill(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, .95, curve: Curves.easeOut),
          ),
          child: GestureDetector(
            onTap: () => Navigator.pop(dialog),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const ColoredBox(color: Color(0x6108234d)),
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: DesignPanelEntrance(
          animation: animation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Material(
                color: const Color(0xfff9fcff),
                borderRadius: BorderRadius.circular(27),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 394,
                    maxHeight: MediaQuery.sizeOf(dialog).height - 76,
                  ),
                  child: _AddressForm(
                    geocode: geocode,
                    initial: initial,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.geocode, this.initial, this.onChanged});
  final List<String>? initial;
  final ValueChanged<List<String>>? onChanged;
  final AddressGeocoder? geocode;
  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final form = GlobalKey<FormState>();
  late final fields = List.generate(
    5,
    (i) => TextEditingController(
      text: widget.initial?[i] ?? (i == 4 ? 'Cuautla' : ''),
    ),
  );
  bool busy = false;
  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final values = fields.map((f) => f.text.trim()).toList();
    final formatted = [
      '${values[0]} ${values[1]}'.trim(),
      'Col. ${values[2]}',
      'C.P. ${values[3]}',
      values[4],
      'Morelos',
    ].join(', ');
    Map<String, dynamic>? place;
    try {
      final results = await widget.geocode?.call(formatted);
      if (results != null && results.isNotEmpty) place = results.first;
    } catch (_) {
      /* Keep manually entered address without inventing coordinates. */
    }
    if (mounted) {
      Navigator.pop(context, {
        'address': formatted,
        'latitude': place?['latitude'],
        'longitude': place?['longitude'],
      });
    }
  }

  Widget field(int i) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 3, bottom: 7),
        child: Text(
          [
            'Calle',
            'Número',
            'Colonia o localidad',
            'Código postal',
            'Municipio o zona',
          ][i],
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xff42678f),
          ),
        ),
      ),
      TextFormField(
        key: ValueKey('manual-address-$i'),
        controller: fields[i],
        onChanged: (_) =>
            widget.onChanged?.call(fields.map((field) => field.text).toList()),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xff173967),
        ),
        enabled: !busy,
        autofocus: i == 0,
        keyboardType: i == 1 || i == 3
            ? TextInputType.number
            : TextInputType.streetAddress,
        inputFormatters: i == 3
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ]
            : null,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffd5e5ef)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xffd5e5ef)),
          ),
          hintText: [
            'Ej. Av. Insurgentes',
            '123',
            'Ej. Emiliano Galeana',
            '62740',
            'Cuautla',
          ][i],
        ),
        validator: (v) {
          if (i != 1 && (v ?? '').trim().isEmpty) return 'Completa este campo.';
          if (i == 3 && !RegExp(r'^\d{5}$').hasMatch(v ?? '')) {
            return 'Escribe cinco dígitos.';
          }
          return null;
        },
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CitizenSticker('pin', size: 50),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación del incidente',
                      style: TextStyle(fontSize: 11, color: Color(0xff6480a3)),
                    ),
                    Text(
                      'Escribe la dirección',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar captura de dirección',
                onPressed: () => Navigator.pop(context),
                icon: const CitizenIcon('close', size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          field(0),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: field(1)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: field(3)),
            ],
          ),
          const SizedBox(height: 12),
          field(2),
          const SizedBox(height: 12),
          field(4),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Ubicando...' : 'Usar dirección'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
