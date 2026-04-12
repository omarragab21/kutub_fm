import 'package:flutter/foundation.dart';

@immutable
class PodcastComment {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final List<PodcastComment> replies;

  const PodcastComment({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  PodcastComment copyWith({
    String? id,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? createdAt,
    List<PodcastComment>? replies,
  }) {
    return PodcastComment(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }
}
