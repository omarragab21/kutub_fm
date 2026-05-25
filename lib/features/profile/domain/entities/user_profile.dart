/// Domain entity representing a user's profile.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final List<String> favoriteCategories;
  final int totalBooksListened;
  final int totalListeningMinutes;
  final int favoritesCount;
  final int followersCount;
  final int followingCount;
  final List<ContinueListeningItem> continueListening;
  final List<int> weeklyActivityMinutes; // 7 values, Mon-Sun
  final List<UserAchievement> achievements;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.favoriteCategories = const [],
    this.totalBooksListened = 0,
    this.totalListeningMinutes = 0,
    this.favoritesCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.continueListening = const [],
    this.weeklyActivityMinutes = const [0, 0, 0, 0, 0, 0, 0],
    this.achievements = const [],
  });

  String get totalListeningHours {
    final hours = totalListeningMinutes ~/ 60;
    return '$hours';
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    List<String>? favoriteCategories,
    int? totalBooksListened,
    int? totalListeningMinutes,
    int? favoritesCount,
    int? followersCount,
    int? followingCount,
    List<ContinueListeningItem>? continueListening,
    List<int>? weeklyActivityMinutes,
    List<UserAchievement>? achievements,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      totalBooksListened: totalBooksListened ?? this.totalBooksListened,
      totalListeningMinutes: totalListeningMinutes ?? this.totalListeningMinutes,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      continueListening: continueListening ?? this.continueListening,
      weeklyActivityMinutes: weeklyActivityMinutes ?? this.weeklyActivityMinutes,
      achievements: achievements ?? this.achievements,
    );
  }
}

/// Represents a badge/achievement earned by the user.
class UserAchievement {
  final String icon;
  final String title;
  final String desc;
  final bool unlocked;

  const UserAchievement({
    required this.icon,
    required this.title,
    required this.desc,
    this.unlocked = false,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      icon: map['icon'] ?? '',
      title: map['title'] ?? '',
      desc: map['desc'] ?? '',
      unlocked: map['unlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'title': title,
      'desc': desc,
      'unlocked': unlocked,
    };
  }
}

/// Represents a book the user has partially listened to.
class ContinueListeningItem {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double progress; // 0.0 – 1.0
  final String lastChapter;

  const ContinueListeningItem({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.progress,
    required this.lastChapter,
  });
}
