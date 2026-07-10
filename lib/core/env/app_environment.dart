import 'package:flutter/foundation.dart';

/// Environment configuration for the application.
///
/// Use flavors or compile-time constants to switch between environments.
enum AppEnvironment { development, staging, production }

class EnvConfig {
  static const defaultApiBaseUrl =
      'https://optimus-cgm-backend-production.up.railway.app/api';

  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrlOverride,
    required this._cgmSdkAppId,
    required this._cgmSdkAppSecret,
    required this.enableLogging,
    required this.connectionTimeoutSeconds,
    required this.maxRetryAttempts,
    required this.bypassAuthentication,
    required this.backendSyncEnabled,
    required this.backendDevEmail,
    required this.backendDevPassword,
  });

  final AppEnvironment environment;
  final String apiBaseUrlOverride;
  final String _cgmSdkAppId;
  final String _cgmSdkAppSecret;
  final bool enableLogging;
  final int connectionTimeoutSeconds;
  final int maxRetryAttempts;
  final bool bypassAuthentication;
  final bool backendSyncEnabled;
  final String backendDevEmail;
  final String backendDevPassword;

  String get apiBaseUrl {
    if (apiBaseUrlOverride.isNotEmpty) {
      return apiBaseUrlOverride.replaceFirst(RegExp(r'/+$'), '');
    }
    return defaultApiBaseUrl;
  }

  String get cgmSdkAppId {
    if (_cgmSdkAppId.isNotEmpty) return _cgmSdkAppId;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return '684654';
    }
    return '';
  }

  String get cgmSdkAppSecret {
    if (_cgmSdkAppSecret.isNotEmpty) return _cgmSdkAppSecret;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return 'VxxWHQ8wKukhxX88gUDd1SqZhhtWEnHU';
    }
    return '';
  }

  static const development = EnvConfig._(
    environment: AppEnvironment.development,
    apiBaseUrlOverride: String.fromEnvironment('API_BASE_URL'),
    cgmSdkAppId: String.fromEnvironment('CGM_APP_ID'),
    cgmSdkAppSecret: String.fromEnvironment('CGM_APP_SECRET'),
    enableLogging: true,
    connectionTimeoutSeconds: 30,
    maxRetryAttempts: 3,
    bypassAuthentication: bool.fromEnvironment(
      'BYPASS_AUTH',
      defaultValue: true,
    ),
    backendSyncEnabled: bool.fromEnvironment(
      'ENABLE_BACKEND_SYNC',
      defaultValue: true,
    ),
    backendDevEmail: String.fromEnvironment(
      'BACKEND_DEV_EMAIL',
      defaultValue: 'customer@optimus.test',
    ),
    backendDevPassword: String.fromEnvironment(
      'BACKEND_DEV_PASSWORD',
      defaultValue: 'password',
    ),
  );

  static const staging = EnvConfig._(
    environment: AppEnvironment.staging,
    apiBaseUrlOverride: String.fromEnvironment('API_BASE_URL'),
    cgmSdkAppId: String.fromEnvironment('CGM_APP_ID'),
    cgmSdkAppSecret: String.fromEnvironment('CGM_APP_SECRET'),
    enableLogging: true,
    connectionTimeoutSeconds: 20,
    maxRetryAttempts: 3,
    bypassAuthentication: bool.fromEnvironment('BYPASS_AUTH'),
    backendSyncEnabled: bool.fromEnvironment(
      'ENABLE_BACKEND_SYNC',
      defaultValue: true,
    ),
    backendDevEmail: String.fromEnvironment('BACKEND_DEV_EMAIL'),
    backendDevPassword: String.fromEnvironment('BACKEND_DEV_PASSWORD'),
  );

  static const production = EnvConfig._(
    environment: AppEnvironment.production,
    apiBaseUrlOverride: String.fromEnvironment('API_BASE_URL'),
    cgmSdkAppId: String.fromEnvironment('CGM_APP_ID'),
    cgmSdkAppSecret: String.fromEnvironment('CGM_APP_SECRET'),
    enableLogging: false,
    connectionTimeoutSeconds: 15,
    maxRetryAttempts: 5,
    bypassAuthentication: bool.fromEnvironment('BYPASS_AUTH'),
    backendSyncEnabled: bool.fromEnvironment(
      'ENABLE_BACKEND_SYNC',
      defaultValue: true,
    ),
    backendDevEmail: String.fromEnvironment('BACKEND_DEV_EMAIL'),
    backendDevPassword: String.fromEnvironment('BACKEND_DEV_PASSWORD'),
  );

  static EnvConfig get current {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    return switch (env) {
      'production' => production,
      'staging' => staging,
      _ => development,
    };
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}
