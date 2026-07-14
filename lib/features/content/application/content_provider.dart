import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/content_model.dart';
import '../data/content_repository.dart';

final recommendedContentProvider = FutureProvider.autoDispose<List<Content>>((ref) async {
  final repository = ref.read(contentRepositoryProvider);
  return repository.getRecommendedContent();
});

final contentStatsProvider = FutureProvider.autoDispose<ContentStats>((ref) async {
  final repository = ref.read(contentRepositoryProvider);
  return repository.getContentStats();
});
