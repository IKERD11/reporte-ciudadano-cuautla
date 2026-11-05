import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/citizen_design.dart';
import '../../../core/citizen_sticker.dart';
import '../../reports/report_wizard.dart' show compressReportPhoto;
import '../application/auth_controller.dart';

/// Photos stay private on this device, scoped to the authenticated account.
class ProfilePhotoStore {
  static const storage = FlutterSecureStorage();
  static Future<Uint8List?> read(String actor) async {
    try {
      final value = await storage.read(key: 'citizen.avatar.$actor');
      return value == null ? null : base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String actor, Uint8List bytes) =>
      storage.write(key: 'citizen.avatar.$actor', value: base64Encode(bytes));
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.auth,
    this.photo,
    required this.onPhotoSaved,
    this.accountOptions,
  });
  final AuthController auth;
  final WidgetBuilder? accountOptions;
  final Uint8List? photo;
  final ValueChanged<Uint8List> onPhotoSaved;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final name = TextEditingController(
    text: '${widget.auth.profile!.firstName} ${widget.auth.profile!.lastName}',
  );
  late final email = TextEditingController(text: widget.auth.account!.email);
  late final phone = TextEditingController(
    text: widget.auth.profile!.phone ?? '',
  );
  late Uint8List? photo = widget.photo;
  final form = GlobalKey<FormState>();
  bool busy = false, photoChanged = false;
  String? message;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> choosePhoto() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (await file.length() > 8000000) {
        throw Exception('Usa una foto de hasta 8 MB.');
      }
      final bytes = await compute(
        compressReportPhoto,
        await file.readAsBytes(),
      );
      if (mounted) {
        setState(() {
          photo = bytes;
          photoChanged = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'No se pudo abrir la foto. Usa una imagen de hasta 8 MB y 24 megapíxeles.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      message = null;
    });
    final auth = widget.auth;
    final original = auth.profile!;
    final full = name.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final suffix = ' ${original.lastName}';
    final boundary = full.endsWith(suffix)
        ? full.length - suffix.length
        : full.lastIndexOf(' ');
    try {
      await auth.edit(
        full.substring(0, boundary),
        full.substring(boundary + 1),
        phone.text,
      );
      if (auth.message != 'Perfil actualizado.') {
        if (mounted) {
          setState(
            () => message = auth.message ?? 'No se pudieron guardar los datos.',
          );
        }
        return;
      }
      if (photoChanged && photo != null) {
        await ProfilePhotoStore.write(original.id, photo!);
        widget.onPhotoSaved(photo!);
        photoChanged = false;
      }
      final changingEmail = email.text.trim() != auth.account!.email;
      if (changingEmail) {
        await auth.changeEmail(email.text.trim());
        if (auth.message !=
            'Confirma el cambio desde los enlaces enviados a tus correos.') {
          if (mounted) {
            setState(
              () => message =
                  'Nombre y teléfono guardados. ${auth.message ?? 'No se pudo solicitar el cambio de correo.'}',
            );
          }
          return;
        }
      }
      if (!mounted) return;
      showDesignNotice(
        context,
        changingEmail
            ? 'Datos guardados. Confirma el cambio en los enlaces enviados a tus correos.'
            : 'Perfil actualizado correctamente',
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Los datos de cuenta se guardaron, pero no pudimos guardar la foto en este dispositivo. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> password() async {
    setState(() {
      busy = true;
      message = null;
    });
    await widget.auth.reset(widget.auth.account!.email);
    if (mounted) {
      setState(() {
        busy = false;
        message = widget.auth.message;
      });
    }
  }

  Widget heading(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xff08295d),
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -.8,
      height: 1.15,
    ),
  );
  Widget field(
    String label,
    TextEditingController controller,
    String icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    Iterable<String>? autofill,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 73),
    padding: const EdgeInsets.fromLTRB(17, 9, 12, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffe3edf5)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0a1c4e75),
          blurRadius: 17,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff6582a7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextFormField(
                controller: controller,
                keyboardType: keyboard,
                validator: validator,
                autofillHints: autofill,
                style: const TextStyle(
                  color: Color(0xff092b60),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.only(top: 4, bottom: 4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: const Color(0xffedf7ff),
            borderRadius: BorderRadius.circular(15),
          ),
          child: CitizenIcon(icon, color: const Color(0xff176bea), size: 27),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => DesignScaffold(
    surface: DesignSurface.editProfile,
    appBar: DesignHeader(
      'Editar mi perfil',
      onBack: busy ? () {} : () => Navigator.maybePop(context),
    ),
    body: PopScope(
      canPop: !busy,
      child: Form(
        key: form,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width <= 360 ? 12 : 18,
            7,
            MediaQuery.sizeOf(context).width <= 360 ? 12 : 18,
            30,
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xffd5f5ff), Color(0xffe8e4ff)],
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width <= 360 ? 90 : 112,
                    height: MediaQuery.sizeOf(context).width <= 360 ? 90 : 112,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xffc6efff), Color(0xff88d7f7)],
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.zero,
                              child: ClipOval(
                                child: photo == null
                                    ? Center(
                                        child: OverflowBox(
                                          minWidth: 0,
                                          minHeight: 0,
                                          maxWidth: double.infinity,
                                          maxHeight: double.infinity,
                                          child: Transform.translate(
                                            offset: const Offset(0, 7),
                                            child: Transform.scale(
                                              scale: 1.14,
                                              child: CitizenSticker(
                                                'user',
                                                size:
                                                    MediaQuery.sizeOf(
                                                          context,
                                                        ).width <=
                                                        360
                                                    ? 86
                                                    : 104,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.memory(photo!, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -7,
                          bottom: 2,
                          child: DesignInteraction(
                            lift: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xff2caaf3),
                                    Color(0xff3155ee),
                                  ],
                                ),
                              ),
                              child: IconButton(
                                onPressed: busy ? null : choosePhoto,
                                tooltip: 'Cambiar foto de perfil',
                                icon: const CitizenIcon(
                                  'camera',
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: name,
                          builder: (context, value, child) => Text(
                            '¡Hola, ${value.text.trim().split(RegExp(r'\s+')).firstOrNull ?? ''}!',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff0a2d70),
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dale tu toque a tu perfil.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xff6480a6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            heading('Tus datos'),
            const SizedBox(height: 5),
            const Text(
              'Así podemos mantenerte informado.',
              style: TextStyle(
                color: Color(0xff6b86a8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AbsorbPointer(
              absorbing: busy,
              child: Column(
                children: [
                  field(
                    'Nombre completo',
                    name,
                    'user',
                    autofill: const [AutofillHints.name],
                    validator: (v) =>
                        v == null || v.trim().split(RegExp(r'\s+')).length < 2
                        ? 'Escribe nombre y apellidos.'
                        : v.length > 240
                        ? 'Máximo 240 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  field(
                    'Correo electrónico',
                    email,
                    'mail',
                    keyboard: TextInputType.emailAddress,
                    autofill: const [AutofillHints.email],
                    validator: (v) =>
                        RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Escribe un correo válido.',
                  ),
                  const SizedBox(height: 10),
                  field(
                    'Teléfono',
                    phone,
                    'phone',
                    keyboard: TextInputType.phone,
                    autofill: const [AutofillHints.telephoneNumber],
                    validator: (v) =>
                        v == null ||
                            v.trim().isEmpty ||
                            RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())
                        ? null
                        : 'Usa de 7 a 15 dígitos, con + opcional.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            heading('Acceso a tu cuenta'),
            const SizedBox(height: 11),
            DesignInteraction(
              lift: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(
                    colors: [Color(0xffe6efff), Color(0xffede4ff)],
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: busy ? null : password,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 82),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(9, 8, 16, 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 82,
                            child: CitizenSticker('profile-security', size: 67),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contraseña',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    letterSpacing: 0,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Actualiza tu contraseña.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff6a83a7),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const CircleAvatar(
                            radius: 19.5,
                            backgroundColor: Color(0xff258df5),
                            child: CitizenIcon(
                              'chevron',
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(message!, semanticsLabel: message),
              ),
            const SizedBox(height: 12),
            if (busy) const LinearProgressIndicator(),
            DesignButton(
              'Guardar cambios',
              check: true,
              onPressed: busy ? null : save,
            ),
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text(
                'Descartar cambios',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu foto se guarda solo en este dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff6b86a8), fontSize: 11),
            ),
            if (widget.accountOptions != null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => Navigator.of(context).push(
                        DesignPageRoute(
                          builder: (context) => DesignScaffold(
                            appBar: const DesignHeader('Mi cuenta'),
                            body: widget.accountOptions!(context),
                          ),
                        ),
                      ),
                child: const Text(
                  'Más opciones de mi cuenta',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
