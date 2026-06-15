import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../book_reader/presentation/pages/book_reader_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// THEME & CONSTANTS
// ════════════════════════════════════════════════════════════════════════════
class _T {
  static const Color surf = Color(0xFF1C1C1E);
  static const Color gold = AppTheme.primary;
  static const Color mute = AppTheme.onSurfaceVariant;
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  // Waveform heights cache per chapter
  final Map<String, List<double>> _waveformHeights = {};

  List<double> _getHeightsForChapter(String chapterId) {
    if (_waveformHeights.containsKey(chapterId)) {
      return _waveformHeights[chapterId]!;
    }
    // Generate deterministic heights using chapterId hash
    final random = Random(chapterId.hashCode);
    final List<double> heights = List.generate(45, (index) {
      // Create a nice sound wave shape: lower at edges, higher in middle
      final double normalizedIdx = index / 45.0;
      final double bellCurve = sin(normalizedIdx * pi);
      final double noise = 0.2 + 0.8 * random.nextDouble();
      return (bellCurve * noise).clamp(0.15, 1.0);
    });
    _waveformHeights[chapterId] = heights;
    return heights;
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatRemainingTime(Duration elapsed, Duration total) {
    final remaining = total - elapsed;
    if (remaining < Duration.zero) return '00:00';
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '-$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final currentTrack = audioProvider.currentTrack;
    final stories = audioProvider.stories;
    final currentIndex = audioProvider.currentIndex;

    // Use current story/chapter if loaded, otherwise fallback
    final String title = currentTrack?.title ?? 'مئة عام من العزلة';
    final String author = currentTrack?.artist ?? 'أحمد خالد توفيق';
    final String category = currentTrack?.album ?? 'كتاب صوتي';
    final String? coverUrl = currentTrack?.artUri;
    final String chapterId = currentTrack?.id ?? 'default_chapter';

    final isPlaying = audioProvider.isPlaying;
    final duration = audioProvider.duration;
    final position = audioProvider.currentPosition;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final heights = _getHeightsForChapter(chapterId);

    // Find next chapter details
    final hasNext = currentIndex < stories.length - 1;
    final nextStory = hasNext ? stories[currentIndex + 1] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient Background Image (Blurred)
            if (coverUrl != null && coverUrl.isNotEmpty) ...[
              coverUrl.startsWith('assets/')
                  ? Image.asset(coverUrl, fit: BoxFit.cover)
                  : Image.network(coverUrl, fit: BoxFit.cover),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.black.withOpacity(0.85)),
              ),
            ] else ...[
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2C2417), Colors.black],
                  ),
                ),
              ),
            ],

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    // 2. Header: Back button (Chapter badge removed from header)
                    _buildHeader(),
                    const SizedBox(height: 36),

                    // 3. Central Book Cover (Dynamic layout: vertically rectangular with overlapping badge)
                    Expanded(
                      child: Center(
                        child: _buildBookCover(coverUrl, category),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Title & Author details
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: const TextStyle(
                        color: _T.mute,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // 5. Quick Actions Row (Share, Favorite, Download)
                    _buildQuickActions(audioProvider),
                    const SizedBox(height: 28),

                    // 6. Waveform Visualizer
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: WaveformProgressPainter(
                          progress: progress,
                          heights: heights,
                          activeColor: _T.gold,
                          inactiveColor: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 7. Slider & Time Labels
                    _buildProgressBar(audioProvider, progress, position, duration),
                    const SizedBox(height: 20),

                    // 8. Main Controls Row
                    _buildMainControls(audioProvider, isPlaying, currentIndex, stories.length),
                    const SizedBox(height: 36),

                    // 9. Bottom Actions
                    _buildBottomDrawer(context, audioProvider, nextStory),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // ── BOOK COVER ───────────────────────────────────────────────────────────
  Widget _buildBookCover(String? coverUrl, String chapterBadgeText) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 240,
          height: 340,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: _T.gold.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: coverUrl != null && coverUrl.isNotEmpty
                ? (coverUrl.startsWith('assets/')
                    ? Image.asset(coverUrl, fit: BoxFit.cover)
                    : Image.network(coverUrl, fit: BoxFit.cover))
                : Container(
                    color: _T.surf,
                    child: const Icon(Icons.book_rounded, color: _T.gold, size: 60),
                  ),
          ),
        ),
        Positioned(
          top: -16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.gold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _T.gold.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              chapterBadgeText,
              style: const TextStyle(
                color: _T.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────────────────────────────
  Widget _buildQuickActions(AudioProvider audioProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleActionButton(
          icon: Icons.share_outlined,
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم نسخ رابط مشاركة الكتاب')),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildCircleActionButton(
          icon: Icons.favorite_border_rounded, // Simple favorite toggle
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة العمل للمفضلة')),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildCircleActionButton(
          icon: Icons.download_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('بدء تحميل الفصل الصوتي')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCircleActionButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
      ),
    );
  }

  // ── PROGRESS BAR ─────────────────────────────────────────────────────────
  Widget _buildProgressBar(
    AudioProvider audioProvider,
    double progress,
    Duration position,
    Duration duration,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _T.gold,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: _T.gold,
            overlayColor: _T.gold.withOpacity(0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: progress,
            onChanged: (v) {
              final newMs = v * duration.inMilliseconds;
              audioProvider.seekTo(newMs / 1000.0);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(position),
                style: const TextStyle(color: _T.gold, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                _formatRemainingTime(position, duration),
                style: const TextStyle(color: _T.mute, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MAIN CONTROLS ────────────────────────────────────────────────────────
  Widget _buildMainControls(
    AudioProvider audioProvider,
    bool isPlaying,
    int currentIndex,
    int totalStories,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip Previous
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
          onPressed: currentIndex > 0
              ? () {
                  HapticFeedback.lightImpact();
                  audioProvider.selectStory(currentIndex - 1);
                }
              : null,
        ),
        const SizedBox(width: 16),

        // Rewind 10s
        IconButton(
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
          onPressed: () {
            HapticFeedback.lightImpact();
            final newPos = (audioProvider.currentPosition.inSeconds - 10).clamp(0, audioProvider.duration.inSeconds);
            audioProvider.seekTo(newPos.toDouble());
          },
        ),
        const SizedBox(width: 24),

        // Play/Pause (White circle, black icon)
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            audioProvider.togglePlay();
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.white24, blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Forward 10s
        IconButton(
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
          onPressed: () {
            HapticFeedback.lightImpact();
            final newPos = (audioProvider.currentPosition.inSeconds + 10).clamp(0, audioProvider.duration.inSeconds);
            audioProvider.seekTo(newPos.toDouble());
          },
        ),
        const SizedBox(width: 16),

        // Skip Next
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
          onPressed: currentIndex < totalStories - 1
              ? () {
                  HapticFeedback.lightImpact();
                  audioProvider.selectStory(currentIndex + 1);
                }
              : null,
        ),
      ],
    );
  }

  // ── BOTTOM DRAWER & NEXT CHAPTER ──────────────────────────────────────────
  Widget _buildBottomDrawer(
    BuildContext context,
    AudioProvider audioProvider,
    dynamic nextStory,
  ) {
    return Column(
      children: [
        // Show chapters drawer trigger
        GestureDetector(
          onTap: () => _showChaptersBottomSheet(context, audioProvider),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'عرض فصول الكتاب',
                  style: const TextStyle(color: _T.gold, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_left_rounded, color: _T.gold, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Next Chapter Card
        if (nextStory != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                // Chapter Number Indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _T.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${audioProvider.currentIndex + 2}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Next chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفصل التالي',
                        style: const TextStyle(
                          color: _T.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextStory.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Play & Read Buttons (Circular icons with premium borders)
                Row(
                  children: [
                    _buildCircularButton(
                      icon: Icons.play_arrow_rounded,
                      iconColor: _T.gold,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        audioProvider.selectStory(audioProvider.currentIndex + 1);
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildCircularButton(
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.white,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Navigate to reader screen for next chapter
                        Navigator.pushNamed(
                          context,
                          AppRoutes.bookReader,
                          arguments: BookReaderScreenArgs(
                            pdfAssetPath: audioProvider.currentReadingBookId ?? 'miah_aam',
                            bookTitle: nextStory.category,
                            audioUrl: nextStory.audioUrl,
                            chapterId: nextStory.id,
                            bookCoverUrl: nextStory.coverUrl,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }

  // ── CHAPTERS BOTTOM SHEET ────────────────────────────────────────────────
  void _showChaptersBottomSheet(BuildContext context, AudioProvider audioProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF151515),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'فصول الكتاب',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: audioProvider.stories.length,
                    itemBuilder: (context, idx) {
                      final story = audioProvider.stories[idx];
                      final isCurrent = idx == audioProvider.currentIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent ? _T.gold.withOpacity(0.05) : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent ? _T.gold.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent ? _T.gold : Colors.white12,
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                story.title,
                                style: TextStyle(
                                  color: isCurrent ? _T.gold : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isCurrent && audioProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isCurrent ? _T.gold : Colors.white,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (isCurrent) {
                                  audioProvider.togglePlay();
                                } else {
                                  audioProvider.selectStory(idx);
                                }
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// WAVEFORM PAINTER
// ════════════════════════════════════════════════════════════════════════════
class WaveformProgressPainter extends CustomPainter {
  final double progress;
  final List<double> heights;
  final Color activeColor;
  final Color inactiveColor;

  WaveformProgressPainter({
    required this.progress,
    required this.heights,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;
    final double barWidth = size.width / (heights.length * 1.5 - 0.5);
    final double gap = barWidth * 0.5;
    final Paint activePaint = Paint()..color = activeColor..style = PaintingStyle.fill;
    final Paint inactivePaint = Paint()..color = inactiveColor..style = PaintingStyle.fill;

    for (int i = 0; i < heights.length; i++) {
      final double x = i * (barWidth + gap);
      final double barHeight = heights[i] * size.height;
      final double y = (size.height - barHeight) / 2;
      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      final double barProgress = (x + barWidth) / size.width;
      if (barProgress <= progress) {
        canvas.drawRRect(rrect, activePaint);
      } else {
        canvas.drawRRect(rrect, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveformProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.heights != heights;
  }
}
