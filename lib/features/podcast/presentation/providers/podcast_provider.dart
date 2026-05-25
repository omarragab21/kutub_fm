import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/podcast_mock_data.dart';
import '../../domain/entities/podcast_episode.dart';
import '../../domain/entities/podcast_comment.dart';

class PodcastProvider extends ChangeNotifier {
  List<PodcastEpisode> _episodes = [];
  bool _isLoading = false;
  String? _error;

  List<PodcastEpisode> get episodes => List.unmodifiable(_episodes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  PodcastProvider() {
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Seed podcasts if collection is empty
      await _seedPodcastsIfEmpty();

      // Fetch from Firestore podcasts collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('podcasts')
          .get();

      final docs = querySnapshot.docs.toList();
      // Sort locally by createdAt (descending) to avoid requiring a custom Firestore index
      docs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = aData['createdAt']?.toString() ?? '';
        final bTime = bData['createdAt']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });

      final List<PodcastEpisode> loadedEpisodes = [];
      for (final doc in docs) {
        final data = doc.data();
        
        final commentsRaw = data['comments'] as List<dynamic>? ?? [];
        final comments = commentsRaw
            .map((c) => _mapToComment(Map<String, dynamic>.from(c)))
            .toList();

        loadedEpisodes.add(
          PodcastEpisode(
            id: doc.id,
            title: data['title']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            audioUrl: data['audioUrl']?.toString() ?? '',
            youtubeUrl: data['youtubeUrl']?.toString(),
            imageUrl: data['imageUrl']?.toString() ?? '',
            duration: data['duration']?.toString() ?? '١٠ دقائق',
            category: data['category']?.toString() ?? 'بودكاست',
            views: (data['views'] as num?)?.toInt() ?? 0,
            comments: comments,
          ),
        );
      }
      _episodes = loadedEpisodes;
    } catch (e) {
      _error = 'Failed to load podcasts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _seedPodcastsIfEmpty() async {
    try {
      final collection = FirebaseFirestore.instance.collection('podcasts');
      final snapshot = await collection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final mockEpisodes = PodcastMockData.buildEpisodes();
        for (final episode in mockEpisodes) {
          await collection.doc(episode.id).set({
            'title': episode.title,
            'description': episode.description,
            'audioUrl': episode.audioUrl,
            'youtubeUrl': '',
            'imageUrl': episode.imageUrl,
            'duration': episode.duration,
            'category': episode.category,
            'views': episode.views,
            'createdAt': DateTime.now().toIso8601String(),
            'comments': episode.comments.map((c) => _commentToMap(c)).toList(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error seeding podcasts: $e');
    }
  }

  Map<String, dynamic> _commentToMap(PodcastComment comment) {
    return {
      'id': comment.id,
      'userName': comment.userName,
      'userAvatarUrl': comment.userAvatarUrl,
      'content': comment.content,
      'createdAt': comment.createdAt.toIso8601String(),
      'replies': comment.replies.map((r) => _commentToMap(r)).toList(),
    };
  }

  PodcastComment _mapToComment(Map<String, dynamic> map) {
    final repliesRaw = map['replies'] as List<dynamic>? ?? [];
    return PodcastComment(
      id: map['id']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userAvatarUrl: map['userAvatarUrl']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      replies: repliesRaw
          .map((r) => _mapToComment(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  Future<void> addComment(String episodeId, String content, {String? parentCommentId}) async {
    final index = _episodes.indexWhere((e) => e.id == episodeId);
    if (index == -1) return;

    final newComment = PodcastComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'أنت', // "You" in Arabic
      userAvatarUrl: 'https://i.pravatar.cc/150?img=65',
      content: content,
      createdAt: DateTime.now(),
    );

    final episode = _episodes[index];
    List<PodcastComment> updatedComments;

    if (parentCommentId == null) {
      updatedComments = [newComment, ...episode.comments];
    } else {
      updatedComments = _addReply(episode.comments, parentCommentId, newComment);
    }

    // Optimistic UI update
    _episodes[index] = episode.copyWith(comments: updatedComments);
    notifyListeners();

    try {
      final docRef = FirebaseFirestore.instance.collection('podcasts').doc(episodeId);
      await docRef.update({
        'comments': updatedComments.map((c) => _commentToMap(c)).toList(),
      });
    } catch (e) {
      debugPrint('Failed to save comment to Firestore: $e');
    }
  }

  List<PodcastComment> _addReply(
    List<PodcastComment> comments,
    String parentId,
    PodcastComment newReply,
  ) {
    return comments.map((comment) {
      if (comment.id == parentId) {
        return comment.copyWith(replies: [...comment.replies, newReply]);
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addReply(comment.replies, parentId, newReply),
        );
      }
      return comment;
    }).toList();
  }
}
