import 'package:flutter/foundation.dart';

class AppConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const configuredRedirect = String.fromEnvironment('AUTH_REDIRECT_URL');
  static bool get isConfigured =>
      Uri.tryParse(url)?.hasAuthority == true &&
      publishableKey.startsWith('sb_publishable_');
  static String get redirect => configuredRedirect.isNotEmpty
      ? configuredRedirect
      : kIsWeb
      ? '${Uri.base.origin}/'
      : 'mx.reporteciudadano.piloto://auth/callback';

  static bool isAuthCallback(Uri uri) {
    final expected = Uri.parse(redirect);
    final parameters = {
      ...uri.queryParameters,
      ...Uri.splitQueryString(uri.fragment),
    };
    final hasAuthParameters = [
      'code',
      'error',
      'error_code',
      'error_description',
    ].any(parameters.containsKey);
    return uri.scheme == expected.scheme &&
        uri.host == expected.host &&
        uri.port == expected.port &&
        uri.path == expected.path &&
        hasAuthParameters;
  }
}
