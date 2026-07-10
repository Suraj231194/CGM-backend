import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env/app_environment.dart';
import '../core/env/runtime_environment.dart';
import '../services/api_token_store.dart';
import '../services/backend_session_service.dart';
import 'contracts/alert_repository.dart';
import 'contracts/auth_repository.dart';
import 'contracts/patient_repository.dart';
import 'local/local_alert_repository.dart';
import 'local/local_auth_repository.dart';
import 'local/local_patient_repository.dart';
import 'remote/remote_alert_repository.dart';
import 'remote/remote_auth_repository.dart';
import 'remote/remote_patient_repository.dart';

final backendSyncEnabledProvider = Provider<bool>((ref) {
  return EnvConfig.current.backendSyncEnabled && !isFlutterTest;
});

final apiTokenStoreProvider = Provider<ApiTokenStore>((ref) {
  return const ApiTokenStore();
});

final apiDioProvider = Provider<Dio>((ref) {
  final env = EnvConfig.current;
  final tokenStore = ref.watch(apiTokenStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: Duration(seconds: env.connectionTimeoutSeconds),
      receiveTimeout: Duration(seconds: env.connectionTimeoutSeconds),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore.clearToken();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});

final backendSessionProvider = Provider<BackendSessionService>((ref) {
  return BackendSessionService(
    dio: ref.watch(apiDioProvider),
    tokenStore: ref.watch(apiTokenStoreProvider),
    env: EnvConfig.current,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(backendSyncEnabledProvider)) return LocalAuthRepository();
  return RemoteAuthRepository(
    ref.watch(apiDioProvider),
    ref.watch(apiTokenStoreProvider),
  );
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  if (!ref.watch(backendSyncEnabledProvider)) return LocalPatientRepository();
  return RemotePatientRepository(ref.watch(apiDioProvider));
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  if (!ref.watch(backendSyncEnabledProvider)) return LocalAlertRepository();
  return RemoteAlertRepository(ref.watch(apiDioProvider));
});
