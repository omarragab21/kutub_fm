import 'package:flutter/services.dart';

import '../../../book_details/domain/entities/book_detail_model.dart';

class TranscriptSelectionMatch {
  final int firstSegmentIndex;
  final int lastSegmentIndex;
  final TextRange textRange;
  final String selectedText;
  final double audioStart;
  final double audioEnd;

  const TranscriptSelectionMatch({
    required this.firstSegmentIndex,
    required this.lastSegmentIndex,
    required this.textRange,
    required this.selectedText,
    required this.audioStart,
    required this.audioEnd,
  });
}

class TranscriptTextIndex {
  factory TranscriptTextIndex(List<TranscriptionSegment> segments) {
    final segmentStarts = <int>[];
    final segmentEnds = <int>[];
    final buffer = StringBuffer();

    for (var i = 0; i < segments.length; i++) {
      if (i > 0) buffer.write(' ');
      segmentStarts.add(buffer.length);
      buffer.write(segments[i].text);
      segmentEnds.add(buffer.length);
    }

    return TranscriptTextIndex._(
      segments: List.unmodifiable(segments),
      plainText: buffer.toString(),
      segmentStarts: List.unmodifiable(segmentStarts),
      segmentEnds: List.unmodifiable(segmentEnds),
    );
  }

  const TranscriptTextIndex._({
    required List<TranscriptionSegment> segments,
    required this.plainText,
    required List<int> segmentStarts,
    required List<int> segmentEnds,
  }) : _segments = segments,
       _segmentStarts = segmentStarts,
       _segmentEnds = segmentEnds;

  final List<TranscriptionSegment> _segments;
  final List<int> _segmentStarts;
  final List<int> _segmentEnds;

  final String plainText;

  int get segmentCount => _segments.length;

  bool get isEmpty => _segments.isEmpty;

  TextRange segmentTextRange(int index) {
    RangeError.checkValidIndex(index, _segments, 'index');
    return TextRange(start: _segmentStarts[index], end: _segmentEnds[index]);
  }

  String segmentDisplayText(int index) {
    RangeError.checkValidIndex(index, _segments, 'index');
    return index == _segments.length - 1
        ? _segments[index].text
        : '${_segments[index].text} ';
  }

  TranscriptSelectionMatch? resolveSegmentRange(int firstIndex, int lastIndex) {
    if (firstIndex < 0 ||
        lastIndex >= _segments.length ||
        firstIndex > lastIndex) {
      return null;
    }

    final textRange = TextRange(
      start: _segmentStarts[firstIndex],
      end: _segmentEnds[lastIndex],
    );
    return _buildMatch(firstIndex, lastIndex, textRange);
  }

  TranscriptSelectionMatch? resolveSelection(TextSelection selection) {
    if (selection.isCollapsed || !selection.isValid || plainText.isEmpty) {
      return null;
    }

    var start = _clampOffset(selection.start);
    var end = _clampOffset(selection.end);
    if (start >= end) return null;

    final textRange = _trimSelectionRange(start, end);
    if (textRange.isCollapsed) return null;

    final firstIndex = _segmentIndexAtTextOffset(textRange.start);
    final lastIndex = _segmentIndexAtTextOffset(textRange.end - 1);
    if (firstIndex == null || lastIndex == null || firstIndex > lastIndex) {
      return null;
    }

    return _buildMatch(firstIndex, lastIndex, textRange);
  }

  int? segmentIndexAtTime(double seconds) {
    if (!seconds.isFinite || _segments.isEmpty) return null;

    var low = 0;
    var high = _segments.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final segment = _segments[mid];

      if (seconds < segment.start) {
        high = mid - 1;
      } else if (seconds >= segment.end) {
        low = mid + 1;
      } else {
        return mid;
      }
    }

    return null;
  }

  TranscriptSelectionMatch _buildMatch(
    int firstIndex,
    int lastIndex,
    TextRange textRange,
  ) {
    return TranscriptSelectionMatch(
      firstSegmentIndex: firstIndex,
      lastSegmentIndex: lastIndex,
      textRange: textRange,
      selectedText: textRange.textInside(plainText),
      audioStart: _segments[firstIndex].start,
      audioEnd: _segments[lastIndex].end,
    );
  }

  int _clampOffset(int offset) {
    if (offset < 0) return 0;
    if (offset > plainText.length) return plainText.length;
    return offset;
  }

  TextRange _trimSelectionRange(int start, int end) {
    while (start < end && _isWhitespaceCodeUnit(plainText.codeUnitAt(start))) {
      start++;
    }
    while (end > start &&
        _isWhitespaceCodeUnit(plainText.codeUnitAt(end - 1))) {
      end--;
    }
    return TextRange(start: start, end: end);
  }

  int? _segmentIndexAtTextOffset(int offset) {
    var low = 0;
    var high = _segmentStarts.length;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (_segmentStarts[mid] <= offset) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    final index = low - 1;
    if (index < 0 || offset >= _segmentEnds[index]) return null;
    return index;
  }

  static bool _isWhitespaceCodeUnit(int codeUnit) {
    return codeUnit == 0x20 ||
        codeUnit == 0x09 ||
        codeUnit == 0x0A ||
        codeUnit == 0x0B ||
        codeUnit == 0x0C ||
        codeUnit == 0x0D ||
        codeUnit == 0x00A0;
  }
}
