import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/audio/audio_provider.dart';
import '../../../../core/audio/audio_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transcript_segment.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _BookTheme {
  // Page feel
  static const Color pageBg = Color(0xFF0E0A05); // Very dark warm black
  static const Color cardBg = Color(0xFF1A1410); // Warm dark surface
  static const Color accent = AppTheme.primary; // Gold

  // Typography colors
  static const Color titleColor = Color(0xFFE8D5A3); // Warm parchment gold
  static const Color metaColor = Color(0xFFB8A87A); // Muted gold
  static const Color labelColor = Color(0xFF8A7A58); // Dimmed label
  static const Color bodyColor = Color(0xFFD4C9AA); // Warm reading white
  static const Color bodyMuted = Color(0xFF9A8E72); // Secondary body
  static const Color dialogColor = Color(0xFFE6D8B8); // Dialogue highlight
  static const Color dividerColor = Color(0xFF3A3020); // Warm divider

  // Ornamental separators
  static const String ornament = '❧';
  static const String ornamentDash = '— ❧ —';
}

// ════════════════════════════════════════════════════════════════════════════
// ENTRY WIDGET
// ════════════════════════════════════════════════════════════════════════════
class BookReaderScreen extends StatefulWidget {
  final String pdfAssetPath; // Kept for route compat; ignored internally
  final String bookTitle;

  const BookReaderScreen({
    super.key,
    required this.pdfAssetPath,
    required this.bookTitle,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class BookReaderScreenArgs {
  const BookReaderScreenArgs({
    required this.pdfAssetPath,
    required this.bookTitle,
  });

  final String pdfAssetPath;
  final String bookTitle;
}

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════
class _BookReaderScreenState extends State<BookReaderScreen>
    with TickerProviderStateMixin {
  // ── Audio ──────────────────────────────────────────────────────────────
  bool _isSeeking = false;
  Duration? _previewPosition;

  // ── Transcript ─────────────────────────────────────────────────────────
  TranscriptDocument? _doc;
  bool _isLoading = true;
  String? _error;
  int _activeIndex = -1;
  final List<GlobalKey> _segmentKeys = [];

  // ── Scroll ─────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── Controls ───────────────────────────────────────────────────────────
  bool _controlsVisible = true;
  Timer? _hideTimer;

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _fadeIn;
  late AnimationController _pulseCtr;

  // =========================================================================
  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtr = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadTranscript();
    if (mounted) _fadeIn.forward();
  }

  // ── Transcript loading ─────────────────────────────────────────────────
  Future<void> _loadTranscript() async {
    try {
      final raw = await rootBundle.loadString('assets/transcript.json');
      final doc = TranscriptDocument.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _segmentKeys
          ..clear()
          ..addAll(List.generate(doc.segments.length, (_) => GlobalKey()));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _syncActive(double sec) {
    final segs = _doc?.segments;
    if (segs == null) return;
    int found = -1;
    for (int i = 0; i < segs.length; i++) {
      if (sec >= segs[i].start && sec < segs[i].end) {
        found = i;
        break;
      }
    }
    if (found != _activeIndex) {
      setState(() => _activeIndex = found);
      if (found >= 0) _scrollToActive(found);
    }
  }

  void _scrollToActive(int idx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _segmentKeys[idx].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOut,
        alignment: 0.35,
      );
    });
  }

  // ── Controls ───────────────────────────────────────────────────────────
  void _togglePlay() {
    final audioProvider = context.read<AudioProvider>();
    HapticFeedback.lightImpact();
    if (_isCurrentReadingAudio(audioProvider)) {
      audioProvider.togglePlay();
    } else {
      unawaited(
        audioProvider.playReadingAudio(
          bookId: _readingBookId,
          title: widget.bookTitle,
          autoplay: true,
        ),
      );
    }
    _resetTimer();
  }

  void _seekTo(double sec) {
    final audioProvider = context.read<AudioProvider>();
    if (_isCurrentReadingAudio(audioProvider)) {
      audioProvider.seekTo(sec);
    } else {
      unawaited(
        audioProvider.playReadingAudio(
          bookId: _readingBookId,
          title: widget.bookTitle,
          autoplay: false,
          initialPosition: Duration(milliseconds: (sec * 1000).round()),
        ),
      );
    }
    _resetTimer();
  }

  void _seekBySegment(int idx) {
    final audioProvider = context.read<AudioProvider>();
    final seg = _doc?.segments[idx];
    if (seg == null) return;
    HapticFeedback.selectionClick();
    unawaited(
      audioProvider.playReadingAudio(
        bookId: _readingBookId,
        title: widget.bookTitle,
        autoplay: true,
        initialPosition: Duration(milliseconds: (seg.start * 1000).round()),
      ),
    );
  }

  void _skip(int delta, Duration position, Duration duration) {
    final next = position + Duration(seconds: delta);
    _seekTo(next.inSeconds.clamp(0, duration.inSeconds).toDouble());
  }

  Future<void> _cycleSpeed() async {
    await context.read<AudioProvider>().cycleSpokenWordSpeed();
    _resetTimer();
  }

  void _resetTimer() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final audioProvider = context.read<AudioProvider>();
      if (_isCurrentReadingAudio(audioProvider) && audioProvider.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _onTap() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _resetTimer();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _readingBookId =>
      widget.pdfAssetPath.isNotEmpty ? widget.pdfAssetPath : widget.bookTitle;

  bool _isCurrentReadingAudio(AudioProvider audioProvider) {
    return audioProvider.currentMode == AudioMode.readingAudio &&
        audioProvider.isActiveReadingBook(_readingBookId);
  }

  bool _isArabic(String t) => RegExp(r'[\u0600-\u06FF]').hasMatch(t);

  // =========================================================================
  @override
  void dispose() {
    _scrollController.dispose();
    _fadeIn.dispose();
    _pulseCtr.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isCurrentReadingAudio(audioProvider)) {
        _syncActive(audioProvider.currentPosition.inMilliseconds / 1000.0);
      } else if (_activeIndex != -1) {
        setState(() => _activeIndex = -1);
      }
    });

    return Scaffold(
      backgroundColor: _BookTheme.pageBg,
      body: _isLoading
          ? _loadingView()
          : _error != null
          ? _errorView()
          : _doc!.isEmpty
          ? _emptyView()
          : _mainView(),
    );
  }

  // ── State views ────────────────────────────────────────────────────────
  Widget _loadingView() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: _BookTheme.titleColor,
            strokeWidth: 1.5,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'جاري تهيئة الكتاب…',
          style: TextStyle(color: _BookTheme.labelColor, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _errorView() {
    log(_error!);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              color: _BookTheme.labelColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _BookTheme.bodyMuted),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadAll();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _BookTheme.accent),
                foregroundColor: _BookTheme.accent,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() => const Center(
    child: Text('النص فارغ', style: TextStyle(color: _BookTheme.labelColor)),
  );

  // ── Main layout ────────────────────────────────────────────────────────
  Widget _mainView() {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Page content (scroll)
          FadeTransition(opacity: _fadeIn, child: _bookPageScroll()),

          // Top navigation bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            top: _controlsVisible ? 0 : -110,
            left: 0,
            right: 0,
            child: _topBar(),
          ),

          // Bottom audio player
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            bottom: _controlsVisible ? 0 : -220,
            left: 0,
            right: 0,
            child: _audioControls(),
          ),
        ],
      ),
    );
  }

  // ── Book page scroll ───────────────────────────────────────────────────
  Widget _bookPageScroll() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Space for top bar
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.top + 80),
        ),

        // ── Book title page ──────────────────────────────────────────
        SliverToBoxAdapter(child: _bookTitlePage()),

        // ── Ornamental chapter break ─────────────────────────────────
        SliverToBoxAdapter(child: _chapterBreak()),

        // ── Body text ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _segmentTile(i, _doc!.segments[i]),
              childCount: _doc!.segments.length,
            ),
          ),
        ),

        // Bottom padding for audio player
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 240),
        ),
      ],
    );
  }

  // ── Book title page ────────────────────────────────────────────────────
  Widget _bookTitlePage() {
    final meta = _doc!.metadata;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Publisher label
          if (meta.publisher.isNotEmpty)
            Text(
              meta.publisher,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: _BookTheme.labelColor,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),

          const SizedBox(height: 28),

          // Top thin rule
          _thinRule(),

          const SizedBox(height: 32),

          // ── Title ──────────────────────────────────────────────────
          Text(
            meta.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: _BookTheme.titleColor,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Genre badge
          if (meta.genre.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _BookTheme.accent.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                meta.genre,
                style: GoogleFonts.amiri(
                  color: _BookTheme.accent.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 36),

          // ── Author block ────────────────────────────────────────────
          if (meta.author.isNotEmpty) ...[
            _metaLabel('بقلم'),
            const SizedBox(height: 6),
            Text(
              meta.author,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: _BookTheme.metaColor,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Light divider
          Row(
            children: [
              Expanded(
                child: Container(height: 0.5, color: _BookTheme.dividerColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _BookTheme.ornament,
                  style: TextStyle(
                    color: _BookTheme.accent.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 0.5, color: _BookTheme.dividerColor),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Translator block ────────────────────────────────────────
          if (meta.translator.isNotEmpty) ...[
            _metaLabel('ترجمة'),
            const SizedBox(height: 6),
            Text(
              meta.translator,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: _BookTheme.metaColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Narrator block ──────────────────────────────────────────
          if (meta.narrator.isNotEmpty) ...[
            _metaLabel('يقرأها عليكم'),
            const SizedBox(height: 6),
            Text(
              meta.narrator,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: _BookTheme.metaColor,
                fontSize: 18,
              ),
            ),
          ],

          const SizedBox(height: 40),
          _thinRule(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Chapter ornamental break ───────────────────────────────────────────
  Widget _chapterBreak() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Column(
        children: [
          Text(
            _BookTheme.ornamentDash,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookTheme.accent.withValues(alpha: 0.45),
              fontSize: 18,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Segment tile (body text) ───────────────────────────────────────────
  Widget _segmentTile(int index, TranscriptSegment seg) {
    final isActive = index == _activeIndex;
    final isArabic = _isArabic(seg.text);

    // Determine inline style based on type and active state
    Color textColor;
    FontWeight fontWeight;
    Color? highlightBg;
    double fontSize = isArabic ? 20 : 16.5;

    if (isActive) {
      textColor = Colors.black;
      fontWeight = FontWeight.w600;
      highlightBg = _BookTheme.accent;
      fontSize = isArabic ? 21 : 17;
    } else {
      switch (seg.type) {
        case TranscriptSegmentType.bold:
          textColor = _BookTheme.bodyColor;
          fontWeight = FontWeight.bold;
          highlightBg = null;
          break;
        case TranscriptSegmentType.highlight:
          // Dialogue: warmer, slightly brighter
          textColor = _BookTheme.dialogColor;
          fontWeight = FontWeight.w500;
          highlightBg = null;
          break;
        default:
          textColor = _BookTheme.bodyColor.withValues(alpha: 0.82);
          fontWeight = FontWeight.normal;
          highlightBg = null;
      }
    }

    final style = isArabic
        ? GoogleFonts.amiri(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.75,
          )
        : GoogleFonts.crimsonPro(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.65,
          );

    Widget textWidget = Text(
      seg.text,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      style: style,
    );

    return GestureDetector(
      key: _segmentKeys[index],
      onTap: () => _seekBySegment(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: _segmentBottomSpacing(seg, index)),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : EdgeInsets.zero,
        decoration: isActive
            ? BoxDecoration(
                color: highlightBg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _BookTheme.accent.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ],
              )
            : null,
        child: textWidget,
      ),
    );
  }

  /// Computes bottom spacing that groups segments into natural paragraphs.
  double _segmentBottomSpacing(TranscriptSegment seg, int index) {
    final segments = _doc!.segments;
    if (index >= segments.length - 1) return 0;
    final next = segments[index + 1];
    final timeDiff = next.start - seg.end;
    if (timeDiff > 1.5) {
      return 18;
    }
    if (seg.type == TranscriptSegmentType.bold ||
        seg.type == TranscriptSegmentType.highlight) {
      return 3;
    }
    return 1;
  }

  // ── Top bar ────────────────────────────────────────────────────────────
  Widget _topBar() {
    final audioProvider = context.watch<AudioProvider>();

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 4,
        right: 12,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_BookTheme.pageBg, _BookTheme.pageBg.withValues(alpha: 0)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _BookTheme.metaColor,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _doc?.metadata.title ?? widget.bookTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.amiri(
                color: _BookTheme.titleColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Speed badge
          GestureDetector(
            onTap: _cycleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _BookTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _BookTheme.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '${audioProvider.spokenWordSpeed}x',
                style: const TextStyle(
                  color: _BookTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Audio controls ─────────────────────────────────────────────────────
  Widget _audioControls() {
    final audioProvider = context.watch<AudioProvider>();
    final isCurrentReading = _isCurrentReadingAudio(audioProvider);
    final effectiveDuration = isCurrentReading
        ? audioProvider.duration
        : Duration.zero;
    final effectivePosition = _isSeeking && _previewPosition != null
        ? _previewPosition!
        : (isCurrentReading ? audioProvider.currentPosition : Duration.zero);
    final isPlaying = isCurrentReading && audioProvider.isPlaying;
    final posSec = effectivePosition.inMilliseconds / 1000.0;
    final durSec = effectiveDuration.inMilliseconds > 0
        ? effectiveDuration.inMilliseconds / 1000.0
        : 1.0;
    final progress = effectiveDuration.inMilliseconds > 0
        ? (posSec / durSec).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _BookTheme.pageBg,
            _BookTheme.pageBg.withValues(alpha: 0.96),
            _BookTheme.pageBg.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.72, 1.0],
        ),
        border: Border(
          top: BorderSide(
            color: _BookTheme.dividerColor.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Slim progress bar ──────────────────────────────────────
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _BookTheme.accent,
              inactiveTrackColor: _BookTheme.dividerColor,
              thumbColor: _BookTheme.accent,
              overlayColor: _BookTheme.accent.withValues(alpha: 0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: progress,
              onChangeStart: (_) => setState(() => _isSeeking = true),
              onChanged: (v) => setState(
                () => _previewPosition = Duration(
                  milliseconds: (v * durSec * 1000).round(),
                ),
              ),
              onChangeEnd: (v) {
                setState(() {
                  _isSeeking = false;
                  _previewPosition = null;
                });
                _seekTo(v * durSec);
              },
            ),
          ),

          // ── Time labels ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(effectivePosition),
                  style: const TextStyle(
                    color: _BookTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _fmt(effectiveDuration),
                  style: const TextStyle(
                    color: _BookTheme.labelColor,
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Playback buttons ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _skipBtn(
                Icons.replay_10_rounded,
                () => _skip(-10, effectivePosition, effectiveDuration),
              ),
              const SizedBox(width: 28),

              // Play/Pause
              GestureDetector(
                onTap: _togglePlay,
                child: AnimatedBuilder(
                  animation: _pulseCtr,
                  builder: (_, child) => Transform.scale(
                    scale: isPlaying ? 1.0 + _pulseCtr.value * 0.035 : 1.0,
                    child: child,
                  ),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: _BookTheme.accent,
                      shape: BoxShape.circle,
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: _BookTheme.accent.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 28),
              _skipBtn(
                Icons.forward_10_rounded,
                () => _skip(10, effectivePosition, effectiveDuration),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skipBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _BookTheme.cardBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: _BookTheme.dividerColor.withValues(alpha: 0.8),
          ),
        ),
        child: Icon(icon, color: _BookTheme.metaColor, size: 22),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _thinRule() => Container(height: 0.5, color: _BookTheme.dividerColor);

  Widget _metaLabel(String label) => Text(
    label,
    textAlign: TextAlign.center,
    style: GoogleFonts.amiri(
      color: _BookTheme.labelColor,
      fontSize: 13,
      letterSpacing: 0.8,
      fontStyle: FontStyle.italic,
    ),
  );
}
