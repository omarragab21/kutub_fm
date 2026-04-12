import 'package:flutter/material.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/home_repository.dart';

class HomeViewModel with ChangeNotifier {
  final HomeRepository _repository;

  HomeViewModel({required HomeRepository repository}) : _repository = repository;

  List<HomeCategory> _categories = [];
  List<BookEntity> _recommendedBooks = [];
  bool _isLoading = false;
  String? _error;

  List<HomeCategory> get categories => _categories;
  List<BookEntity> get recommendedBooks => _recommendedBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getRecommendedBooks(),
      ]);

      _categories = results[0] as List<HomeCategory>;
      _recommendedBooks = results[1] as List<BookEntity>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
