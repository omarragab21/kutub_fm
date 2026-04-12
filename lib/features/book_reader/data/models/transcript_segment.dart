enum TranscriptSegmentType {
  normal,
  bold,
  highlight,
  unknown;

  static TranscriptSegmentType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'normal':
        return TranscriptSegmentType.normal;
      case 'bold':
        return TranscriptSegmentType.bold;
      case 'highlight':
        return TranscriptSegmentType.highlight;
      default:
        return TranscriptSegmentType.unknown;
    }
  }
}

/// Top-level metadata parsed from the JSON file.
class BookMetadata {
  final String title;
  final String author;
  final String genre;
  final String translator;
  final String narrator;
  final String publisher;

  const BookMetadata({
    required this.title,
    required this.author,
    required this.genre,
    required this.translator,
    required this.narrator,
    required this.publisher,
  });

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      translator: json['translator']?.toString() ?? '',
      narrator: json['narrator']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
    );
  }

  bool get isEmpty =>
      title.isEmpty &&
      author.isEmpty &&
      translator.isEmpty &&
      narrator.isEmpty;
}

class TranscriptDocument {
  final BookMetadata metadata;
  final List<TranscriptSegment> segments;

  TranscriptDocument({required this.metadata, required this.segments});

  factory TranscriptDocument.fromJson(Map<String, dynamic> json) {
    final List<dynamic> segmentsJson = json['segments'] ?? [];
    return TranscriptDocument(
      metadata: BookMetadata.fromJson(json),
      segments: segmentsJson
          .map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => segments.isEmpty;
}

class TranscriptSegment {
  final int id;
  final String text;
  final double start;
  final double end;
  final TranscriptSegmentType type;

  const TranscriptSegment({
    required this.id,
    required this.text,
    required this.start,
    required this.end,
    required this.type,
  });

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      text: json['text']?.toString() ?? '',
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      type: TranscriptSegmentType.fromString(json['type']?.toString()),
    );
  }
}
