import 'package:dio/dio.dart';

import '../app/theme.dart';
import '../core/env/app_environment.dart';
import '../repositories/contracts/auth_repository.dart';
import '../repositories/remote/remote_model_parsers.dart';
import 'api_token_store.dart';

class BackendSessionService {
  BackendSessionService({
    required Dio dio,
    required ApiTokenStore tokenStore,
    required EnvConfig env,
  }) : this._(dio, tokenStore, env);

  BackendSessionService._(this._dio, this._tokenStore, this._env);

  final Dio _dio;
  final ApiTokenStore _tokenStore;
  final EnvConfig _env;

  Future<AuthResult?> ensureSession({bool force = false}) async {
    if (!force) {
      final existing = await _tokenStore.readToken();
      if (existing != null && existing.isNotEmpty) {
        final session = await _sessionFromToken(existing);
        if (session != null) return session;
        await _tokenStore.clearToken();
      }
    }

    if (!_env.bypassAuthentication) {
      return null;
    }

    final email = _env.backendDevEmail;
    final password = _env.backendDevPassword;
    if (email.isEmpty || password.isEmpty) return null;

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sign-in',
      data: {
        'email': email,
        'password': password,
        'device_name': 'optimus-flutter-dev',
      },
    );
    final data = response.data ?? const {};
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) return null;

    await _tokenStore.writeToken(token);
    final userJson = data['user'];
    final user = userJson is Map<String, dynamic>
        ? userFromJson(userJson)
        : null;

    return AuthResult(
      success: data['success'] != false,
      user: user,
      role: user?.role ?? OptimusRole.customer,
      token: token,
    );
  }

  Future<void> storeToken(String? token) async {
    if (token == null || token.isEmpty) return;
    await _tokenStore.writeToken(token);
  }

  Future<void> clearToken() {
    return _tokenStore.clearToken();
  }

  Future<AuthResult?> _sessionFromToken(String token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/session');
      final data = response.data ?? const {};
      if (data['valid'] != true) return null;
      final userJson = data['user'];
      final user = userJson is Map<String, dynamic>
          ? userFromJson(userJson)
          : null;
      return AuthResult(
        success: true,
        user: user,
        role: user?.role ?? OptimusRole.customer,
        token: token,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) return null;
      rethrow;
    }
  }
}
