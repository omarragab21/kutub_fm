import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/active_reader.dart';
import '../../domain/entities/reader_comment.dart';
import '../../domain/entities/reader_post.dart';
import '../../data/reader_feed_mock_data.dart';

class ReaderSessionsProvider extends ChangeNotifier {
  ReaderSessionsProvider() {
    unawaited(_initFeed());
  }

  final List<ActiveReader> _activeReaders = [];
  final List<ReaderPost> _posts = [];
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  StreamSubscription<QuerySnapshot>? _usersSubscription;

  bool _isLoading = true;

  List<ActiveReader> get activeReaders => List.unmodifiable(_activeReaders);
  List<ReaderPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  int get activeReadersOverflow =>
      _activeReaders.length > 5 ? _activeReaders.length - 5 : 0;

  Future<void> _initFeed() async {
    _isLoading = true;
    notifyListeners();

    // Seed Firestore with default data if empty
    await _seedUsersIfEmpty();
    await _seedIfEmpty();

    // Listen to real users from Firestore for active readers (limit to 15)
    _listenToActiveReaders();

    // Start listening to live feed updates from Firestore
    listenToPosts();
  }

  void _listenToActiveReaders() {
    _usersSubscription?.cancel();
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .limit(15)
        .snapshots()
        .listen((snapshot) {
      _activeReaders.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'مستخدم كتب FM';
        final photoUrl = data['photoUrl'] ?? 'https://i.pravatar.cc/150?img=65';
        _activeReaders.add(
          ActiveReader(
            id: doc.id,
            name: name,
            avatarUrl: photoUrl,
            isOnline: true,
          ),
        );
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to active readers: $e');
    });
  }

  void listenToPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = FirebaseFirestore.instance
        .collection('reader_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _posts.clear();
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUid = currentUser?.uid;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Deserialize comments
        final commentsData = data['comments'] as List? ?? [];
        final comments = commentsData
            .map((c) => commentFromMap(Map<String, dynamic>.from(c)))
            .toList();

        // Check if liked by current user
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final isLikedByMe = currentUid != null && likedBy.contains(currentUid);

        // Map post type
        final typeStr = data['type'] ?? 'quote';
        ReaderPostType postType = ReaderPostType.quote;
        if (typeStr == 'discussion') {
          postType = ReaderPostType.discussion;
        } else if (typeStr == 'review') {
          postType = ReaderPostType.review;
        }

        // Parse createdAt timestamp
        DateTime createdAt = DateTime.now();
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }

        _posts.add(
          ReaderPost(
            id: doc.id,
            userName: data['userName'] ?? 'مستخدم كتب FM',
            userAvatarUrl: data['userAvatarUrl'] ??
                'https://i.pravatar.cc/150?img=65',
            content: data['content'] ?? '',
            createdAt: createdAt,
            type: postType,
            likeCount: likedBy.length,
            comments: comments,
            bookTitle: data['bookTitle'],
            isLikedByMe: isLikedByMe,
          ),
        );
      }

      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to reader posts: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadFeed() async {
    await _initFeed();
  }

  ReaderPost? findPostById(String postId) {
    for (final post in _posts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  Future<void> toggleLike(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final currentUid = currentUser.uid;

    final docRef =
        FirebaseFirestore.instance.collection('reader_posts').doc(postId);

    // Optimistic local update
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex >= 0) {
      final post = _posts[postIndex];
      final liked = !post.isLikedByMe;
      _posts[postIndex] = post.copyWith(
        isLikedByMe: liked,
        likeCount: liked ? post.likeCount + 1 : post.likeCount - 1,
      );
      notifyListeners();
    }

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
        if (likedBy.contains(currentUid)) {
          await docRef.update({
            'likedBy': FieldValue.arrayRemove([currentUid]),
          });
        } else {
          await docRef.update({
            'likedBy': FieldValue.arrayUnion([currentUid]),
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling like in Firestore: $e');
      listenToPosts();
    }
  }

  Future<Map<String, String>> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'name': 'مستخدم كتب FM',
        'photoUrl': 'https://i.pravatar.cc/150?img=65',
      };
    }

    String name = user.displayName ?? '';
    String photoUrl = user.photoURL ?? '';

    if (name.isEmpty || photoUrl.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (name.isEmpty) {
            name = data?['name'] ?? '';
          }
          if (photoUrl.isEmpty) {
            photoUrl = data?['photoUrl'] ?? '';
          }
        }
      } catch (e) {
        debugPrint('Error getting user profile document: $e');
      }
    }

    if (name.isEmpty) name = 'مستخدم كتب FM';
    if (photoUrl.isEmpty) photoUrl = 'https://i.pravatar.cc/150?img=65';

    return {
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  Future<void> createPost({
    required String content,
    required ReaderPostType type,
    String? bookTitle,
  }) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) return;

    final normalizedBookTitle = bookTitle?.trim();

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'unknown';
    final userProfile = await _getUserProfile();

    try {
      await FirebaseFirestore.instance.collection('reader_posts').add({
        'userName': userProfile['name'],
        'userAvatarUrl': userProfile['photoUrl'],
        'content': normalizedContent,
        'createdAt': FieldValue.serverTimestamp(),
        'type': type.name,
        'likedBy': <String>[],
        'bookTitle': normalizedBookTitle == null || normalizedBookTitle.isEmpty
            ? null
            : normalizedBookTitle,
        'comments': [],
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error creating post in Firestore: $e');
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty) return;

    final userProfile = await _getUserProfile();
    final newCommentId = 'comment_${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'unknown';

    final newComment = ReaderComment(
      id: newCommentId,
      userName: userProfile['name']!,
      userAvatarUrl: userProfile['photoUrl']!,
      content: normalized,
      createdAt: DateTime.now(),
      replies: const [],
    );

    final docRef =
        FirebaseFirestore.instance.collection('reader_posts').doc(postId);

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final commentsData = doc.data()?['comments'] as List? ?? [];
        final comments = commentsData
            .map((c) => commentFromMap(Map<String, dynamic>.from(c)))
            .toList();

        final updatedComments = parentCommentId == null
            ? [newComment, ...comments]
            : _addReply(comments, parentCommentId, newComment);

        final commentsJson =
            updatedComments.map((c) => commentToMap(c)).toList();

        await docRef.update({
          'comments': commentsJson,
        });
      }
    } catch (e) {
      debugPrint('Error adding comment to Firestore: $e');
    }
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

  Map<String, dynamic> commentToMap(ReaderComment comment) {
    return {
      'id': comment.id,
      'userName': comment.userName,
      'userAvatarUrl': comment.userAvatarUrl,
      'content': comment.content,
      'createdAt': comment.createdAt.toIso8601String(),
      'replies': comment.replies.map((reply) => commentToMap(reply)).toList(),
    };
  }

  ReaderComment commentFromMap(Map<String, dynamic> map) {
    DateTime commentCreatedAt = DateTime.now();
    if (map['createdAt'] != null) {
      final parsed = DateTime.tryParse(map['createdAt']);
      if (parsed != null) {
        commentCreatedAt = parsed;
      }
    }

    return ReaderComment(
      id: map['id'] ?? '',
      userName: map['userName'] ?? '',
      userAvatarUrl: map['userAvatarUrl'] ?? '',
      content: map['content'] ?? '',
      createdAt: commentCreatedAt,
      replies: (map['replies'] as List?)
              ?.map((reply) => commentFromMap(Map<String, dynamic>.from(reply)))
              .toList() ??
          const [],
    );
  }

  Future<void> _seedUsersIfEmpty() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(1)
          .get();
      if (usersSnapshot.docs.isEmpty) {
        debugPrint('Firestore users collection is empty. Seeding mock users...');
        final mockReaders = ReaderFeedMockData.buildActiveReaders();
        for (final reader in mockReaders) {
          await FirebaseFirestore.instance.collection('users').doc(reader.id).set({
            'name': reader.name,
            'photoUrl': reader.avatarUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error seeding mock users to Firestore: $e');
    }
  }

  Future<void> _seedIfEmpty() async {
    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('reader_posts')
          .limit(1)
          .get();
      if (postsSnapshot.docs.isEmpty) {
        debugPrint('Firestore reader_posts collection is empty. Seeding mock posts...');
        final mockPosts = ReaderFeedMockData.buildPosts();
        for (final post in mockPosts) {
          final commentsJson = post.comments.map((c) => commentToMap(c)).toList();
          await FirebaseFirestore.instance.collection('reader_posts').add({
            'userName': post.userName,
            'userAvatarUrl': post.userAvatarUrl,
            'content': post.content,
            'createdAt': post.createdAt,
            'type': post.type.name,
            'likedBy': <String>[],
            'bookTitle': post.bookTitle,
            'comments': commentsJson,
            'userId': 'mock_author',
          });
        }
      }
    } catch (e) {
      debugPrint('Error seeding mock posts to Firestore: $e');
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }
}
