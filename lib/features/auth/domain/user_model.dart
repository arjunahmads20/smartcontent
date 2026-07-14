class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? avatarUrl;
  final String? careerDream;
  final Membership? membership;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.avatarUrl,
    this.careerDream,
    this.membership,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'] ?? '${json['first_name']} ${json['last_name']}',
      avatarUrl: json['avatar_url'],
      careerDream: json['career_dream'],
      membership: json['membership'] != null ? Membership.fromJson(json['membership']) : null,
    );
  }
}

class Membership {
  final int xp;
  final String? levelTitle;
  final int? level;

  Membership({
    required this.xp,
    this.levelTitle,
    this.level,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      xp: json['xp'] ?? 0,
      levelTitle: json['level_title'],
      level: json['level'],
    );
  }
}
