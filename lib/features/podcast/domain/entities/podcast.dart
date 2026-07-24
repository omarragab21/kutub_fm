import 'package:flutter/foundation.dart';
import 'podcast_episode.dart';

@immutable
class PodcastSeason {
  final String id;
  final String name;
  final int seasonNumber;
  final List<PodcastEpisode> episodes;

  const PodcastSeason({
    required this.id,
    required this.name,
    required this.seasonNumber,
    this.episodes = const [],
  });

  PodcastSeason copyWith({
    String? id,
    String? name,
    int? seasonNumber,
    List<PodcastEpisode>? episodes,
  }) {
    return PodcastSeason(
      id: id ?? this.id,
      name: name ?? this.name,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodes: episodes ?? this.episodes,
    );
  }
}

@immutable
class Podcast {
  final String id;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String? bannerUrl;
  final int totalEpisodes;
  final bool isPopular;
  final int viewsCount;
  final DateTime? createdAt;
  final List<PodcastSeason> seasons;

  const Podcast({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    this.bannerUrl,
    required this.totalEpisodes,
    this.isPopular = false,
    this.viewsCount = 0,
    this.createdAt,
    this.seasons = const [],
  });

  /// Flat list of all episodes across all seasons
  List<PodcastEpisode> get allEpisodes {
    final list = <PodcastEpisode>[];
    for (final season in seasons) {
      list.addAll(season.episodes);
    }
    return List.unmodifiable(list);
  }

  Podcast copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    String? bannerUrl,
    int? totalEpisodes,
    bool? isPopular,
    int? viewsCount,
    DateTime? createdAt,
    List<PodcastSeason>? seasons,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      isPopular: isPopular ?? this.isPopular,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      seasons: seasons ?? this.seasons,
    );
  }
}
