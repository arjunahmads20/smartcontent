import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/career_model.dart';
import '../data/career_repository.dart';

final careerDreamsProvider = FutureProvider<List<CareerDream>>((ref) async {
  final repository = ref.read(careerRepositoryProvider);
  return repository.getCareerDreams();
});
