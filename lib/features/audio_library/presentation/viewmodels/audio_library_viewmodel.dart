import 'package:flutter/material.dart';
import '../../../reels/domain/entities/reel_model.dart';

class LibraryBook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double progress; // 0.0 to 1.0 (0.0 means no progress indicator, like "حديث الصباح")
  final String pdfAssetPath;

  LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.progress,
    required this.pdfAssetPath,
  });
}

class LibraryPodcast {
  final String id;
  final String title;
  final String author;
  final String coverUrl;

  LibraryPodcast({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
  });
}

class LibraryHighlight {
  final String id;
  final String bookTitle;
  final String quote;
  final String date;

  LibraryHighlight({
    required this.id,
    required this.bookTitle,
    required this.quote,
    required this.date,
  });
}

class AudioLibraryViewModel extends ChangeNotifier {
  // Navigation tabs: 0 = المفضلة (Favorites), 1 = التنزيلات (Downloads), 2 = الإشارات (Highlights)
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  // Favorites filters: 0 = كتب (Books), 1 = بودكاست (Podcasts), 2 = ريلز (Reels)
  int _activeFavFilterIndex = 0;
  int get activeFavFilterIndex => _activeFavFilterIndex;

  // List data states
  final List<LibraryBook> _favoriteBooks = [
    LibraryBook(
      id: 'lib_b1',
      title: 'حديث الصباح',
      author: 'أحمد سعيد',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 0.0,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'lib_b2',
      title: 'مئة عام من العزلة',
      author: 'أحمد خالد توفيق',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 0.75,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'lib_b3',
      title: 'كيف تركت العزلة',
      author: 'رجب البابورجي',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 0.10,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'lib_b4',
      title: 'في انتظار البرابرة',
      author: 'جينيفير إغان',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 0.60,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'lib_b5',
      title: 'العمى',
      author: 'جوزيه ساراماغو',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 1.00,
      pdfAssetPath: 'book.pdf',
    ),
  ];

  final List<LibraryPodcast> _favoritePodcasts = [
    LibraryPodcast(
      id: 'lib_p1',
      title: 'بين الماضي والحاضر',
      author: 'فاطمة الزهراء',
      coverUrl: 'assets/miah_aam_cover.png',
    ),
    LibraryPodcast(
      id: 'lib_p2',
      title: 'قصص من الحياة',
      author: 'علي حسن',
      coverUrl: 'assets/miah_aam_cover.png',
    ),
  ];

  final List<Reel> _favoriteReels = [
    Reel.mock(0),
    Reel.mock(1),
    Reel.mock(2),
  ];

  final List<LibraryBook> _downloadedBooks = [
    LibraryBook(
      id: 'down_b1',
      title: 'رحلة في عالم الكتب',
      author: 'نور الهدى',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 0.0,
      pdfAssetPath: 'book.pdf',
    ),
  ];

  final List<LibraryHighlight> _highlights = [
    LibraryHighlight(
      id: 'hl_1',
      bookTitle: 'مئة عام من العزلة',
      quote: 'نحن لا نموت من وراء رغبتنا في الموت، بل نموت لأننا لا نستطيع العيش بمفردنا في هذا العالم القاسي والمظلم.',
      date: '١٥ يونيو ٢٠٢٦',
    ),
    LibraryHighlight(
      id: 'hl_2',
      bookTitle: 'الخيميائي',
      quote: 'عندما ترغب في شيء ما، فإن الكون كله يتآمر لمساعدتك على تحقيق رغبتك وجعل المستحيل ممكناً.',
      date: '١٤ يونيو ٢٠٢٦',
    ),
  ];

  // Getters
  List<LibraryBook> get favoriteBooks => _favoriteBooks;
  List<LibraryPodcast> get favoritePodcasts => _favoritePodcasts;
  List<Reel> get favoriteReels => _favoriteReels;
  List<LibraryBook> get downloadedBooks => _downloadedBooks;
  List<LibraryHighlight> get highlights => _highlights;

  // Actions
  void setActiveTab(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  void setActiveFavFilter(int index) {
    _activeFavFilterIndex = index;
    notifyListeners();
  }

  void toggleFavoriteBook(String id) {
    final index = _favoriteBooks.indexWhere((book) => book.id == id);
    if (index != -1) {
      _favoriteBooks.removeAt(index);
    } else {
      // Re-add mock item for demonstration
      _favoriteBooks.add(
        LibraryBook(
          id: id,
          title: 'كتاب مفضل جديد',
          author: 'كاتب مجهول',
          coverUrl: 'assets/miah_aam_cover.png',
          progress: 0.0,
          pdfAssetPath: 'book.pdf',
        ),
      );
    }
    notifyListeners();
  }

  void toggleFavoritePodcast(String id) {
    final index = _favoritePodcasts.indexWhere((pod) => pod.id == id);
    if (index != -1) {
      _favoritePodcasts.removeAt(index);
    }
    notifyListeners();
  }

  void toggleFavoriteReel(String id) {
    final index = _favoriteReels.indexWhere((reel) => reel.id == id);
    if (index != -1) {
      _favoriteReels.removeAt(index);
    }
    notifyListeners();
  }

  void deleteDownload(String id) {
    _downloadedBooks.removeWhere((book) => book.id == id);
    notifyListeners();
  }

  void deleteHighlight(String id) {
    _highlights.removeWhere((hl) => hl.id == id);
    notifyListeners();
  }
}
