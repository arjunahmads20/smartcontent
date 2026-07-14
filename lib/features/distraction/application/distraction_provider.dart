import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/distraction_model.dart';
import '../data/distraction_repository.dart';

final distractionAppsProvider = FutureProvider.autoDispose<List<DistractionApp>>((ref) async {
  final repository = ref.read(distractionRepositoryProvider);
  return repository.getDistractionApps();
});
