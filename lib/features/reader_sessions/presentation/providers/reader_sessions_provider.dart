import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/reader_feed_mock_data.dart';
import '../../domain/entities/active_reader.dart';
import '../../domain/entities/reader_comment.dart';
import '../../domain/entities/reader_post.dart';

class ReaderSessionsProvider extends ChangeNotifier {
  ReaderSessionsProvider() {
    unawaited(loadFeed());
  }

  final List<ActiveReader> _activeReaders = [];
  final List<ReaderPost> _posts = [];

  bool _isLoading = true;
  int _postSequence = 0;
  int _commentSequence = 0;

  List<ActiveReader> get activeReaders => List.unmodifiable(_activeReaders);
  List<ReaderPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  int get activeReadersOverflow =>
      _activeReaders.length > 5 ? _activeReaders.length - 5 : 0;

  Future<void> loadFeed() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 260));
    _activeReaders
      ..clear()
      ..addAll(ReaderFeedMockData.buildActiveReaders());
    _posts
      ..clear()
      ..addAll(ReaderFeedMockData.buildPosts());
    _isLoading = false;
    notifyListeners();
  }

  ReaderPost? findPostById(String postId) {
    for (final post in _posts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  void toggleLike(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index < 0) return;

    final post = _posts[index];
    final liked = !post.isLikedByMe;
    _posts[index] = post.copyWith(
      isLikedByMe: liked,
      likeCount: liked ? post.likeCount + 1 : post.likeCount - 1,
    );
    notifyListeners();
  }

  Future<void> createPost({
    required String content,
    required ReaderPostType type,
    String? bookTitle,
  }) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) return;

    final normalizedBookTitle = bookTitle?.trim();
    _postSequence += 1;
    _posts.insert(
      0,
      ReaderPost(
        id: 'created_post_$_postSequence',
        userName: 'أنت',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=65',
        content: normalizedContent,
        createdAt: DateTime.now(),
        type: type,
        likeCount: 0,
        comments: const [],
        bookTitle: normalizedBookTitle == null || normalizedBookTitle.isEmpty
            ? null
            : normalizedBookTitle,
      ),
    );
    notifyListeners();
  }

  void addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) {
    final normalized = content.trim();
    if (normalized.isEmpty) return;

    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex < 0) return;

    _commentSequence += 1;
    final newComment = ReaderComment(
      id: 'created_comment_$_commentSequence',
      userName: 'أنت',
      userAvatarUrl: 'https://i.pravatar.cc/150?img=65',
      content: normalized,
      createdAt: DateTime.now(),
    );

    final post = _posts[postIndex];
    final updatedComments = parentCommentId == null
        ? [newComment, ...post.comments]
        : _addReply(post.comments, parentCommentId, newComment);

    _posts[postIndex] = post.copyWith(comments: updatedComments);
    notifyListeners();
  }

  String formatTimestamp(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) {
      return 'الآن';
    }
    if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} د';
    }
    if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} س';
    }
    return 'منذ ${difference.inDays} ي';
  }

  List<ReaderComment> _addReply(
    List<ReaderComment> comments,
    String parentCommentId,
    ReaderComment reply,
  ) {
    return comments.map((comment) {
      if (comment.id == parentCommentId) {
        return comment.copyWith(replies: [...comment.replies, reply]);
      }
      if (comment.replies.isEmpty) {
        return comment;
      }
      return comment.copyWith(
        replies: _addReply(comment.replies, parentCommentId, reply),
      );
    }).toList();
  }
}
