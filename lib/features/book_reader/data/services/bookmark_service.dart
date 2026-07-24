import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BookReaderBookmark {
  final int firstSegmentIndex;
  final int lastSegmentIndex;
  final String text;
  final double audioStart;
  final double audioEnd;
  final DateTime createdAt;

  const BookReaderBookmark({
    required this.firstSegmentIndex,
    required this.lastSegmentIndex,
    required this.text,
    required this.audioStart,
    required this.audioEnd,
    required this.createdAt,
  });

  String get rangeKey => buildRangeKey(firstSegmentIndex, lastSegmentIndex);

  Map<String, dynamic> toJson() {
    return {
      'firstSegmentIndex': firstSegmentIndex,
      'lastSegmentIndex': lastSegmentIndex,
      'text': text,
      'audioStart': audioStart,
      'audioEnd': audioEnd,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookReaderBookmark.fromJson(Map<String, dynamic> json) {
    return BookReaderBookmark(
      firstSegmentIndex: _readInt(json['firstSegmentIndex']),
      lastSegmentIndex: _readInt(json['lastSegmentIndex']),
      text: json['text']?.toString() ?? '',
      audioStart: _readDouble(json['audioStart']),
      audioEnd: _readDouble(json['audioEnd']),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String buildRangeKey(int firstSegmentIndex, int lastSegmentIndex) {
    return '$firstSegmentIndex:$lastSegmentIndex';
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class BookmarkService {
  static const _prefix = 'book_reader_bookmarks';

  static String _key(String bookId, String chapterId) {
    return '${_prefix}_${bookId}_$chapterId';
  }

  static Future<List<BookReaderBookmark>> getBookmarks({
    required String bookId,
    required String chapterId,
  }) async {
    if (bookId.isEmpty || chapterId.isEmpty) return const [];

    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key(bookId, chapterId)) ?? const [];
    final bookmarks = <BookReaderBookmark>[];

    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          bookmarks.add(BookReaderBookmark.fromJson(decoded));
        } else if (decoded is Map) {
          bookmarks.add(BookReaderBookmark.fromJson(Map.from(decoded)));
        }
      } catch (_) {
        // Ignore malformed legacy values and keep loading the rest.
      }
    }

    return bookmarks;
  }

  static Future<List<BookReaderBookmark>> saveBookmark({
    required String bookId,
    required String chapterId,
    required BookReaderBookmark bookmark,
  }) async {
    if (bookId.isEmpty || chapterId.isEmpty) return const [];

    final bookmarks = await getBookmarks(bookId: bookId, chapterId: chapterId);
    final byRange = {
      for (final existing in bookmarks) existing.rangeKey: existing,
      bookmark.rangeKey: bookmark,
    };
    final updated = byRange.values.toList()
      ..sort((a, b) => a.firstSegmentIndex.compareTo(b.firstSegmentIndex));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(bookId, chapterId),
      updated.map((bookmark) => jsonEncode(bookmark.toJson())).toList(),
    );

    return updated;
  }
}
