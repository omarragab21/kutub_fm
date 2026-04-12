enum TranscriptSegmentType {
  narration,
  quote,
  emphasis,
  heading,
  note,
  unknown,
}

class TranscriptDocument {
  const TranscriptDocument({required this.segments, this.title, this.language});

  final String? title;
  final String? language;
  final List<TranscriptSegment> segments;

  bool get isEmpty => segments.isEmpty;

  String get combinedText => segments.map((segment) => segment.text).join(' ');

  Duration get totalDuration {
    var maxEnd = Duration.zero;

    for (final segment in segments) {
      if (segment.end > maxEnd) {
        maxEnd = segment.end;
      }
    }

    return maxEnd;
  }

  factory TranscriptDocument.fromJson(dynamic json) {
    if (json is List) {
      return TranscriptDocument(
        segments: json
            .map(
              (item) => TranscriptSegment.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
    }

    final map = Map<String, dynamic>.from(json as Map);
    final rawSegments = map['segments'];

    return TranscriptDocument(
      title: map['title'] as String?,
      language: map['language'] as String?,
      segments: rawSegments is List
          ? rawSegments
                .map(
                  (item) => TranscriptSegment.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : const <TranscriptSegment>[],
    );
  }
}

class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.text,
    required this.start,
    required this.end,
    required this.type,
  });

  final String id;
  final String text;
  final Duration start;
  final Duration end;
  final TranscriptSegmentType type;

  bool contains(Duration position) => position >= start && position < end;

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString().trim(),
      start: _parseDuration(json['start']),
      end: _parseDuration(json['end']),
      type: _parseType(json['type']?.toString()),
    );
  }

  static TranscriptSegmentType _parseType(String? rawType) {
    switch (rawType?.trim().toLowerCase()) {
      case 'narration':
        return TranscriptSegmentType.narration;
      case 'quote':
        return TranscriptSegmentType.quote;
      case 'emphasis':
        return TranscriptSegmentType.emphasis;
      case 'heading':
        return TranscriptSegmentType.heading;
      case 'note':
        return TranscriptSegmentType.note;
      default:
        return TranscriptSegmentType.unknown;
    }
  }

  static Duration _parseDuration(dynamic rawValue) {
    if (rawValue == null) {
      return Duration.zero;
    }

    if (rawValue is int) {
      return Duration(milliseconds: rawValue * 1000);
    }

    if (rawValue is double) {
      return Duration(milliseconds: (rawValue * 1000).round());
    }

    if (rawValue is num) {
      return Duration(milliseconds: (rawValue.toDouble() * 1000).round());
    }

    final value = rawValue.toString().trim();
    final numericValue = double.tryParse(value);
    if (numericValue != null) {
      return Duration(milliseconds: (numericValue * 1000).round());
    }

    final parts = value.split(':');
    if (parts.isEmpty) {
      return Duration.zero;
    }

    final segments = parts
        .map((part) => double.tryParse(part.trim()) ?? 0)
        .toList(growable: false);
    var totalSeconds = 0.0;

    for (final segment in segments) {
      totalSeconds = (totalSeconds * 60) + segment;
    }

    return Duration(milliseconds: (totalSeconds * 1000).round());
  }
}
