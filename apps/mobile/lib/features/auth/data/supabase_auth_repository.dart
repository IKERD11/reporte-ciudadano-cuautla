import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_config.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  Account? _account(User? user) => user == null
      ? null
      : Account(user.id, user.email ?? '', user.emailConfirmedAt != null);
  @override
  Stream<AuthSignal> get changes => client.auth.onAuthStateChange.map(
    (state) => AuthSignal(
      _account(state.session?.user),
      recovery: state.event == AuthChangeEvent.passwordRecovery,
    ),
  );
  @override
  Future<Account?> validateSession() async {
    if (client.auth.currentSession == null) return null;
    return _account((await client.auth.getUser()).user);
  }

  @override
  Future<Account?> signUp(String email, String password) async => _account(
    (await client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: AppConfig.redirect,
    )).session?.user,
  );
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> resendConfirmation(String email) async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: AppConfig.redirect,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) => client.auth
      .resetPasswordForEmail(email.trim(), redirectTo: AppConfig.redirect);
  @override
  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.global);
  @override
  Future<CitizenProfile?> loadProfile() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final result = await client
        .from('profiles')
        .select('id,municipality_id,first_name,last_name,phone,identity_status')
        .eq('id', uid)
        .maybeSingle();
    return result == null ? null : CitizenProfile.fromJson(result);
  }

  @override
  Future<List<Municipality>> registrationMunicipalities() async {
    final rows = await client.rpc('list_registration_municipalities') as List;
    return rows
        .map(
          (r) => Municipality(
            r['id'] as String,
            r['name'] as String,
            r['state'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<CitizenProfile> completeProfile(
    String municipality,
    String firstName,
    String lastName,
  ) async {
    final row = await client.rpc(
      'complete_citizen_profile',
      params: {
        'p_municipality_id': municipality,
        'p_first_name': firstName,
        'p_last_name': lastName,
      },
    );
    return CitizenProfile.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<CitizenProfile> updateProfile(
    String firstName,
    String lastName,
    String? phone,
  ) async {
    final row = await client.rpc(
      'update_my_profile',
      params: {
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_phone': phone,
      },
    );
    return CitizenProfile.fromJson(Map<String, dynamic>.from(row));
  }
}
