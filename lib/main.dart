import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'features/distraction/application/blocker_service.dart';
import 'features/distraction/data/distraction_repository.dart';

void main() {
  runApp(const ProviderScope(child: SmartContentApp()));
}

class SmartContentApp extends ConsumerStatefulWidget {
  const SmartContentApp({super.key});

  @override
  ConsumerState<SmartContentApp> createState() => _SmartContentAppState();
}

class _SmartContentAppState extends ConsumerState<SmartContentApp> {
  @override
  void initState() {
    super.initState();
    // Sync blocked apps to native layer on every app startup.
    // This ensures the AccessibilityService has the correct blocklist even if
    // the user never visits the Focus Apps screen in this session.
    _syncBlockedAppsOnStartup();
  }

  Future<void> _syncBlockedAppsOnStartup() async {
    try {
      final repo = ref.read(distractionRepositoryProvider);
      final apps = await repo.getDistractionApps();
      final blocker = ref.read(blockerServiceProvider);
      final packages = apps
          .where((a) => a.isActive && a.packageId.isNotEmpty)
          .map((a) => a.packageId)
          .toList();
      await blocker.syncBlockedApps(packages);
    } catch (_) {
      // Silently ignore — user may not be logged in yet (onboarding)
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SmartContent',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
