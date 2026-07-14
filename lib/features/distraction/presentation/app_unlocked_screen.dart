import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../application/distraction_provider.dart';
import '../application/blocker_service.dart';
import '../data/distraction_repository.dart';
import '../domain/distraction_model.dart';

// Popular apps the user can quickly pick from
final _popularApps = [
  {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'icon': LucideIcons.music},
  {'name': 'Instagram', 'package': 'com.instagram.android', 'icon': LucideIcons.camera},
  {'name': 'Twitter / X', 'package': 'com.twitter.android', 'icon': LucideIcons.message_circle},
  {'name': 'YouTube', 'package': 'com.google.android.youtube', 'icon': LucideIcons.circle_play},
  {'name': 'Facebook', 'package': 'com.facebook.katana', 'icon': LucideIcons.thumbs_up},
  {'name': 'Snapchat', 'package': 'com.snapchat.android', 'icon': LucideIcons.ghost},
];

IconData _iconForApp(String name) {
  final lname = name.toLowerCase();
  if (lname.contains('tiktok')) return LucideIcons.music;
  if (lname.contains('instagram')) return LucideIcons.camera;
  if (lname.contains('twitter') || lname.contains(' x')) return LucideIcons.message_circle;
  if (lname.contains('youtube')) return LucideIcons.circle_play;
  if (lname.contains('facebook')) return LucideIcons.thumbs_up;
  if (lname.contains('snapchat')) return LucideIcons.ghost;
  if (lname.contains('reddit')) return LucideIcons.message_square;
  return LucideIcons.smartphone;
}

class AppUnlockedScreen extends ConsumerStatefulWidget {
  const AppUnlockedScreen({super.key});

  @override
  ConsumerState<AppUnlockedScreen> createState() => _AppUnlockedScreenState();
}

class _AppUnlockedScreenState extends ConsumerState<AppUnlockedScreen> {
  bool _isAccessibilityEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkAccessibility();
  }

  Future<void> _checkAccessibility() async {
    final blocker = ref.read(blockerServiceProvider);
    final enabled = await blocker.isAccessibilityEnabled();
    if (mounted) {
      setState(() => _isAccessibilityEnabled = enabled);
    }
  }

  void _syncBlockedApps(List<DistractionApp> apps) {
    final blocker = ref.read(blockerServiceProvider);
    // Only sync apps that are active AND have a valid package ID
    final packages = apps
        .where((a) => a.isActive && a.packageId.isNotEmpty)
        .map((a) => a.packageId)
        .toList();
    blocker.syncBlockedApps(packages);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in blocked apps and sync with native layer
    ref.listen<AsyncValue<List<DistractionApp>>>(
      distractionAppsProvider,
      (previous, next) {
        next.whenData((apps) => _syncBlockedApps(apps));
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Apps'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apps on this list are blocked while SmartContent is active. Complete content to earn temporary unlock time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            if (!_isAccessibilityEnabled)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Permission Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                          const SizedBox(height: 4),
                          Text('Enable Accessibility for SmartContent to block apps.', style: TextStyle(fontSize: 12, color: AppTheme.error.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(blockerServiceProvider).openAccessibilitySettings();
                      },
                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                      child: const Text('ENABLE'),
                    )
                  ],
                ),
              )
            else
              const SizedBox(height: 8),

            Expanded(
              child: ref.watch(distractionAppsProvider).when(
                data: (apps) {
                  if (apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.shield_off, size: 64, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          const Text('No apps blocked yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the button below to add your first distraction app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      return _buildAppCard(context, ref, apps[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddAppSheet(context, ref),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Add App to Blocklist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, WidgetRef ref, DistractionApp app) {
    final bool isActive = app.isActive;

    return Dismissible(
      key: Key(app.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(LucideIcons.trash_2, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final repo = ref.read(distractionRepositoryProvider);
        try {
          await repo.deleteDistractionApp(app.id);
          ref.invalidate(distractionAppsProvider);
          return true;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppTheme.error),
          );
          return false;
        }
      },
      child: GestureDetector(
        onLongPress: () => _confirmDelete(context, ref, app),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppTheme.error.withOpacity(0.4) : AppTheme.success.withOpacity(0.5),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForApp(app.appName),
                  size: 32,
                  color: isActive ? AppTheme.error : AppTheme.success,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                app.appName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.lock : Icons.lock_open,
                    size: 13,
                    color: isActive ? AppTheme.error : AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Blocked' : 'Unlocked',
                    style: TextStyle(
                      color: isActive ? AppTheme.error : AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DistractionApp app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove App'),
        content: Text('Remove "${app.appName}" from your blocklist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(distractionRepositoryProvider);
              await repo.deleteDistractionApp(app.id);
              ref.invalidate(distractionAppsProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddAppSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAppSheet(onAppAdded: () {
        ref.invalidate(distractionAppsProvider);
      }),
    );
  }
}

class _AddAppSheet extends ConsumerStatefulWidget {
  final VoidCallback onAppAdded;
  const _AddAppSheet({required this.onAppAdded});

  @override
  ConsumerState<_AddAppSheet> createState() => _AddAppSheetState();
}

class _AddAppSheetState extends ConsumerState<_AddAppSheet> {
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  Future<void> _addApp({String? name, String? packageId}) async {
    final appName = name ?? _nameController.text.trim();
    final appPackage = packageId ?? _packageController.text.trim();

    if (appName.isEmpty) {
      setState(() => _error = 'App name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(distractionRepositoryProvider);
      await repo.addDistractionApp(appName, appPackage);
      widget.onAppAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Block an App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Choose a popular app or enter a custom one.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          // Quick-pick chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularApps.map((app) {
              return InkWell(
                onTap: () => _addApp(name: app['name'] as String, packageId: app['package'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(app['icon'] as IconData, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(app['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          const Text('Or enter a custom app', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'App Name',
              hintText: 'e.g. BeReal',
              prefixIcon: const Icon(LucideIcons.smartphone),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _packageController,
            decoration: InputDecoration(
              labelText: 'Package ID (optional)',
              hintText: 'e.g. com.bereal.ft',
              prefixIcon: const Icon(LucideIcons.package),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: AppTheme.error, fontSize: 13)),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _addApp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add to Blocklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
