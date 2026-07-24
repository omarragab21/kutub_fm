import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutub_fm/features/book_details/domain/entities/book_detail_model.dart';
import 'package:kutub_fm/features/book_reader/presentation/utils/transcript_selection_mapper.dart';

void main() {
  late TranscriptTextIndex index;

  setUp(() {
    index = TranscriptTextIndex([
      TranscriptionSegment(start: 0, end: 10, text: 'لا'),
      TranscriptionSegment(start: 10, end: 30, text: 'نعم'),
      TranscriptionSegment(start: 30, end: 40, text: 'ثالثة'),
    ]);
  });

  test('maps selected sentences to their transcript audio range', () {
    const selectedText = 'لا نعم';

    final match = index.resolveSelection(
      TextSelection(baseOffset: 0, extentOffset: selectedText.length),
    );

    expect(match, isNotNull);
    expect(match!.firstSegmentIndex, 0);
    expect(match.lastSegmentIndex, 1);
    expect(match.selectedText, selectedText);
    expect(match.audioStart, 0);
    expect(match.audioEnd, 30);
  });

  test('ignores trailing separator whitespace in text selection', () {
    const selectedText = 'لا نعم';

    final match = index.resolveSelection(
      TextSelection(baseOffset: 0, extentOffset: selectedText.length + 1),
    );

    expect(match, isNotNull);
    expect(match!.firstSegmentIndex, 0);
    expect(match.lastSegmentIndex, 1);
    expect(match.audioStart, 0);
    expect(match.audioEnd, 30);
  });

  test('uses segment boundaries for direct segment playback', () {
    final match = index.resolveSegmentRange(0, 1);

    expect(match, isNotNull);
    expect(match!.selectedText, 'لا نعم');
    expect(match.audioStart, 0);
    expect(match.audioEnd, 30);
  });

  test('finds the currently playing segment by time', () {
    expect(index.segmentIndexAtTime(0), 0);
    expect(index.segmentIndexAtTime(9.999), 0);
    expect(index.segmentIndexAtTime(10), 1);
    expect(index.segmentIndexAtTime(30), 2);
    expect(index.segmentIndexAtTime(40), isNull);
  });

  test('returns null for whitespace-only selections', () {
    final match = index.resolveSelection(
      const TextSelection(baseOffset: 2, extentOffset: 3),
    );

    expect(match, isNull);
  });
}
