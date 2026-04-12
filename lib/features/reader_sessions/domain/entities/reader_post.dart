import 'reader_comment.dart';

enum ReaderPostType { quote, discussion, review }

extension ReaderPostTypeUi on ReaderPostType {
  String get label {
    switch (this) {
      case ReaderPostType.quote:
        return 'اقتباس';
      case ReaderPostType.discussion:
        return 'نقاش';
      case ReaderPostType.review:
        return 'مراجعة';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReaderPostType.quote:
        return 'Quote';
      case ReaderPostType.discussion:
        return 'Talk';
      case ReaderPostType.review:
        return 'Review';
    }
  }
}

class ReaderPost {
  const ReaderPost({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
    required this.type,
    required this.likeCount,
    required this.comments,
    this.bookTitle,
    this.isLikedByMe = false,
  });

  final String id;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final ReaderPostType type;
  final int likeCount;
  final List<ReaderComment> comments;
  final String? bookTitle;
  final bool isLikedByMe;

  int get totalCommentCount {
    var total = comments.length;
    for (final comment in comments) {
      total += comment.totalReplyCount;
    }
    return total;
  }

  ReaderPost copyWith({
    String? id,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? createdAt,
    ReaderPostType? type,
    int? likeCount,
    List<ReaderComment>? comments,
    Object? bookTitle = _unset,
    bool? isLikedByMe,
  }) {
    return ReaderPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      likeCount: likeCount ?? this.likeCount,
      comments: comments ?? this.comments,
      bookTitle: identical(bookTitle, _unset)
          ? this.bookTitle
          : bookTitle as String?,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }

  static const Object _unset = Object();
}
