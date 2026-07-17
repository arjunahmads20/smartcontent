import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_constants.dart';

final storageProvider = Provider((ref) => const FlutterSecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(AuthInterceptor(dio, ref.read(storageProvider)));
  return dio;
});

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage storage;

  // Prevents concurrent refresh attempts from triggering each other.
  bool _isRefreshing = false;

  AuthInterceptor(this._dio, this.storage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final is401 = err.response?.statusCode == 401;
    // Avoid infinite loop: don't retry the refresh endpoint itself.
    final isRefreshRequest =
        err.requestOptions.path.contains('token/refresh');

    if (is401 && !isRefreshRequest && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await storage.read(key: 'refresh_token');
        if (refreshToken == null) {
          // No refresh token stored — clear everything and force re-login.
          await _clearTokens();
          return super.onError(err, handler);
        }

        // Attempt to get a new access token.
        final response = await _dio.post(
          ApiConstants.tokenRefresh,
          data: {'refresh': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccess = response.data['access'] as String?;
        final newRefresh = response.data['refresh'] as String?;

        if (newAccess == null) {
          await _clearTokens();
          return super.onError(err, handler);
        }

        // Persist the new tokens.
        await storage.write(key: 'access_token', value: newAccess);
        if (newRefresh != null) {
          // SimpleJWT rotates refresh tokens when ROTATE_REFRESH_TOKENS=True.
          await storage.write(key: 'refresh_token', value: newRefresh);
        }

        // Retry the original request with the new access token.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await _dio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed (token expired / blacklisted) — force re-login.
        await _clearTokens();
        return super.onError(err, handler);
      } finally {
        _isRefreshing = false;
      }
    }

    return super.onError(err, handler);
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}
