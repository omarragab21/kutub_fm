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
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        final allDocs = await _firestore.collection('books').get();
        return allDocs.docs.map((doc) => _bookEntityFromSnapshot(doc)).toList();
      }
      return snapshot.docs.map((doc) => _bookEntityFromSnapshot(doc)).toList();
    } catch (e) {
      final allDocs = await _firestore.collection('books').get();
      return allDocs.docs.map((doc) => _bookEntityFromSnapshot(doc)).toList();
    }
  }

  BookEntity _bookEntityFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final contributors = data['contributors'] as List<dynamic>? ?? [];

    return BookEntity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      author: _getAuthorFromContributors(contributors),
      coverUrl: data['imageUrl'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      duration: _formatDuration(data['duration'] as String? ?? ''),
    );
  }

  String _getAuthorFromContributors(List<dynamic> contributors) {
    if (contributors.isEmpty) return '';
    for (final c in contributors) {
      if (c is Map<String, dynamic>) {
        if (c['role'] == 'AUTHOR') {
          return c['nameSnapshot'] ?? '';
        }
      }
    }
    final first = contributors.first;
    if (first is Map<String, dynamic>) {
      return first['nameSnapshot'] ?? '';
    }
    return '';
  }

  String _formatDuration(String durationStr) {
    if (durationStr.isEmpty) return '';
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      if (minutes != null) {
        if (minutes == 1) return 'دقيقة واحدة';
        if (minutes == 2) return 'دقيقتان';
        if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
        return '$minutes دقيقة';
      }
    } else if (parts.length == 3) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        String hoursStr = '';
        if (hours == 1) {
          hoursStr = 'ساعة';
        } else if (hours == 2) {
          hoursStr = 'ساعتان';
        } else if (hours >= 3 && hours <= 10) {
          hoursStr = '$hours ساعات';
        } else {
          hoursStr = '$hours ساعة';
        }

        if (minutes == 0) {
          return hoursStr;
        }

        String minutesStr = '';
        if (minutes == 1) {
          minutesStr = 'دقيقة';
        } else if (minutes == 2) {
          minutesStr = 'دقيقتان';
        } else if (minutes >= 3 && minutes <= 10) {
          minutesStr = '$minutes دقائق';
        } else {
          minutesStr = '$minutes دقيقة';
        }

        return '$hoursStr و $minutesStr';
      }
    }
    return durationStr;
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
