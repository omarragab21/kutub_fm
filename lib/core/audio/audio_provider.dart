import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../../features/audio_player/data/models/transcript_segment.dart';
import '../../features/audio_player/data/services/transcript_asset_loader.dart';
import '../../features/audio_player/domain/entities/audio_story.dart';
import '../../features/radio/domain/fm_station.dart';
import '../../features/podcast/domain/entities/podcast_episode.dart';
import '../../features/book_details/domain/entities/book_detail_model.dart';
import 'audio_models.dart';
import 'audio_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AudioProvider extends ChangeNotifier {
  AudioProvider({AudioService? audioService})
    : _audioService = audioService ?? AudioService() {
    _audioService.stateListenable.addListener(_handleServiceStateChanged);
  }

  // static const String _spokenWordAssetPath = 'assets/audio_book.mp3';
  static const String _transcriptAssetPath = 'assets/transcript.json';

  final AudioService _audioService;
  final TranscriptAssetLoader _transcriptLoader = const TranscriptAssetLoader();
  final List<AudioStory> _stories = AudioStory.mockList;
  final Map<String, bool> _likedStories = {};

  int _currentIndex = 0;
  double _spokenWordSpeed = 1.0;
  TranscriptDocument? _transcript;
  bool _isLoadingTranscript = false;
  String? _transcriptError;
  FmStation? _currentStation;
  String? _currentReadingBookId;
  String? _currentReadingChapterId;
  String? _currentReadingBookTitle;
  String? _currentPodcastEpisodeId;
  String? _currentBookId;
  Timer? _listeningTimer;
  int _accumulatedSeconds = 0;


  AudioState get state => _audioService.state;
  AudioMode get currentMode => state.mode;
  AudioTrack? get currentTrack => state.currentTrack;

  List<AudioStory> get stories => List.unmodifiable(_stories);
  int get currentIndex => _currentIndex;
  AudioStory get currentStory => _stories[_currentIndex];
  TranscriptDocument? get transcript => _transcript;
  bool get isLoadingTranscript => _isLoadingTranscript;
  String? get transcriptError => _transcriptError;
  bool get isPlaying => state.isPlaying;
  bool get isLoading => state.isLoading || state.isBuffering;
  bool get isBuffering => state.isBuffering;
  Duration get currentPosition => state.position;
  Duration get bufferedPosition => state.bufferedPosition;
  Duration get duration => state.duration;
  double get speed => state.speed;
  double get spokenWordSpeed => _spokenWordSpeed;
  double get volume => state.volume;
  String? get errorMessage => state.errorMessage;
  bool get hasActiveAudio => state.hasSource;
  bool get shouldShowMiniPlayer => hasActiveAudio;
  bool get isLiveMode => currentTrack?.isLive ?? false;
  String get miniPlayerTitle => currentTrack?.title ?? 'مشغل الصوت';
  String get miniPlayerSubtitle {
    final artist = currentTrack?.artist?.trim();
    if (artist != null && artist.isNotEmpty) {
      return artist;
    }

    switch (currentMode) {
      case AudioMode.audiobook:
        return 'كتاب صوتي';
      case AudioMode.readingAudio:
        return 'القراءة الصوتية';
      case AudioMode.fmRadio:
        return 'بث مباشر';
      case AudioMode.podcast:
        return 'بودكاست';
      case AudioMode.idle:
        return '';
    }
  }

  String? get miniPlayerArtworkUrl => currentTrack?.artUri;
  double get progressValue {
    if (duration.inMilliseconds <= 0 || isLiveMode) {
      return 0.0;
    }

    return (currentPosition.inMilliseconds / duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  FmStation? get currentStation =>
      currentMode == AudioMode.fmRadio ? _currentStation : null;
  String? get currentReadingBookId => _currentReadingBookId;
  String? get currentReadingChapterId => _currentReadingChapterId;
  String? get currentReadingBookTitle => _currentReadingBookTitle;
  String? get currentPodcastEpisodeId => _currentPodcastEpisodeId;
  String? get currentBookId => _currentBookId;
  int get currentPositionSeconds => currentPosition.inSeconds;
  int get totalDurationSeconds {
    if (duration > Duration.zero) {
      return duration.inSeconds;
    }

    if (currentMode == AudioMode.audiobook) {
      return currentStory.totalDurationSeconds;
    }

    return 0;
  }

  Future<void> initialize() => _audioService.initialize();

  bool isLiked(String storyId) => _likedStories[storyId] ?? false;

  bool isCurrentMode(AudioMode mode) => currentMode == mode;

  bool isActiveStory(AudioStory story) =>
      currentMode == AudioMode.audiobook && currentTrack?.id == story.id;

  bool isActiveReadingBook(String bookId, {String? chapterId}) =>
      currentMode == AudioMode.readingAudio &&
      currentTrack?.id == _readingTrackId(bookId, chapterId: chapterId);

  Future<void> ensureAudiobookLoaded({
    int? index,
    bool autoplay = false,
    Duration initialPosition = Duration.zero,
  }) async {
    final track = currentTrack;
    if (track == null || track.id.startsWith('story_')) {
      if (_stories.isEmpty || !_stories.first.id.startsWith('story_')) {
        _stories.clear();
        _stories.addAll(AudioStory.mockList);
        if (_currentIndex >= _stories.length) {
          _currentIndex = 0;
        }
      }
    }

    if (index != null && index >= 0 && index < _stories.length) {
      _currentIndex = index;
    }

    unawaited(_ensureTranscriptLoaded());

    final story = currentStory;
    _clearReadingContext();
    _currentStation = null;
    _currentBookId = story.id;
    _markBookAsListened(story.id);

    if (isActiveStory(story)) {
      if (initialPosition != Duration.zero) {
        await _audioService.seek(initialPosition);
      }
      if (autoplay && !isPlaying) {
        await _audioService.play();
      }
      notifyListeners();
      return;
    }

    final rawSource = story.audioUrl?.trim();
    if (rawSource == null || rawSource.isEmpty) {
      debugPrint('Audio URL is empty for story ${story.id}.');
      notifyListeners();
      return;
    }
    final source = rawSource;
    const inputType = AudioInputType.uri;

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: story.id,
          mode: AudioMode.audiobook,
          inputType: inputType,
          source: source,
          title: story.title,
          artist: story.author,
          album: story.category,
          artUri: story.coverUrl.isNotEmpty ? story.coverUrl : null,
        ),
        autoplay: autoplay,
        initialPosition: initialPosition,
        speed: _spokenWordSpeed,
      );
    } catch (_) {
      // Error state is already reflected in AudioService.
    }

    notifyListeners();
  }

  String? _currentReadingBookAudioUrl;

  String? get currentReadingBookAudioUrl => _currentReadingBookAudioUrl;

  Future<void> playReadingAudio({
    required String bookId,
    required String title,
    String? chapterId,
    String? audioUrl,
    bool autoplay = true,
    Duration initialPosition = Duration.zero,
  }) async {
    final rawSource = audioUrl?.trim();
    if (rawSource == null || rawSource.isEmpty) {
      debugPrint('Reading audio URL is empty for book $bookId.');
      notifyListeners();
      return;
    }

    _currentStation = null;
    _currentReadingBookId = bookId;
    _currentReadingChapterId = chapterId;
    _currentReadingBookTitle = title;
    _currentReadingBookAudioUrl = rawSource;
    _currentBookId = bookId;
    _markBookAsListened(bookId);

    if (isActiveReadingBook(bookId, chapterId: chapterId)) {
      if (initialPosition != Duration.zero) {
        await _audioService.seek(initialPosition);
      }
      if (autoplay && !isPlaying) {
        await _audioService.play();
      }
      notifyListeners();
      return;
    }

    final source = rawSource;
    const inputType = AudioInputType.uri;

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: _readingTrackId(bookId, chapterId: chapterId),
          mode: AudioMode.readingAudio,
          inputType: inputType,
          source: source,
          title: title,
          artist: 'القراءة الصوتية',
          album: 'كتاب صوتي',
        ),
        autoplay: autoplay,
        initialPosition: initialPosition,
        speed: _spokenWordSpeed,
      );
    } catch (_) {
      // Error state is already reflected in AudioService.
    }

    notifyListeners();
  }

  bool isActiveChapter(String chapterId) =>
      currentMode == AudioMode.audiobook && currentTrack?.id == chapterId;

  Future<void> playChapterAudio({
    required String bookId,
    required Chapter chapter,
    required List<Chapter> chapters,
    required String bookTitle,
    String? bookCoverUrl,
    String? author,
    bool autoplay = true,
    Duration initialPosition = Duration.zero,
  }) async {
    if (!chapter.isReadableAudio) {
      debugPrint('Chapter ${chapter.id} is missing transcript or audio URL.');
      notifyListeners();
      return;
    }

    final availableChapters = chapters
        .where((ch) => ch.isReadableAudio)
        .toList(growable: false);
    if (availableChapters.isEmpty) {
      debugPrint('No playable chapters available for book $bookId.');
      notifyListeners();
      return;
    }

    _clearReadingContext();
    _currentStation = null;
    _currentBookId = bookId;
    _markBookAsListened(bookId);

    // Convert all chapters to AudioStory entities
    final chaptersStories = availableChapters.map((ch) {
      return AudioStory(
        id: ch.id,
        title: ch.title,
        author: author ?? 'غير معروف',
        description: 'شابتر من كتاب $bookTitle',
        category: bookTitle,
        coverUrl: bookCoverUrl ?? '',
        totalDurationSeconds: _parseDurationToSeconds(ch.duration),
        likes: 0,
        comments: 0,
        shares: 0,
        saves: 0,
        audioUrl: ch.audioUrl,
        transcript: ch.transcript,
      );
    }).toList();

    _stories.clear();
    _stories.addAll(chaptersStories);

    final idx = chaptersStories.indexWhere((s) => s.id == chapter.id);
    if (idx != -1) {
      _currentIndex = idx;
    }

    if (isActiveChapter(chapter.id)) {
      if (initialPosition != Duration.zero) {
        await _audioService.seek(initialPosition);
      }
      if (autoplay && !isPlaying) {
        await _audioService.play();
      }
      notifyListeners();
      return;
    }

    // Extract audio source — prefer YouTube URL extraction, fall back to audioUrl
    String source = chapter.audioUrl;
    if (chapter.hasYoutubeUrl) {
      final yt = yt_explode.YoutubeExplode();
      try {
        final videoId = YoutubePlayer.convertUrlToId(chapter.youtubeUrl!);
        if (videoId != null) {
          final manifest = await yt.videos.streamsClient.getManifest(videoId);
          final streamInfo = manifest.audioOnly.withHighestBitrate();
          source = streamInfo.url.toString();
        }
      } catch (e) {
        debugPrint('Error extracting YouTube audio for chapter ${chapter.id}: $e');
      } finally {
        yt.close();
      }
    }

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: chapter.id,
          mode: AudioMode.audiobook,
          inputType: AudioInputType.uri,
          source: source,
          title: chapter.title,
          artist: author ?? 'غير معروف',
          album: bookTitle,
          artUri: bookCoverUrl,
        ),
        autoplay: autoplay,
        initialPosition: initialPosition,
        speed: _spokenWordSpeed,
      );
    } catch (_) {
      // Error handled by AudioService
    }

    notifyListeners();
  }

  Future<void> playStation(
    FmStation station, {
    required String streamUrl,
  }) async {
    _clearReadingContext();
    _currentStation = station;
    _currentBookId = null;

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: station.id,
          mode: AudioMode.fmRadio,
          inputType: AudioInputType.uri,
          source: streamUrl,
          title: station.name,
          artist: station.tagline,
          album: 'راديو مباشر',
          artUri: station.coverImageUrl,
          isLive: true,
        ),
        autoplay: true,
        speed: 1.0,
      );
    } catch (_) {
      _currentStation = null;
    }

    notifyListeners();
  }

  Future<void> playPodcast(PodcastEpisode episode) async {
    _clearReadingContext();
    _currentStation = null;
    _currentPodcastEpisodeId = episode.id;
    _currentBookId = null;

    try {
      String sourceUrl = episode.audioUrl;
      if (episode.youtubeUrl != null && episode.youtubeUrl!.isNotEmpty) {
        final yt = yt_explode.YoutubeExplode();
        try {
          final videoId = YoutubePlayer.convertUrlToId(episode.youtubeUrl!);
          if (videoId != null) {
            final manifest = await yt.videos.streamsClient.getManifest(videoId);
            final streamInfo = manifest.audioOnly.withHighestBitrate();
            sourceUrl = streamInfo.url.toString();
          }
        } catch (e) {
          debugPrint('Error extracting YouTube audio stream: $e');
        } finally {
          yt.close();
        }
      }

      await _audioService.loadTrack(
        AudioTrack(
          id: episode.id,
          mode: AudioMode.podcast,
          inputType: AudioInputType.uri,
          source: sourceUrl,
          title: episode.title,
          artist: 'بودكاست',
          album: episode.category,
          artUri: episode.imageUrl,
        ),
        autoplay: true,
      );
    } catch (_) {
      // Error handled by AudioService
    }

    notifyListeners();
  }

  void setPage(int index) {
    unawaited(selectStory(index, autoplay: true));
  }

  Future<void> selectStory(int index, {bool autoplay = true}) async {
    if (index < 0 || index >= _stories.length) return;
    _currentIndex = index;
    notifyListeners();
    await ensureAudiobookLoaded(index: index, autoplay: autoplay);
  }

  void play() {
    if (state.hasSource) {
      unawaited(_audioService.play());
      return;
    }

    unawaited(ensureAudiobookLoaded(autoplay: true));
  }

  void pause() {
    unawaited(_audioService.pause());
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _audioService.pause();
      return;
    }

    if (state.hasSource) {
      await _audioService.play();
      return;
    }

    await ensureAudiobookLoaded(autoplay: true);
  }

  void togglePlay() {
    unawaited(togglePlayPause());
  }

  void seekTo(double seconds) {
    unawaited(
      _audioService.seek(Duration(milliseconds: (seconds * 1000).round())),
    );
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> cycleSpokenWordSpeed() async {
    const speeds = <double>[0.75, 1.0, 1.25, 1.5, 2.0];
    final currentPosition = speeds.indexOf(_spokenWordSpeed);
    final nextPosition = (currentPosition + 1) % speeds.length;
    _spokenWordSpeed = speeds[nextPosition];

    if (currentMode == AudioMode.audiobook ||
        currentMode == AudioMode.readingAudio) {
      await _audioService.setSpeed(_spokenWordSpeed);
    } else {
      notifyListeners();
    }
  }

  void toggleLike() {
    final currentLikes = _likedStories[currentStory.id] ?? false;
    _likedStories[currentStory.id] = !currentLikes;
    notifyListeners();
  }

  Future<void> clearAudioCache() async {
    _transcript = null;
    _transcriptError = null;
    notifyListeners();
  }

  Future<void> stop() async {
    final previousMode = currentMode;
    await _audioService.stop();
    if (previousMode == AudioMode.fmRadio) {
      _currentStation = null;
    }
    if (previousMode == AudioMode.podcast) {
      _currentPodcastEpisodeId = null;
    }
    _clearReadingContext();
    _currentBookId = null;
    _listeningTimer?.cancel();
    _listeningTimer = null;
    _accumulatedSeconds = 0;
    notifyListeners();
  }

  Future<void> stopAudioCompletely() => stop();

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _audioService.stateListenable.removeListener(_handleServiceStateChanged);
    unawaited(_audioService.dispose());
    super.dispose();
  }

  Future<void> _ensureTranscriptLoaded() async {
    if (_transcript != null || _isLoadingTranscript) return;

    _isLoadingTranscript = true;
    _transcriptError = null;
    notifyListeners();

    try {
      _transcript = await _transcriptLoader.loadFromAsset(_transcriptAssetPath);
    } catch (error) {
      _transcriptError = error.toString();
    } finally {
      _isLoadingTranscript = false;
      notifyListeners();
    }
  }

  void _handleServiceStateChanged() {
    _updateListeningTimer();
    notifyListeners();
  }

  void _updateListeningTimer() {
    final user = FirebaseAuth.instance.currentUser;
    final isUserLoggedIn = user != null && !user.isAnonymous;
    final isTimerActive = isPlaying && isUserLoggedIn && _currentBookId != null;

    if (isTimerActive) {
      if (_listeningTimer == null) {
        _listeningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null || currentUser.isAnonymous) {
            timer.cancel();
            _listeningTimer = null;
            return;
          }
          _accumulatedSeconds++;
          if (_accumulatedSeconds >= 60) {
            _accumulatedSeconds = 0;
            _incrementListeningMinutes();
          }
        });
      }
    } else {
      _listeningTimer?.cancel();
      _listeningTimer = null;
    }
  }

  Future<void> _incrementListeningMinutes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final currentMinutes =
            (data['totalListeningMinutes'] as num?)?.toInt() ?? 0;
        final newMinutes = currentMinutes + 1;

        List<int> weekly = const [0, 0, 0, 0, 0, 0, 0];
        if (data['weeklyActivityMinutes'] != null) {
          weekly = List<int>.from(data['weeklyActivityMinutes']);
        }
        if (weekly.length != 7) {
          weekly = [0, 0, 0, 0, 0, 0, 0];
        }

        final weekdayIndex = DateTime.now().weekday - 1; // 0-based for Mon-Sun
        weekly[weekdayIndex] = weekly[weekdayIndex] + 1;

        transaction.update(userDocRef, {
          'totalListeningMinutes': newMinutes,
          'weeklyActivityMinutes': weekly,
        });
      });
    } catch (e) {
      debugPrint('Error incrementing listening minutes: $e');
    }
  }

  Future<void> _markBookAsListened(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final listenedDocRef = userDocRef
          .collection('listened_books')
          .doc(bookId);

      final doc = await listenedDocRef.get();
      if (!doc.exists) {
        await listenedDocRef.set({
          'bookId': bookId,
          'listenedAt': FieldValue.serverTimestamp(),
        });
        await userDocRef.update({
          'totalBooksListened': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error marking book as listened: $e');
    }
  }

  static String _readingTrackId(String bookId, {String? chapterId}) {
    final normalizedChapterId = chapterId?.trim();
    if (normalizedChapterId == null || normalizedChapterId.isEmpty) {
      return 'reading:$bookId';
    }
    return 'reading:$bookId:$normalizedChapterId';
  }

  void _clearReadingContext() {
    _currentReadingBookId = null;
    _currentReadingChapterId = null;
    _currentReadingBookTitle = null;
    _currentReadingBookAudioUrl = null;
  }

  static int _parseDurationToSeconds(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return minutes * 60 + seconds;
      } else if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        return hours * 3600 + minutes * 60 + seconds;
      }
    } catch (_) {}

    try {
      final hoursRegex = RegExp(r'(\d+)h');
      final minutesRegex = RegExp(r'(\d+)m');
      final secondsRegex = RegExp(r'(\d+)s');

      int total = 0;
      final hMatch = hoursRegex.firstMatch(durationStr);
      if (hMatch != null) {
        total += int.parse(hMatch.group(1)!) * 3600;
      }
      final mMatch = minutesRegex.firstMatch(durationStr);
      if (mMatch != null) {
        total += int.parse(mMatch.group(1)!) * 60;
      }
      final sMatch = secondsRegex.firstMatch(durationStr);
      if (sMatch != null) {
        total += int.parse(sMatch.group(1)!);
      }
      if (total > 0) return total;
    } catch (_) {}

    return 0;
  }

}
