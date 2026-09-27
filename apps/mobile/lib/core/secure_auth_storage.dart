import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Solo Android/iOS. La vista web de desarrollo usa sesiones en memoria.
class SecureAuthStorage extends LocalStorage {
  const SecureAuthStorage(this.namespace);
  final String namespace;
  static const _storage = FlutterSecureStorage();
  String get _key => '$namespace.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);
  @override
  Future<String?> accessToken() => _storage.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage(this.namespace);
  final String namespace;
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: '$namespace.pkce.$key');
  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: '$namespace.pkce.$key', value: value);
  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: '$namespace.pkce.$key');
}
