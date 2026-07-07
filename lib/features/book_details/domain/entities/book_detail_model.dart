import 'dart:convert';

const String _chapterOneSilentWallsAudioUrl =
    'https://firebasestorage.googleapis.com/v0/b/kutubfm-1ef89.firebasestorage.app/o/002.%20%D8%A7%D9%84%D8%AC%D8%B2%D8%A1%20%D8%A7%D9%84%D8%A7%D9%94%D9%88%D9%84%20%D8%B3%D9%83%D9%88%D9%86%20%D8%A7%D9%84%D8%B4%D8%AA%D8%A7%D8%A1%20%D8%A7%D9%84%D9%81%D8%B5%D9%84%20%D8%A7%D9%84%D8%A7%D9%94%D9%88%D9%84%20%D8%A7%D9%84%D8%A8%D9%8A%D8%AA%20%D8%B0%D9%88%20%D8%A7%D9%84%D8%AC%D8%AF%D8%B1%D8%A7%D9%86%20%D8%A7%D9%84%D8%B5%D8%A7%D9%85%D8%AA%D8%A9.mp3?alt=media&token=a72ee120-f56d-4972-980a-ebaf1ea0c9b5';

const String _chapterTwoScreenLightAudioUrl =
    'https://firebasestorage.googleapis.com/v0/b/kutubfm-1ef89.firebasestorage.app/o/003.%20%D8%A7%D9%84%D9%81%D8%B5%D9%84%20%D8%A7%D9%84%D8%AB%D8%A7%D9%86%D9%8A%20%D8%B6%D9%88%D8%A1%20%D8%B9%D8%A8%D8%B1%20%D8%A7%D9%84%D8%B4%D8%A7%D8%B4%D8%A9.mp3?alt=media&token=1868d5f1-7718-4d25-9045-7f5a6a359ccc';

const String _chapterThreeDinnerShadowsAudioUrl =
    'https://firebasestorage.googleapis.com/v0/b/kutubfm-1ef89.firebasestorage.app/o/004.%20%D8%A7%D9%84%D9%81%D8%B5%D9%84%20%D8%A7%D9%84%D8%AB%D8%A7%D9%84%D8%AB%20%D8%B8%D9%84%D8%A7%D9%84%20%D8%B9%D9%84%D9%89%20%D9%85%D8%A7%D9%8A%D9%94%D8%AF%D8%A9%20%D8%A7%D9%84%D8%B9%D8%B4%D8%A7%D8%A1.mp3?alt=media&token=6233a477-f851-4857-b9f3-3b6730ae13c1';

const String _camelliaFlowerPdfUrl =
    'https://firebasestorage.googleapis.com/v0/b/kutubfm-1ef89.firebasestorage.app/o/%D8%B2%D9%87%D8%B1%D8%A9%20%D8%A7%D9%84%D9%83%D8%A7%D9%85%D9%8A%D9%84%D9%8A%D8%A7-%20%D8%A7%D9%84%D9%86%D8%B3%D8%AE%D8%A9%20%D8%A7%D9%84%D9%86%D9%87%D8%A7%D9%8A%D9%94%D9%8A%D8%A9.pdf?alt=media&token=c4dd08dd-ef21-464a-9f24-7c376aa16a51';

class Chapter {
  final String id;
  final String title;
  final String duration;
  final String audioUrl;
  final String? youtubeUrl;
  final int orderIndex;
  final bool isCompleted;
  final String? transcript;

  Chapter({
    required this.id,
    required this.title,
    required this.duration,
    required this.audioUrl,
    this.youtubeUrl,
    required this.orderIndex,
    this.isCompleted = false,
    this.transcript,
  });

  factory Chapter.fromFirestore(Map<String, dynamic> data, String docId) {
    final title = data['title'] as String? ?? '';
    final ytUrl = _readString(data, const [
      'youtubeUrl',
      'youtubeURL',
      'youtube_url',
    ]);
    final fallbackAudioUrl = _readString(data, const [
      'downloadUrl',
      'downloadURL',
      'download_url',
      'audioDownloadUrl',
      'audio_download_url',
      'audioUrl',
      'audio_url',
      'streamUrl',
      'stream_url',
      'url',
    ]);
    final orderIndex = (data['orderIndex'] is int)
        ? data['orderIndex'] as int
        : int.tryParse(data['orderIndex']?.toString() ?? '') ?? 0;
    final audioUrlOverride = _knownAudioUrlOverride(
      docId: docId,
      title: title,
      orderIndex: orderIndex,
      hasExistingAudio: ytUrl.isNotEmpty || fallbackAudioUrl.isNotEmpty,
    );
    return Chapter(
      id: docId,
      title: title,
      duration: data['duration'] as String? ?? '',
      audioUrl:
          audioUrlOverride ?? (ytUrl.isNotEmpty ? ytUrl : fallbackAudioUrl),
      youtubeUrl: audioUrlOverride == null && ytUrl.isNotEmpty ? ytUrl : null,
      orderIndex: orderIndex,
      isCompleted: false,
      transcript: _readTranscript(data['transcript']),
    );
  }

  bool get hasTranscript => transcript?.trim().isNotEmpty == true;

  bool get hasAudioUrl => audioUrl.trim().isNotEmpty;

  bool get hasYoutubeUrl => youtubeUrl != null && youtubeUrl!.trim().isNotEmpty;

  bool get isReadableAudio => hasTranscript && (hasYoutubeUrl || hasAudioUrl);

  static String? _knownAudioUrlOverride({
    required String docId,
    required String title,
    required int orderIndex,
    required bool hasExistingAudio,
  }) {
    final normalized = _normalizeArabic('$docId $title');
    final titleAudioOverrides = <String, String>{
      _normalizeArabic('البيت ذو الجدران الصامتة'):
          _chapterOneSilentWallsAudioUrl,
      _normalizeArabic('ضوء عبر الشاشة'): _chapterTwoScreenLightAudioUrl,
      _normalizeArabic('ظلال على مائدة العشاء'):
          _chapterThreeDinnerShadowsAudioUrl,
    };
    for (final entry in titleAudioOverrides.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    if (hasExistingAudio) {
      return null;
    }

    if (_isChapterMatch(
      normalized: normalized,
      orderIndex: orderIndex,
      expectedOrder: 1,
      arabicTitle: 'الفصل الأول',
      englishMarkers: const ['chapter1', 'ch1'],
    )) {
      return _chapterOneSilentWallsAudioUrl;
    }

    if (_isChapterMatch(
      normalized: normalized,
      orderIndex: orderIndex,
      expectedOrder: 2,
      arabicTitle: 'الفصل الثاني',
      englishMarkers: const ['chapter2', 'ch2'],
    )) {
      return _chapterTwoScreenLightAudioUrl;
    }

    if (_isChapterMatch(
      normalized: normalized,
      orderIndex: orderIndex,
      expectedOrder: 3,
      arabicTitle: 'الفصل الثالث',
      englishMarkers: const ['chapter3', 'ch3'],
    )) {
      return _chapterThreeDinnerShadowsAudioUrl;
    }

    return null;
  }

  static bool _isChapterMatch({
    required String normalized,
    required int orderIndex,
    required int expectedOrder,
    required String arabicTitle,
    required List<String> englishMarkers,
  }) {
    final compact = normalized.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    if (orderIndex == expectedOrder) {
      return true;
    }
    if (normalized.contains(_normalizeArabic(arabicTitle))) {
      return true;
    }
    return englishMarkers.any(compact.contains);
  }

  static String _normalizeArabic(String value) {
    return value
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  static String? _readTranscript(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
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
  final String pdfUrl;

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
    required this.pdfUrl,
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
    final title = data['title'] as String? ?? '';
    final pdfUrlOverride = _knownPdfUrlOverride(docId: docId, title: title);

    return BookDetail(
      id: docId,
      title: title,
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
      audioUrl: _readString(data, const [
        'downloadUrl',
        'downloadURL',
        'download_url',
        'audioDownloadUrl',
        'audio_download_url',
        'audioUrl',
        'audio_url',
      ]),
      pdfUrl:
          pdfUrlOverride ??
          _readString(data, const [
            'pdfUrl',
            'pdfURL',
            'pdf_url',
            'pdfDownloadUrl',
            'pdf_download_url',
          ]),
    );
  }

  factory BookDetail.mock() {
    return BookDetail(
      id: 'miah_aam',
      title: 'مئة عام من العزلة',
      author: 'أحمد خالد توفيق',
      authorId: 'author_akt',
      authorFullNameRussian: '',
      authorLife: '10 يونيو 1962 - 2 أبريل 2018',
      description:
          'استكشف عالماً من العزلة الساحرة في "مئة عام من العزلة"، حيث تتشابك الأجيال والأحداث في ملحمة فريدة.',
      rating: 4.8,
      playCount: '150K',
      duration: '4h 48m',
      category: 'دراما',
      imageUrl: 'assets/miah_aam_cover.png',
      chapters: [
        Chapter(
          id: 'ch1',
          title: 'الفصل الأول',
          duration: '45:00',
          audioUrl: _chapterOneSilentWallsAudioUrl,
          orderIndex: 1,
          isCompleted: true,
          transcript: 'الفصل الأول من رواية مئة عام من العزلة...',
        ),
        Chapter(
          id: 'ch2',
          title: 'الفصل الثاني',
          duration: '50:00',
          audioUrl: _chapterTwoScreenLightAudioUrl,
          orderIndex: 2,
          isCompleted: true,
          transcript: 'الفصل الثاني من رواية مئة عام من العزلة...',
        ),
        Chapter(
          id: 'ch3',
          title: 'الفصل الثالث',
          duration: '43:00',
          audioUrl: _chapterThreeDinnerShadowsAudioUrl,
          orderIndex: 3,
          transcript: 'الفصل الثالث من رواية مئة عام من العزلة...',
        ),
        Chapter(
          id: 'ch4',
          title: 'الفصل الرابع',
          duration: '55:00',
          audioUrl: '',
          orderIndex: 4,
          transcript: 'الفصل الرابع من رواية مئة عام من العزلة...',
        ),
        Chapter(
          id: 'ch5',
          title: 'الفصل الخامس',
          duration: '35:00',
          audioUrl: '',
          orderIndex: 5,
          transcript: 'الفصل الخامس من رواية مئة عام من العزلة...',
        ),
        Chapter(
          id: 'ch6',
          title: 'الفصل السادس',
          duration: '60:00',
          audioUrl: '',
          orderIndex: 6,
          transcript: 'الفصل السادس من رواية مئة عام من العزلة...',
        ),
      ],
      comments: [
        BookComment(
          id: '101',
          userName: 'سامر العلي',
          userAvatar: '',
          text:
              'رواية استثنائية، أعادت تشكيل نظرتي للوزارة والوجود أسلوب ساحر ومترجم بشكل رائع، أنصح بها بشدة.',
          timeAgo: '24/5/2026',
          likes: 24,
        ),
        BookComment(
          id: '102',
          userName: 'ليلى حسن',
          userAvatar: '',
          text:
              'قصة عميقة تحمل بين طياتها مشاعر صادقة وأحداث مشوقة، لا يمكنني الانتظار لقراءة المزيد من...',
          timeAgo: '15/6/2026',
          likes: 12,
        ),
      ],
      pages: 256,
      language: 'العربية',
      shortQuote: 'المرض لا يمحو الحب، بل يجعله أكثر نقاءً.',
      translator: 'صالح علماني',
      translatorId: 'translator_sc',
      narrator: 'أحمد مجدي',
      narratorId: 'narrator_am',
      publisherId: 'publisher_dar_al_shorouk',
      publisherName: 'الدار العربية للعلوم ناشرون',
      audioUrl: '',
      pdfUrl: '',
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

  static String? _knownPdfUrlOverride({
    required String docId,
    required String title,
  }) {
    final normalized = Chapter._normalizeArabic('$docId $title');
    if (normalized.contains(Chapter._normalizeArabic('زهرة الكاميليا'))) {
      return _camelliaFlowerPdfUrl;
    }
    return null;
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
