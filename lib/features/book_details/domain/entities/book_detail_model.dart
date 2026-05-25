class Chapter {
  final String id;
  final String title;
  final String duration;
  final String audioUrl;
  final int orderIndex;
  final bool isCompleted;
  final String? transcript;

  Chapter({
    required this.id,
    required this.title,
    required this.duration,
    required this.audioUrl,
    required this.orderIndex,
    this.isCompleted = false,
    this.transcript,
  });

  factory Chapter.fromFirestore(Map<String, dynamic> data, String docId) {
    return Chapter(
      id: docId,
      title: data['title'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      orderIndex: (data['orderIndex'] is int)
          ? data['orderIndex'] as int
          : int.tryParse(data['orderIndex']?.toString() ?? '') ?? 0,
      isCompleted: false,
      transcript: data['transcript'] as String?,
    );
  }
}

class BookComment {
  final String id;
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;
  final int likes;

  BookComment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
  });
}

class BookDetail {
  final String id;
  final String title;
  final String author;
  final String authorId;
  final String authorFullNameRussian;
  final String authorLife;
  final String description;
  final double rating;
  final String playCount;
  final String duration;
  final String category;
  final String imageUrl;
  final List<Chapter> chapters;
  final List<BookComment> comments;
  final int pages;
  final String language;
  final String shortQuote;
  final String translator;
  final String translatorId;
  final String narrator;
  final String narratorId;
  final String publisherId;
  final String publisherName;
  final String audioUrl;

  BookDetail({
    required this.id,
    required this.title,
    required this.author,
    required this.authorId,
    required this.authorFullNameRussian,
    required this.authorLife,
    required this.description,
    required this.rating,
    required this.playCount,
    required this.duration,
    required this.category,
    required this.imageUrl,
    required this.chapters,
    required this.comments,
    required this.pages,
    required this.language,
    required this.shortQuote,
    required this.translator,
    required this.translatorId,
    required this.narrator,
    required this.narratorId,
    required this.publisherId,
    required this.publisherName,
    required this.audioUrl,
  });

  factory BookDetail.fromFirestore(
    Map<String, dynamic> data,
    String docId,
    List<Chapter> chapters,
  ) {
    final contributors = data['contributors'] as List<dynamic>? ?? [];
    String authorName = '';
    String authorId = '';
    String authorFullNameRussian = '';
    String authorLife = '';
    String translatorName = '';
    String translatorId = '';
    String narratorName = '';
    String narratorId = '';

    for (final c in contributors) {
      if (c is Map<String, dynamic>) {
        final role = c['role'] as String?;
        final name = c['nameSnapshot'] as String? ?? '';
        final contributorId = _readContributorId(c);
        if (role == 'AUTHOR') {
          authorName = name;
          authorId = contributorId;
        } else if (role == 'TRANSLATOR') {
          translatorName = name;
          translatorId = contributorId;
        } else if (role == 'NARRATOR' || role == 'READER') {
          narratorName = name;
          narratorId = contributorId;
        }
      }
    }

    final categorySnapshots = data['categorySnapshots'] as List<dynamic>? ?? [];
    final category = categorySnapshots
        .map(
          (c) => c is Map<String, dynamic> ? (c['name'] as String? ?? '') : '',
        )
        .where((name) => name.isNotEmpty)
        .join('، ');

    final primaryCategory =
        data['primaryCategorySnapshot'] as Map<String, dynamic>?;
    final fallbackCategory = primaryCategory?['name'] as String? ?? 'غير محدد';

    final pages = (data['pages'] is int)
        ? data['pages'] as int
        : int.tryParse(data['pages']?.toString() ?? '') ?? 0;

    return BookDetail(
      id: docId,
      title: data['title'] as String? ?? '',
      author: authorName.isNotEmpty ? authorName : 'غير معروف',
      authorId: authorId,
      authorFullNameRussian: authorFullNameRussian,
      authorLife: authorLife,
      description: data['description'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      playCount: '0',
      duration: data['duration'] as String? ?? '',
      category: category.isNotEmpty ? category : fallbackCategory,
      imageUrl: data['imageUrl'] as String? ?? '',
      chapters: chapters,
      comments: const [],
      pages: pages,
      language: data['languageNameSnapshot'] as String? ?? 'العربية',
      shortQuote: data['shortQuote'] as String? ?? '',
      translator: translatorName,
      translatorId: translatorId,
      narrator: narratorName,
      narratorId: narratorId,
      publisherId: _readPublisherId(data),
      publisherName:
          data['publisherNameSnapshot'] as String? ??
          data['publisher'] as String? ??
          '',
      audioUrl: data['audioUrl'] as String? ?? '',
    );
  }

  factory BookDetail.mock() {
    return BookDetail(
      id: '1',
      title: 'الخيميائي',
      author: 'باولو كويلو',
      authorId: '',
      authorFullNameRussian: '',
      authorLife: '',
      description:
          'الخيميائي هي الرواية الثانية التي كتبها باولو كويلو، والتي حققت نجاحاً عالمياً باهراً، جعل كاتبها من أشهر الكتاب العالميين. تتحدث الرواية عن راع أندلسي شاب يدعى سانتياغو. مضى في البحث عن حلمه المتمثل بكنز مدفون قرب أهرامات مصر، بدأت رحلته من أسبانيا عندما التقى الملك ملكي صادق الذي أخبره عن الكنز.',
      rating: 4.8,
      playCount: '1.2M',
      duration: '4h 30m',
      category: 'خيال، فلسفة',
      imageUrl:
          'https://m.media-amazon.com/images/I/71aFt4+OTOL._AC_UF1000,1000_QL80_.jpg',
      chapters: [
        Chapter(
          id: '1',
          title: 'البداية: الراعي سانتياغو',
          duration: '12:45',
          audioUrl: '',
          orderIndex: 1,
          isCompleted: true,
          transcript: null,
        ),
        Chapter(
          id: '2',
          title: 'لقاء مع الملك',
          duration: '18:20',
          audioUrl: '',
          orderIndex: 2,
          isCompleted: true,
          transcript: null,
        ),
        Chapter(
          id: '3',
          title: 'عبور الصحراء',
          duration: '45:10',
          audioUrl: '',
          orderIndex: 3,
          transcript: null,
        ),
        Chapter(
          id: '4',
          title: 'فن تحول المعادن',
          duration: '32:15',
          audioUrl: '',
          orderIndex: 4,
          transcript: null,
        ),
        Chapter(
          id: '5',
          title: 'البحث عن الكنز',
          duration: '55:00',
          audioUrl: '',
          orderIndex: 5,
          transcript: null,
        ),
      ],
      comments: [
        BookComment(
          id: '101',
          userName: 'سارة خالد',
          userAvatar: 'https://i.pravatar.cc/150?img=1',
          text: 'من أجمل ما قرأت، كتاب يغير نظرتك للحياة ولأحلامك.',
          timeAgo: 'منذ يومين',
          likes: 24,
        ),
        BookComment(
          id: '102',
          userName: 'محمد أحمد',
          userAvatar: 'https://i.pravatar.cc/150?img=2',
          text: 'سرد رائع وأداء صوتي مذهل. شكراً لكم.',
          timeAgo: 'منذ 5 ساعات',
          likes: 12,
        ),
      ],
      pages: 180,
      language: 'العربية',
      shortQuote: 'أن تحقق أسطورتك الشخصية هو الواجب الوحيد للإنسان.',
      translator: '',
      translatorId: '',
      narrator: 'مروان خوري',
      narratorId: '',
      publisherId: '',
      publisherName: '',
      audioUrl: '',
    );
  }

  static String _readContributorId(Map<String, dynamic> data) {
    return _readString(data, [
      'id',
      'uid',
      'contributorId',
      'contributor_id',
      'publisherId',
      'publisher_id',
      'personId',
      'person_id',
    ]);
  }

  static String _readPublisherId(Map<String, dynamic> data) {
    return _readString(data, [
      'publisherId',
      'publisher_id',
      'publisher.id',
      'publisherRef',
    ]);
  }

  static String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      Object? value;
      if (key.contains('.')) {
        value = data;
        for (final part in key.split('.')) {
          if (value is! Map) {
            value = null;
            break;
          }
          value = value[part];
        }
      } else {
        value = data[key];
      }
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
