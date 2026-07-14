import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/distraction_model.dart';

final distractionRepositoryProvider = Provider<DistractionRepository>((ref) {
  return DistractionRepository(dio: ref.read(dioProvider));
});

class DistractionRepository {
  final Dio _dio;

  DistractionRepository({required Dio dio}) : _dio = dio;

  Future<List<DistractionApp>> getDistractionApps() async {
    try {
      final response = await _dio.get(ApiConstants.distractionApps);
      final List results = response.data['results'];
      return results.map((json) => DistractionApp.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load distraction apps');
    }
  }

  Future<void> toggleAppStatus(int appId, bool isActive) async {
    try {
      await _dio.patch('${ApiConstants.distractionApps}$appId/', data: {
        'is_active': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update app status');
    }
  }

  Future<DistractionApp> addDistractionApp(String name, String packageId) async {
    try {
      final response = await _dio.post(ApiConstants.distractionApps, data: {
        'name': name,
        'package_id': packageId,
        'is_active': true,
      });
      return DistractionApp.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add app to blocklist');
    }
  }

  Future<void> deleteDistractionApp(int appId) async {
    try {
      await _dio.delete('${ApiConstants.distractionApps}$appId/');
    } catch (e) {
      throw Exception('Failed to remove app from blocklist');
    }
  }
}
