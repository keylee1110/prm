import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/auth_interceptor.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository, Ref ref) : super(AuthInitial()) {
    // Bind Force Logout callback dynamically to resolve circular dependency
    try {
      final dio = ref.read(dioProvider);
      final interceptor = dio.interceptors.firstWhere((i) => i is AuthInterceptor) as AuthInterceptor;
      interceptor.onForceLogout = () {
        handleForceLogout();
      };
    } catch (_) {
      // Fallback if interceptor is not registered
    }
    checkAuth();
  }

  // 1. Check existing session on App startup
  Future<void> checkAuth() async {
    state = AuthLoading();
    try {
      final token = await SecureStorage.instance.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final user = await _repository.getCurrentUser();
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      // If server fails (e.g. expired tokens) during initial check, clear and prompt login
      await SecureStorage.instance.clearTokens();
      state = AuthUnauthenticated();
    }
  }

  // 2. Email & Password Login
  Future<bool> login(String email, String password) async {
    state = AuthLoading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthAuthenticated(user);
      return true;
    } catch (e) {
      state = AuthError('Sai tài khoản hoặc mật khẩu. Vui lòng thử lại.');
      return false;
    }
  }

  // 3. Force Logout triggered by network Interceptor on 401 refresh failure
  Future<void> handleForceLogout() async {
    await SecureStorage.instance.clearTokens();
    state = AuthUnauthenticated();
  }

  // 4. Manual Logout
  Future<void> logout() async {
    state = AuthLoading();
    try {
      await _repository.logout();
    } catch (_) {
      // Even if network fails, we clear local states
      await SecureStorage.instance.clearTokens();
    }
    state = AuthUnauthenticated();
  }
}

// Explicitly type authStateProvider to resolve compiler inference warnings
final StateNotifierProvider<AuthNotifier, AuthState> authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});
