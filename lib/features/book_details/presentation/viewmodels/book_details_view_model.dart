import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/book_detail_model.dart';
import '../../domain/repositories/book_details_repository.dart';

class BookDetailsViewModel extends ChangeNotifier {
  final BookDetailsRepository repository;
  final String bookId;

  BookDetail? _book;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFavorite = false;

  BookDetail? get book => _book;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFavorite => _isFavorite;

  BookDetailsViewModel({
    required this.repository,
    required this.bookId,
  }) {
    loadBookDetails();
  }

  Future<void> loadBookDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _book = await repository.getBookDetails(bookId);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final favDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(bookId)
            .get();
        _isFavorite = favDoc.exists;
      } else {
        _isFavorite = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final favDocRef = userDocRef.collection('favorites').doc(bookId);

    _isFavorite = !_isFavorite;
    notifyListeners();

    try {
      if (_isFavorite) {
        await favDocRef.set({
          'bookId': bookId,
          'title': _book?.title ?? '',
          'author': _book?.author ?? '',
          'imageUrl': _book?.imageUrl ?? '',
          'favoritedAt': FieldValue.serverTimestamp(),
        });
        await userDocRef.update({
          'favoritesCount': FieldValue.increment(1),
        });
      } else {
        await favDocRef.delete();
        await userDocRef.update({
          'favoritesCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      _isFavorite = !_isFavorite;
      notifyListeners();
    }
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
