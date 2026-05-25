import 'package:flutter/foundation.dart';
import 'package:kutub_fm/features/home/data/repositories/home_repository_impl.dart';
import 'package:kutub_fm/features/home/domain/entities/book_entity.dart';
import 'package:kutub_fm/features/home/domain/repositories/home_repository.dart';
import 'package:kutub_fm/features/podcast/data/podcast_mock_data.dart';
import 'package:kutub_fm/features/podcast/domain/entities/podcast_episode.dart';
import 'package:kutub_fm/features/radio/data/repositories/fm_radio_repository_impl.dart';
import 'package:kutub_fm/features/radio/domain/fm_station.dart';
import 'package:kutub_fm/features/radio/domain/repositories/fm_radio_repository.dart';

enum SearchState { initial, loading, success, empty, failure }

class SearchViewModel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  final FmRadioRepository _radioRepository;

  SearchViewModel({
    HomeRepository? homeRepository,
    FmRadioRepository? radioRepository,
  })  : _homeRepository = homeRepository ?? HomeRepositoryImpl(),
        _radioRepository = radioRepository ?? FmRadioRepositoryImpl();

  String _query = '';
  SearchState _state = SearchState.initial;
  String? _errorMessage;

  List<BookEntity> _allBooks = [];
  List<FmStation> _allStations = [];
  List<PodcastEpisode> _allPodcasts = [];

  List<BookEntity> _filteredBooks = [];
  List<FmStation> _filteredStations = [];
  List<PodcastEpisode> _filteredPodcasts = [];

  String get query => _query;
  SearchState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == SearchState.loading;

  List<BookEntity> get filteredBooks => _filteredBooks;
  List<FmStation> get filteredStations => _filteredStations;
  List<PodcastEpisode> get filteredPodcasts => _filteredPodcasts;

  int get totalResultsCount =>
      _filteredBooks.length + _filteredStations.length + _filteredPodcasts.length;

  Future<void> initSearchData() async {
    if (_allBooks.isNotEmpty && _allStations.isNotEmpty && _allPodcasts.isNotEmpty) {
      return;
    }

    try {
      final results = await Future.wait([
        _homeRepository.getRecommendedBooks(),
        _radioRepository.getStations(quranOnly: false),
      ]);

      _allBooks = results[0] as List<BookEntity>;
      _allStations = results[1] as List<FmStation>;
      _allPodcasts = PodcastMockData.buildEpisodes();
    } catch (e) {
      debugPrint('Search preloading error: $e');
      _allBooks = [];
      _allStations = [];
      _allPodcasts = PodcastMockData.buildEpisodes();
    }
  }

  Future<void> performSearch(String newQuery) async {
    _query = newQuery.trim();
    if (_query.isEmpty) {
      clearSearch();
      return;
    }

    _state = SearchState.loading;
    notifyListeners();

    try {
      await initSearchData();

      final searchPattern = _query.toLowerCase();

      // Filter Books by title or author
      _filteredBooks = _allBooks.where((book) {
        return book.title.toLowerCase().contains(searchPattern) ||
            book.author.toLowerCase().contains(searchPattern);
      }).toList();

      // Filter Stations by name or tagline
      _filteredStations = _allStations.where((station) {
        return station.name.toLowerCase().contains(searchPattern) ||
            station.tagline.toLowerCase().contains(searchPattern);
      }).toList();

      // Filter Podcasts by title, description or category
      _filteredPodcasts = _allPodcasts.where((episode) {
        return episode.title.toLowerCase().contains(searchPattern) ||
            episode.description.toLowerCase().contains(searchPattern) ||
            episode.category.toLowerCase().contains(searchPattern);
      }).toList();

      _state = totalResultsCount == 0 ? SearchState.empty : SearchState.success;
      _errorMessage = null;
    } catch (e) {
      _state = SearchState.failure;
      _errorMessage = 'حدث خطأ أثناء إجراء البحث. يرجى المحاولة لاحقاً.';
    }

    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _filteredBooks = [];
    _filteredStations = [];
    _filteredPodcasts = [];
    _state = SearchState.initial;
    notifyListeners();
  }
}
