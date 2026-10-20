import '../../../core/citizen_sticker.dart';
import 'welcome_screen.dart';
import '../../../core/citizen_design.dart';
import '../../notifications/notifications_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_config.dart';
import '../../../core/citizen_theme.dart';
import 'citizen_home.dart';
import '../../identity/identity_screen.dart';
import '../../identity/identity_repository.dart';
import '../../reports/report_repository.dart';
import '../../reports/report_address_search.dart';
import '../application/auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});
  final AuthController controller;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final repeat = TextEditingController();
  final first = TextEditingController();
  final last = TextEditingController();
  final phone = TextEditingController();
  bool register = false, forgot = false, editing = false, obscure = true;
  bool welcomed = false;
  bool repeatObscure = true;
  bool accepted = false;
  String? municipality;
  AuthStage? previous;
  AuthController get auth => widget.controller;
  @override
  void initState() {
    super.initState();
    auth.addListener(changed);
    unawaited(auth.start());
  }

  void changed() {
    if (previous != auth.stage) {
      if (auth.stage == AuthStage.profileSetup &&
          first.text.trim().contains(' ')) {
        final parts = first.text.trim().split(RegExp(r'\s+'));
        first.text = parts.first;
        last.text = parts.skip(1).join(' ');
      }
      password.clear();
      repeat.clear();
      editing = false;
      if (auth.stage == AuthStage.signedOut) {
        register = false;
        forgot = false;
        first.clear();
        last.clear();
        phone.clear();
        municipality = null;
      }
      previous = auth.stage;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    auth.removeListener(changed);
    for (final c in [email, password, repeat, first, last, phone]) {
      c.dispose();
    }
    auth.dispose();
    super.dispose();
  }

  Widget field(
    String label,
    TextEditingController c, {
    bool secret = false,
    bool optional = false,
    int max = 160,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: c,
      enabled: !auth.busy,
      obscureText: secret && (c == repeat ? repeatObscure : obscure),
      autofillHints: c == email
          ? const [AutofillHints.email]
          : secret
          ? [
              register || auth.stage == AuthStage.recovery
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ]
          : null,
      autocorrect: !secret,
      enableSuggestions: !secret,
      maxLength: secret ? null : max,
      keyboardType: c == email
          ? TextInputType.emailAddress
          : c == phone
          ? TextInputType.phone
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: c == email
            ? 'Tu correo electrónico'
            : secret
            ? 'Escribe tu contraseña'
            : null,
        prefixIcon: Icon(
          secret
              ? Icons.lock_outline
              : c == email
              ? Icons.mail_outline
              : c == phone
              ? Icons.phone_outlined
              : Icons.badge_outlined,
          size: auth.stage == AuthStage.signedOut && !register && !forgot
              ? 27
              : 21,
        ),
        counterText: '',
        suffixIcon: secret
            ? IconButton(
                tooltip: (c == repeat ? repeatObscure : obscure)
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () => setState(() {
                  if (c == repeat) {
                    repeatObscure = !repeatObscure;
                  } else {
                    obscure = !obscure;
                  }
                }),
                icon: Icon(
                  (c == repeat ? repeatObscure : obscure)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
      validator: (value) {
        final v = value ?? '';
        if (!optional && v.trim().isEmpty) return 'Completa este campo.';
        if (c == email &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
          return 'Escribe un correo válido.';
        }
        if (c == password &&
            (register || auth.stage == AuthStage.recovery) &&
            v.length < 12) {
          return 'Usa al menos 12 caracteres.';
        }
        if (c == repeat && v != password.text) {
          return 'Las contraseñas no coinciden.';
        }
        if (c == phone &&
            v.trim().isNotEmpty &&
            !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(v.trim())) {
          return 'Incluye el código de país, por ejemplo +525512345678.';
        }
        return null;
      },
    ),
  );
  Widget button(
    String title,
    Future<void> Function() action, {
    bool validate = true,
  }) => DesignButton(
    title,
    arrow: true,
    auth: auth.stage == AuthStage.signedOut || auth.stage == AuthStage.recovery,
    onPressed: auth.busy
        ? null
        : () async {
            if (validate && !(form.currentState?.validate() ?? false)) return;
            final task = action();
            password.clear();
            repeat.clear();
            await task;
          },
  );
  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment:
          auth.stage == AuthStage.signedOut || auth.stage == AuthStage.recovery
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign:
              auth.stage == AuthStage.signedOut ||
                  auth.stage == AuthStage.recovery
              ? TextAlign.center
              : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: register ? 24 : 32,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign:
              auth.stage == AuthStage.signedOut ||
                  auth.stage == AuthStage.recovery
              ? TextAlign.center
              : TextAlign.start,
          style: const TextStyle(
            height: 1.45,
            fontSize: 14,
            color: Color(0xff6a85a6),
          ),
        ),
      ],
    ),
  );
  List<Widget> content() {
    switch (auth.stage) {
      case AuthStage.loading:
        return [
          heading('Preparando tu acceso', 'Estamos verificando tu sesión.'),
          const Center(child: CircularProgressIndicator()),
        ];
      case AuthStage.unavailable:
        return [
          heading(
            'No pudimos abrir tu cuenta',
            'Puedes volver a intentarlo o cerrar la sesión.',
          ),
          button('Reintentar', auth.start, validate: false),
          TextButton(
            onPressed: auth.busy ? null : auth.logout,
            child: const Text('Cerrar sesión'),
          ),
        ];
      case AuthStage.confirmation:
        return [
          heading(
            'Revisa tu correo',
            'Abre el enlace de confirmación en el mismo dispositivo y navegador donde creaste la cuenta.',
          ),
          Text(
            auth.pendingEmail,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          button('Reenviar confirmación', auth.resend, validate: false),
          TextButton(
            onPressed: auth.busy ? null : auth.returnToLogin,
            child: const Text('Volver a iniciar sesión'),
          ),
        ];
      case AuthStage.recovery:
        return [
          heading(
            'Nueva contraseña',
            'Al guardarla, cerraremos las sesiones y podrás entrar de nuevo.',
          ),
          field('Nueva contraseña', password, secret: true),
          field('Repite la contraseña', repeat, secret: true),
          button(
            'Restablecer contraseña',
            () => auth.savePassword(password.text),
          ),
          TextButton(
            onPressed: auth.busy ? null : auth.logout,
            child: const Text('Cancelar y cerrar sesión'),
          ),
        ];
      case AuthStage.profileSetup:
        return [
          heading(
            'Completa tu perfil',
            'Tu correo está confirmado. Cuéntanos cómo te llamas para continuar.',
          ),
          field('Nombre(s)', first, max: 120),
          field('Apellidos', last),
          DropdownButtonFormField<String>(
            initialValue: municipality,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Municipio'),
            items: auth.municipalities
                .map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text('${m.name}, ${m.state}'),
                  ),
                )
                .toList(),
            onChanged: auth.busy
                ? null
                : (v) => setState(() => municipality = v),
            validator: (v) => v == null ? 'Selecciona tu municipio.' : null,
          ),
          const SizedBox(height: 20),
          if (auth.municipalities.isEmpty)
            const Text(
              'No hay municipios habilitados para el registro en este momento.',
            )
          else
            button(
              'Crear perfil ciudadano',
              () => auth.complete(municipality!, first.text, last.text),
            ),
          TextButton(
            onPressed: auth.busy ? null : auth.logout,
            child: const Text('Cerrar sesión'),
          ),
        ];
      case AuthStage.ready:
        final profile = auth.profile!;
        if (editing) {
          return [
            heading('Editar perfil', 'Actualiza tus datos de contacto.'),
            field('Nombre(s)', first, max: 120),
            field('Apellidos', last),
            field('Teléfono (opcional)', phone, optional: true, max: 16),
            button(
              'Guardar cambios',
              () => auth.edit(first.text, last.text, phone.text),
            ),
            TextButton(
              onPressed: auth.busy
                  ? null
                  : () => setState(() => editing = false),
              child: const Text('Volver a mi cuenta'),
            ),
          ];
        }
        void notice(String title, String text) => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        return [
          const Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xffedf5fc),
              child: CitizenSticker('user', size: 80),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${profile.firstName} ${profile.lastName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          Text(
            auth.account?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 28),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mis datos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() {
              first.text = profile.firstName;
              last.text = profile.lastName;
              phone.text = profile.phone ?? '';
              editing = true;
            }),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambiar contraseña'),
            trailing: const Icon(Icons.chevron_right),
            onTap: auth.busy ? null : () => auth.reset(auth.account!.email),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Verificación de identidad'),
            subtitle: Text(
              profile.identityStatus == 'PENDING'
                  ? 'Pendiente · INE real deshabilitada'
                  : profile.identityStatus,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: !AppConfig.isConfigured
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IdentityScreen(
                        repository: SupabaseIdentityRepository(
                          Supabase.instance.client,
                        ),
                        auth: auth,
                      ),
                    ),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            subtitle: const Text('Consulta los cambios de tus reportes'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(
                  repository: SupabaseReportRepository(
                    Supabase.instance.client,
                  ),
                  auth: auth,
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ayuda y soporte'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => notice(
              'Ayuda y soporte',
              'Crea un reporte de prueba, elige una categoría, marca su ubicación y agrega los detalles. Puedes consultar el folio y estado en Mis reportes. Esta plataforma no sustituye a los servicios de emergencia.',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y privacidad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => notice(
              'Condiciones del piloto',
              'Este entorno es exclusivamente de prueba, sin atención municipal real. No incluyas documentos ni datos personales en los reportes. El aviso institucional y los términos definitivos están pendientes de aprobación.',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () => notice(
              'Reporte Ciudadano',
              'Versión 1.0.0 · Piloto de Cuautla, Morelos. Una herramienta en desarrollo para la participación ciudadana.',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: auth.busy ? null : auth.logout,
          ),
        ];
      case AuthStage.signedOut:
        return [
          heading(
            forgot
                ? 'Recupera tu cuenta'
                : register
                ? 'Únete a Ciudad Segura'
                : '¡Qué gusto verte!',
            forgot
                ? 'Te enviaremos un enlace para elegir una nueva contraseña.'
                : register
                ? 'Tu participación comienza con una cuenta segura.'
                : 'Inicia sesión para seguir cuidando tu comunidad.',
          ),
          if (register && !forgot) field('Nombre completo', first, max: 120),
          field('Correo electrónico', email, max: 254),
          if (!forgot) field('Contraseña', password, secret: true),
          if (register && !forgot)
            field('Repite la contraseña', repeat, secret: true),
          if (register && !forgot) ...[
            const Text(
              'Mínimo 12 caracteres para proteger tu cuenta.',
              style: TextStyle(fontSize: 12),
            ),
            FormField<bool>(
              validator: (_) => accepted
                  ? null
                  : 'Acepta las condiciones del piloto para continuar.',
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: accepted,
                    onChanged: auth.busy
                        ? null
                        : (v) => setState(() {
                            accepted = v ?? false;
                            state.didChange(accepted);
                          }),
                    title: const Text(
                      'Acepto los términos y el aviso de privacidad del piloto',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Condiciones del piloto'),
                        content: const Text(
                          'Entorno de prueba, sin atención municipal real. Usa datos sintéticos y evita datos personales en reportes. Tus reportes y evidencias son privados. Las INE reales siguen deshabilitadas. Los términos institucionales definitivos están pendientes de aprobación.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('Leer términos y privacidad'),
                  ),
                  if (state.errorText != null)
                    Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (!register && !forgot)
            TextButton(
              onPressed: auth.busy
                  ? null
                  : () => setState(() {
                      forgot = true;
                      password.clear();
                      auth.clearMessage();
                    }),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          button(
            forgot
                ? 'Enviar enlace'
                : register
                ? 'Crear cuenta'
                : 'Iniciar sesión',
            () => forgot
                ? auth.reset(email.text)
                : register
                ? auth.register(email.text, password.text)
                : auth.login(email.text, password.text),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            forgot
                ? '¿Ya recuerdas tu contraseña?'
                : register
                ? '¿Ya tienes cuenta?'
                : '¿Aún no tienes cuenta?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xff6a85a6)),
          ),
          TextButton(
            onPressed: auth.busy
                ? null
                : () => setState(() {
                    if (forgot) {
                      forgot = false;
                    } else {
                      register = !register;
                    }
                    password.clear();
                    repeat.clear();
                    auth.clearMessage();
                  }),
            child: Text(forgot || register ? 'Inicia sesión' : 'Crear cuenta'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Piloto gratuito · El correo de confirmación está limitado a las direcciones autorizadas del equipo.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ];
    }
  }

  Widget profileForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...content(),
          if (auth.busy) const LinearProgressIndicator(),
          if (auth.message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(auth.message!),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (auth.stage == AuthStage.ready && AppConfig.isConfigured) {
      final reports = SupabaseReportRepository(Supabase.instance.client);
      return CitizenHome(
        auth: auth,
        repository: reports,
        geocode: ReportAddressSearch(reports).search,
        profileBuilder: profileForm,
      );
    }
    if (auth.stage == AuthStage.signedOut && !welcomed) {
      return WelcomeScreen(onContinue: () => setState(() => welcomed = true));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        leading: auth.stage == AuthStage.signedOut
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  if (register || forgot) {
                    register = false;
                    forgot = false;
                  } else {
                    welcomed = false;
                  }
                  password.clear();
                  repeat.clear();
                  auth.clearMessage();
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: ValueKey('auth-${auth.stage}-$register-$forgot'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.stage == AuthStage.signedOut ||
                      auth.stage == AuthStage.recovery) ...[
                    Image.asset(
                      'assets/renewal/auth/${auth.stage == AuthStage.recovery
                          ? 'reset'
                          : forgot
                          ? 'recovery'
                          : register
                          ? 'people'
                          : 'lock'}.webp',
                      height: register
                          ? 160
                          : forgot
                          ? 210
                          : 240,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ciudad Segura',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...content(),
                        if (auth.busy) const LinearProgressIndicator(),
                        if (auth.message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(auth.message!),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
