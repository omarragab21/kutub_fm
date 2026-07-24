import 'package:flutter/foundation.dart';

import '../../../../core/audio/audio_models.dart';
import '../../../../core/audio/audio_provider.dart';
import '../../data/repositories/fm_radio_repository_impl.dart';
import '../../domain/fm_station.dart';
import '../../domain/repositories/fm_radio_repository.dart';

enum FmRadioLoadState { idle, loading, loaded, empty, failure }

class FmRadioViewModel extends ChangeNotifier {
  FmRadioViewModel({FmRadioRepository? repository})
    : _repository = repository ?? FmRadioRepositoryImpl();

  final FmRadioRepository _repository;

  AudioProvider? _audioProvider;
  List<FmStation> _allStations = [];
  List<FmStation> _filteredStations = [];
  FmRadioLoadState _loadState = FmRadioLoadState.idle;
  String? _errorMessage;
  String _searchQuery = '';
  bool _quranOnly = false;

  List<FmStation> get stations => List.unmodifiable(_filteredStations);
  FmStation? get currentStation => _audioProvider?.currentStation;
  FmRadioLoadState get loadState => _loadState;
  bool get isDataLoading => _loadState == FmRadioLoadState.loading;
  String? get errorMessage => _errorMessage;
  bool get isQuranOnly => _quranOnly;

  bool get isPlaying =>
      _audioProvider?.currentMode == AudioMode.fmRadio &&
      (_audioProvider?.isPlaying ?? false);

  bool get isLoading =>
      _audioProvider?.currentMode == AudioMode.fmRadio &&
      (_audioProvider?.isLoading ?? false);

  void bindAudioProvider(AudioProvider audioProvider) {
    if (identical(_audioProvider, audioProvider)) return;

    _audioProvider?.removeListener(_onAudioProviderChanged);
    _audioProvider = audioProvider;
    _audioProvider?.addListener(_onAudioProviderChanged);
  }

  Future<void> fetchStations() async {
    _loadState = FmRadioLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allStations = await _repository.getStations(quranOnly: _quranOnly);
      _applySearch();
      _loadState = _filteredStations.isEmpty
          ? FmRadioLoadState.empty
          : FmRadioLoadState.loaded;
    } catch (error, stackTrace) {
      debugPrint('FM Radio Firebase Error: $error\n$stackTrace');
      _allStations = [];
      _filteredStations = [];
      _loadState = FmRadioLoadState.failure;
      _errorMessage =
          'حدث خطأ أثناء جلب محطات الراديو من Firebase. يرجى المحاولة لاحقاً.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchStations();

  void setQuranFilter(bool value) {
    if (_quranOnly == value) return;
    _quranOnly = value;
    fetchStations();
  }

  void searchStations(String query) {
    _searchQuery = query.trim();
    _applySearch();
    if (_loadState != FmRadioLoadState.loading &&
        _loadState != FmRadioLoadState.failure) {
      _loadState = _filteredStations.isEmpty
          ? FmRadioLoadState.empty
          : FmRadioLoadState.loaded;
    }
    notifyListeners();
  }

  Future<void> playStation(FmStation station) async {
    final audioProvider = _audioProvider;
    if (audioProvider == null) return;

    if (currentStation?.id == station.id &&
        audioProvider.currentMode == AudioMode.fmRadio &&
        (audioProvider.currentTrack?.isLive ?? false)) {
      await audioProvider.togglePlayPause();
      return;
    }

    try {
      await audioProvider.playStation(station, streamUrl: station.streamUrl);
    } catch (error, stackTrace) {
      debugPrint('FM Radio Play Error: $error\n$stackTrace');
      _errorMessage = 'تعذر تشغيل هذه المحطة حالياً.';
      notifyListeners();
    }
  }

  Future<void> playRadioEpisode({
    required FmStation station,
    required RadioProgram program,
    required RadioAudio audio,
  }) async {
    final audioProvider = _audioProvider;
    if (audioProvider == null) return;

    if (audioProvider.currentMode == AudioMode.fmRadio &&
        audioProvider.currentTrack?.id == audio.id) {
      await audioProvider.togglePlayPause();
      return;
    }

    try {
      await audioProvider.playRadioAudioEpisode(
        station: station,
        program: program,
        audio: audio,
      );
    } catch (error, stackTrace) {
      debugPrint('FM Radio Episode Play Error: $error\n$stackTrace');
      _errorMessage = 'تعذر تشغيل هذه الحلقة حالياً.';
      notifyListeners();
    }
  }

  bool isEpisodePlaying(String audioId) {
    return _audioProvider?.currentMode == AudioMode.fmRadio &&
        _audioProvider?.currentTrack?.id == audioId &&
        (_audioProvider?.isPlaying ?? false);
  }


  Future<void> togglePlayPause() async {
    await _audioProvider?.togglePlayPause();
  }

  Future<void> stop() async {
    await _audioProvider?.stop();
  }

  @override
  void dispose() {
    _audioProvider?.removeListener(_onAudioProviderChanged);
    super.dispose();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredStations = _allStations;
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredStations = _allStations
        .where((station) {
          return station.name.toLowerCase().contains(query) ||
              station.tagline.toLowerCase().contains(query) ||
              station.frequencyLabel.contains(query);
        })
        .toList(growable: false);
  }

  void _onAudioProviderChanged() {
    notifyListeners();
  }
}
