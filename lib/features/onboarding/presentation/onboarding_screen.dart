/// Career Selection Onboarding Screen.
///
/// Shown to first-time users (no token) before login / registration.
/// The user browses career paths, taps one, and then proceeds to login or register.
/// The chosen career ID is saved to SharedPreferences so it survives navigation.
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../career/domain/career_model.dart';
import '../application/onboarding_provider.dart';
import '../data/onboarding_repository.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careersAsync = ref.watch(onboardingCareersProvider);
    final selectedCareer = ref.watch(selectedCareerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1115),
                  Color(0xFF1A1040),
                  Color(0xFF0F1115),
                ],
              ),
            ),
          ),

          // ── Decorative orbs ─────────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.3),
                              AppTheme.secondary.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.zap,
                                size: 14, color: AppTheme.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              'SmartContent',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'What\'s your\ndream career?',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  height: 1.15,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We\'ll build a personalised learning path\njust for you. Pick one to get started.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Career cards
                Expanded(
                  child: careersAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.wifi_off,
                                size: 48, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'Could not load career paths.\nPlease check your connection.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  ref.refresh(onboardingCareersProvider),
                              icon:
                                  const Icon(LucideIcons.refresh_cw, size: 16),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (careers) => _CareerGrid(
                      careers: careers,
                      selectedCareer: selectedCareer,
                      onSelect: (career) async {
                        ref.read(selectedCareerProvider.notifier).state =
                            career;
                        await ref
                            .read(onboardingRepositoryProvider)
                            .savePendingCareerId(career.id);
                      },
                    ),
                  ),
                ),

                // ── CTA section ───────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Selected career chip
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: selectedCareer != null
                            ? Container(
                                key: ValueKey(selectedCareer.id),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.circle_check,
                                        color: AppTheme.success, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedCareer.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Primary CTA
                      ElevatedButton(
                        onPressed: selectedCareer == null
                            ? null
                            : () => context.go('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          disabledBackgroundColor: AppTheme.surface,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          selectedCareer == null
                              ? 'Select a career path'
                              : 'Create Account  →',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Already have account
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Career grid ───────────────────────────────────────────────────────────────

class _CareerGrid extends StatelessWidget {
  final List<CareerDream> careers;
  final CareerDream? selectedCareer;
  final ValueChanged<CareerDream> onSelect;

  const _CareerGrid({
    required this.careers,
    required this.selectedCareer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: careers.length,
      itemBuilder: (context, index) {
        final career = careers[index];
        final isSelected = selectedCareer?.id == career.id;
        final imageUrl = career.imageUrls.isNotEmpty
            ? career.imageUrls.first
            : 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=600';

        return GestureDetector(
          onTap: () => onSelect(career),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : Colors.white.withOpacity(0.08),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surface,
                      child: Center(
                        child: Icon(
                          LucideIcons.briefcase,
                          size: 40,
                          color: AppTheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),

                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(isSelected ? 0.75 : 0.6),
                        ],
                      ),
                    ),
                  ),

                  // Selected overlay tint
                  if (isSelected)
                    Container(
                      color: AppTheme.primary.withOpacity(0.15),
                    ),

                  // Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(LucideIcons.check,
                                      size: 10, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Selected',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            career.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (career.description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              career.description,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
