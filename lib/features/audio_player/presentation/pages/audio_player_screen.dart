import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';
import 'package:kutub_fm/features/book_details/domain/entities/book_detail_model.dart';
import 'package:kutub_fm/features/book_reader/presentation/pages/book_reader_screen.dart';
import 'package:provider/provider.dart';
import 'package:kutub_fm/core/audio/audio_provider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String? bookId;
  final String? bookTitle;
  final String? authorName;
  final String? coverUrl;
  final String? pdfUrl;
  final List<Chapter> chapters;
  final String? initialChapterId;

  const AudioPlayerScreen({
    super.key,
    this.bookId,
    this.bookTitle,
    this.authorName,
    this.coverUrl,
    this.pdfUrl,
    this.chapters = const [],
    this.initialChapterId,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  int _currentChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.chapters.isNotEmpty) {
      final initialIndex = widget.chapters.indexWhere(
        (ch) => ch.id == widget.initialChapterId,
      );
      if (initialIndex != -1) {
        _currentChapterIndex = initialIndex;
      } else {
        final firstAudioIndex = widget.chapters.indexWhere((ch) => ch.hasAudioUrl);
        if (firstAudioIndex != -1) {
          _currentChapterIndex = firstAudioIndex;
        }
      }
    }
    _loadAudioIfNeeded();
  }

  void _loadAudioIfNeeded() {
    final bookId = widget.bookId;
    if (bookId == null || bookId.isEmpty || widget.chapters.isEmpty) return;

    final audio = context.read<AudioProvider>();
    final currentBookId = audio.currentBookId;
    final currentTrack = audio.currentTrack;
    // Don't reload if this book's audio is already the active track.
    if (currentBookId == bookId && currentTrack != null) return;

    final chapter = widget.chapters[_currentChapterIndex];
    if (!chapter.hasAudioUrl) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      audio.playChapterAudio(
        bookId: bookId,
        chapter: chapter,
        chapters: widget.chapters,
        bookTitle: widget.bookTitle ?? '',
        bookCoverUrl: widget.coverUrl,
        author: widget.authorName,
        autoplay: false,
      );
    });
  }

  void _playCurrentChapter() {
    final bookId = widget.bookId;
    if (bookId == null || bookId.isEmpty || widget.chapters.isEmpty) return;
    final chapter = widget.chapters[_currentChapterIndex];
    if (!chapter.hasAudioUrl) return;

    context.read<AudioProvider>().playChapterAudio(
      bookId: bookId,
      chapter: chapter,
      chapters: widget.chapters,
      bookTitle: widget.bookTitle ?? '',
      bookCoverUrl: widget.coverUrl,
      author: widget.authorName,
      autoplay: true,
    );
  }

  void _onTogglePlayPause() {
    final audio = context.read<AudioProvider>();
    if (audio.currentBookId == widget.bookId && audio.state.hasSource) {
      audio.togglePlayPause();
      return;
    }
    _playCurrentChapter();
  }

  void _seekRelative(int seconds) {
    final audio = context.read<AudioProvider>();
    if (audio.currentBookId != widget.bookId || !audio.state.canSeek) return;
    final newPosition = audio.currentPosition + Duration(seconds: seconds);
    final clamped = newPosition < Duration.zero
        ? Duration.zero
        : (newPosition > audio.duration ? audio.duration : newPosition);
    audio.seekTo(clamped.inMilliseconds / 1000.0);
  }

  void _changeChapter(int delta) {
    if (widget.chapters.isEmpty) return;
    final newIndex = _currentChapterIndex + delta;
    if (newIndex < 0 || newIndex >= widget.chapters.length) return;
    setState(() => _currentChapterIndex = newIndex);
    _playCurrentChapter();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final isPlaying = audio.isPlaying && audio.currentBookId == widget.bookId;
    final progress = audio.progressValue;

    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C0C),
        body: SafeArea(
          child: Stack(
            children: [
              // Main player content (scrolls above the sheet)
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Bar (Aligned to top-left to follow Figma design layout)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/arrow_back.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // Cover Image
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final bookId = widget.bookId;
                      if (bookId != null && bookId.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.bookDetails,
                          arguments: bookId,
                        );
                      }
                    },
                    child: Container(
                      width: 220,
                      height: 309,
                      margin: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        image: DecorationImage(
                          image: widget.coverUrl != null && widget.coverUrl!.isNotEmpty
                              ? NetworkImage(widget.coverUrl!)
                              : const AssetImage('assets/miah_aam_cover.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                // Title and Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          final bookId = widget.bookId;
                          if (bookId != null && bookId.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.bookDetails,
                              arguments: bookId,
                            );
                          }
                        },
                        child: Text(
                          widget.bookTitle ?? 'مئة عام من العزلة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final bookId = widget.bookId;
                          if (bookId != null && bookId.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.bookDetails,
                              arguments: bookId,
                            );
                          }
                        },
                        child: Text(
                          widget.authorName ?? 'أحمد خالد توفيق',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Soundwave
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(40, (index) {
                          final threshold = (progress * 40).round();
                          final isPlayed = index < threshold;
                          final height =
                              10.0 + (index % 5) * 5.0 + (index % 3) * 8.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4,
                            height: height > 35 ? 35 : height,
                            decoration: BoxDecoration(
                              color: isPlayed
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // Timers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(audio.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(audio.currentPosition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Media Controls (Wrapped in LTR to ensure exact left-to-right alignment and chevron orientations)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => _changeChapter(-1),
                              child: SvgPicture.asset(
                                'assets/backward.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 35,
                                height: 35,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _seekRelative(-10),
                              child: SvgPicture.asset(
                                'assets/replay_10.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 30,
                                height: 30,
                              ),
                            ),
                            GestureDetector(
                              onTap: _onTogglePlayPause,
                              child: SvgPicture.asset(
                                isPlaying
                                    ? 'assets/pause_circle.svg'
                                    : 'assets/play_circle.svg',
                                width: 70,
                                height: 70,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _seekRelative(10),
                              child: SvgPicture.asset(
                                'assets/forward_10.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 30,
                                height: 30,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _changeChapter(1),
                              child: SvgPicture.asset(
                                'assets/forward.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                width: 35,
                                height: 35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Bottom padding so content stays above the collapsed sheet
                      SizedBox(height: screenHeight * 0.22),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Draggable chapters sheet
          DraggableScrollableSheet(
                initialChildSize: 0.18,
                minChildSize: 0.18,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0C0C),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'فصول الكتاب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'الفصل التالي',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SvgPicture.asset(
                                  'assets/arrow_back.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white54,
                                    BlendMode.srcIn,
                                  ),
                                  width: 16,
                                  height: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Preview / chapter list
                        if (widget.chapters.isEmpty) ...[
                          _buildChapterItemStatic(
                            'الفصل الأول',
                            '45 دقيقة',
                            '1',
                            false,
                          ),
                          const SizedBox(height: 12),
                          _buildChapterItemStatic(
                            'الفصل الثاني',
                            '50 دقيقة',
                            '2',
                            false,
                          ),
                          const SizedBox(height: 12),
                          _buildChapterItemStatic(
                            'الفصل الثالث',
                            '40 دقيقة',
                            '3',
                            true,
                          ),
                          const SizedBox(height: 12),
                          _buildChapterItemStatic(
                            'الفصل الرابع',
                            '55 دقيقة',
                            '4',
                            false,
                          ),
                          const SizedBox(height: 12),
                          _buildChapterItemStatic(
                            'الفصل الخامس',
                            '35 دقيقة',
                            '5',
                            false,
                          ),
                          const SizedBox(height: 12),
                          _buildChapterItemStatic(
                            'الفصل السادس',
                            '60 دقيقة',
                            '6',
                            false,
                          ),
                        ] else
                          ...widget.chapters.asMap().entries.expand((entry) {
                            final chapter = entry.value;
                            final isPlaying = entry.key == _currentChapterIndex;
                            return [
                              _buildChapterItem(chapter, isPlaying),
                              if (entry.key != widget.chapters.length - 1)
                                const SizedBox(height: 12),
                            ];
                          }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.abs();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _playChapter(Chapter chapter) {
    final index = widget.chapters.indexWhere((ch) => ch.id == chapter.id);
    if (index != -1) {
      setState(() => _currentChapterIndex = index);
    }
    _playCurrentChapter();
  }

  void _openReader(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.bookReader),
        builder: (_) => BookReaderScreen(
          bookId: widget.bookId ?? '',
          chapterId: chapter.id,
          pdfUrl: widget.pdfUrl,
          startPage: chapter.startPage,
          endPage: chapter.endPage,
          bookTitle: widget.bookTitle ?? '',
          chapterTitle: chapter.title,
          audioUrl: chapter.audioUrl,
          transcription: chapter.transcription,
          chapters: widget.chapters,
        ),
      ),
    );
  }

  Widget _buildChapterItem(Chapter chapter, bool isPlaying) {
    return Opacity(
      opacity: isPlaying ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            // Left side: Buttons (Play/Pause + Read Book)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _playChapter(chapter),
                  child: isPlaying
                      ? SvgPicture.asset(
                          'assets/pause.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/play.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white54,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _openReader(chapter),
                  child: SvgPicture.asset(
                    'assets/nav_books.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white54,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Middle side: Chapter Title and duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chapter.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chapter.duration,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Right side: Index circle or Audio Wave
            if (isPlaying)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/audio_wave.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF333333), width: 1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    chapter.orderIndex.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterItemStatic(
    String title,
    String duration,
    String index,
    bool isPlaying,
  ) {
    return Opacity(
      opacity: isPlaying ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            // Left side: Buttons (Play/Pause + Read Book)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: isPlaying
                      ? SvgPicture.asset(
                          'assets/pause.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/play.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white54,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookReaderScreen(),
                      ),
                    );
                  },
                  child: SvgPicture.asset(
                    'assets/nav_books.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white54,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Middle side: Chapter Title and duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                    fontFamily: 'ThmanyahSans',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Right side: Index circle or Audio Wave
            if (isPlaying)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/audio_wave.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF333333), width: 1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    index,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
