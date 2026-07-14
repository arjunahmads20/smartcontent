import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/content_model.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(dio: ref.read(dioProvider));
});

class ContentRepository {
  final Dio _dio;

  ContentRepository({required Dio dio}) : _dio = dio;

  Future<List<Content>> getRecommendedContent() async {
    try {
      final response = await _dio.get(ApiConstants.content);
      final List results = response.data['results'];
      return results.map((json) => Content.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load content');
    }
  }

  Future<ContentStats> getContentStats() async {
    try {
      final response = await _dio.get(ApiConstants.contentStats);
      return ContentStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load stats');
    }
  }

  Future<void> completeContent(int contentId) async {
    try {
      await _dio.post('${ApiConstants.content}$contentId/complete/');
    } catch (e) {
      throw Exception('Failed to mark content as completed');
    }
  }

  Future<List<ContentTestQuestion>> getCtqs(int contentId) async {
    try {
      final response = await _dio.get('${ApiConstants.content}$contentId/ctqs/');
      final List data = response.data['results'] ?? response.data;
      return data.map((json) => ContentTestQuestion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load CTQs');
    }
  }

  /// Logs the minutes spent on a content item.
  /// Returns a map with is_eligible_for_ctqs and required_minutes.
  Future<Map<String, dynamic>> logTime(int contentId, double minutesSpent) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.content}$contentId/log-time/',
        data: {'minutes_spent': minutesSpent},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to log time');
    }
  }

  /// Submits CTQ answers. answers = { questionId: selectedChoiceId }
  Future<Map<String, dynamic>> submitCtqs(
      int contentId, Map<int, int> answers) async {
    try {
      final answersStr = answers.map((k, v) => MapEntry(k.toString(), v));
      final response = await _dio.post(
        '${ApiConstants.content}$contentId/submit-ctqs/',
        data: {'answers': answersStr},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Failed to submit CTQs');
    }
  }
}

