import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_navigation_state.dart';
import '../audio_navigation_helper.dart';
import '../audio_provider.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final navigationState = context.read<AppNavigationState>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AudioNavigationHelper.openCurrentPlayingScreen(
          audioProvider: audioProvider,
          navigationState: navigationState,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.only(top: 10, left: 16, right: 8, bottom: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF040707),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x7F333333),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x59000000),
                blurRadius: 14.90,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  // White close button on the far right
                  _MiniPlayerIconButton(
                    onTap: () => audioProvider.stop(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cover image next to the close button
                  _MiniPlayerArtwork(
                    imageUrl: audioProvider.miniPlayerArtworkUrl,
                  ),
                  const SizedBox(width: 11),
                  // Title and author in the middle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          audioProvider.miniPlayerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Color(0xFFF4F4F4),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'ThmanyahSans',
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          audioProvider.miniPlayerSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'ThmanyahSans',
                            height: 1.50,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play/pause + forward 10 controls on the left
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniPlayerIconButton(
                        onTap: () => audioProvider.togglePlayPause(),
                        child: audioProvider.isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : SvgPicture.asset(
                                audioProvider.isPlaying
                                    ? 'assets/pause.svg'
                                    : 'assets/play.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 24,
                                height: 24,
                              ),
                      ),
                      const SizedBox(width: 8),
                      _MiniPlayerIconButton(
                        onTap: () {
                          final seconds = audioProvider.currentPosition.inSeconds + 10;
                          audioProvider.seekTo(seconds.toDouble());
                        },
                        child: SvgPicture.asset(
                          'assets/forward_10.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MiniPlayerProgress(
                isLive: audioProvider.isLiveMode,
                isLoading: audioProvider.isLoading,
                progress: audioProvider.progressValue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerArtwork extends StatelessWidget {
  const _MiniPlayerArtwork({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1F1F1F),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasUrl
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) =>
                    Image.asset('assets/book.png', fit: BoxFit.cover),
              )
            : Image.asset('assets/book.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _MiniPlayerProgress extends StatelessWidget {
  const _MiniPlayerProgress({
    required this.isLive,
    required this.isLoading,
    required this.progress,
  });

  final bool isLive;
  final bool isLoading;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 4,
        color: Colors.white.withValues(alpha: 0.19),
        child: FractionallySizedBox(
          alignment: Alignment.centerRight,
          widthFactor: isLive ? (isLoading ? 0.35 : 1.0) : progress,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerIconButton extends StatelessWidget {
  const _MiniPlayerIconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 32, height: 32, child: Center(child: child)),
    );
  }
}
