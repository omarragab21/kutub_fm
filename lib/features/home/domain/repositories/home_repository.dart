import '../entities/book_entity.dart';
import '../entities/category_entity.dart';
import '../entities/book_collection_entity.dart';

abstract class HomeRepository {
  Future<List<HomeCategory>> getCategories();
  Future<List<BookEntity>> getRecommendedBooks();
  Future<List<BookCollectionEntity>> getBookCollections();
}

