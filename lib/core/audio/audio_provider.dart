import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/audio_player/data/models/transcript_segment.dart';
import '../../features/audio_player/data/services/transcript_asset_loader.dart';
import '../../features/audio_player/domain/entities/audio_story.dart';
import '../../features/radio/domain/fm_station.dart';
import '../../features/podcast/domain/entities/podcast_episode.dart';
import 'audio_models.dart';
import 'audio_service.dart';

class AudioProvider extends ChangeNotifier {
  AudioProvider({AudioService? audioService})
    : _audioService = audioService ?? AudioService() {
    _audioService.stateListenable.addListener(_handleServiceStateChanged);
  }

  static const String _spokenWordAssetPath = 'assets/audio_book.mp3';
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
  String? _currentReadingBookTitle;
  String? _currentPodcastEpisodeId;

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
  String? get currentReadingBookTitle => _currentReadingBookTitle;
  String? get currentPodcastEpisodeId => _currentPodcastEpisodeId;
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

  bool isActiveReadingBook(String bookId) =>
      currentMode == AudioMode.readingAudio &&
      currentTrack?.id == _readingTrackId(bookId);

  Future<void> ensureAudiobookLoaded({
    int? index,
    bool autoplay = false,
    Duration initialPosition = Duration.zero,
  }) async {
    if (index != null && index >= 0 && index < _stories.length) {
      _currentIndex = index;
    }

    unawaited(_ensureTranscriptLoaded());

    final story = currentStory;
    _clearReadingContext();
    _currentStation = null;

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

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: story.id,
          mode: AudioMode.audiobook,
          inputType: AudioInputType.asset,
          source: _spokenWordAssetPath,
          title: story.title,
          artist: story.author,
          album: story.category,
          artUri: story.coverUrl,
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

  Future<void> playReadingAudio({
    required String bookId,
    required String title,
    bool autoplay = true,
    Duration initialPosition = Duration.zero,
  }) async {
    _currentStation = null;
    _currentReadingBookId = bookId;
    _currentReadingBookTitle = title;

    if (isActiveReadingBook(bookId)) {
      if (initialPosition != Duration.zero) {
        await _audioService.seek(initialPosition);
      }
      if (autoplay && !isPlaying) {
        await _audioService.play();
      }
      notifyListeners();
      return;
    }

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: _readingTrackId(bookId),
          mode: AudioMode.readingAudio,
          inputType: AudioInputType.asset,
          source: _spokenWordAssetPath,
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

  Future<void> playStation(
    FmStation station, {
    required String streamUrl,
  }) async {
    _clearReadingContext();
    _currentStation = station;

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

    try {
      await _audioService.loadTrack(
        AudioTrack(
          id: episode.id,
          mode: AudioMode.podcast,
          inputType: AudioInputType.uri,
          source: episode.audioUrl,
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
    notifyListeners();
  }

  Future<void> stopAudioCompletely() => stop();

  @override
  void dispose() {
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
    notifyListeners();
  }

  static String _readingTrackId(String bookId) => 'reading:$bookId';

  void _clearReadingContext() {
    _currentReadingBookId = null;
    _currentReadingBookTitle = null;
  }
}
