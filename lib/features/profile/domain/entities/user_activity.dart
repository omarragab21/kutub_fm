enum UserActivityType {
  reviewPost,
  podcast,
  continueReading,
  radio,
}

/// Domain entity representing a single activity item in the user's history.
class UserActivityItem {
  final String id;
  final UserActivityType type;
  final String title;
  final String? subtitle;
  final String? textContent;
  final String? author;
  final String? coverImage;
  final String? avatarUrl;
  final String? userName;
  final String? date;
  final double rating; // 1.0 to 5.0
  final List<String> hashtags;
  final String? linkedBookTitle;
  final String? linkedBookAuthor;
  final String? linkedBookCover;
  final String? linkedBookId;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isBookmarked;
  final String? duration; // e.g. "30:00 د"
  final double progress; // 0.0 to 1.0 (e.g. 0.1 for 10%)
  final String? audioUrl;
  final String? bookId;

  const UserActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.textContent,
    this.author,
    this.coverImage,
    this.avatarUrl,
    this.userName,
    this.date,
    this.rating = 5.0,
    this.hashtags = const [],
    this.linkedBookTitle,
    this.linkedBookAuthor,
    this.linkedBookCover,
    this.linkedBookId,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.duration,
    this.progress = 0.0,
    this.audioUrl,
    this.bookId,
  });

  UserActivityItem copyWith({
    String? id,
    UserActivityType? type,
    String? title,
    String? subtitle,
    String? textContent,
    String? author,
    String? coverImage,
    String? avatarUrl,
    String? userName,
    String? date,
    double? rating,
    List<String>? hashtags,
    String? linkedBookTitle,
    String? linkedBookAuthor,
    String? linkedBookCover,
    String? linkedBookId,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isBookmarked,
    String? duration,
    double? progress,
    String? audioUrl,
    String? bookId,
  }) {
    return UserActivityItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      textContent: textContent ?? this.textContent,
      author: author ?? this.author,
      coverImage: coverImage ?? this.coverImage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      rating: rating ?? this.rating,
      hashtags: hashtags ?? this.hashtags,
      linkedBookTitle: linkedBookTitle ?? this.linkedBookTitle,
      linkedBookAuthor: linkedBookAuthor ?? this.linkedBookAuthor,
      linkedBookCover: linkedBookCover ?? this.linkedBookCover,
      linkedBookId: linkedBookId ?? this.linkedBookId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      duration: duration ?? this.duration,
      progress: progress ?? this.progress,
      audioUrl: audioUrl ?? this.audioUrl,
      bookId: bookId ?? this.bookId,
    );
  }
}

/// Group of activities grouped by a timeframe header (e.g. "قبل ساعة", "قبل يومين").
class UserActivityGroup {
  final String timeframe;
  final List<UserActivityItem> items;

  const UserActivityGroup({
    required this.timeframe,
    required this.items,
  });
}
