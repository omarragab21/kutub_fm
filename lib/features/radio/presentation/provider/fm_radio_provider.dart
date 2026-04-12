import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kutub_fm/features/radio/data/radio_browser_service.dart';

import '../../../../core/audio/audio_provider.dart';
import '../../../../core/audio/audio_models.dart';
import '../../domain/fm_station.dart';

class FmRadioProvider extends ChangeNotifier {
  final RadioBrowserService _service = RadioBrowserService();

  AudioProvider? _audioProvider;
  List<FmStation> _allStations = [];
  List<FmStation> _filteredStations = [];
  bool _isDataLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _quranOnly = false;

  List<FmStation> get stations => _filteredStations;
  FmStation? get currentStation => _audioProvider?.currentStation;
  bool get isPlaying =>
      _audioProvider?.currentMode == AudioMode.fmRadio &&
      (_audioProvider?.isPlaying ?? false);
  bool get isLoading =>
      _audioProvider?.currentMode == AudioMode.fmRadio &&
      (_audioProvider?.isLoading ?? false);
  bool get isDataLoading => _isDataLoading;
  String? get errorMessage => _errorMessage;
  bool get isQuranOnly => _quranOnly;

  void bindAudioProvider(AudioProvider audioProvider) {
    if (identical(_audioProvider, audioProvider)) return;

    _audioProvider?.removeListener(_onAudioProviderChanged);
    _audioProvider = audioProvider;
    _audioProvider?.addListener(_onAudioProviderChanged);
  }

  Future<void> fetchStations() async {
    _isDataLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allStations = await _service.fetchEgyptStations(quranOnly: _quranOnly);
      _filteredStations = _allStations;
      if (_searchQuery.isNotEmpty) {
        searchStations(_searchQuery);
      }
    } catch (_) {
      _errorMessage =
          'حدث خطأ أثناء جلب المحطات المصرية. يرجى المحاولة لاحقاً.';
    } finally {
      _isDataLoading = false;
      notifyListeners();
    }
  }

  void setQuranFilter(bool value) {
    if (_quranOnly == value) return;
    _quranOnly = value;
    fetchStations();
  }

  void searchStations(String query) {
    _searchQuery = query;
    if (_searchQuery.isEmpty) {
      _filteredStations = _allStations;
    } else {
      _filteredStations = _allStations.where((station) {
        return station.name.toLowerCase().contains(query.toLowerCase()) ||
            station.tagline.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  Future<void> playStation(FmStation station) async {
    final audioProvider = _audioProvider;
    if (audioProvider == null) return;

    if (currentStation?.id == station.id &&
        audioProvider.currentMode == AudioMode.fmRadio) {
      await audioProvider.togglePlayPause();
      return;
    }

    try {
      final resolvedUrl = await _service.getPlayableUrl(station.id);
      var streamUrlToPlay = resolvedUrl ?? station.streamUrl;

      if (streamUrlToPlay.startsWith('http://')) {
        streamUrlToPlay = streamUrlToPlay.replaceFirst('http://', 'https://');
      }

      await audioProvider.playStation(station, streamUrl: streamUrlToPlay);
    } catch (error) {
      debugPrint('FM Radio Play Error: $error');
    }
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

  void _onAudioProviderChanged() {
    notifyListeners();
  }
}
