import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_provider.dart';

class PlayControls extends StatelessWidget {
  const PlayControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final theme = Theme.of(context);

    final position = audioProvider.currentPosition;
    final duration = audioProvider.duration;
    
    // Safety check for duration
    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderOverlayShape(overlayRadius: 0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
            trackShape: const RectangularSliderTrackShape(),
            thumbColor: theme.colorScheme.primary,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: progress,
            onChanged: (value) {
              audioProvider.seekTo(value * totalMs / 1000);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Controls Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10),
              color: Colors.white,
              iconSize: 32,
              onPressed: () {
                audioProvider.seekTo((position.inSeconds - 10).toDouble());
              },
            ),
            const SizedBox(width: 32),
            GestureDetector(
              onTap: audioProvider.togglePlayPause,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: audioProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Icon(
                          audioProvider.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 48,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: const Icon(Icons.forward_30),
              color: Colors.white,
              iconSize: 32,
              onPressed: () {
                audioProvider.seekTo((position.inSeconds + 30).toDouble());
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
