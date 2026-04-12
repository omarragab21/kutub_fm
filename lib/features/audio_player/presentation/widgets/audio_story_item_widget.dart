import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/audio_story.dart';
import '../pages/transcript_reader_screen.dart';
import 'floating_book_cover.dart';
import 'audio_waveform_visualizer.dart';

class AudioStoryItemWidget extends StatelessWidget {
  final AudioStory story;
  final AudioProvider viewModel;
  final bool isCurrentStory;

  const AudioStoryItemWidget({
    super.key,
    required this.story,
    required this.viewModel,
    required this.isCurrentStory,
  });

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = isCurrentStory ? viewModel.currentPositionSeconds : 0;
    final isPlaying = isCurrentStory && viewModel.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black, // Darkest base
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Ambient Background
          Image.network(
            story.coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2C2417), Color(0xFF090806)],
                  ),
                ),
              );
            },
          ),
          // Blur the image heavily
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: AppTheme.background.withValues(
                alpha: 0.85,
              ), // Noir-Gold mix
            ),
          ),

          // Layer 2 & 3: Floating Cover and Waveform
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Floating Cover
                FloatingBookCover(
                  imageUrl: story.coverUrl,
                  isPlaying: isPlaying,
                ),

                const SizedBox(height: 48),

                // Audio Pulse Waveform
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AudioWaveformVisualizer(isPlaying: isPlaying),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),

          // Layer 4: Interactive Glass UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, // RTL orientation
                children: [
                  // Top Nav with glassmorphism
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: -5,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              story.category,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            _buildGlassIconButton(
                              icon: Icons.text_snippet_outlined,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) =>
                                      const TranscriptReaderScreen(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Section Split
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 16),

                      // Left Info + Controls
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end, // RTL
                          children: [
                            Text(
                              story.title,
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 32,
                                    color: AppTheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              story.author,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              story.description,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Playback Controls
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15,
                                    sigmaY: 15,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.05),
                                          Colors.white.withValues(alpha: 0.02),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      children: [
                                        // Progress Bar Slider
                                        SliderTheme(
                                          data: SliderTheme.of(context)
                                              .copyWith(
                                                activeTrackColor:
                                                    AppTheme.primary,
                                                inactiveTrackColor:
                                                    Colors.white24,
                                                thumbColor: AppTheme.primary,
                                                overlayColor: AppTheme.primary
                                                    .withValues(alpha: 0.2),
                                                trackHeight: 4,
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 6,
                                                    ),
                                              ),
                                          child: Slider(
                                            value: progress.toDouble(),
                                            min: 0,
                                            max:
                                                viewModel.totalDurationSeconds
                                                        .toDouble() >
                                                    0
                                                ? viewModel.totalDurationSeconds
                                                      .toDouble()
                                                : 1.0,
                                            onChanged: isCurrentStory
                                                ? (val) => viewModel.seekTo(val)
                                                : null,
                                          ),
                                        ),
                                        // Time Text
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(progress),
                                              style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(
                                                viewModel.totalDurationSeconds,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Play Pause Middle Control
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildGlassIconButton(
                                              icon: Icons.replay_10,
                                              onPressed: () {
                                                viewModel.seekTo(
                                                  (progress - 10)
                                                      .clamp(
                                                        0,
                                                        viewModel
                                                            .totalDurationSeconds,
                                                      )
                                                      .toDouble(),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 16),
                                            GestureDetector(
                                              onTap: isCurrentStory
                                                  ? () {
                                                      HapticFeedback.mediumImpact();
                                                      viewModel.togglePlay();
                                                    }
                                                  : null,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    if (isPlaying)
                                                      BoxShadow(
                                                        color: AppTheme.primary
                                                            .withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        blurRadius: 20,
                                                        spreadRadius: 2,
                                                      ),
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  transitionBuilder:
                                                      (child, animation) {
                                                        return ScaleTransition(
                                                          scale: animation,
                                                          child: child,
                                                        );
                                                      },
                                                  child: Icon(
                                                    isPlaying
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                              .play_arrow_rounded,
                                                    key: ValueKey(isPlaying),
                                                    color: Colors.black,
                                                    size: 32,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            _buildGlassIconButton(
                                              icon: Icons.forward_10,
                                              onPressed: () {
                                                viewModel.seekTo(
                                                  (progress + 10)
                                                      .clamp(
                                                        0,
                                                        viewModel
                                                            .totalDurationSeconds,
                                                      )
                                                      .toDouble(),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white70,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onPressed();
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    child: IconButton(
                      icon: Icon(icon, color: color, size: 24),
                      onPressed: null, // Handled by InkWell
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
