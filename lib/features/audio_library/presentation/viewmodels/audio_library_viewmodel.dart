import 'package:flutter/material.dart';
import '../../domain/entities/audio_category.dart';
import '../../../audio_player/domain/entities/audio_story.dart';

class AudioLibraryViewModel extends ChangeNotifier {
  final List<AudioCategory> _categories = AudioCategory.mockCategories;
  String _selectedCategoryId = '';
  
  List<AudioStory> _books = [];
  AudioStory? _featuredBook;

  bool _isLoading = true;

  AudioLibraryViewModel() {
    _initData();
  }

  void _initData() {
    if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
      _loadBooksForCategory(_selectedCategoryId);
    }
  }

  Future<void> _loadBooksForCategory(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    // Mock network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // For mock purposes, just retrieve a shuffled list or fresh list of AudioStories
    // In a real app, you would fetch by category ID.
    final mockData = AudioStory.mockList;
    _featuredBook = mockData.first;
    _books = mockData.skip(1).toList();
    // Pad to at least 3 items by rotating through the curated mock list
    if (_books.length < 3) {
      final extra = List.generate(
        3 - _books.length,
        (i) => mockData[(i + 2) % mockData.length],
      );
      _books.addAll(extra);
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String id) {
    if (_selectedCategoryId != id) {
      _selectedCategoryId = id;
      _loadBooksForCategory(id);
    }
  }

  List<AudioCategory> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;
  List<AudioStory> get books => _books;
  AudioStory? get featuredBook => _featuredBook;
  bool get isLoading => _isLoading;

  bool _isSearchActive = false;
  String _searchQuery = '';

  bool get isSearchActive => _isSearchActive;
  String get searchQuery => _searchQuery;

  void toggleSearch(bool active) {
    _isSearchActive = active;
    _searchQuery = '';
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<AudioStory> get filteredBooks {
    if (_searchQuery.isEmpty) {
      return _books;
    }
    // Search across all available curated books so user can find multiple stories
    final allCuratedBooks = [
      AudioStory.theEnemies,
      AudioStory.theAlchemist,
      AudioStory.theStranger,
      AudioStory.crimeAndPunishment,
    ];
    return allCuratedBooks.where((book) {
      final queryClean = _searchQuery.trim().toLowerCase();
      final titleMatch = book.title.toLowerCase().contains(queryClean);
      final authorMatch = book.author.toLowerCase().contains(queryClean);
      return titleMatch || authorMatch;
    }).toList();
  }
}
