import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/api/api_constants.dart';
import '../domain/membership_model.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(dio: ref.read(dioProvider));
});

class MembershipRepository {
  final Dio _dio;

  MembershipRepository({required Dio dio}) : _dio = dio;

  Future<MembershipProfile> getMembershipProfile() async {
    try {
      final response = await _dio.get(ApiConstants.membershipMe);
      return MembershipProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load membership profile');
    }
  }

  Future<List<MembershipReward>> getRewards() async {
    try {
      final response = await _dio.get(ApiConstants.membershipRewards);
      final List results = response.data['results'];
      return results.map((json) => MembershipReward.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load rewards');
    }
  }

  Future<void> claimReward(int rewardId) async {
    try {
      await _dio.post('${ApiConstants.membershipRewards}$rewardId/claim/');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data.toString());
      }
      throw Exception('Failed to claim reward');
    }
  }
}
