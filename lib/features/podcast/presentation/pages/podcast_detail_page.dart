import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/podcast_provider.dart';
import '../widgets/play_controls.dart';
import '../widgets/comment_section.dart';
import '../../../../core/audio/audio_provider.dart';

class PodcastDetailPage extends StatefulWidget {
  final String episodeId;

  const PodcastDetailPage({super.key, required this.episodeId});

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final podcastProvider = context.read<PodcastProvider>();
      final audioProvider = context.read<AudioProvider>();
      
      final episode = podcastProvider.episodes.firstWhere((e) => e.id == widget.episodeId);
      
      // Auto-play the podcast if it's not already playing this episode
      if (audioProvider.currentTrack?.id != episode.id) {
        audioProvider.playPodcast(episode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podcastProvider = context.watch<PodcastProvider>();
    final episode = podcastProvider.episodes.firstWhere(
      (e) => e.id == widget.episodeId,
      orElse: () => podcastProvider.episodes.first,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Immersive Header
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    episode.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          theme.colorScheme.surface.withValues(alpha: 0.8),
                          theme.colorScheme.surface,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Metadata
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    episode.category,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).align(Alignment.centerRight),
                const SizedBox(height: 16),
                Text(
                  episode.title,
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.headset_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${episode.views} شخص يستمعون الآن',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  episode.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Playback Controls
                const PlayControls(),
                const SizedBox(height: 60),
                
                // Social Layer
                CommentSection(
                  episodeId: episode.id,
                  comments: episode.comments,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget align(Alignment alignment) => Align(alignment: alignment, child: this);
}
