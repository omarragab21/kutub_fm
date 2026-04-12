import 'package:flutter/foundation.dart';
import 'podcast_comment.dart';

@immutable
class PodcastEpisode {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;
  final String duration;
  final String category;
  final int views;
  final List<PodcastComment> comments;

  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
    required this.duration,
    required this.category,
    required this.views,
    this.comments = const [],
  });

  PodcastEpisode copyWith({
    String? id,
    String? title,
    String? description,
    String? audioUrl,
    String? imageUrl,
    String? duration,
    String? category,
    int? views,
    List<PodcastComment>? comments,
  }) {
    return PodcastEpisode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      views: views ?? this.views,
      comments: comments ?? this.comments,
    );
  }
}
