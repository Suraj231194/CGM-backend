import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/core/env/app_environment.dart';
import 'package:optimus_cgm_flutter/repositories/repository_providers.dart';

void main() {
  test('uses the deployed Railway API by default', () {
    expect(
      EnvConfig.current.apiBaseUrl,
      'https://optimus-cgm-backend-production.up.railway.app/api',
    );
  });

  test('default API URL includes the Laravel API prefix', () {
    final uri = Uri.parse(EnvConfig.defaultApiBaseUrl);

    expect(uri.scheme, 'https');
    expect(uri.host, 'optimus-cgm-backend-production.up.railway.app');
    expect(uri.path, '/api');
  });

  test('does not synchronize production data while running tests', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(backendSyncEnabledProvider), isFalse);
  });
}
