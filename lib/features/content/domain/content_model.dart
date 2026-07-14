class Content {
  final int id;
  final String title;
  final String synopsis;
  final String description;
  final String url;
  final String? thumbnailUrl;
  final int xpEarn;
  final int estimatedMinutes;
  final int sequenceNumber;
  final int completionMinutes;
  final bool isCompleted;
  final bool isUnlocked;
  final ContentCompletion? completion;

  Content({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.description,
    required this.url,
    this.thumbnailUrl,
    required this.xpEarn,
    required this.estimatedMinutes,
    required this.sequenceNumber,
    required this.completionMinutes,
    this.isCompleted = false,
    this.isUnlocked = true,
    this.completion,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'],
      title: json['title'],
      synopsis: json['synopsis'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      xpEarn: json['xp_earn'] ?? 0,
      estimatedMinutes: json['estimated_minutes'] ?? 5,
      sequenceNumber: json['sequence_number'] ?? 1,
      completionMinutes: json['completion_minutes'] ?? 5,
      isCompleted: json['is_completed'] ?? false,
      isUnlocked: json['is_unlocked'] ?? true,
      completion: json['completion'] != null
          ? ContentCompletion.fromJson(json['completion'])
          : null,
    );
  }
}

class ContentCompletion {
  final int id;
  final int penaltyMinutes;
  final bool isEligibleToClaimReward;

  ContentCompletion({
    required this.id,
    required this.penaltyMinutes,
    required this.isEligibleToClaimReward,
  });

  factory ContentCompletion.fromJson(Map<String, dynamic> json) {
    return ContentCompletion(
      id: json['id'],
      penaltyMinutes: json['penalty_minutes'] ?? 0,
      isEligibleToClaimReward: json['is_eligible_to_claim_reward'] ?? false,
    );
  }
}

class ContentTestQuestion {
  final int id;
  final String question;
  final List<Map<String, dynamic>> choices;

  ContentTestQuestion({
    required this.id,
    required this.question,
    required this.choices,
  });

  factory ContentTestQuestion.fromJson(Map<String, dynamic> json) {
    return ContentTestQuestion(
      id: json['id'],
      question: json['question'],
      choices: List<Map<String, dynamic>>.from(json['choices']),
    );
  }
}

class ContentStats {
  final int totalCompletions;
  final int totalXp;
  final int currentStreakDays;
  final List<dynamic> dailyCompletions;

  ContentStats({
    required this.totalCompletions,
    required this.totalXp,
    required this.currentStreakDays,
    required this.dailyCompletions,
  });

  factory ContentStats.fromJson(Map<String, dynamic> json) {
    return ContentStats(
      totalCompletions: json['total_completions'] ?? 0,
      totalXp: json['total_xp'] ?? 0,
      currentStreakDays: json['current_streak_days'] ?? 0,
      dailyCompletions: json['daily_completions'] ?? [],
    );
  }
}

