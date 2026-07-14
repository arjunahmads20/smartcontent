class MembershipReward {
  final int id;
  final String title;
  final String description;
  final int xpNeededToEarn;
  final String levelNeededToEarn;
  final bool isClaimed;

  MembershipReward({
    required this.id,
    required this.title,
    required this.description,
    required this.xpNeededToEarn,
    required this.levelNeededToEarn,
    this.isClaimed = false,
  });

  factory MembershipReward.fromJson(Map<String, dynamic> json) {
    return MembershipReward(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      xpNeededToEarn: json['xp_needed_to_earn'],
      levelNeededToEarn: json['level_needed_to_earn_title'] ?? 'Unknown',
      isClaimed: json['is_claimed'] ?? false,
    );
  }
}

class MembershipProfile {
  final int currentXp;
  final String? levelTitle;
  final int? level;
  final int? nextLevelXp;

  MembershipProfile({
    required this.currentXp,
    this.levelTitle,
    this.level,
    this.nextLevelXp,
  });

  factory MembershipProfile.fromJson(Map<String, dynamic> json) {
    return MembershipProfile(
      currentXp: json['xp'] ?? 0,
      levelTitle: json['level_title'],
      level: json['level'],
      nextLevelXp: json['next_level_xp'],
    );
  }
}
