import 'package:flutter/material.dart';
import '../../domain/entities/book_detail_model.dart';

class BookDetailsViewModel extends ChangeNotifier {
  BookDetail? _book;
  bool _isLoading = false;

  BookDetail? get book => _book;
  bool get isLoading => _isLoading;

  BookDetailsViewModel() {
    loadBookDetails();
  }

  Future<void> loadBookDetails() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    _book = BookDetail.mock();
    
    _isLoading = false;
    notifyListeners();
  }

  void toggleFavorite() {
    // Implement favorite toggle logic
    notifyListeners();
  }

  void addComment(String text) {
    if (_book != null && text.trim().isNotEmpty) {
      final newComment = BookComment(
        id: DateTime.now().toString(),
        userName: 'أنت', // "You"
        userAvatar: 'https://i.pravatar.cc/150?img=12', // Mock avatar
        text: text,
        timeAgo: 'الآن', // "Now"
        likes: 0,
      );
      _book!.comments.insert(0, newComment); 
      notifyListeners();
    }
  }
}
