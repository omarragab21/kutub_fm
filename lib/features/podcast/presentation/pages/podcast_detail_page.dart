import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/podcast_episode.dart';
import '../providers/podcast_provider.dart';
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
    _episode = podcastProvider.getEpisodeById(widget.episodeId) ??
        podcastProvider.allEpisodes.firstWhere(
          (e) => e.id == widget.episodeId,
          orElse: () => podcastProvider.allEpisodes.first,
        );

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
      // Audio MP3: play audio in background using AudioProvider
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
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFC00E))),
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
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFFFC00E),
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

  // --- PREMIUM AUDIO PLAYER UI ---
  Widget _buildAudioPlayerPanel(AudioProvider audioProvider, PodcastEpisode episode) {
    final position = audioProvider.currentPosition;
    final duration = audioProvider.duration;

    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    final authorName = episode.author ?? (episode.programTitle.isNotEmpty ? episode.programTitle : 'عامر واجد');

    return Column(
      children: [
        const SizedBox(height: 16),
        // Centered Album Art / Episode Cover frame
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: const Color(0xFF333333), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.0),
              child: Image.network(
                episode.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2E2E2E),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 80),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Episode Title
        Text(
          episode.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'ThmanyahSans',
          ),
        ),
        const SizedBox(height: 8),

        // Podcast category/tag & author
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC00E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'الموسم ${episode.season} • الحلقة ${episode.episodeNumber}',
                style: const TextStyle(
                  color: Color(0xFFFFC00E),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '•',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(width: 8),
            Text(
              authorName,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontFamily: 'ThmanyahSans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Progress Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFFFFC00E),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: const Color(0xFFFFC00E),
            overlayColor: const Color(0xFFFFC00E).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: progress,
            onChanged: (value) {
              audioProvider.seekTo(value * totalMs / 1000);
            },
          ),
        ),

        // Slider timing text labels (RTL format)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remaining time on the left in RTL
              Text(
                '-${_formatDuration(duration - position)}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
              // Elapsed time on the right in RTL
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Audio Player Controls Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skip backward 10s
            IconButton(
              icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 30),
              onPressed: () {
                audioProvider.seekTo((position.inSeconds - 10).toDouble());
              },
            ),
            const SizedBox(width: 32),

            // Large circular play/pause button
            GestureDetector(
              onTap: audioProvider.togglePlayPause,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFC00E),
                ),
                child: Center(
                  child: audioProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Icon(
                          audioProvider.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 40,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 32),

            // Skip forward 30s
            IconButton(
              icon: const Icon(Icons.forward_30_rounded, color: Colors.white, size: 30),
              onPressed: () {
                audioProvider.seekTo((position.inSeconds + 30).toDouble());
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:${twoDigits(duration.inMinutes.remainder(60))}:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final podcastProvider = context.watch<PodcastProvider>();
    final audioProvider = context.watch<AudioProvider>();

    final episode = podcastProvider.getEpisodeById(widget.episodeId) ??
        podcastProvider.allEpisodes.firstWhere(
          (e) => e.id == widget.episodeId,
          orElse: () => _episode,
        );

    final otherEpisodes = podcastProvider.allEpisodes
        .where((e) => e.id != episode.id)
        .toList();

    // Media header for Video/YouTube vs custom audio page
    final isVideoOrYoutube = _isYoutube || _isVideo;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF090806),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F1F),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 12),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F1F),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                onPressed: () {},
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 12),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1F1F1F),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 18),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isVideoOrYoutube) ...[
                // Video/YouTube Player Header
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: _isYoutube ? YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: const Color(0xFFFFC00E),
                  ) : _buildVideoPlayer(),
                ),
                const SizedBox(height: 20),
                // Titles and detail information
                Text(
                  episode.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  episode.category,
                  style: const TextStyle(
                    color: Color(0xFFFFC00E),
                    fontSize: 12,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Custom Premium Audio Player UI
                _buildAudioPlayerPanel(audioProvider, episode),
              ],

              // Episode Description
              const Text(
                'عن الحلقة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                episode.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'ThmanyahSans',
                ),
              ),
              const SizedBox(height: 32),

              // Comment Section
              CommentSection(
                episodeId: episode.id,
                comments: episode.comments,
              ),

              const SizedBox(height: 32),

              // Other Episodes Section
              if (otherEpisodes.isNotEmpty) ...[
                const Text(
                  'حلقات قد تهمك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: otherEpisodes.length,
                    itemBuilder: (context, index) {
                      final item = otherEpisodes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/podcast_detail',
                            arguments: item.id,
                          );
                        },
                        child: Container(
                          width: 220,
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    color: const Color(0xFF2E2E2E),
                                    child: const Icon(Icons.music_note_rounded, color: Colors.white38),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الموسم ${item.season} • ${item.duration}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFC00E),
                                        fontSize: 10,
                                        fontFamily: 'ThmanyahSans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'ThmanyahSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
