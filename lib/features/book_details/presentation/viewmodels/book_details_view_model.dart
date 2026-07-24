import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/storage/firebase_storage_url_resolver.dart';
import '../../domain/entities/book_detail_model.dart';
import '../../domain/repositories/book_details_repository.dart';

class BookDetailsViewModel extends ChangeNotifier {
  final BookDetailsRepository repository;
  final String bookId;

  BookDetail? _book;
  List<BookDetail> _publisherBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFavorite = false;

  BookDetail? get book => _book;
  List<BookDetail> get publisherBooks => _publisherBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFavorite => _isFavorite;

  BookDetailsViewModel({required this.repository, required this.bookId}) {
    loadBookDetails();
  }

  Future<void> loadBookDetails() async {
    _isLoading = true;
    _errorMessage = null;
    _publisherBooks = [];
    notifyListeners();

    try {
      if (bookId.trim().isEmpty) {
        throw Exception('معرف الكتاب غير صالح');
      }
      _book = await repository.getBookDetails(bookId.trim());
      
      if (_book != null) {
        await _loadPublisherBooks();
      }

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
      _book = null;
      _publisherBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPublisherBooks() async {
    if (_book == null) return;
    try {
      final publisherId = _book!.publisherId;
      final publisherName = _book!.publisherName;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();

      final List<BookDetail> fetchedBooks = [];
      for (final doc in querySnapshot.docs) {
        if (doc.id == bookId) continue; // Skip current book
        final data = doc.data();
        final b = BookDetail.fromFirestore(data, doc.id, []);

        final matchesId = publisherId.isNotEmpty && b.publisherId == publisherId;
        final matchesName = publisherName.isNotEmpty && b.publisherName == publisherName;

        if (matchesId || matchesName) {
          final resolvedImg = await FirebaseStorageUrlResolver.resolve(b.imageUrl);
          final resolvedBook = BookDetail(
            id: b.id,
            title: b.title,
            author: b.author,
            authorId: b.authorId,
            authorImage: b.authorImage,
            authorFullNameRussian: b.authorFullNameRussian,
            authorLife: b.authorLife,
            description: b.description,
            rating: b.rating,
            playCount: b.playCount,
            duration: b.duration,
            category: b.category,
            interests: b.interests,
            imageUrl: resolvedImg,
            chapters: b.chapters,
            comments: b.comments,
            pages: b.pages,
            language: b.language,
            shortQuote: b.shortQuote,
            translator: b.translator,
            translatorId: b.translatorId,
            narrator: b.narrator,
            narratorId: b.narratorId,
            publisherId: b.publisherId,
            publisherName: b.publisherName,
            publisherLogo: b.publisherLogo,
            audioUrl: b.audioUrl,
            pdfUrl: b.pdfUrl,
          );
          fetchedBooks.add(resolvedBook);
        }
      }
      _publisherBooks = fetchedBooks;
    } catch (e) {
      debugPrint('Error loading publisher books: $e');
      _publisherBooks = [];
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
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
        await userDocRef.update({'favoritesCount': FieldValue.increment(1)});
      } else {
        await favDocRef.delete();
        await userDocRef.update({'favoritesCount': FieldValue.increment(-1)});
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
