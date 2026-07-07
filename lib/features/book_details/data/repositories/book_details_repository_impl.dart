import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/storage/firebase_storage_url_resolver.dart';
import '../../domain/entities/book_detail_model.dart';
import '../../domain/repositories/book_details_repository.dart';

class BookDetailsRepositoryImpl implements BookDetailsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<BookDetail> getBookDetails(String bookId) async {
    final bookDoc = await _firestore.collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      throw Exception('الكتاب غير موجود');
    }

    final data = bookDoc.data();
    if (data == null) {
      throw Exception('بيانات الكتاب فارغة');
    }

    // Load chapters subcollection
    final chaptersSnap = await _firestore
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .get();

    final chapters = chaptersSnap.docs.map((doc) {
      return Chapter.fromFirestore(doc.data(), doc.id);
    }).toList();

    // Sort chapters by orderIndex
    chapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final resolvedData = Map<String, dynamic>.from(data);
    resolvedData['imageUrl'] = await FirebaseStorageUrlResolver.resolve(
      _readString(data, const ['imageUrl', 'coverUrl', 'cover_url']),
    );

    return BookDetail.fromFirestore(resolvedData, bookDoc.id, chapters);
  }

  String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
