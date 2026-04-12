class ReaderComment {
  const ReaderComment({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  final String id;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final List<ReaderComment> replies;

  int get totalReplyCount {
    var total = replies.length;
    for (final reply in replies) {
      total += reply.totalReplyCount;
    }
    return total;
  }

  ReaderComment copyWith({
    String? id,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? createdAt,
    List<ReaderComment>? replies,
  }) {
    return ReaderComment(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }
}
