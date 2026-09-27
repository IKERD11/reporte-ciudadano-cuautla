import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_repository.dart';

enum AuthStage {
  loading,
  signedOut,
  confirmation,
  profileSetup,
  ready,
  recovery,
  unavailable,
}

class AuthController extends ChangeNotifier {
  AuthController(this.repository);
  final AuthRepository repository;
  AuthStage stage = AuthStage.loading;
  Account? account;
  CitizenProfile? profile;
  List<Municipality> municipalities = [];
  String? message;
  String pendingEmail = '';
  bool busy = false;
  int _epoch = 0;
  bool _disposed = false;
  StreamSubscription<AuthSignal>? _subscription;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    _subscription ??= repository.changes.listen(
      (signal) {
        unawaited(_accept(signal));
      },
      onError: (Object error) {
        ++_epoch;
        profile = null;
        message = errorMessage(error);
        stage = AuthStage.unavailable;
        _emit();
      },
    );
    final epoch = _epoch;
    try {
      final user = await repository.validateSession().timeout(
        const Duration(seconds: 20),
      );
      if (epoch == _epoch) await _accept(AuthSignal(user));
    } catch (error) {
      if (epoch == _epoch) {
        message = errorMessage(error);
        stage = AuthStage.unavailable;
        _emit();
      }
    }
  }

  Future<void> _accept(AuthSignal signal) async {
    final epoch = ++_epoch;
    account = signal.account;
    profile = null;
    if (account == null) {
      stage = AuthStage.signedOut;
      municipalities = [];
      _emit();
      return;
    }
    if (signal.recovery || stage == AuthStage.recovery) {
      stage = AuthStage.recovery;
      _emit();
      return;
    }
    if (!account!.confirmed) {
      pendingEmail = account!.email;
      stage = AuthStage.confirmation;
      _emit();
      return;
    }
    stage = AuthStage.loading;
    _emit();
    try {
      final fetched = await repository.loadProfile().timeout(
        const Duration(seconds: 20),
      );
      if (epoch != _epoch || _disposed) return;
      if (fetched != null) {
        profile = fetched;
        stage = AuthStage.ready;
      } else {
        final available = await repository.registrationMunicipalities().timeout(
          const Duration(seconds: 20),
        );
        if (epoch != _epoch || _disposed) return;
        municipalities = available;
        stage = AuthStage.profileSetup;
      }
    } catch (error) {
      if (epoch == _epoch) {
        message = errorMessage(error);
        stage = AuthStage.unavailable;
      }
    }
    _emit();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (busy) return;
    busy = true;
    message = null;
    _emit();
    try {
      await operation().timeout(const Duration(seconds: 25));
    } catch (error) {
      message = errorMessage(error);
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> register(String email, String password) => _run(() async {
    pendingEmail = email.trim();
    final user = await repository.signUp(email, password);
    if (user != null) {
      await _accept(AuthSignal(user));
    } else {
      stage = AuthStage.confirmation;
      message =
          'Revisa tu correo para confirmar la cuenta. Si ya tienes una, puedes iniciar sesión.';
    }
  });
  Future<void> login(String email, String password) => _run(() async {
    try {
      await repository.signIn(email, password);
    } on AuthException catch (error) {
      if (error.code == 'email_not_confirmed') {
        pendingEmail = email.trim();
        stage = AuthStage.confirmation;
      }
      rethrow;
    }
  });
  Future<void> resend() => _run(() async {
    await repository.resendConfirmation(pendingEmail);
    message = 'Si la cuenta requiere confirmación, recibirás un nuevo enlace.';
  });
  Future<void> reset(String email) => _run(() async {
    await repository.requestPasswordReset(email);
    message =
        'Si el correo corresponde a una cuenta, recibirás las instrucciones para recuperar el acceso.';
  });
  Future<void> savePassword(String password) => _run(() async {
    await repository.updatePassword(password);
    await repository.signOut();
    stage = AuthStage.signedOut;
    account = null;
    profile = null;
    message = 'Contraseña actualizada. Inicia sesión de nuevo.';
  });
  Future<void> logout() => _run(() async {
    await repository.signOut();
    ++_epoch;
    account = null;
    profile = null;
    municipalities = [];
    stage = AuthStage.signedOut;
  });
  Future<void> complete(String municipality, String first, String last) =>
      _run(() async {
        final epoch = _epoch;
        final result = await repository.completeProfile(
          municipality,
          first.trim(),
          last.trim(),
        );
        if (epoch != _epoch || account?.id != result.id) return;
        profile = result;
        stage = AuthStage.ready;
      });
  Future<void> edit(String first, String last, String? phone) => _run(() async {
    final epoch = _epoch;
    final result = await repository.updateProfile(
      first.trim(),
      last.trim(),
      phone?.trim(),
    );
    if (epoch != _epoch || account?.id != result.id) return;
    profile = result;
    message = 'Perfil actualizado.';
  });
  void returnToLogin() {
    message = null;
    stage = AuthStage.signedOut;
    _emit();
  }

  void clearMessage() {
    message = null;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    _subscription?.cancel();
    super.dispose();
  }
}

String errorMessage(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'email_not_confirmed':
        return 'Confirma tu correo antes de iniciar sesión.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Se alcanzó el límite temporal. Espera antes de intentarlo nuevamente.';
      case 'email_address_not_authorized':
      case 'email_address_not_authorized_for_sender':
        return 'Este piloto solo puede enviar correo a direcciones autorizadas del equipo.';
      case 'weak_password':
        return 'Usa una contraseña de al menos 12 caracteres.';
      case 'same_password':
        return 'Elige una contraseña distinta de la anterior.';
      case 'otp_expired':
      case 'flow_state_expired':
      case 'flow_state_not_found':
        return 'El enlace expiró o se abrió en otro dispositivo. Solicita uno nuevo desde esta aplicación.';
    }
    return 'No se pudo completar el acceso. Revisa los datos o solicita un enlace nuevo.';
  }
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return 'La cuenta o el registro no están habilitados. Verifica tu correo o contacta al responsable del piloto.';
    }
    if (error.code == '22023') {
      return 'Revisa el nombre, los apellidos y el teléfono.';
    }
  }
  return 'No pudimos conectar. Revisa tu conexión e inténtalo otra vez.';
}
