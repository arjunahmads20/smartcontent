import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/career_model.dart';

final careerRepositoryProvider = Provider<CareerRepository>((ref) {
  return CareerRepository(dio: ref.read(dioProvider));
});

class CareerRepository {
  final Dio _dio;

  CareerRepository({required Dio dio}) : _dio = dio;

  Future<List<CareerDream>> getCareerDreams() async {
    try {
      final response = await _dio.get(ApiConstants.careerDreams);
      final List results = response.data['results'];
      return results.map((json) => CareerDream.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load career dreams');
    }
  }
}
