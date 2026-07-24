import 'package:flutter/foundation.dart';
import 'podcast_comment.dart';

@immutable
class PodcastEpisode {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String? youtubeUrl;
  final String imageUrl;
  final String duration;
  final String category;
  final int views;
  final String programTitle;
  final String? programId;
  final String? author;
  final int season;
  final int episodeNumber;
  final String? publishedAgo;
  final bool isTrending;
  final DateTime? publishedAt;
  final List<PodcastComment> comments;

  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.youtubeUrl,
    required this.imageUrl,
    required this.duration,
    required this.category,
    required this.views,
    this.programTitle = '',
    this.programId,
    this.author,
    this.season = 1,
    this.episodeNumber = 1,
    this.publishedAgo,
    this.isTrending = false,
    this.publishedAt,
    this.comments = const [],
  });

  PodcastEpisode copyWith({
    String? id,
    String? title,
    String? description,
    String? audioUrl,
    String? youtubeUrl,
    String? imageUrl,
    String? duration,
    String? category,
    int? views,
    String? programTitle,
    String? programId,
    String? author,
    int? season,
    int? episodeNumber,
    String? publishedAgo,
    bool? isTrending,
    DateTime? publishedAt,
    List<PodcastComment>? comments,
  }) {
    return PodcastEpisode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      views: views ?? this.views,
      programTitle: programTitle ?? this.programTitle,
      programId: programId ?? this.programId,
      author: author ?? this.author,
      season: season ?? this.season,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      publishedAgo: publishedAgo ?? this.publishedAgo,
      isTrending: isTrending ?? this.isTrending,
      publishedAt: publishedAt ?? this.publishedAt,
      comments: comments ?? this.comments,
    );
  }
}

