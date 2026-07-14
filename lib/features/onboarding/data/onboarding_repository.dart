/// Onboarding repository.
///
/// Manages the "pending career" — the career dream the user picks before
/// they have created an account. The ID is stored in SharedPreferences so
/// it survives hot-restart and is available at registration time.
///
/// Also provides a public (unauthenticated) Dio instance for fetching
/// the career list without a JWT token.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_constants.dart';
import '../../career/domain/career_model.dart';

const _kPendingCareerKey = 'pending_career_dream_id';

// ── Public Dio (no auth interceptor) ─────────────────────────────────────────

final publicDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

// ── Repository ────────────────────────────────────────────────────────────────

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(dio: ref.read(publicDioProvider));
});

class OnboardingRepository {
  final Dio _dio;

  OnboardingRepository({required Dio dio}) : _dio = dio;

  /// Fetch all career dreams without authentication.
  Future<List<CareerDream>> getCareerDreams() async {
    try {
      final response = await _dio.get(ApiConstants.careerDreams);
      final List results = response.data['results'] ?? response.data;
      return results.map((json) => CareerDream.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load career dreams. Please check your connection.');
    }
  }

  /// Persist the selected career dream ID locally (pre-login).
  Future<void> savePendingCareerId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPendingCareerKey, id);
  }

  /// Read the pending career dream ID (returns null if not set).
  Future<int?> loadPendingCareerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPendingCareerKey);
  }

  /// Clear the pending career dream ID (called after successful registration).
  Future<void> clearPendingCareerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingCareerKey);
  }
}
