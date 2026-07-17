import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    storage: ref.read(storageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository({required Dio dio, required FlutterSecureStorage storage})
      : _dio = dio,
        _storage = storage;

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      await _storage.write(key: 'access_token', value: data['access']);
      await _storage.write(key: 'refresh_token', value: data['refresh']);
      
      return User.fromJson(data['user']);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data.toString());
      }
      throw Exception('Failed to connect to server.');
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    int? careerDreamId,
  }) async {
    try {
      // 1. Register the user (with optional career dream)
      final payload = {
        'email': email,
        'password': password,
        'password_confirm': password,
        'first_name': firstName,
        'last_name': lastName,
        if (careerDreamId != null) 'career_dream': careerDreamId,
      };
      await _dio.post(ApiConstants.register, data: payload);

      // 2. Log in to obtain JWT tokens.
      return await login(email, password);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data.toString());
      }
      throw Exception('Registration failed.');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<User?> checkAuthStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    try {
      final response = await _dio.get(ApiConstants.me);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      // The Dio interceptor already attempted a token refresh before this catch
      // fires. If we still get a 401 here it means the refresh token is also
      // expired/blacklisted — the interceptor will have cleared both tokens.
      // For any other error (network timeout, server error) we keep the stored
      // tokens so the user isn't unnecessarily logged out.
      if (e.response?.statusCode == 401) {
        return null;
      }
      // Non-auth error (e.g. no internet) — stay logged in and try again later.
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiConstants.me, data: data);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data.toString());
      }
      throw Exception('Failed to update profile.');
    }
  }
}
