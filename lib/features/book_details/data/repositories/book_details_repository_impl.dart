import 'package:cloud_firestore/cloud_firestore.dart';
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

    return BookDetail.fromFirestore(data, bookDoc.id, chapters);
  }
}
