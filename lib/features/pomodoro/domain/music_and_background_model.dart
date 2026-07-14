class MusicAndBackground {
  final int id;
  final String backgroundName;
  final String downloadBackgroundImgUrl;
  final String musicName;
  final String downloadMusicUrl;
  final bool isPremium;
  final int? minimumMembershipLevelRequired;

  MusicAndBackground({
    required this.id,
    required this.backgroundName,
    required this.downloadBackgroundImgUrl,
    required this.musicName,
    required this.downloadMusicUrl,
    required this.isPremium,
    this.minimumMembershipLevelRequired,
  });

  factory MusicAndBackground.fromJson(Map<String, dynamic> json) {
    return MusicAndBackground(
      id: json['id'],
      backgroundName: json['background_name'],
      downloadBackgroundImgUrl: json['download_background_img_url'],
      musicName: json['music_name'],
      downloadMusicUrl: json['download_music_url'],
      isPremium: json['is_premium'] ?? false,
      minimumMembershipLevelRequired: json['minimum_membership_level_required'],
    );
  }
}
