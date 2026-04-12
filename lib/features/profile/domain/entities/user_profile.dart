/// Domain entity representing a user's profile.
class UserProfile {
  final String id;
  final String name;
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

  const UserProfile({
    required this.id,
    required this.name,
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
  });

  String get totalListeningHours {
    final hours = totalListeningMinutes ~/ 60;
    return '$hours';
  }

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    String? bio,
    List<String>? favoriteCategories,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      totalBooksListened: totalBooksListened,
      totalListeningMinutes: totalListeningMinutes,
      favoritesCount: favoritesCount,
      followersCount: followersCount,
      followingCount: followingCount,
      continueListening: continueListening,
      weeklyActivityMinutes: weeklyActivityMinutes,
    );
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
