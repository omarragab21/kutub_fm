import 'package:flutter/foundation.dart';
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
      // Simulating API call
      await Future.delayed(const Duration(milliseconds: 800));
      _episodes = PodcastMockData.buildEpisodes();
    } catch (e) {
      _error = 'Failed to load podcasts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addComment(String episodeId, String content, {String? parentCommentId}) {
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

    _episodes[index] = episode.copyWith(comments: updatedComments);
    notifyListeners();
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
