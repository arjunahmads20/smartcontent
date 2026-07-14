import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/pomodoro_provider.dart';
import '../domain/music_and_background_model.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  static const int _workDuration = 25 * 60; // 25 minutes
  int _secondsRemaining = _workDuration;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_timer != null) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopTimer();
          // Logic for short break could go here
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _secondsRemaining = _workDuration;
    });
  }

  String get _timeFormatted {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    double percent = _secondsRemaining / _workDuration;
    final selectedTheme = ref.watch(selectedThemeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Focus Timer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.palette),
            onPressed: _showThemePicker,
            tooltip: 'Change Theme & Music',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          if (selectedTheme != null &&
              selectedTheme.downloadBackgroundImgUrl.isNotEmpty)
            Image.network(
              selectedTheme.downloadBackgroundImgUrl,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),

          if (selectedTheme == null ||
              selectedTheme.downloadBackgroundImgUrl.isEmpty)
            Container(color: AppTheme.background),

          // Main Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedTheme != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          const Icon(LucideIcons.music,
                              size: 24, color: Colors.white70),
                          const SizedBox(height: 8),
                          Text(
                            'Playing: ${selectedTheme.musicName}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  CircularPercentIndicator(
                    radius: 150.0,
                    lineWidth: 12.0,
                    percent: percent,
                    center: Text(
                      _timeFormatted,
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(fontSize: 64),
                    ),
                    progressColor: AppTheme.primary,
                    backgroundColor: Colors.white24,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 64),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlBtn(
                        icon: _isRunning ? LucideIcons.pause : LucideIcons.play,
                        onPressed: _isRunning ? _stopTimer : _startTimer,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _buildControlBtn(
                        icon: LucideIcons.rotate_ccw,
                        onPressed: _resetTimer,
                        isPrimary: false,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(
      {required IconData icon,
      required VoidCallback onPressed,
      required bool isPrimary}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : AppTheme.surface,
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _ThemePickerSheet extends ConsumerWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(pomodoroThemesProvider);
    final selectedTheme = ref.watch(selectedThemeProvider);

    // Get user level to determine locks
    final authState = ref.watch(authProvider);
    int userLevel = 1;
    if (authState is AuthAuthenticated) {
      userLevel = authState.user.membership?.level ?? 1;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Theme & Music',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Customize your focus environment.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: themesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading themes: $e')),
                data: (themes) {
                  if (themes.isEmpty) {
                    return const Center(
                        child: Text('No themes available yet.'));
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: themes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final theme = themes[index];
                      final isSelected = selectedTheme?.id == theme.id;

                      final requiredLevel =
                          theme.minimumMembershipLevelRequired ?? 1;
                      final isLocked =
                          theme.isPremium && userLevel < requiredLevel;

                      return Stack(
                        children: [
                          Opacity(
                            opacity: isLocked ? 0.5 : 1.0,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              tileColor: isSelected
                                  ? AppTheme.primary.withOpacity(0.1)
                                  : AppTheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isSelected
                                    ? BorderSide(
                                        color: AppTheme.primary, width: 2)
                                    : BorderSide.none,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  theme.downloadBackgroundImgUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: AppTheme.primary.withOpacity(0.2),
                                    child: const Icon(LucideIcons.image),
                                  ),
                                ),
                              ),
                              title: Text(theme.backgroundName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  const Icon(LucideIcons.music,
                                      size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      theme.musicName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isLocked
                                  ? const Icon(LucideIcons.lock,
                                      color: AppTheme.textSecondary)
                                  : isSelected
                                      ? const Icon(LucideIcons.circle_check,
                                          color: AppTheme.primary)
                                      : null,
                              onTap: isLocked
                                  ? () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Reach Level $requiredLevel to unlock this theme!'),
                                          backgroundColor: AppTheme.surface,
                                        ),
                                      );
                                    }
                                  : () {
                                      ref
                                          .read(selectedThemeProvider.notifier)
                                          .state = theme;
                                      Navigator.pop(context);
                                    },
                            ),
                          ),
                          if (theme.isPremium)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
