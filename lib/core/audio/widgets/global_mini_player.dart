import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_navigation_state.dart';
import '../audio_navigation_helper.dart';
import '../audio_models.dart';
import '../audio_provider.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final navigationState = context.read<AppNavigationState>();
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AudioNavigationHelper.openCurrentPlayingScreen(
          audioProvider: audioProvider,
          navigationState: navigationState,
        ),
        borderRadius: BorderRadius.circular(26),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161615).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _MiniPlayerArtwork(
                        imageUrl: audioProvider.miniPlayerArtworkUrl,
                        mode: audioProvider.currentMode,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              audioProvider.miniPlayerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (audioProvider.isLiveMode) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF35B58),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    audioProvider.miniPlayerSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _MiniPlayerAction(
                        backgroundColor: theme.colorScheme.primary,
                        onTap: () {
                          audioProvider.togglePlayPause();
                        },
                        child: audioProvider.isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : Icon(
                                audioProvider.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 8),
                      _MiniPlayerAction(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        onTap: () {
                          audioProvider.stop();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MiniPlayerProgress(
                    isLive: audioProvider.isLiveMode,
                    isLoading: audioProvider.isLoading,
                    progress: audioProvider.progressValue,
                    accentColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerArtwork extends StatelessWidget {
  const _MiniPlayerArtwork({required this.imageUrl, required this.mode});

  final String? imageUrl;
  final AudioMode mode;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      AudioMode.fmRadio => Icons.radio_rounded,
      AudioMode.readingAudio => Icons.menu_book_rounded,
      AudioMode.audiobook => Icons.headphones_rounded,
      AudioMode.podcast => Icons.mic_external_on_rounded,
      AudioMode.idle => Icons.graphic_eq_rounded,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF2CA50), Color(0xFFD4A73F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) =>
                    Icon(icon, color: Colors.black),
              )
            : Icon(icon, color: Colors.black),
      ),
    );
  }
}

class _MiniPlayerProgress extends StatelessWidget {
  const _MiniPlayerProgress({
    required this.isLive,
    required this.isLoading,
    required this.progress,
    required this.accentColor,
  });

  final bool isLive;
  final bool isLoading;
  final double progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.white.withValues(alpha: 0.08);

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: baseColor),
            if (isLive)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: isLoading ? 0.35 : 1.0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: accentColor),
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: accentColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerAction extends StatelessWidget {
  const _MiniPlayerAction({
    required this.child,
    required this.backgroundColor,
    required this.onTap,
  });

  final Widget child;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 42, height: 42, child: Center(child: child)),
      ),
    );
  }
}
