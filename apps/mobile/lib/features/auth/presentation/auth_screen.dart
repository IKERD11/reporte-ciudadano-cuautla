import 'welcome_screen.dart';
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
      obscureText: secret && obscure,
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
        prefixIcon: Icon(
          secret
              ? Icons.lock_outline
              : c == email
              ? Icons.person_outline
              : c == phone
              ? Icons.phone_outlined
              : Icons.badge_outlined,
          size: 20,
        ),
        counterText: '',
        suffixIcon: secret && c == password
            ? IconButton(
                tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
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
  }) => FilledButton(
    onPressed: auth.busy
        ? null
        : () async {
            if (validate && !(form.currentState?.validate() ?? false)) return;
            final task = action();
            password.clear();
            repeat.clear();
            await task;
          },
    child: Text(title),
  );
  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(subtitle, style: const TextStyle(height: 1.5)),
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
            'Crea una nueva contraseña',
            'Al guardarla, cerraremos las sesiones y podrás entrar de nuevo.',
          ),
          field('Nueva contraseña', password, secret: true),
          field('Repite la contraseña', repeat, secret: true),
          button('Guardar contraseña', () => auth.savePassword(password.text)),
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
              backgroundColor: Color(0xff352557),
              child: Icon(Icons.person, size: 56, color: navy),
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
          if (forgot || register)
            heading(
              forgot
                  ? 'Recupera tu acceso'
                  : register
                  ? 'Crea tu cuenta'
                  : 'Bienvenido a tu comunidad',
              forgot
                  ? 'Te enviaremos un enlace para elegir una nueva contraseña.'
                  : register
                  ? 'Tu participación comienza con una cuenta segura.'
                  : 'Inicia sesión para preparar tu perfil ciudadano.',
            ),
          field('Correo electrónico', email, max: 254),
          if (!forgot) field('Contraseña', password, secret: true),
          if (register && !forgot)
            field('Repite la contraseña', repeat, secret: true),
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
          if (!register && !forgot)
            TextButton(
              onPressed: auth.busy
                  ? null
                  : () => setState(() {
                      forgot = true;
                      password.clear();
                      auth.clearMessage();
                    }),
              child: const Text('Olvidé mi contraseña'),
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
            child: Text(
              forgot || register
                  ? 'Ya tengo cuenta · Iniciar sesión'
                  : 'Soy nuevo · Crear una cuenta',
            ),
          ),
          const Divider(height: 32),
          if (!forgot && !register) ...[
            const Text(
              'Otros accesos · aún no habilitados',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: null, child: Text('Google')),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple),
                        SizedBox(width: 6),
                        Text('Apple'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
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
      return CitizenHome(
        auth: auth,
        repository: SupabaseReportRepository(Supabase.instance.client),
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
                  welcomed = false;
                  register = false;
                  forgot = false;
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.stage == AuthStage.signedOut) ...[
                    const CitizenBrand(),
                    const SizedBox(height: 16),
                    const Text(
                      'Inicia sesión o crea tu cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    if (!forgot)
                      Row(
                        children: [
                          Expanded(
                            child: register
                                ? TextButton(
                                    onPressed: () =>
                                        setState(() => register = false),
                                    child: const Text('Iniciar sesión'),
                                  )
                                : FilledButton(
                                    onPressed: () {},
                                    child: const Text('Iniciar sesión'),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: register
                                ? FilledButton(
                                    onPressed: () {},
                                    child: const Text('Registrarse'),
                                  )
                                : OutlinedButton(
                                    onPressed: () =>
                                        setState(() => register = true),
                                    child: const Text('Registrarse'),
                                  ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
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
