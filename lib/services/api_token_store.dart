import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiTokenStore {
  const ApiTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'optimus_backend_auth_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> writeToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
