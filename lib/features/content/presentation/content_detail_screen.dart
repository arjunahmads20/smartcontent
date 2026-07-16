import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/application/auth_notifier.dart';
import '../domain/content_model.dart';
import '../data/content_repository.dart';
import '../application/content_provider.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final Content content;

  const ContentDetailScreen({
    super.key,
    required this.content,
  });

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  late YoutubePlayerController _controller;

  // Extract YouTube video ID from various URL formats
  static String _extractVideoId(String url) {
    final regExp = RegExp(
      r'^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    final id = match?.group(2);
    return (id != null && id.length == 11) ? id : '';
  }

  // --- Timer & completion state ---
  Timer? _timer;
  int _secondsWatched = 0;
  bool _isEligibleForCtqs = false;
  bool _ctqBannerDismissed = false;
  bool _rewardClaimed = false;

  // CTQ state
  List<ContentTestQuestion> _ctqs = [];
  Map<int, int> _selectedAnswers = {};
  bool _isLoadingCtqs = false;
  bool _isSubmittingCtqs = false;

  @override
  void initState() {
    super.initState();
    final videoId = _extractVideoId(widget.content.url);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    // Check if already eligible from a prior session
    final c = widget.content.completion;
    if (c != null) {
      _rewardClaimed = c.isEligibleToClaimReward;
    }

    if (!_rewardClaimed) {
      _startWatchTimer();
    }
  }

  void _startWatchTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsWatched++;
      final minutesWatched = _secondsWatched / 60.0;
      final required = widget.content.completionMinutes +
          (widget.content.completion?.penaltyMinutes ?? 0);

      if (!_isEligibleForCtqs && minutesWatched >= required) {
        _onThresholdReached(minutesWatched);
      }
    });
  }

  Future<void> _onThresholdReached(double minutesWatched) async {
    if (_isEligibleForCtqs) return;
    try {
      final repo = ref.read(contentRepositoryProvider);
      final result = await repo.logTime(widget.content.id, minutesWatched);
      if (mounted && result['is_eligible_for_ctqs'] == true) {
        setState(() => _isEligibleForCtqs = true);
      }
    } catch (_) {
      // silent — we'll still show the banner optimistically
      if (mounted) setState(() => _isEligibleForCtqs = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
    super.dispose();
  }

  // ─── Load & show CTQ modal ─────────────────────────────────────────────────

  Future<void> _showCtqModal() async {
    setState(() {
      _isLoadingCtqs = true;
      _ctqBannerDismissed = true;
    });

    try {
      final repo = ref.read(contentRepositoryProvider);
      _ctqs = await repo.getCtqs(widget.content.id);
      _selectedAnswers = {};
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load questions: $e'),
              backgroundColor: AppTheme.error),
        );
      }
      setState(() => _isLoadingCtqs = false);
      return;
    }

    setState(() => _isLoadingCtqs = false);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildCtqSheet(ctx),
    );
  }

  Widget _buildCtqSheet(BuildContext ctx) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) {
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Comprehension Questions',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(
                              'Answer correctly to claim your reward.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                if (_ctqs.isEmpty)
                  const Expanded(
                    child: Center(
                        child:
                            Text('No questions available for this content.')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(20),
                      itemCount: _ctqs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, qIndex) {
                        final q = _ctqs[qIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${qIndex + 1}. ${q.question}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...q.choices.map((choice) {
                              final choiceId = choice['id'] as int;
                              final isSelected =
                                  _selectedAnswers[q.id] == choiceId;
                              return GestureDetector(
                                onTap: () => setSheetState(
                                    () => _selectedAnswers[q.id] = choiceId),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary.withOpacity(0.2)
                                        : AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.white12,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primary
                                                : AppTheme.textSecondary,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppTheme.primary
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check,
                                                size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          choice['text'] ?? '',
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.textPrimary
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedAnswers.length < _ctqs.length ||
                              _isSubmittingCtqs)
                          ? null
                          : () => _submitCtqs(ctx),
                      child: _isSubmittingCtqs
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Answers'),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitCtqs(BuildContext sheetCtx) async {
    setState(() => _isSubmittingCtqs = true);
    try {
      final repo = ref.read(contentRepositoryProvider);
      final result = await repo.submitCtqs(widget.content.id, _selectedAnswers);
      if (!mounted) return;

      Navigator.pop(sheetCtx); // close CTQ sheet

      if (result['all_correct'] == true) {
        // Refresh content list in background
        ref.invalidate(recommendedContentProvider);
        ref.invalidate(contentStatsProvider);
        ref.read(authProvider.notifier).checkAuth(); // Update User XP!
        setState(() => _rewardClaimed = true);
        _showRewardModal(result);
      } else {
        final penalty = result['total_penalty_minutes'] ?? 0;
        // Reset timer tracking
        setState(() {
          _secondsWatched = 0;
          _isEligibleForCtqs = false;
          _ctqBannerDismissed = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Some answers were wrong. Watch ${penalty} more minute(s) and try again!')),
                ],
              ),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingCtqs = false);
    }
  }

  void _showRewardModal(Map<String, dynamic> result) {
    final xp = result['xp_awarded'] ?? 0;
    final appUnlock = result['app_unlock'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.trophy,
                    color: Colors.amber, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Reward Claimed! ߎ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You answered all questions correctly!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              // XP earned
              if (xp > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        '+$xp XP Earned',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              // App unlock
              if (appUnlock != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_open,
                          color: AppTheme.primaryLight, size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${appUnlock['app_package']} unlocked for ${appUnlock['unlock_minutes']} min',
                          style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // back to content list
                  },
                  child: const Text('Back to Content'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final minutesWatched = _secondsWatched ~/ 60;
    final requiredMinutes = widget.content.completionMinutes +
        (widget.content.completion?.penaltyMinutes ?? 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Player
                  YoutubePlayer(
                    controller: _controller,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.content.title,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 16),

                        // Metadata Row
                        Row(
                          children: [
                            _buildMetaChip(LucideIcons.clock,
                                '${widget.content.completionMinutes} min required'),
                            if (widget.content.xpEarn > 0) ...[
                              const SizedBox(width: 12),
                              _buildMetaChip(LucideIcons.star,
                                  '+${widget.content.xpEarn} XP',
                                  color: Colors.amber),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Watch progress
                        if (!_rewardClaimed && !_isEligibleForCtqs) ...[
                          _buildWatchProgress(minutesWatched, requiredMinutes),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 24),

                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.content.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Flash Banner ───────────────────────────────────────────────
          if (_isEligibleForCtqs && !_ctqBannerDismissed && !_rewardClaimed)
            _buildCtqBanner(),

          if (_rewardClaimed) _buildRewardClaimedBanner(),
        ],
      ),
    );
  }

  Widget _buildWatchProgress(int minutesWatched, int requiredMinutes) {
    final progress = (minutesWatched / requiredMinutes).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Watch Progress',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
            Text('$minutesWatched / $requiredMinutes min',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCtqBanner() {
    return GestureDetector(
      onTap: _isLoadingCtqs ? null : _showCtqModal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.trophy, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Completed! ߎ',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to answer questions and claim your reward!',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_isLoadingCtqs)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
            else
              const Icon(LucideIcons.arrow_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardClaimedBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.success),
          SizedBox(width: 12),
          Text('Reward Claimed!',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color?.withOpacity(0.3) ?? Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
