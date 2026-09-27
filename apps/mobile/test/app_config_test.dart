import 'package:flutter_test/flutter_test.dart';
import 'package:reporte_ciudadano/core/app_config.dart';

void main() {
  test('solo acepta callbacks PKCE en el destino exacto', () {
    final base = AppConfig.redirect;
    expect(AppConfig.isAuthCallback(Uri.parse(base)), isFalse);
    expect(AppConfig.isAuthCallback(Uri.parse('$base?code=test-code')), isTrue);
    expect(
      AppConfig.isAuthCallback(Uri.parse('$base?error=access_denied')),
      isTrue,
    );
    expect(
      AppConfig.isAuthCallback(Uri.parse('https://example.test/?code=test')),
      isFalse,
    );
    expect(
      AppConfig.isAuthCallback(Uri.parse('${base}unexpected?code=test')),
      isFalse,
    );
  });
}
