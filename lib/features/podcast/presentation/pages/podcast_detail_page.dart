import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/podcast_episode.dart';
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
  late final PodcastEpisode _episode;
  late final bool _isYoutube;
  late final bool _isVideo;

  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlayerInitialized = false;

  @override
  void initState() {
    super.initState();

    final podcastProvider = context.read<PodcastProvider>();
    _episode = podcastProvider.episodes.firstWhere((e) => e.id == widget.episodeId);

    _isYoutube = _episode.youtubeUrl != null && _episode.youtubeUrl!.isNotEmpty;
    _isVideo = !_isYoutube && !_episode.audioUrl.endsWith('.mp3') && _episode.audioUrl.isNotEmpty;

    if (_isYoutube) {
      final videoId = YoutubePlayer.convertUrlToId(_episode.youtubeUrl!);
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId ?? '',
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          isLive: false,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AudioProvider>().stop();
      });
    } else if (_isVideo) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(_episode.audioUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoPlayerInitialized = true;
            });
            _videoPlayerController!.play();
          }
        });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AudioProvider>().stop();
      });
    } else {
      // Audio MP3: play audio in background
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final audioProvider = context.read<AudioProvider>();
        if (audioProvider.currentTrack?.id != _episode.id) {
          audioProvider.playPodcast(_episode);
        }
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoPlayerInitialized || _videoPlayerController == null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoPlayerController!.value.isPlaying) {
            _videoPlayerController!.pause();
          } else {
            _videoPlayerController!.play();
          }
        });
      },
      child: AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoPlayerController!),
            if (!_videoPlayerController!.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoPlayerController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    ThemeData theme,
    PodcastEpisode episode, {
    required bool isVideoOrYoutube,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 24),
        if (!isVideoOrYoutube) ...[
          const PlayControls(),
          const SizedBox(height: 24),
        ],
        Text(
          episode.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        CommentSection(
          episodeId: episode.id,
          comments: episode.comments,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final podcastProvider = context.watch<PodcastProvider>();
    final episode = podcastProvider.episodes.firstWhere(
      (e) => e.id == widget.episodeId,
      orElse: () => _episode,
    );

    // Header widget based on the episode type
    Widget headerMediaWidget;
    if (_isYoutube) {
      headerMediaWidget = YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: theme.colorScheme.primary,
      );
    } else if (_isVideo) {
      headerMediaWidget = _buildVideoPlayer();
    } else {
      // Audio MP3: Show image as a frame
      headerMediaWidget = AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          episode.imageUrl,
          fit: BoxFit.cover,
        ),
      );
    }

    Widget contentScaffold = Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          Stack(
            children: [
              headerMediaWidget,
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildDetailsContent(context, theme, episode, isVideoOrYoutube: _isYoutube || _isVideo),
            ),
          ),
        ],
      ),
    );

    if (_isYoutube) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: theme.colorScheme.primary,
        ),
        builder: (context, player) {
          return contentScaffold;
        },
      );
    }

    return contentScaffold;
  }
}

extension on Widget {
  Widget align(Alignment alignment) => Align(alignment: alignment, child: this);
}


