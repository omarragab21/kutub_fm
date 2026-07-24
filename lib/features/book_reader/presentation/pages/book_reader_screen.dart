import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../book_details/domain/entities/book_detail_model.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/pdf_extraction_service.dart';
import '../../data/services/reading_progress_service.dart';
import '../utils/transcript_selection_mapper.dart';

class BookReaderScreenArgs {
  final String pdfAssetPath;
  final String bookTitle;
  final String audioUrl;
  final String chapterId;
  final String? transcript;
  final String? bookCoverUrl;

  const BookReaderScreenArgs({
    required this.pdfAssetPath,
    required this.bookTitle,
    required this.audioUrl,
    required this.chapterId,
    this.transcript,
    this.bookCoverUrl,
  });
}

class BookReaderScreen extends StatefulWidget {
  final String? bookId;
  final String? chapterId;
  final String? pdfUrl;
  final int? startPage;
  final int? endPage;
  final String? bookTitle;
  final String? chapterTitle;
  final String? audioUrl;
  final List<TranscriptionSegment>? transcription;
  final List<Chapter> chapters;

  const BookReaderScreen({
    super.key,
    this.bookId,
    this.chapterId,
    this.pdfUrl,
    this.startPage,
    this.endPage,
    this.bookTitle,
    this.chapterTitle,
    this.audioUrl,
    this.transcription,
    this.chapters = const [],
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final PdfExtractionService _pdfService = PdfExtractionService();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _error;
  String _content = '';

  // Saved reading progress per chapter (0.0 - 1.0), keyed by chapter id.
  final Map<String, double> _chapterProgress = {};

  // Read-along (transcription) state.
  AudioProvider? _audio;
  List<TapGestureRecognizer> _recognizers = const [];
  int? _selectedSegmentIndex; // sentence tapped by the user (shows the popup)
  int? _playingSegmentIndex; // sentence currently playing (auto highlight)
  int? _playUntilMs; // when set, auto-pause once playback passes this point

  bool _isSelectionPlaybackMode = false;
  double? _selectionPlayStart;
  double? _selectionPlayEnd;
  int? _selectionPlaybackStartSegmentIndex;
  int? _selectionPlaybackEndSegmentIndex;
  int? _selectedStartSegmentIndex;
  int? _selectedEndSegmentIndex;
  int _lastLoggedSelectionStart = -1;
  int _lastLoggedSelectionEnd = -1;
  List<BookReaderBookmark> _bookmarks = const [];
  Set<int> _bookmarkedSegmentIndexes = const {};
  late TranscriptTextIndex _transcriptTextIndex;

  List<TranscriptionSegment> get _segments => widget.transcription ?? const [];

  double _fontSize = 18.0;
  String _fontFamily = 'ThmanyahSans';
  Color _themeBgColor = const Color(0xFF040707);
  Color _themeTextColor = Colors.white;
  Color _themeSecondaryTextColor = Colors.white54;
  late TextEditingController _textController;

  String get _bookmarkBookStorageId {
    final bookId = widget.bookId?.trim();
    if (bookId != null && bookId.isNotEmpty) return bookId;

    final bookTitle = widget.bookTitle?.trim();
    if (bookTitle != null && bookTitle.isNotEmpty) return bookTitle;

    final pdfUrl = widget.pdfUrl?.trim();
    if (pdfUrl != null && pdfUrl.isNotEmpty) return pdfUrl;

    return 'book_reader_default_book';
  }

  String get _bookmarkChapterStorageId {
    final chapterId = widget.chapterId?.trim();
    if (chapterId != null && chapterId.isNotEmpty) return chapterId;

    final chapterTitle = widget.chapterTitle?.trim();
    if (chapterTitle != null && chapterTitle.isNotEmpty) return chapterTitle;

    final audioUrl = widget.audioUrl?.trim();
    if (audioUrl != null && audioUrl.isNotEmpty) return audioUrl;

    return 'book_reader_default_chapter';
  }

  void _rebuildTranscriptTextIndex() {
    _transcriptTextIndex = TranscriptTextIndex(_segments);
  }

  void _rebuildSegmentRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = List.generate(
      _segments.length,
      (i) => TapGestureRecognizer()..onTap = () => _selectSegment(i),
    );
  }

  void _syncAudioListener() {
    if (_hasTranscription && _audio == null) {
      _audio = context.read<AudioProvider>();
      _audio!.addListener(_onAudioTick);
      return;
    }

    if (!_hasTranscription && _audio != null) {
      _audio!.removeListener(_onAudioTick);
      _audio = null;
    }
  }

  void _setControllerTextSilently(String text) {
    _textController.removeListener(_onSelectionChanged);
    _textController.value = TextEditingValue(
      text: text,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _textController.addListener(_onSelectionChanged);
  }

  Future<void> _loadBookmarks() async {
    final bookId = _bookmarkBookStorageId;
    final chapterId = _bookmarkChapterStorageId;
    final bookmarks = await BookmarkService.getBookmarks(
      bookId: bookId,
      chapterId: chapterId,
    );

    if (!mounted ||
        bookId != _bookmarkBookStorageId ||
        chapterId != _bookmarkChapterStorageId) {
      return;
    }

    setState(() {
      _applyBookmarks(bookmarks);
    });
  }

  void _applyBookmarks(List<BookReaderBookmark> bookmarks) {
    _bookmarks = List.unmodifiable(bookmarks);
    _bookmarkedSegmentIndexes = _buildBookmarkedSegmentIndexes(bookmarks);
  }

  Set<int> _buildBookmarkedSegmentIndexes(List<BookReaderBookmark> bookmarks) {
    final indexes = <int>{};
    final lastAvailableIndex = _segments.length - 1;
    if (lastAvailableIndex < 0) return indexes;

    for (final bookmark in bookmarks) {
      final first = bookmark.firstSegmentIndex
          .clamp(0, lastAvailableIndex)
          .toInt();
      final last = bookmark.lastSegmentIndex
          .clamp(0, lastAvailableIndex)
          .toInt();
      if (first > last) continue;

      for (var index = first; index <= last; index++) {
        indexes.add(index);
      }
    }

    return indexes;
  }

  @override
  void didUpdateWidget(covariant BookReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final transcriptChanged = oldWidget.transcription != widget.transcription;
    final bookmarkScopeChanged =
        oldWidget.bookId != widget.bookId ||
        oldWidget.chapterId != widget.chapterId ||
        oldWidget.bookTitle != widget.bookTitle ||
        oldWidget.chapterTitle != widget.chapterTitle ||
        oldWidget.pdfUrl != widget.pdfUrl ||
        oldWidget.audioUrl != widget.audioUrl;

    if (transcriptChanged) {
      _rebuildTranscriptTextIndex();
      _rebuildSegmentRecognizers();
      _setControllerTextSilently(_transcriptTextIndex.plainText);
      _resetSelectedTextState();
      _resetSelectionPlaybackState();
    }
    if (transcriptChanged || bookmarkScopeChanged) {
      _applyBookmarks(const []);
      unawaited(_loadBookmarks());
    }
    if (transcriptChanged || oldWidget.audioUrl != widget.audioUrl) {
      _syncAudioListener();
    }
  }

  // Read-along mode: time-aligned transcription + a chapter audio track.
  bool get _hasTranscription =>
      _segments.isNotEmpty &&
      widget.audioUrl != null &&
      widget.audioUrl!.trim().isNotEmpty;

  // PDF text mode is only used when there is no read-along transcription.
  bool get _isPdfMode =>
      !_hasTranscription &&
      widget.pdfUrl != null &&
      widget.pdfUrl!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadAllProgress();
    _scrollController.addListener(_onScroll);
    _rebuildTranscriptTextIndex();
    _rebuildSegmentRecognizers();
    unawaited(_loadBookmarks());
    if (_isPdfMode) {
      _loadPdfText();
    }

    _textController = RichTextEditingController(
      text: _transcriptTextIndex.plainText,
      buildSpan: (context, style) {
        return TextSpan(
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.9,
            fontFamily: _fontFamily,
          ),
          children: [
            for (int i = 0; i < _segments.length; i++)
              TextSpan(
                text: _transcriptTextIndex.segmentDisplayText(i),
                style: TextStyle(
                  color: i == _playingSegmentIndex
                      ? const Color(0xFF1F1F1F)
                      : _themeTextColor,
                  backgroundColor: _segmentHighlight(i),
                  fontWeight: i == _playingSegmentIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                recognizer: i < _recognizers.length ? _recognizers[i] : null,
              ),
          ],
        );
      },
    );
    _textController.addListener(_onSelectionChanged);
    _syncAudioListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audio?.removeListener(_onAudioTick);
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _textController.removeListener(_onSelectionChanged);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProgress() async {
    final bookId = widget.bookId ?? '';
    final chapters = widget.chapters;
    if (bookId.isEmpty || chapters.isEmpty) return;
    final progress = <String, double>{};
    for (final chapter in chapters) {
      progress[chapter.id] = await ReadingProgressService.getProgress(
        bookId,
        chapter.id,
      );
    }
    if (mounted) {
      setState(() {
        _chapterProgress
          ..clear()
          ..addAll(progress);
      });
      _restoreScroll(progress[widget.chapterId ?? ''] ?? 0.0);
    }
  }

  void _restoreScroll(double progress) {
    if (progress <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max > 0) {
        _scrollController.jumpTo(progress * max);
      }
    });
  }

  void _onScroll() {
    final bookId = widget.bookId ?? '';
    final chapterId = widget.chapterId ?? '';
    if (bookId.isEmpty || chapterId.isEmpty) return;
    final position = _scrollController.position;
    final max = position.maxScrollExtent;
    if (max <= 0) return;
    final value = (position.pixels / max).clamp(0.0, 1.0);
    ReadingProgressService.setProgress(bookId, chapterId, value);
    setState(() => _chapterProgress[chapterId] = value);
  }

  void _onAudioTick() {
    final audio = _audio;
    if (audio == null || !mounted) return;

    // Only react while our chapter's reading audio is the active track.
    final isOurs = audio.isActiveReadingBook(
      widget.bookId ?? '',
      chapterId: widget.chapterId,
    );
    if (!isOurs) return;

    final posMs = audio.currentPosition.inMilliseconds;

    // Stop and clean up when snippet playback reaches the selected range end.
    if (_playUntilMs != null && posMs >= _playUntilMs!) {
      _finishSelectionPlayback(stopAudio: true);
      return;
    }

    // Highlight the sentence that matches the current audio position.
    final posSec = posMs / 1000.0;
    final active = _transcriptTextIndex.segmentIndexAtTime(posSec);
    if (_playingSegmentIndex != active) {
      setState(() {
        _playingSegmentIndex = active;
      });
    }
  }

  void _selectSegment(int index) {
    final match = _transcriptTextIndex.resolveSegmentRange(index, index);
    if (match == null) return;

    _setTextSelectionSilently(
      TextSelection(
        baseOffset: match.textRange.start,
        extentOffset: match.textRange.end,
      ),
    );
    _debugPrintTranscriptSelection(match);

    setState(() {
      _selectedSegmentIndex = index;
      _selectedStartSegmentIndex = index;
      _selectedEndSegmentIndex = index;
    });
  }

  void _clearSelection() {
    if (_selectedSegmentIndex != null ||
        _selectedStartSegmentIndex != null ||
        _selectedEndSegmentIndex != null ||
        !_textController.selection.isCollapsed) {
      _setTextSelectionSilently(const TextSelection.collapsed(offset: 0));
      setState(() {
        _resetSelectedTextState();
      });
    }
  }

  Future<void> _loadPdfText() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Read the PDF online (in memory) and extract only the chapter's pages.
      final text = await _pdfService.extractTextFromUrl(
        widget.pdfUrl!.trim(),
        startPage: widget.startPage,
        endPage: widget.endPage,
      );
      if (!mounted) return;
      setState(() {
        _content = text;
        _isLoading = false;
      });
      _restoreScroll(_chapterProgress[widget.chapterId ?? ''] ?? 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل محتوى الكتاب';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _themeBgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _themeBgColor,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Actions: Chevron Back and Sliders/Tune icon
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          'assets/arrow_back.svg',
                          colorFilter: ColorFilter.mode(
                            _themeTextColor,
                            BlendMode.srcIn,
                          ),
                          width: 18,
                          height: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _showSettingsBottomSheet,
                        child: SvgPicture.asset(
                          'assets/filter.svg',
                          colorFilter: ColorFilter.mode(
                            _themeTextColor,
                            BlendMode.srcIn,
                          ),
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                  // Center Title
                  Text(
                    widget.bookTitle ?? 'مئة عام من العزلة',
                    style: TextStyle(
                      color: _themeTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: _fontFamily,
                    ),
                  ),
                  // Balanced Right Spacer
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 1,
                    color: _themeTextColor.withValues(alpha: 0.1),
                  ),
                  Expanded(child: _buildReaderBody()),

                  // Bottom Progress Bar
                  Container(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    decoration: BoxDecoration(
                      color: _themeBgColor == const Color(0xFF040707)
                          ? const Color(0xFF1F1F1F)
                          : _themeBgColor.withValues(alpha: 0.95),
                      border: Border(
                        top: BorderSide(
                          color: _themeTextColor.withValues(alpha: 0.1),
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        GestureDetector(
                          onTap: () => _showChaptersBottomSheet(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 18,
                            children: [
                              // Title row: "فصول الكتاب" and "الفصل الأول"
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left side: فصول الكتاب + chevron back
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 4,
                                    children: [
                                      Icon(
                                        Icons.chevron_left,
                                        color: _themeSecondaryTextColor,
                                        size: 24,
                                      ),
                                      Text(
                                        'فصول الكتاب',
                                        style: TextStyle(
                                          color: _themeSecondaryTextColor,
                                          fontSize: 14,
                                          fontFamily: _fontFamily,
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Right side: chapter title + circle arrow up
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        widget.chapterTitle ?? 'الفصل الأول',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _themeTextColor,
                                          fontSize: 16,
                                          fontFamily: _fontFamily,
                                          fontWeight: FontWeight.w700,
                                          height: 1.50,
                                        ),
                                      ),
                                      Icon(
                                        CupertinoIcons.chevron_up_circle,
                                        color: _themeTextColor,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Dynamic chapter progress segments
                              if (widget.chapters.isNotEmpty)
                                Row(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < widget.chapters.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(width: 2),
                                      _buildChapterProgressSegment(
                                        widget.chapters[i],
                                        _chapterProgress[widget
                                                .chapters[i]
                                                .id] ??
                                            0.0,
                                        widget.chapters[i].id ==
                                            widget.chapterId,
                                      ),
                                    ],
                                  ],
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildSegment(72, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(15, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(71, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(28, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(30, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(59, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(20, true),
                                      const SizedBox(width: 2),
                                      _buildSegment(49, false),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Selection playback controls row below progress
                        if (_isSelectionPlaybackMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left spacer to keep center pill centered
                              const SizedBox(width: 35),

                              // Center control pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF333333),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 16,
                                  children: [
                                    // Rewind 10s (Left side of pill)
                                    GestureDetector(
                                      onTap: () => _seekRelative(-10),
                                      child: SvgPicture.asset(
                                        'assets/replay_10.svg',
                                        colorFilter: ColorFilter.mode(
                                          _themeTextColor,
                                          BlendMode.srcIn,
                                        ),
                                        width: 25,
                                        height: 25,
                                      ),
                                    ),
                                    // Play/Pause (Center of pill)
                                    GestureDetector(
                                      onTap: _togglePlayPause,
                                      child: SvgPicture.asset(
                                        _audio?.isPlaying == true
                                            ? 'assets/pause.svg'
                                            : 'assets/play.svg',
                                        colorFilter: ColorFilter.mode(
                                          _themeTextColor,
                                          BlendMode.srcIn,
                                        ),
                                        width: 30,
                                        height: 30,
                                      ),
                                    ),
                                    // Fast Forward 10s (Right side of pill)
                                    GestureDetector(
                                      onTap: () => _seekRelative(10),
                                      child: SvgPicture.asset(
                                        'assets/forward_10.svg',
                                        colorFilter: ColorFilter.mode(
                                          _themeTextColor,
                                          BlendMode.srcIn,
                                        ),
                                        width: 25,
                                        height: 25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Far Right Close "X" button
                              GestureDetector(
                                onTap: _exitSelectionPlayback,
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _themeTextColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: _themeTextColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Figma mockup overlays only shown in the static demo mode.
              if (!_hasTranscription && !_isPdfMode) ...[
                Positioned(top: 180, right: 30, child: _buildTextPopup()),
                Positioned(top: 310, right: 30, child: _buildCaptionTag()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReaderBody() {
    // Read-along mode: time-aligned transcription synced to the chapter audio.
    if (_hasTranscription) {
      return _buildTranscriptionBody();
    }

    // Backward-compatible demo mode when no PDF URL is supplied.
    if (!_isPdfMode) {
      return _buildStaticDemoBody();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFC00E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontFamily: 'ThmanyahSans',
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPdfText,
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  color: Color(0xFFFFC00E),
                  fontFamily: 'ThmanyahSans',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.chapterTitle ?? '',
            style: TextStyle(
              color: _themeTextColor,
              fontSize: _fontSize + 6,
              fontWeight: FontWeight.bold,
              fontFamily: _fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            _content,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _themeTextColor,
              fontSize: _fontSize,
              height: 1.8,
              fontFamily: _fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticDemoBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفصل الأول',
            style: TextStyle(
              color: _themeTextColor,
              fontSize: _fontSize + 6,
              fontWeight: FontWeight.bold,
              fontFamily: _fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText.rich(
            TextSpan(
              style: TextStyle(
                color: _themeTextColor,
                fontSize: _fontSize,
                height: 1.8,
                fontFamily: _fontFamily,
              ),
              children: [
                const TextSpan(
                  text:
                      'في مدينة لا تنام، تُعرف بين سكانها باسم "مدينة الوهم". كانت الأضواء دائمًا تخفي أكثر مما تكشف. الشوارع القديمة تحمل همسات الماضي، ',
                ),
                TextSpan(
                  text: 'والوجوه العابرة تخفي قصصًا لم تُروَ بعد.',
                  style: TextStyle(
                    backgroundColor: const Color(
                      0xFFF38181,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                const TextSpan(
                  text:
                      ' هناك، في ليلة بدا فيها كل شيء عاديًا، تظهر بوابة غامضة تقود إلى زمن آخر...\n\n',
                ),
                TextSpan(
                  text: 'زمن يرتبط',
                  style: const TextStyle(
                    backgroundColor: Color(0xFFFFBD10),
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text:
                      ' بسر عائلة الرياح المؤسسة. العائلة التي بُنيت المدينة على أنقاض قوتها واختفائها المفاجئ. تبدأ الرحلة حين يجد الأبطال أنفسهم أمام سلسلة من الأحداث التي تتجاوز حدود الواقع.\n\nحيث تختلط الذكريات بالأحلام، ويصبح من الصعب التفرقة بين الحقيقة والوهم. ومع كل خطوة داخل هذا العالم الغامض، \n\nتتكشف أسرار قديمة عن السلطة، الخيانة، والتحالفات التي شكّلت مصير المدينة لسنوات طويلة. في مدينة لا تنام، تُعرف بين سكانها باسم "مدينة الوهم". كانت الأضواء دائمًا تخفي أكثر مما تكشف. الشوارع القديمة تحمل همسات الماضي،',
                ),
              ],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionBody() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _clearSelection,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chapterTitle ?? '',
              style: TextStyle(
                color: _themeTextColor,
                fontSize: _fontSize + 6,
                fontWeight: FontWeight.bold,
                fontFamily: _fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              readOnly: true,
              maxLines: null,
              showCursor: false,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.justify,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.9,
                fontFamily: _fontFamily,
              ),
              contextMenuBuilder: (context, editableTextState) {
                final currentMatch = _currentSelectionMatch();
                final isBookmarked =
                    currentMatch != null && _isBookmarkedRange(currentMatch);
                return AdaptiveTextSelectionToolbar(
                  anchors: editableTextState.contextMenuAnchors,
                  children: [
                    // Play Button
                    GestureDetector(
                      onTap: () {
                        final match = _currentSelectionMatch();
                        editableTextState.hideToolbar();
                        if (match != null) {
                          _startSelectionPlayback(
                            match.firstSegmentIndex,
                            match.lastSegmentIndex,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'استمع',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'ThmanyahSans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.white24),
                    GestureDetector(
                      onTap: () {
                        final match = _currentSelectionMatch();
                        editableTextState.hideToolbar();
                        if (match != null) {
                          unawaited(_bookmarkSelection(match));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBookmarked
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                              color: isBookmarked
                                  ? const Color(0xFFFFBD10)
                                  : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'بوك مارك',
                              style: TextStyle(
                                color: isBookmarked
                                    ? const Color(0xFFFFBD10)
                                    : Colors.white,
                                fontSize: 14,
                                fontFamily: 'ThmanyahSans',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _segmentHighlight(int index) {
    if (index == _playingSegmentIndex) {
      return const Color(0xFFFFC00E); // currently playing sentence
    }
    final startIndex = _selectedStartSegmentIndex;
    final endIndex = _selectedEndSegmentIndex;
    if (startIndex != null &&
        endIndex != null &&
        index >= startIndex &&
        index <= endIndex) {
      return const Color(0xFFFFC00E).withValues(alpha: 0.3);
    }
    if (_bookmarkedSegmentIndexes.contains(index)) {
      return const Color(0xFFFFBD10).withValues(alpha: 0.18);
    }
    return Colors.transparent;
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات القراءة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'خط القراءة',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children:
                        [
                          'ThmanyahSans',
                          'System',
                          'Courier',
                          'Times New Roman',
                        ].map((font) {
                          final isSelected = _fontFamily == font;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _fontFamily = font;
                                });
                                setModalState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFBD10)
                                      : const Color(0xFF333333),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  font == 'ThmanyahSans' ? 'ثمانية' : font,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF1F1F1F)
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontFamily: font,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حجم الخط',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'ThmanyahSans',
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_fontSize > 12) {
                                setState(() {
                                  _fontSize -= 2;
                                });
                                setModalState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF333333),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _fontSize.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ThmanyahSans',
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              if (_fontSize < 36) {
                                setState(() {
                                  _fontSize += 2;
                                });
                                setModalState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF333333),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'مظهر الصفحة',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildThemeOption(
                        themeName: 'داكن',
                        bg: const Color(0xFF040707),
                        text: Colors.white,
                        secondary: Colors.white54,
                        setModalState: setModalState,
                      ),
                      _buildThemeOption(
                        themeName: 'سيبيا',
                        bg: const Color(0xFFFBF0D9),
                        text: const Color(0xFF5B4636),
                        secondary: const Color(0xFF8B7355),
                        setModalState: setModalState,
                      ),
                      _buildThemeOption(
                        themeName: 'فاتح',
                        bg: const Color(0xFFF4F4F4),
                        text: const Color(0xFF1F1F1F),
                        secondary: const Color(0xFF7F7F7F),
                        setModalState: setModalState,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String themeName,
    required Color bg,
    required Color text,
    required Color secondary,
    required StateSetter setModalState,
  }) {
    final isSelected = _themeBgColor == bg;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _themeBgColor = bg;
            _themeTextColor = text;
            _themeSecondaryTextColor = secondary;
          });
          setModalState(() {});
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFBD10)
                  : const Color(0xFF444444),
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Text(
            themeName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'ThmanyahSans',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(double width, bool isActive) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: isActive
            ? _themeTextColor
            : _themeTextColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildChapterProgressSegment(
    Chapter chapter,
    double progress,
    bool isCurrent,
  ) {
    final fillColor = isCurrent ? const Color(0xFFFFC00E) : _themeTextColor;

    return Expanded(
      flex: _chapterProgressUnit(chapter),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: _themeTextColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: FractionallySizedBox(
          alignment: Alignment.centerRight,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  int _chapterProgressUnit(Chapter chapter) {
    final start = chapter.startPage ?? 1;
    final end = chapter.endPage ?? start;
    return (end - start + 1).clamp(1, 1000);
  }

  Widget _buildTextPopup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6.3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.share_outlined, color: Colors.black, size: 20),
          _buildPopupDivider(),
          const Icon(Icons.format_quote, color: Colors.black, size: 20),
          _buildPopupDivider(),
          Row(
            children: [
              _buildColorCircle(const Color(0xFFFFAE56)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFFFFDA62)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFFF38181)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFFAA96DA)),
              const SizedBox(width: 4),
              _buildColorCircle(const Color(0xFF609966)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      height: 20,
      color: Colors.black12,
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildCaptionTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFBD10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'زمن يرتبط',
        style: TextStyle(
          color: Color(0xFF1F1F1F),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'ThmanyahSans',
        ),
      ),
    );
  }

  void _showChaptersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Color(0xFF0C0C0C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Row(
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
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chapter List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
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
                          final isCurrent = chapter.id == widget.chapterId;
                          return [
                            _buildChapterItem(chapter, isCurrent),
                            if (entry.key != widget.chapters.length - 1)
                              const SizedBox(height: 12),
                          ];
                        }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterItem(Chapter chapter, bool isCurrent) {
    final hasAudio = chapter.audioUrl.trim().isNotEmpty;

    return Opacity(
      opacity: isCurrent ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            // Left side: Play (audio only) + Read (close sheet & navigate)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAudio)
                  GestureDetector(
                    onTap: () {
                      context.read<AudioProvider>().playReadingAudio(
                        bookId: widget.bookId ?? '',
                        title: widget.bookTitle ?? '',
                        chapterId: chapter.id,
                        audioUrl: chapter.audioUrl,
                        autoplay: true,
                      );
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset(
                      'assets/play.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white54,
                        BlendMode.srcIn,
                      ),
                      width: 24,
                      height: 24,
                    ),
                  ),
                if (hasAudio) const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    if (!isCurrent) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          settings: const RouteSettings(
                            name: AppRoutes.bookReader,
                          ),
                          builder: (_) => BookReaderScreen(
                            bookId: widget.bookId,
                            chapterId: chapter.id,
                            pdfUrl: widget.pdfUrl,
                            startPage: chapter.startPage,
                            endPage: chapter.endPage,
                            bookTitle: widget.bookTitle,
                            chapterTitle: chapter.title,
                            audioUrl: chapter.audioUrl,
                            transcription: chapter.transcription,
                            chapters: widget.chapters,
                          ),
                        ),
                      );
                    }
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
            // Middle side: Chapter Title and duration
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  if (!isCurrent) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(
                          name: AppRoutes.bookReader,
                        ),
                        builder: (_) => BookReaderScreen(
                          bookId: widget.bookId,
                          chapterId: chapter.id,
                          pdfUrl: widget.pdfUrl,
                          startPage: chapter.startPage,
                          endPage: chapter.endPage,
                          bookTitle: widget.bookTitle,
                          chapterTitle: chapter.title,
                          audioUrl: chapter.audioUrl,
                          transcription: chapter.transcription,
                          chapters: widget.chapters,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 12,
                        fontFamily: 'ThmanyahSans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right side: Audio wave if chapter has audio, otherwise index circle
            if (hasAudio)
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
    bool isCurrent,
  ) {
    return Opacity(
      opacity: isCurrent ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: SvgPicture.asset(
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
                  onTap: () => Navigator.pop(context),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 12,
                      fontFamily: 'ThmanyahSans',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (isCurrent)
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

  void _onSelectionChanged() {
    final match = _transcriptTextIndex.resolveSelection(
      _textController.selection,
    );

    if (match == null) {
      _resetLoggedSelection();
      if (_selectedSegmentIndex != null ||
          _selectedStartSegmentIndex != null ||
          _selectedEndSegmentIndex != null) {
        setState(_resetSelectedTextState);
      }
      return;
    }

    _debugPrintTranscriptSelection(match);
    if (_selectedSegmentIndex !=
            (match.firstSegmentIndex == match.lastSegmentIndex
                ? match.firstSegmentIndex
                : null) ||
        _selectedStartSegmentIndex != match.firstSegmentIndex ||
        _selectedEndSegmentIndex != match.lastSegmentIndex) {
      setState(() {
        _selectedSegmentIndex =
            match.firstSegmentIndex == match.lastSegmentIndex
            ? match.firstSegmentIndex
            : null;
        _selectedStartSegmentIndex = match.firstSegmentIndex;
        _selectedEndSegmentIndex = match.lastSegmentIndex;
      });
    }
  }

  TranscriptSelectionMatch? _currentSelectionMatch() {
    final selectedTextMatch = _transcriptTextIndex.resolveSelection(
      _textController.selection,
    );
    if (selectedTextMatch != null) return selectedTextMatch;

    final firstIndex = _selectedStartSegmentIndex ?? _selectedSegmentIndex;
    final lastIndex = _selectedEndSegmentIndex ?? _selectedSegmentIndex;
    if (firstIndex == null || lastIndex == null) return null;

    return _transcriptTextIndex.resolveSegmentRange(firstIndex, lastIndex);
  }

  bool _isBookmarkedRange(TranscriptSelectionMatch match) {
    return _bookmarks.any(
      (bookmark) =>
          bookmark.firstSegmentIndex == match.firstSegmentIndex &&
          bookmark.lastSegmentIndex == match.lastSegmentIndex,
    );
  }

  Future<void> _bookmarkSelection(TranscriptSelectionMatch match) async {
    _debugPrintTranscriptSelection(match);

    final bookId = _bookmarkBookStorageId;
    final chapterId = _bookmarkChapterStorageId;
    final updatedBookmarks = await BookmarkService.saveBookmark(
      bookId: bookId,
      chapterId: chapterId,
      bookmark: BookReaderBookmark(
        firstSegmentIndex: match.firstSegmentIndex,
        lastSegmentIndex: match.lastSegmentIndex,
        text: match.selectedText,
        audioStart: match.audioStart,
        audioEnd: match.audioEnd,
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted ||
        bookId != _bookmarkBookStorageId ||
        chapterId != _bookmarkChapterStorageId) {
      return;
    }

    _setTextSelectionSilently(const TextSelection.collapsed(offset: 0));
    setState(() {
      _applyBookmarks(updatedBookmarks);
      _resetSelectedTextState();
    });

    assert(() {
      debugPrint(
        '[BookReader] bookmark saved: '
        '${match.firstSegmentIndex}-${match.lastSegmentIndex}',
      );
      return true;
    }());
  }

  void _setTextSelectionSilently(TextSelection selection) {
    _textController.removeListener(_onSelectionChanged);
    _textController.selection = selection;
    _textController.addListener(_onSelectionChanged);
  }

  void _resetLoggedSelection() {
    _lastLoggedSelectionStart = -1;
    _lastLoggedSelectionEnd = -1;
  }

  void _resetSelectedTextState() {
    _selectedSegmentIndex = null;
    _selectedStartSegmentIndex = null;
    _selectedEndSegmentIndex = null;
    _resetLoggedSelection();
  }

  void _resetSelectionPlaybackState() {
    _isSelectionPlaybackMode = false;
    _selectionPlayStart = null;
    _selectionPlayEnd = null;
    _selectionPlaybackStartSegmentIndex = null;
    _selectionPlaybackEndSegmentIndex = null;
    _playUntilMs = null;
    _playingSegmentIndex = null;
  }

  bool _isCurrentReadingAudio(AudioProvider audio) {
    return audio.isActiveReadingBook(
      widget.bookId ?? '',
      chapterId: widget.chapterId,
    );
  }

  void _finishSelectionPlayback({required bool stopAudio}) {
    final audio = _audio ?? context.read<AudioProvider>();
    if (stopAudio && _isCurrentReadingAudio(audio)) {
      unawaited(audio.stop());
    }

    _setTextSelectionSilently(const TextSelection.collapsed(offset: 0));
    setState(() {
      _resetSelectionPlaybackState();
      _resetSelectedTextState();
    });
  }

  void _debugPrintTranscriptSelection(TranscriptSelectionMatch match) {
    if (_lastLoggedSelectionStart == match.textRange.start &&
        _lastLoggedSelectionEnd == match.textRange.end) {
      return;
    }
    _lastLoggedSelectionStart = match.textRange.start;
    _lastLoggedSelectionEnd = match.textRange.end;

    assert(() {
      debugPrint('[BookReader] selected text: "${match.selectedText}"');
      debugPrint(
        '[BookReader] selection audio range: '
        '${match.audioStart.toStringAsFixed(3)}s -> '
        '${match.audioEnd.toStringAsFixed(3)}s',
      );
      return true;
    }());
  }

  void _startSelectionPlayback(int firstIdx, int lastIdx) {
    final match = _transcriptTextIndex.resolveSegmentRange(firstIdx, lastIdx);
    if (match == null || match.audioEnd <= match.audioStart) return;

    _debugPrintTranscriptSelection(match);

    setState(() {
      _isSelectionPlaybackMode = true;
      _selectionPlayStart = match.audioStart;
      _selectionPlayEnd = match.audioEnd;
      _selectionPlaybackStartSegmentIndex = match.firstSegmentIndex;
      _selectionPlaybackEndSegmentIndex = match.lastSegmentIndex;
      _playUntilMs = (match.audioEnd * 1000).round();
      _selectedSegmentIndex = match.firstSegmentIndex == match.lastSegmentIndex
          ? match.firstSegmentIndex
          : null;
      _selectedStartSegmentIndex = match.firstSegmentIndex;
      _selectedEndSegmentIndex = match.lastSegmentIndex;
    });

    final audio = _audio ?? context.read<AudioProvider>();
    final alreadyActive = audio.isActiveReadingBook(
      widget.bookId ?? '',
      chapterId: widget.chapterId,
    );

    if (alreadyActive) {
      audio.seekTo(match.audioStart);
      if (!audio.isPlaying) audio.play();
    } else {
      unawaited(
        audio.playReadingAudio(
          bookId: widget.bookId ?? '',
          title: widget.bookTitle ?? '',
          chapterId: widget.chapterId,
          audioUrl: widget.audioUrl,
          autoplay: true,
          initialPosition: Duration(
            milliseconds: (match.audioStart * 1000).round(),
          ),
        ),
      );
    }
  }

  void _exitSelectionPlayback() {
    _finishSelectionPlayback(stopAudio: true);
  }

  void _togglePlayPause() {
    final audio = _audio ?? context.read<AudioProvider>();
    final alreadyActive = audio.isActiveReadingBook(
      widget.bookId ?? '',
      chapterId: widget.chapterId,
    );

    if (_isSelectionPlaybackMode &&
        _selectionPlayStart != null &&
        _selectionPlayEnd != null) {
      if (alreadyActive) {
        final currentPosSec = audio.currentPosition.inMilliseconds / 1000.0;
        if (currentPosSec >= _selectionPlayEnd! - 0.1 ||
            currentPosSec < _selectionPlayStart! - 0.1) {
          audio.seekTo(_selectionPlayStart!);
        }
        _playUntilMs = (_selectionPlayEnd! * 1000).round();
        unawaited(audio.togglePlayPause());
      } else if (_selectionPlaybackStartSegmentIndex != null &&
          _selectionPlaybackEndSegmentIndex != null) {
        _startSelectionPlayback(
          _selectionPlaybackStartSegmentIndex!,
          _selectionPlaybackEndSegmentIndex!,
        );
      }
    }
  }

  void _seekRelative(int seconds) {
    final audio = _audio ?? context.read<AudioProvider>();
    final alreadyActive = audio.isActiveReadingBook(
      widget.bookId ?? '',
      chapterId: widget.chapterId,
    );
    if (!alreadyActive || !audio.state.canSeek) return;

    final currentPosition = audio.currentPosition;
    final newPosition = currentPosition + Duration(seconds: seconds);

    Duration clamped;
    if (_isSelectionPlaybackMode &&
        _selectionPlayStart != null &&
        _selectionPlayEnd != null) {
      final start = Duration(
        milliseconds: (_selectionPlayStart! * 1000).round(),
      );
      final end = Duration(milliseconds: (_selectionPlayEnd! * 1000).round());
      clamped = newPosition < start
          ? start
          : (newPosition > end ? end : newPosition);
      _playUntilMs = end.inMilliseconds;
    } else {
      clamped = newPosition < Duration.zero
          ? Duration.zero
          : (newPosition > audio.duration ? audio.duration : newPosition);
    }
    audio.seekTo(clamped.inMilliseconds / 1000.0);
  }
}

class RichTextEditingController extends TextEditingController {
  RichTextEditingController({required String text, required this.buildSpan})
    : super(text: text);

  final TextSpan Function(BuildContext context, TextStyle? style) buildSpan;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return buildSpan(context, style);
  }
}
