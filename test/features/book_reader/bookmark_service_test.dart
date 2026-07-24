import 'package:flutter_test/flutter_test.dart';
import 'package:kutub_fm/features/book_reader/data/services/bookmark_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and loads reader bookmarks from shared preferences', () async {
    final bookmark = BookReaderBookmark(
      firstSegmentIndex: 0,
      lastSegmentIndex: 1,
      text: 'لا نعم',
      audioStart: 0,
      audioEnd: 30,
      createdAt: DateTime.utc(2026),
    );

    await BookmarkService.saveBookmark(
      bookId: 'book-1',
      chapterId: 'chapter-1',
      bookmark: bookmark,
    );

    final bookmarks = await BookmarkService.getBookmarks(
      bookId: 'book-1',
      chapterId: 'chapter-1',
    );

    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.firstSegmentIndex, 0);
    expect(bookmarks.single.lastSegmentIndex, 1);
    expect(bookmarks.single.text, 'لا نعم');
    expect(bookmarks.single.audioStart, 0);
    expect(bookmarks.single.audioEnd, 30);
  });

  test(
    'updates an existing bookmark range instead of duplicating it',
    () async {
      final first = BookReaderBookmark(
        firstSegmentIndex: 0,
        lastSegmentIndex: 1,
        text: 'old',
        audioStart: 0,
        audioEnd: 30,
        createdAt: DateTime.utc(2026),
      );
      final second = BookReaderBookmark(
        firstSegmentIndex: 0,
        lastSegmentIndex: 1,
        text: 'new',
        audioStart: 0,
        audioEnd: 30,
        createdAt: DateTime.utc(2026, 1, 2),
      );

      await BookmarkService.saveBookmark(
        bookId: 'book-1',
        chapterId: 'chapter-1',
        bookmark: first,
      );
      final bookmarks = await BookmarkService.saveBookmark(
        bookId: 'book-1',
        chapterId: 'chapter-1',
        bookmark: second,
      );

      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.text, 'new');
    },
  );
}
