import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/top_floating_navbar.dart';
import '../../auth/application/auth_notifier.dart';
import '../../content/application/content_provider.dart';
import '../../content/domain/content_model.dart';
import '../../career/application/career_provider.dart';
import '../../content/presentation/content_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user;
    final hasCareer = user.careerDream != null;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 100, bottom: 24),
            children: [
              // ── "Pick your career" banner (Approach B) ─────────────────
              if (!hasCareer) _buildCareerBanner(context, ref),

              _buildHeroSection(context, ref, userCareerTitle: user.careerDream),
              const SizedBox(height: 32),
              _buildContentsSection(context, ref),
            ],
          ),
          TopFloatingNavbar(
            membershipLevel: user.membership?.level ?? 1,
            careerDreamTitle: user.careerDream ?? 'Not Set',
            userName: user.fullName,
          ),
        ],
      ),
    );
  }

  // ── Career missing banner ─────────────────────────────────────────────────

  Widget _buildCareerBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.25),
            AppTheme.secondary.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.target,
                color: AppTheme.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No career path selected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pick a career to unlock your learning path.',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _showCareerPicker(context, ref),
            child: const Text(
              'Pick',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showCareerPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CareerPickerSheet(ref: ref),
    );
  }

  // ── Hero / career paths ───────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, {required String? userCareerTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Career Path',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ref.watch(careerDreamsProvider).when(
            data: (dreams) {
              var displayDreams = dreams;
              if (userCareerTitle != null) {
                displayDreams = dreams.where((d) => d.title == userCareerTitle).toList();
              }
              
              if (displayDreams.isEmpty) {
                return const Center(
                    child: Text('No career paths available.'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayDreams.length,
                itemBuilder: (context, index) {
                  final dream = displayDreams[index];
                  final imageUrl = dream.imageUrls.isNotEmpty
                      ? dream.imageUrls.first
                      : 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&q=80&w=800';
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.surface,
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8)
                          ],
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dream.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (dream.description.isNotEmpty)
                            Text(
                              dream.description,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  // ── Recommended content ───────────────────────────────────────────────────

  Widget _buildContentsSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended Content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {},
                child: Text('See All',
                    style: TextStyle(color: AppTheme.primaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ref.watch(recommendedContentProvider).when(
            data: (contents) {
              if (contents.isEmpty) {
                return const Text('No content available.');
              }
              return Column(
                children: contents.map((content) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildContentCard(context, content),
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  // ── Content card with lock overlay ────────────────────────────────────────

  Widget _buildContentCard(BuildContext context, Content content) {
    final isLocked = !content.isUnlocked;

    return Stack(
      children: [
        // Base card
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isLocked ? 0.45 : 1.0,
          child: InkWell(
            onTap: isLocked
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ContentDetailScreen(content: content),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                    child: Image.network(
                      content.thumbnailUrl ??
                          'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&q=80&w=500',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: AppTheme.surface,
                        child: Icon(LucideIcons.circle_play,
                            size: 32, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sequence number badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '#${content.sequenceNumber}',
                                  style: TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (content.isCompleted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.check,
                                          size: 10,
                                          color: AppTheme.success),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Done',
                                        style: TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            content.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content.synopsis,
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.star,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('+${content.xpEarn} XP',
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lock overlay
        if (isLocked)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(LucideIcons.lock, color: Colors.white, size: 16),
                        SizedBox(width: 10),
                        Text('Complete the previous content first!'),
                      ],
                    ),
                    backgroundColor: AppTheme.surface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.lock,
                      color: Colors.white70, size: 22),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Career Picker Bottom Sheet ────────────────────────────────────────────────

class _CareerPickerSheet extends ConsumerWidget {
  final WidgetRef ref;

  const _CareerPickerSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final careersAsync = widgetRef.watch(careerDreamsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
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
                  Text('Choose Your Career Path',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'This will personalise your content feed.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: careersAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary)),
                error: (e, _) =>
                    Center(child: Text('Error loading careers: $e')),
                data: (careers) => ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: careers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final career = careers[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primary.withOpacity(0.15),
                        ),
                        child: career.imageUrls.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  career.imageUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      LucideIcons.briefcase,
                                      color: AppTheme.primaryLight),
                                ),
                              )
                            : const Icon(LucideIcons.briefcase,
                                color: AppTheme.primaryLight),
                      ),
                      title: Text(career.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: career.description.isNotEmpty
                          ? Text(
                              career.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      trailing:
                          const Icon(LucideIcons.chevron_right, size: 16),
                      onTap: () async {
                        // Update career on the backend via PATCH /auth/me/
                        try {
                          await widgetRef.read(authProvider.notifier).updateCareer(career.id);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${career.title} selected! Loading your learning path…'),
                                backgroundColor: AppTheme.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                          
                          // Refresh content to load paths for the new career
                          widgetRef.invalidate(recommendedContentProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Failed to update career. Please try again.'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
