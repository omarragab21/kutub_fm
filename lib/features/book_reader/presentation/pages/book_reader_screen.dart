import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/audio/audio_provider.dart';
import '../../../../core/audio/audio_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/transcript_segment.dart';
import 'package:kutub_fm/features/book_reader/data/services/transcription_api_service.dart';
import 'package:kutub_fm/features/reels/data/services/reel_api_service.dart';
import 'package:kutub_fm/features/reels/presentation/pages/reel_preview_page.dart';
import 'package:kutub_fm/core/routes/app_routes.dart';
import 'package:dio/dio.dart';

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
  final String? audioUrl;
  final String? chapterId;
  final String? transcript;
  final String? bookCoverUrl;

  const BookReaderScreen({
    super.key,
    required this.pdfAssetPath,
    required this.bookTitle,
    this.audioUrl,
    this.chapterId,
    this.transcript,
    this.bookCoverUrl,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class BookReaderScreenArgs {
  const BookReaderScreenArgs({
    required this.pdfAssetPath,
    required this.bookTitle,
    this.audioUrl,
    this.chapterId,
    this.transcript,
    this.bookCoverUrl,
  });

  final String pdfAssetPath;
  final String bookTitle;
  final String? audioUrl;
  final String? chapterId;
  final String? transcript;
  final String? bookCoverUrl;
}

// ════════════════════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════════════════════
class _BookReaderScreenState extends State<BookReaderScreen>
    with TickerProviderStateMixin {
  // ── Audio ──────────────────────────────────────────────────────────────

  // ── Transcript ─────────────────────────────────────────────────────────
  TranscriptDocument? _doc;
  bool _isLoading = true;
  String _loadingMessage = 'جاري تهيئة الكتاب…';
  String? _error;
  String? _resolvedAudioUrl;
  String? _bookCoverUrl;
  int _activeIndex = -1;
  final List<GlobalKey> _segmentKeys = [];
  bool _isRequestInProgress = false;
  CancelToken? _cancelToken;

  // ── Scroll ─────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (maxScroll > 0) {
      final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      if ((progress - _scrollProgress).abs() > 0.01) {
        setState(() {
          _scrollProgress = progress;
        });
      }
    }
  }

  // ── Controls ───────────────────────────────────────────────────────────
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _autoStopMode = false;
  bool _isSingleSegmentPlaying = false;
  double? _singleSegmentEndTime;

  // ── Animations ─────────────────────────────────────────────────────────
  late AnimationController _fadeIn;
  late AnimationController _pulseCtr;

  // ── Reading Settings State ──────────────────────────────────────────────
  double _fontSize = 20.0;
  String _themeMode = 'dark'; // Kept for backward compatibility
  bool _isBookmarked = false;
  final Map<int, Color> _highlightedSegments = {};
  Color _selectedTextColor = const Color(
    0xFFD4C9AA,
  ); // Default: warm vanilla white

  final List<Color> _textColorPresets = const [
    Color(0xFFD4C9AA), // Warm reading white (vanilla)
    Color(0xFFE8D5A3), // Parchment Gold
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFB0BEC5), // Light Slate Gray
    Color(0xFF8D6E63), // Muted Sepia Brown
  ];

  Color get _colorPageBg => const Color(0xFF0E0A05); // Fixed dark warm black
  Color get _colorCardBg => const Color(0xFF1A1410); // Warm dark surface
  Color get _colorAccent => AppTheme.primary; // Gold
  Color get _colorBodyColor => _selectedTextColor;
  Color get _colorMutedColor => _selectedTextColor.withOpacity(0.65);
  Color get _colorTitleColor =>
      const Color(0xFFE8D5A3); // Gold remains gold for titles
  Color get _colorDividerColor => const Color(0xFF3A3020);

  // =========================================================================
  @override
  void initState() {
    super.initState();
    _bookCoverUrl = widget.bookCoverUrl;
    _scrollController.addListener(_onScroll);
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
    if (_isRequestInProgress) return;
    _isRequestInProgress = true;
    _cancelToken = CancelToken();

    try {
      Map<String, dynamic>? chapterData;

      if (widget.chapterId != null && widget.chapterId!.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _loadingMessage = 'جاري البحث عن النص…';
        });

        final chapterDoc = await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.pdfAssetPath)
            .collection('chapters')
            .doc(widget.chapterId)
            .get();
        chapterData = chapterDoc.data();
      }

      _resolvedAudioUrl = _resolveAudioUrl(chapterData);

      // 1. If transcript parameter is already provided, decode and render
      final canTrustRouteTranscript =
          widget.chapterId == null ||
          widget.chapterId!.isEmpty ||
          _effectiveAudioUrl == null;
      if (canTrustRouteTranscript &&
          widget.transcript != null &&
          widget.transcript!.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded =
              jsonDecode(widget.transcript!) as Map<String, dynamic>;
          final doc = TranscriptDocument.fromJson(decoded);
          if (!mounted) return;
          setState(() {
            _doc = doc;
            _segmentKeys
              ..clear()
              ..addAll(List.generate(doc.segments.length, (_) => GlobalKey()));
            _isLoading = false;
          });
          return;
        } catch (e) {
          log(
            'Passed transcript parameter is not JSON, parsing as raw text dummy data: $e',
          );
          final rawText = widget.transcript!;
          final lines = rawText.split(RegExp(r'\n+|\.\s+'));
          final List<TranscriptSegment> segments = [];
          double currentStart = 0.0;
          int id = 0;
          for (var line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            final double duration = (trimmed.length * 0.1).clamp(3.0, 15.0);
            segments.add(
              TranscriptSegment(
                id: id++,
                text: trimmed,
                start: currentStart,
                end: currentStart + duration,
                type: TranscriptSegmentType.normal,
              ),
            );
            currentStart += duration;
          }
          final metadata = BookMetadata(
            title: widget.bookTitle,
            author: 'أحمد خالد توفيق',
            genre: 'رواية',
            translator: '',
            narrator: '',
            publisher: 'كتوب إف إم',
          );
          final doc = TranscriptDocument(
            metadata: metadata,
            segments: segments,
          );
          if (!mounted) return;
          setState(() {
            _doc = doc;
            _segmentKeys
              ..clear()
              ..addAll(List.generate(doc.segments.length, (_) => GlobalKey()));
            _isLoading = false;
          });
          return;
        }
      }

      // 2. If chapterId is null or empty, load static asset default
      if (widget.chapterId == null || widget.chapterId!.isEmpty) {
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
        return;
      }

      // 3. Ask the transcript service to read a trusted cached transcript or
      // generate a new one from the exact audio URL used by playback.
      if (!mounted) return;
      setState(() {
        _loadingMessage = 'جاري توليد نص ذكي…';
      });

      final chapterTitle =
          chapterData?['title'] as String? ?? 'شابتر بدون عنوان';
      final chapterAudioUrl = _resolvedAudioUrl ?? '';

      // Get parent book info
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.pdfAssetPath)
          .get();
      final bookData = bookDoc.data() ?? {};
      final resolvedCoverUrl =
          bookData['imageUrl'] as String? ?? widget.bookCoverUrl;
      if (mounted) {
        setState(() {
          _bookCoverUrl = resolvedCoverUrl;
        });
      }

      // Parse metadata
      final bookTitle = bookData['title'] as String? ?? widget.bookTitle;

      final contributors = bookData['contributors'] as List<dynamic>? ?? [];
      String authorName = 'غير معروف';
      String translator = '';
      String narrator = '';
      for (final c in contributors) {
        if (c is Map<String, dynamic>) {
          final role = c['role'] as String?;
          final name = c['nameSnapshot'] as String? ?? '';
          if (role == 'AUTHOR') {
            authorName = name;
          } else if (role == 'TRANSLATOR') {
            translator = name;
          } else if (role == 'NARRATOR' || role == 'READER') {
            narrator = name;
          }
        }
      }

      final categorySnapshots =
          bookData['categorySnapshots'] as List<dynamic>? ?? [];
      final category = categorySnapshots
          .map(
            (c) =>
                c is Map<String, dynamic> ? (c['name'] as String? ?? '') : '',
          )
          .where((name) => name.isNotEmpty)
          .join('، ');
      final primaryCategory =
          bookData['primaryCategorySnapshot'] as Map<String, dynamic>?;
      final fallbackCategory =
          primaryCategory?['name'] as String? ?? 'غير محدد';
      final genre = category.isNotEmpty ? category : fallbackCategory;

      final publisher =
          bookData['publisherNameSnapshot'] as String? ??
          bookData['publisher'] as String? ??
          'كتوب إف إم';

      // Call service
      final doc = await TranscriptionApiService().getOrGenerateTranscript(
        bookId: widget.pdfAssetPath,
        chapterId: widget.chapterId!,
        chapterTitle: chapterTitle,
        audioUrl: chapterAudioUrl,
        bookTitle: bookTitle,
        authorName: authorName,
        genre: genre,
        translator: translator,
        narrator: narrator,
        publisher: publisher,
        cancelToken: _cancelToken,
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
      if (e is DioException && CancelToken.isCancel(e)) {
        log('Transcription API request was cancelled.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      _isRequestInProgress = false;
    }
  }

  String? _resolveAudioUrl(Map<String, dynamic>? chapterData) {
    final chapterAudioUrl = _readString(chapterData, [
      'audioUrl',
      'audio_url',
      'streamUrl',
      'stream_url',
      'url',
    ]);
    if (chapterAudioUrl.isNotEmpty) return chapterAudioUrl;

    final routeAudioUrl = widget.audioUrl?.trim();
    if (routeAudioUrl != null && routeAudioUrl.isNotEmpty) {
      return routeAudioUrl;
    }

    return null;
  }

  String _readString(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return '';
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
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
          chapterId: widget.chapterId,
          audioUrl: _effectiveAudioUrl,
          autoplay: true,
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
    setState(() {
      _controlsVisible = true;
    });
    _resetTimer();
    unawaited(
      audioProvider.playReadingAudio(
        bookId: _readingBookId,
        title: widget.bookTitle,
        chapterId: widget.chapterId,
        audioUrl: _effectiveAudioUrl,
        autoplay: true,
        initialPosition: Duration(milliseconds: (seg.start * 1000).round()),
      ),
    );
  }

  // _playSegmentOnly is no longer used since we now launch the bottom sheet instead of playing the segment only.
  // void _playSegmentOnly(int idx) {
  //   final audioProvider = context.read<AudioProvider>();
  //   final seg = _doc?.segments[idx];
  //   if (seg == null) return;
  //   HapticFeedback.selectionClick();
  //   setState(() {
  //     _isSingleSegmentPlaying = true;
  //     _singleSegmentEndTime = seg.end;
  //     _controlsVisible = true;
  //   });
  //   unawaited(
  //     audioProvider.playReadingAudio(
  //       bookId: _readingBookId,
  //       title: widget.bookTitle,
  //       chapterId: widget.chapterId,
  //       audioUrl: _effectiveAudioUrl,
  //       autoplay: true,
  //       initialPosition: Duration(milliseconds: (seg.start * 1000).round()),
  //     ),
  //   );
  // }

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

  String? get _effectiveAudioUrl {
    final resolved = _resolvedAudioUrl?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    final routeAudio = widget.audioUrl?.trim();
    if (routeAudio != null && routeAudio.isNotEmpty) return routeAudio;
    return null;
  }

  bool _isCurrentReadingAudio(AudioProvider audioProvider) {
    return audioProvider.currentMode == AudioMode.readingAudio &&
        audioProvider.isActiveReadingBook(
          _readingBookId,
          chapterId: widget.chapterId,
        );
  }

  bool _isArabic(String t) => RegExp(r'[\u0600-\u06FF]').hasMatch(t);

  // =========================================================================
  @override
  void dispose() {
    _cancelToken?.cancel();
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
        final posSec = audioProvider.currentPosition.inMilliseconds / 1000.0;
        _syncActive(posSec);

        if (_isSingleSegmentPlaying && _singleSegmentEndTime != null) {
          if (posSec >= _singleSegmentEndTime!) {
            audioProvider.pause();
            setState(() {
              _isSingleSegmentPlaying = false;
              _singleSegmentEndTime = null;
              _controlsVisible = false;
            });
          }
        } else if (_autoStopMode &&
            _activeIndex != -1 &&
            audioProvider.isPlaying) {
          final activeSeg = _doc!.segments[_activeIndex];
          if (posSec >= activeSeg.end) {
            audioProvider.pause();
            setState(() {
              _controlsVisible = false;
            });
          }
        }
      } else {
        if (_activeIndex != -1) {
          setState(() => _activeIndex = -1);
        }
        if (_isSingleSegmentPlaying) {
          setState(() {
            _isSingleSegmentPlaying = false;
            _singleSegmentEndTime = null;
          });
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _colorPageBg,
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
  Widget _loadingView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: _BookTheme.titleColor,
            strokeWidth: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _loadingMessage,
          style: const TextStyle(color: _BookTheme.labelColor, fontSize: 14),
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

          // Bottom widget (floating player or progress bar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            bottom: _controlsVisible ? 0 : -250,
            left: 0,
            right: 0,
            child: _bottomWidget(),
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

        // Bottom padding for audio player/reading progress
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 185),
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
              style: TextStyle(
                color: _colorMutedColor,
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
            style: TextStyle(
              color: _colorTitleColor,
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
                border: Border.all(color: _colorAccent.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                meta.genre,
                style: TextStyle(
                  color: _colorAccent.withOpacity(0.75),
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
              style: TextStyle(
                color: _colorMutedColor,
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
                child: Container(height: 0.5, color: _colorDividerColor),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _BookTheme.ornament,
                  style: TextStyle(
                    color: _colorAccent.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 0.5, color: _colorDividerColor),
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
              style: TextStyle(color: _colorMutedColor, fontSize: 18),
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
              style: TextStyle(color: _colorMutedColor, fontSize: 18),
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
    final customHighlightColor = _highlightedSegments[index];

    // Determine inline style based on type and active state
    Color textColor;
    FontWeight fontWeight;
    Color? highlightBg;
    double fontSize = isArabic ? _fontSize : _fontSize - 3.5;

    if (isActive) {
      textColor = Colors.black;
      fontWeight = FontWeight.w600;
      highlightBg = _colorAccent;
      fontSize = isArabic ? _fontSize + 1 : _fontSize - 2.5;
    } else if (customHighlightColor != null) {
      textColor = Colors.black;
      fontWeight = FontWeight.normal;
      highlightBg = customHighlightColor;
    } else {
      switch (seg.type) {
        case TranscriptSegmentType.bold:
          textColor = _colorBodyColor;
          fontWeight = FontWeight.bold;
          highlightBg = null;
          break;
        case TranscriptSegmentType.highlight:
          // Dialogue: warmer, slightly brighter
          textColor = _colorTitleColor;
          fontWeight = FontWeight.w500;
          highlightBg = null;
          break;
        default:
          textColor = _colorBodyColor.withOpacity(0.82);
          fontWeight = FontWeight.normal;
          highlightBg = null;
      }
    }

    final style = isArabic
        ? TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.75,
          )
        : TextStyle(
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

    final showHighlightDecoration = isActive || customHighlightColor != null;

    Widget tile = GestureDetector(
      key: _segmentKeys[index],
      onTap: () => _showSegmentFloatingToolbar(index, seg),
      onLongPress: () => _showSegmentFloatingToolbar(index, seg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: _segmentBottomSpacing(seg, index)),
        padding: showHighlightDecoration
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : EdgeInsets.zero,
        decoration: showHighlightDecoration
            ? BoxDecoration(
                color: highlightBg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _colorAccent.withOpacity(0.4),
                          blurRadius: 18,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              )
            : null,
        child: textWidget,
      ),
    );

    if (isActive) {
      final firstWords = seg.text.split(' ').take(3).join(' ') + '...';
      tile = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Pill Tooltip pointing to active text
          Padding(
            padding: const EdgeInsets.only(right: 10, bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _colorAccent, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _colorAccent.withOpacity(0.25),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded, color: _colorAccent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'كلمة الصوت الحالية: $firstWords',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          tile,
        ],
      );
    }

    return tile;
  }

  void _showSegmentFloatingToolbar(int index, TranscriptSegment seg) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.40),
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _colorAccent.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Copy button
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: seg.text));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ النص إلى الحافظة'),
                          ),
                        );
                      },
                      tooltip: 'نسخ النص',
                    ),
                    const SizedBox(width: 4),

                    // 2. Play/Listen button
                    IconButton(
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _seekBySegment(index);
                      },
                      tooltip: 'استماع',
                    ),
                    const SizedBox(width: 4),

                    // 3. Share/Community button
                    IconButton(
                      icon: const Icon(
                        Icons.people_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم نشر الاقتباس في مجتمع كتب FM بنجاح!',
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        );
                      },
                      tooltip: 'مشاركة مع المجتمع',
                    ),

                    // Divider
                    Container(
                      height: 24,
                      width: 1.5,
                      color: Colors.white.withOpacity(0.15),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),

                    // Color selectors
                    ...[
                      const Color(0xFFFFF176), // Yellow
                      const Color(0xFFA5D6A7), // Green
                      const Color(0xFFF48FB1), // Pink
                      const Color(0xFF90CAF9), // Blue
                      const Color(0xFFB0BEC5), // Grey/Silver
                    ].map((color) {
                      final isSelected = _highlightedSegments[index] == color;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            if (isSelected) {
                              _highlightedSegments.remove(index);
                            } else {
                              _highlightedSegments[index] = color;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  Widget _topBar() {
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
          colors: [_colorPageBg, _colorPageBg.withOpacity(0)],
        ),
      ),
      child: Row(
        children: [
          // Settings button (left)
          IconButton(
            icon: Icon(Icons.tune_rounded, color: _colorMutedColor, size: 20),
            onPressed: _showSettingsDialog,
          ),

          Expanded(
            child: Text(
              _doc?.metadata.title ?? widget.bookTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _colorTitleColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Bookmark/Save button
          IconButton(
            icon: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isBookmarked ? _colorAccent : _colorMutedColor,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBookmarked
                        ? 'تم حفظ الصفحة بنجاح!'
                        : 'تم إزالة الصفحة من المحفوظات',
                    textDirection: TextDirection.rtl,
                  ),
                ),
              );
            },
          ),
          // Highlight Pen Button
          IconButton(
            icon: Icon(
              Icons.border_color_rounded,
              color: _highlightedSegments.isNotEmpty
                  ? _colorAccent
                  : _colorMutedColor,
              size: 18,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (_highlightedSegments.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'لتظليل أي نص، اضغط عليه واختر اللون المطلوب من القائمة العائمة.',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              } else {
                setState(() {
                  _highlightedSegments.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم مسح جميع التظليلات.',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              }
            },
          ),
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _colorMutedColor,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ── Audio controls ─────────────────────────────────────────────────────
  Widget _bottomWidget() {
    final audioProvider = context.watch<AudioProvider>();
    final isCurrentReading = _isCurrentReadingAudio(audioProvider);

    if (isCurrentReading) {
      return _audioControls();
    } else {
      return _readingProgressWidget(audioProvider);
    }
  }

  Widget _readingProgressWidget(AudioProvider audioProvider) {
    final stories = audioProvider.stories;
    final idx = stories.indexWhere((s) => s.id == widget.chapterId);
    final currentChapterIdx = idx != -1 ? idx : 0;
    final String chapterLabel =
        'الفصل ${_getArabicOrdinal(currentChapterIdx + 1)}';

    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        border: Border(top: BorderSide(color: _colorDividerColor, width: 0.8)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: `< فصول الكتاب`
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showReaderChaptersBottomSheet(audioProvider);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      color: _colorMutedColor,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'فصول الكتاب',
                      style: TextStyle(
                        color: _colorMutedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: `الفصل الأول ∧`
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showReaderChaptersBottomSheet(audioProvider);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chapterLabel,
                      style: TextStyle(
                        color: _colorTitleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _colorTitleColor, width: 1.0),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: _colorTitleColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dashed/Segmented Progress Bar
          Row(
            children: List.generate(10, (index) {
              // For RTL, we fill from right to left (index 9 is rightmost, index 0 is leftmost).
              // So we reverse the check: active if (9 - index) / 10 < progress.
              final isFilled = (9 - index) / 10 < _scrollProgress;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 3,
                    right: index == 9 ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: isFilled ? _colorAccent : _colorDividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Center: The Dark Navigation Pill
          Container(
            decoration: BoxDecoration(
              color: const Color(
                0xFF2C221C,
              ), // Lighter warm brown/black for contrast
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Left chevron (Navigates to previous chapter)
                GestureDetector(
                  onTap: () {
                    if (currentChapterIdx > 0) {
                      HapticFeedback.lightImpact();
                      final prevStory = stories[currentChapterIdx - 1];
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.bookReader,
                        arguments: BookReaderScreenArgs(
                          pdfAssetPath: widget.pdfAssetPath,
                          bookTitle: widget.bookTitle,
                          audioUrl: prevStory.audioUrl,
                          chapterId: prevStory.id,
                          bookCoverUrl: widget.bookCoverUrl,
                        ),
                      );
                    }
                  },
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: currentChapterIdx > 0
                        ? _colorAccent
                        : Colors.white24,
                    size: 20,
                  ),
                ),
                Container(
                  height: 14,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Text(
                  '${currentChapterIdx + 1} / ${stories.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  height: 14,
                  width: 1,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Right chevron (Navigates to next chapter)
                GestureDetector(
                  onTap: () {
                    if (currentChapterIdx < stories.length - 1) {
                      HapticFeedback.lightImpact();
                      final nextStory = stories[currentChapterIdx + 1];
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.bookReader,
                        arguments: BookReaderScreenArgs(
                          pdfAssetPath: widget.pdfAssetPath,
                          bookTitle: widget.bookTitle,
                          audioUrl: nextStory.audioUrl,
                          chapterId: nextStory.id,
                          bookCoverUrl: widget.bookCoverUrl,
                        ),
                      );
                    }
                  },
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: currentChapterIdx < stories.length - 1
                        ? _colorAccent
                        : Colors.white24,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioControls() {
    final audioProvider = context.watch<AudioProvider>();
    final isCurrentReading = _isCurrentReadingAudio(audioProvider);
    if (!isCurrentReading) return const SizedBox.shrink();

    final isPlaying = audioProvider.isPlaying;
    final effectiveDuration = audioProvider.duration;
    final effectivePosition = audioProvider.currentPosition;

    return Center(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 24,
          right: 24,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24), // Elegant dark obsidian grey
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _colorAccent.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Audio active/pulsing indicator icon
            Icon(
              isPlaying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
              color: _colorAccent,
              size: 20,
            ),
            const SizedBox(width: 12),

            // 2. Play / Pause Button
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _colorAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 3. Time status
            Text(
              '${_fmt(effectivePosition)} / ${_fmt(effectiveDuration)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),

            // Divider
            Container(
              height: 20,
              width: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 12),

            // 4. Stop / Close Button
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                audioProvider.stop();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReelBottomSheet(TranscriptSegment seg) {
    HapticFeedback.mediumImpact();

    // Pause any playing audio first to prevent overlap
    final audioProvider = context.read<AudioProvider>();
    if (audioProvider.isPlaying) {
      audioProvider.pause();
    }

    String selectedType = 'quote'; // Default dropdown type
    final startTimeStr = _formatSegmentTime(seg.start);
    final endTimeStr = _formatSegmentTime(seg.end);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 24,
                  right: 24,
                  top: 16,
                ),
                decoration: const BoxDecoration(
                  color: _BookTheme.cardBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: _BookTheme.dividerColor, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle line
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _BookTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(
                          Icons.video_library_rounded,
                          color: _BookTheme.accent,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'توليد مقطع ريلز',
                          style: TextStyle(
                            color: _BookTheme.titleColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Selected segment text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _BookTheme.pageBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _BookTheme.dividerColor),
                      ),
                      child: Text(
                        seg.text,
                        style: TextStyle(
                          color: _BookTheme.bodyColor,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: _BookTheme.labelColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'البداية: $startTimeStr',
                              style: const TextStyle(
                                color: _BookTheme.metaColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: _BookTheme.labelColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'النهاية: $endTimeStr',
                              style: const TextStyle(
                                color: _BookTheme.metaColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dropdown for type selection
                    const Text(
                      'تصنيف المقطع:',
                      style: TextStyle(
                        color: _BookTheme.labelColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _BookTheme.pageBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _BookTheme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          dropdownColor: _BookTheme.cardBg,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _BookTheme.accent,
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          onChanged: (String? value) {
                            if (value != null) {
                              setModalState(() {
                                selectedType = value;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'quote',
                              child: Text('اقتباس (Quote)'),
                            ),
                            DropdownMenuItem(
                              value: 'philosophy',
                              child: Text('فلسفة (Philosophy)'),
                            ),
                            DropdownMenuItem(
                              value: 'scan',
                              child: Text('مسح ضوئي (Scan)'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _processReelCreation(
                            seg,
                            selectedType,
                            startTimeStr,
                            endTimeStr,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _BookTheme.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'إنشاء ريلز',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatSegmentTime(double seconds) {
    final totalSeconds = seconds.round();
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _processReelCreation(
    TranscriptSegment seg,
    String type,
    String startStr,
    String endStr,
  ) async {
    final audioUrl = _effectiveAudioUrl;
    final coverUrl = _bookCoverUrl;

    // Check for missing data
    if (audioUrl == null || audioUrl.isEmpty) {
      _showErrorSnackBar(
        'تعذر إنشاء مقطع الريل: رابط الملف الصوتي الخاص بالكتاب غير متوفر.',
      );
      return;
    }
    if (coverUrl == null || coverUrl.isEmpty) {
      _showErrorSnackBar('تعذر إنشاء مقطع الريل: رابط غلاف الكتاب غير متوفر.');
      return;
    }
    if (seg.start == 0.0 && seg.end == 0.0) {
      _showErrorSnackBar(
        'تعذر إنشاء مقطع الريل: الجملة المحددة لا تحتوي على طوابع زمنية.',
      );
      return;
    }

    // Show loading indicator dialog
    String currentProgressMessage = 'جاري طلب إنشاء مقطع الريل من الخادم…';
    bool isCompleted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Keep dynamic update of dialog text
            if (isCompleted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
            }
            return PopScope(
              canPop: false,
              child: Dialog(
                backgroundColor: _BookTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(
                    color: _BookTheme.dividerColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: _BookTheme.accent),
                      const SizedBox(height: 24),
                      Text(
                        currentProgressMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _BookTheme.titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'قد تستغرق هذه العملية ما يصل إلى دقيقة واحدة، يرجى عدم إغلاق التطبيق.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _BookTheme.bodyMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final reelService = ReelApiService();
    try {
      // 1. Create Reel via API
      final createResponse = await reelService.createReel(
        audioUrl: audioUrl,
        coverUrl: coverUrl,
        start: startStr,
        end: endStr,
      );

      final downloadUrl = createResponse['download_url']?.toString();
      final outputFile = createResponse['output_file']?.toString();

      if (downloadUrl == null ||
          downloadUrl.isEmpty ||
          outputFile == null ||
          outputFile.isEmpty) {
        throw Exception(
          'الاستجابة المستلمة من الخادم لا تحتوي على معلومات التحميل.',
        );
      }

      // Update loading dialog state
      currentProgressMessage = 'تم إنشاء المقطع بنجاح! جاري تحميل ملف الفيديو…';
      if (mounted) setState(() {});

      // 2. Download generated video file
      final localFilePath = await reelService.downloadReel(
        downloadUrl,
        outputFile,
      );

      // Fetch dynamic logo url configured in remote config
      final logoUrl = await reelService.getLogoUrl();

      // Dismiss dialog
      isCompleted = true;
      if (mounted) setState(() {});

      // 3. Navigate to preview screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.reelPreview,
          arguments: ReelPreviewArgs(
            videoPath: localFilePath,
            sentenceText: seg.text,
            start: startStr,
            end: endStr,
            audioUrl: audioUrl,
            coverUrl: coverUrl,
            logoUrl: logoUrl,
            downloadUrl: downloadUrl,
            type: type,
            bookTitle: _doc?.metadata.title ?? widget.bookTitle,
            author: _doc?.metadata.author ?? 'غير معروف',
          ),
        );
      }
    } catch (e) {
      log('Error during reel generation/download process: $e');
      // Dismiss dialog
      isCompleted = true;
      if (mounted) setState(() {});

      // Extract a helpful error message
      String friendlyError = e.toString();
      if (friendlyError.startsWith('Exception: ')) {
        friendlyError = friendlyError.substring(10);
      }
      _showErrorSnackBar('فشل إنشاء مقطع الريل: $friendlyError');
    }
  }

  void _showErrorSnackBar(String errorMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _colorCardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: _colorDividerColor, width: 0.5),
                  ),
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
                          color: _colorDividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'إعدادات القراءة',
                      style: TextStyle(
                        color: _colorTitleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Font Size option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'حجم الخط',
                          style: TextStyle(
                            color: _colorBodyColor,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: _colorBodyColor),
                              onPressed: _fontSize > 14
                                  ? () {
                                      setState(() => _fontSize--);
                                      setModalState(() {});
                                    }
                                  : null,
                            ),
                            Text(
                              '${_fontSize.round()}',
                              style: TextStyle(
                                color: _colorTitleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: _colorBodyColor),
                              onPressed: _fontSize < 32
                                  ? () {
                                      setState(() => _fontSize++);
                                      setModalState(() {});
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Text Color selector option
                    Text(
                      'لون النص',
                      style: TextStyle(color: _colorBodyColor, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _textColorPresets.map((color) {
                        final isSelected = _selectedTextColor == color;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedTextColor = color;
                            });
                            setModalState(() {});
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? _colorAccent
                                    : Colors.transparent,
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReaderChaptersBottomSheet(AudioProvider audioProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _colorCardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: _colorDividerColor, width: 0.5),
              ),
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
                      color: _colorDividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'فصول الكتاب',
                  style: TextStyle(
                    color: _colorTitleColor,
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
                      final isCurrent = story.id == widget.chapterId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _colorAccent.withOpacity(0.05)
                              : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? _colorAccent.withOpacity(0.3)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? _colorAccent
                                    : Colors.white.withOpacity(0.08),
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? (_themeMode == 'light'
                                              ? Colors.white
                                              : Colors.black)
                                        : _colorBodyColor,
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
                                  color: isCurrent
                                      ? _colorAccent
                                      : _colorBodyColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.menu_book_rounded,
                                color: isCurrent
                                    ? _colorAccent
                                    : _colorBodyColor,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.bookReader,
                                  arguments: BookReaderScreenArgs(
                                    pdfAssetPath: widget.pdfAssetPath,
                                    bookTitle: widget.bookTitle,
                                    audioUrl: story.audioUrl,
                                    chapterId: story.id,
                                    bookCoverUrl: widget.bookCoverUrl,
                                  ),
                                );
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

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _thinRule() => Container(height: 0.5, color: _colorDividerColor);

  Widget _metaLabel(String label) => Text(
    label,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: _colorMutedColor,
      fontSize: 13,
      letterSpacing: 0.8,
      fontStyle: FontStyle.italic,
    ),
  );

  String _getArabicOrdinal(int n) {
    switch (n) {
      case 1:
        return 'الأول';
      case 2:
        return 'الثاني';
      case 3:
        return 'الثالث';
      case 4:
        return 'الرابع';
      case 5:
        return 'الخامس';
      case 6:
        return 'السادس';
      case 7:
        return 'السابع';
      case 8:
        return 'الثامن';
      case 9:
        return 'التاسع';
      case 10:
        return 'العاشر';
      default:
        return 'الـ $n';
    }
  }
}

// ── Dashed Progress Bar for Reading Progress ───────────────────────────────
class DashedProgressBar extends StatelessWidget {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const DashedProgressBar({
    super.key,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 6),
      painter: _DashedProgressBarPainter(
        progress: progress,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}

class _DashedProgressBarPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _DashedProgressBarPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double y = size.height / 2;
    const double dashWidth = 5.0;
    const double spaceWidth = 4.0;
    final double width = size.width;

    double x = 0.0;
    while (x < width) {
      final double endX = (x + dashWidth).clamp(0.0, width);
      final double centerX = (x + endX) / 2;
      // In RTL (Arabic), active dashes start from the right (width) going left.
      // So a dash is active if its center is >= width * (1 - progress).
      final bool isActive = centerX >= width * (1 - progress);

      paint.color = isActive ? activeColor : inactiveColor;
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += dashWidth + spaceWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
