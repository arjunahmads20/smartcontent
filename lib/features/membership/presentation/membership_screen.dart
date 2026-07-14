import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/theme/app_theme.dart';
import '../application/membership_provider.dart';
import '../domain/membership_model.dart';

class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(membershipProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership & Rewards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profile.when(
        data: (data) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildMembershipCard(data),
                  const SizedBox(height: 32),
                  const Text(
                    'Available Rewards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRewardsList(ref),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildMembershipCard(MembershipProfile data) {
    final currentXp = data.currentXp;
    final nextLevelXp = data.nextLevelXp ?? (currentXp + 100);
    final double progress = (nextLevelXp - currentXp <= 0) ? 1.0 : (currentXp / nextLevelXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 8.0,
            percent: progress,
            center: Text(
              "${(progress * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.levelTitle ?? 'Starter',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.currentXp} / ${nextLevelXp} XP to next',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRewardsList(WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    return rewards.when(
      data: (list) => Column(
        children: list.map((reward) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRewardCard(
            title: reward.title,
            xpCost: reward.xpNeededToEarn,
            levelRequired: reward.levelNeededToEarn,
            icon: LucideIcons.gift,
            isClaimed: reward.isClaimed,
          ),
        )).toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildRewardCard({
    required String title,
    required int xpCost,
    required String levelRequired,
    required IconData icon,
    bool isClaimed = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.gift, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$xpCost XP',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Requires $levelRequired',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isClaimed ? null : () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              backgroundColor: isClaimed ? AppTheme.surface : AppTheme.primary,
            ),
            child: Text(isClaimed ? 'Claimed' : 'Claim'),
          ),
        ],
      ),
    );
  }
}
