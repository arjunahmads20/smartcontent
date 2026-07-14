import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/membership_model.dart';
import '../data/membership_repository.dart';

final membershipProfileProvider = FutureProvider.autoDispose<MembershipProfile>((ref) async {
  final repository = ref.read(membershipRepositoryProvider);
  return repository.getMembershipProfile();
});

final rewardsProvider = FutureProvider.autoDispose<List<MembershipReward>>((ref) async {
  final repository = ref.read(membershipRepositoryProvider);
  return repository.getRewards();
});
