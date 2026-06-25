import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage.dart';
import 'models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // Email/Password login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    // Save tokens securely
    await SecureStorage.instance.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return UserModel.fromJson(userJson);
  }

  // Logout from server and clear local secure tokens
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Fail silently if server is unreachable, we still clear local session
    } finally {
      await SecureStorage.instance.clearTokens();
    }
  }

  // Verify and fetch user details with existing access token
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    final userJson = response.data as Map<String, dynamic>;
    return UserModel.fromJson(userJson);
  }
}
