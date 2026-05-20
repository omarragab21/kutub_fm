import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/book_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<List<HomeCategory>> getCategories() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final userSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userSnapshot.data();
    if (userData == null) return [];

    final selectedCategoryIds = _stringList(userData['favoriteCategoryIds']);
    if (selectedCategoryIds.isEmpty) {
      return _categoriesFromSavedNames(userData['favoriteCategories']);
    }

    final categorySnapshots = await Future.wait(
      selectedCategoryIds.map(
        (id) => _firestore.collection('categories').doc(id).get(),
      ),
    );

    return categorySnapshots
        .where((snapshot) => snapshot.exists)
        .map((snapshot) => _categoryFromSnapshot(snapshot))
        .toList(growable: false);
  }

  @override
  Future<List<BookEntity>> getRecommendedBooks() async {
    // Mocking data for now as per plan
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      BookEntity(
        id: '1',
        title: 'طوق الحمامة',
        author: 'ابن حزم الأندلسي',
        coverUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAWFZCLuzVeFM8VOxTMQDaoCX32AsfAoFptyv7ybXLA9nWloCJIFpZRxzNos9lRiewswhOlsRD2rhZhAec2A4g2W5BrwUTXQtuhzSCSreirZ4H1V8DOduYMa41MsMTUC-1yJ9-nLj8Tz4eIesKNLqC3A4w7LvW14LEXOmsTp9Yanh-S9fHtKOgNstHl56ln1egcgonGot07PUeL5o23As7E4ZloPrK1jIXMGrPpiI0Tbetqq9Mil9Ax5HtFfLrQxNgX71ZsUe-zFWc',
        rating: 4.9,
        duration: '٨ ساعات',
      ),
      BookEntity(
        id: '2',
        title: 'مدن الملح',
        author: 'عبدالرحمن منيف',
        coverUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuB3Y2apirvC_AC_GljgNERIW6vN2VU2XLDuM6miQcYxg14eKriUyVUF8UOdBiYUihVSjme9wverOPLC7aLqTqaZWcHrtjlOPswnjkI2zh-3k4ahmBUCwyJ2hD18e4Z7IDiQ5xYxEU_iMZHXd9-t4ACOMWzjGWkXBNTDOhdg80fGVaX7Z0in6tELGV5cnBUWqgAVNOEO5fUqKZkshwhJkNEKmHAK1UT7t_1xPnwG2T7VJY70fZlqTFgXgIrauwX1JMsQmcx7RrVowTE',
        rating: 4.7,
        duration: '١٥ ساعة',
      ),
      BookEntity(
        id: '3',
        title: 'رسالة الغفران',
        author: 'أبو العلاء المعري',
        coverUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAffVaFTvImZAjqiBfOil4oF4TMZpaOdEy6CfOkIC5PEFWSKDbdS51fF5hI3uRUAK29XLGc_ZuoQrwIY950n-OayP0DK4KleW-aTLflfiiIfMv0wUSsV553YGCOtOp3myIiA0daC6qpMgWl8RO2wBPTDaE5SPBkjl8ANmMSC-fDzocmR_a6KryJJ54af0slKYLFskA0912aIfhzKR-_9FBmpsqCLPYNCSKlXdB1cv_nTEAu27JFKGJDIgW3P0U68hjbMdMs26O0fv4',
        rating: 4.8,
        duration: '١١ ساعة',
      ),
    ];
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<HomeCategory> _categoriesFromSavedNames(Object? value) {
    return _stringList(value)
        .map(
          (name) => HomeCategory(
            id: name,
            title: name,
            icon: _fallbackIconNameFor(name, name),
          ),
        )
        .toList(growable: false);
  }

  HomeCategory _categoryFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    final title = _stringField(data, const [
      'name',
      'title',
      'nameAr',
      'arabicName',
    ], fallback: snapshot.id);

    return HomeCategory(
      id: snapshot.id,
      title: title,
      icon:
          _nullableStringField(data, const ['icon', 'iconUrl']) ??
          _fallbackIconNameFor(snapshot.id, title),
    );
  }

  String _stringField(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  String? _nullableStringField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _fallbackIconNameFor(String id, String title) {
    final source = '$id $title'.toLowerCase();
    if (source.contains('fiction') || source.contains('روا')) {
      return 'auto_stories';
    }
    if (source.contains('history') || source.contains('تاريخ')) {
      return 'history_edu';
    }
    if (source.contains('self') || source.contains('ذات')) {
      return 'self_improvement';
    }
    if (source.contains('business') || source.contains('اقتصاد')) {
      return 'trending_up';
    }
    if (source.contains('children') || source.contains('أطفال')) {
      return 'child_care';
    }
    if (source.contains('technology') || source.contains('تقنية')) {
      return 'memory';
    }
    if (source.contains('science') || source.contains('علوم')) {
      return 'science';
    }
    if (source.contains('religion') || source.contains('دين')) {
      return 'mosque';
    }
    return 'category';
  }
}
