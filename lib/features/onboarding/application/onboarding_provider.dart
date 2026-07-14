/// Onboarding state providers.
///
/// [onboardingCareersProvider]  – async list of career dreams fetched without auth
/// [selectedCareerProvider]     – the career the user tapped on the onboarding screen
/// [pendingCareerIdProvider]    – reads the persisted pending career ID from SharedPreferences
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../career/domain/career_model.dart';
import '../data/onboarding_repository.dart';

/// Fetches career dreams via the public (no-auth) endpoint.
final onboardingCareersProvider = FutureProvider<List<CareerDream>>((ref) async {
  return ref.read(onboardingRepositoryProvider).getCareerDreams();
});

/// Holds the career the user has selected on the onboarding screen (in-memory).
final selectedCareerProvider = StateProvider<CareerDream?>((ref) => null);

/// Reads the pending career ID that was written to SharedPreferences.
/// Used by the register screen to attach the career at account creation time.
final pendingCareerIdProvider = FutureProvider<int?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('pending_career_dream_id');
});
