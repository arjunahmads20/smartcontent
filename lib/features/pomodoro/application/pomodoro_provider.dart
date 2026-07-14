import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pomodoro_repository.dart';
import '../domain/music_and_background_model.dart';

// Provides the list of all available themes
final pomodoroThemesProvider = FutureProvider<List<MusicAndBackground>>((ref) async {
  final repository = ref.read(pomodoroRepositoryProvider);
  return repository.getThemes();
});

// State provider for the currently selected theme. Null means default theme.
final selectedThemeProvider = StateProvider<MusicAndBackground?>((ref) => null);
