import 'dart:async';
import 'package:reporte_ciudadano/features/auth/domain/auth_repository.dart';

const user = Account('citizen-a', 'citizen@example.test', true);
const citizen = CitizenProfile(
  id: 'citizen-a',
  municipalityId: 'cuautla',
  firstName: 'Ana',
  lastName: 'Pérez',
  identityStatus: 'PENDING',
);

class FakeAuthRepository implements AuthRepository {
  final events = StreamController<AuthSignal>.broadcast(sync: true);
  Account? current;
  CitizenProfile? profile;
  Completer<CitizenProfile?>? pendingProfile;
  Object? loginError;
  int signupCalls = 0, logoutCalls = 0, updatePasswordCalls = 0;
  @override
  Stream<AuthSignal> get changes => events.stream;
  @override
  Future<Account?> validateSession() async => current;
  @override
  Future<Account?> signUp(String email, String password) async {
    signupCalls++;
    return null;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (loginError != null) throw loginError!;
    current = user;
    events.add(const AuthSignal(user));
  }

  @override
  Future<void> resendConfirmation(String email) async {}
  @override
  Future<void> requestPasswordReset(String email) async {}
  @override
  Future<void> updatePassword(String password) async {
    updatePasswordCalls++;
  }

  @override
  Future<void> signOut() async {
    logoutCalls++;
    current = null;
    events.add(const AuthSignal(null));
  }

  @override
  Future<CitizenProfile?> loadProfile() =>
      pendingProfile?.future ?? Future.value(profile);
  @override
  Future<List<Municipality>> registrationMunicipalities() async => [
    const Municipality('cuautla', 'Cuautla', 'Morelos'),
  ];
  @override
  Future<CitizenProfile> completeProfile(
    String municipality,
    String firstName,
    String lastName,
  ) async => citizen;
  @override
  Future<CitizenProfile> updateProfile(
    String firstName,
    String lastName,
    String? phone,
  ) async => citizen;
}
