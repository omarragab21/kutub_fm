import '../entities/book_detail_model.dart';

abstract class BookDetailsRepository {
  Future<BookDetail> getBookDetails(String bookId);
}
