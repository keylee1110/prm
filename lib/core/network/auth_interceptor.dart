import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../security/secure_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  VoidCallback? onForceLogout;

  AuthInterceptor({
    required Dio dio,
    this.onForceLogout,
  })  : _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add Access Token to Header
    final accessToken = await SecureStorage.instance.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token available, force logout
        onForceLogout?.call();
        return handler.next(err);
      }

      try {
        // Call API to refresh token
        // Use a separate Dio instance to avoid interceptor recursion
        final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
        
        final response = await refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data;
          final newAccessToken = data['accessToken'] as String;
          final newRefreshToken = data['refreshToken'] as String;

          // Save new tokens
          await SecureStorage.instance.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          // Update header and retry original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final cloneRequest = await _dio.request(
            options.path,
            options: Options(
              method: options.method,
              headers: options.headers,
              contentType: options.contentType,
            ),
            data: options.data,
            queryParameters: options.queryParameters,
          );

          return handler.resolve(cloneRequest);
        }
      } catch (e) {
        // Refresh token failed or threw an exception
        await SecureStorage.instance.clearTokens();
        onForceLogout?.call();
        return handler.next(err);
      }
    }
    
    return handler.next(err);
  }
}
