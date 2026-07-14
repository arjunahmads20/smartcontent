import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/music_and_background_model.dart';

final pomodoroRepositoryProvider = Provider<PomodoroRepository>((ref) {
  return PomodoroRepository(dio: ref.read(dioProvider));
});

class PomodoroRepository {
  final Dio _dio;

  PomodoroRepository({required Dio dio}) : _dio = dio;

  Future<List<MusicAndBackground>> getThemes() async {
    try {
      final response = await _dio.get(ApiConstants.pomodoroThemes);
      // Django REST Framework pagination wraps the list in a 'results' map
      final List data = response.data['results'] ?? response.data;
      return data.map((json) => MusicAndBackground.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pomodoro themes: $e');
    }
  }
}
