import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(secureStorageProvider),
  );
});

class AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepository(this._api, this._storage);

  Future<User> login(LoginRequest req) async {
    try {
      final res = await _api.post('/auth/login', data: req.toJson());
      final data = res.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await _storage.saveToken(token);
      // After login, fetch /auth/me
      final me = await getMe(token: token);
      await _storage.saveUser(me.toJsonString());
      return me;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final code = data['error']?['code'] as String? ?? 'UNKNOWN';
        final message = data['error']?['message'] as String? ??
            data['detail'] as String? ??
            'Login failed';
        final reason = data['error']?['reason'] as String?;
        final actualRole = data['error']?['actual_role'] as String?;
        throw AuthException(
            code: code, message: message, reason: reason, actualRole: actualRole);
      }
      throw AuthException(code: 'NETWORK_ERROR', message: extractApiError(e));
    }
  }

  Future<User> getMe({String? token}) async {
    try {
      final res = await _api.get('/auth/me');
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(
          code: 'FETCH_ME_FAILED', message: extractApiError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.clearAll();
  }

  Future<User?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null) return null;
    try {
      final me = await getMe(token: token);
      await _storage.saveUser(me.toJsonString());
      return me;
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }
}
