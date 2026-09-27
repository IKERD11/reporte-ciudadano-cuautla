class Account {
  const Account(this.id, this.email, this.confirmed);
  final String id;
  final String email;
  final bool confirmed;
}

class AuthSignal {
  const AuthSignal(this.account, {this.recovery = false});
  final Account? account;
  final bool recovery;
}

class CitizenProfile {
  const CitizenProfile({
    required this.id,
    required this.municipalityId,
    required this.firstName,
    required this.lastName,
    required this.identityStatus,
    this.phone,
  });
  final String id, municipalityId, firstName, lastName, identityStatus;
  final String? phone;
  factory CitizenProfile.fromJson(Map<String, dynamic> json) => CitizenProfile(
    id: json['id'] as String,
    municipalityId: json['municipality_id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    identityStatus: json['identity_status'] as String,
    phone: json['phone'] as String?,
  );
}

class Municipality {
  const Municipality(this.id, this.name, this.state);
  final String id, name, state;
}

abstract interface class AuthRepository {
  Stream<AuthSignal> get changes;
  Future<Account?> validateSession();
  Future<Account?> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> resendConfirmation(String email);
  Future<void> requestPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
  Future<CitizenProfile?> loadProfile();
  Future<List<Municipality>> registrationMunicipalities();
  Future<CitizenProfile> completeProfile(
    String municipality,
    String firstName,
    String lastName,
  );
  Future<CitizenProfile> updateProfile(
    String firstName,
    String lastName,
    String? phone,
  );
}
