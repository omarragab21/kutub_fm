import 'dart:convert';

class TranscriptionSegment {
  final double start;
  final double end;
  final String text;

  TranscriptionSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
    );
  }
}

class Chapter {
  final String id;
  final String title;
  final String duration;
  final String audioUrl;
  final int orderIndex;
  final bool isCompleted;
  final String? transcript;
  final int? startPage;
  final int? endPage;
  final String? description;
  final List<TranscriptionSegment> transcription;

  Chapter({
    required this.id,
    required this.title,
    required this.duration,
    required this.audioUrl,
    required this.orderIndex,
    this.isCompleted = false,
    this.transcript,
    this.startPage,
    this.endPage,
    this.description,
    this.transcription = const [],
  });

  factory Chapter.fromFirestore(Map<String, dynamic> data, String docId) {
    final title = data['title'] as String? ?? '';
    final audioUrl = _readString(data, const [
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

    int? parsePage(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    List<TranscriptionSegment> parseTranscription(dynamic value) {
      if (value == null) return const [];
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map((e) => TranscriptionSegment.fromJson(e))
            .toList();
      }
      if (value is Map) {
        final List<dynamic>? segments = value['segments'] as List<dynamic>?;
        if (segments != null) {
          return segments
              .whereType<Map<String, dynamic>>()
              .map((e) => TranscriptionSegment.fromJson(e))
              .toList();
        }
      }
      return const [];
    }

    return Chapter(
      id: docId,
      title: title,
      duration: data['duration'] as String? ?? '',
      audioUrl: audioUrl,
      orderIndex: orderIndex,
      isCompleted: false,
      transcript: _readTranscript(data['transcript']),
      startPage: parsePage(data['startPage']),
      endPage: parsePage(data['endPage']),
      description: data['description'] as String?,
      transcription: parseTranscription(data['transcription']),
    );
  }

  bool get hasTranscript => transcript?.trim().isNotEmpty == true;

  bool get hasAudioUrl => audioUrl.trim().isNotEmpty;

  bool get isReadableAudio => hasTranscript && hasAudioUrl;

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
  final String authorImage;
  final String authorFullNameRussian;
  final String authorLife;
  final String description;
  final double rating;
  final String playCount;
  final String duration;
  final String category;
  final List<String> interests;
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
  final String publisherLogo;
  final String audioUrl;
  final String pdfUrl;

  BookDetail({
    required this.id,
    required this.title,
    required this.author,
    required this.authorId,
    this.authorImage = '',
    required this.authorFullNameRussian,
    required this.authorLife,
    required this.description,
    required this.rating,
    required this.playCount,
    required this.duration,
    required this.category,
    this.interests = const [],
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
    this.publisherLogo = '',
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
    String authorImage = '';
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
        final image = (c['imageSnapshot'] as String? ?? '').trim();
        final contributorId = _readContributorId(c);
        if (role == 'AUTHOR') {
          authorName = name;
          authorId = contributorId;
          authorImage = image;
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

    final interestSnapshots = data['interestSnapshots'] as List<dynamic>? ?? [];
    final interests = interestSnapshots
        .whereType<Map<String, dynamic>>()
        .map((c) => c['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return BookDetail(
      id: docId,
      title: title,
      author: authorName.isNotEmpty ? authorName : 'غير معروف',
      authorId: authorId,
      authorImage: authorImage,
      authorFullNameRussian: authorFullNameRussian,
      authorLife: authorLife,
      description: data['description'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      playCount: '0',
      duration: data['duration'] as String? ?? '',
      category: category.isNotEmpty ? category : fallbackCategory,
      interests: interests,
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
      publisherLogo: data['publisherLogoSnapshot'] as String? ?? '',
      audioUrl: _readString(data, const [
        'downloadUrl',
        'downloadURL',
        'download_url',
        'audioDownloadUrl',
        'audio_download_url',
        'audioUrl',
        'audio_url',
      ]),
      pdfUrl: _readString(data, const [
        'pdfUrl',
        'pdfURL',
        'pdf_url',
        'pdfDownloadUrl',
        'pdf_download_url',
      ]),
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
      if (value != null && value is! Map) {
        if (value.runtimeType.toString().contains('DocumentReference')) {
          try {
            final id = (value as dynamic).id;
            if (id != null && id.toString().isNotEmpty) {
              return id.toString();
            }
          } catch (_) {}
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }
}
