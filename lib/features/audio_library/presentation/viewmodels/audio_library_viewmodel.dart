import 'package:flutter/material.dart';

class LibraryBook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double progress; // 0.0 to 1.0
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

class LibraryPodcastShow {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int episodesCount;

  LibraryPodcastShow({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.episodesCount,
  });
}

class LibraryPodcastEpisode {
  final String id;
  final String title;
  final String metaText; // e.g. "قبل اسبوع • الموسم الثاني • الحلقه 22"
  final String duration; // e.g. "2:55 س"
  final String coverUrl;

  LibraryPodcastEpisode({
    required this.id,
    required this.title,
    required this.metaText,
    required this.duration,
    required this.coverUrl,
  });
}

class LibraryReel {
  final String id;
  final String bookTitle;
  final String quote;
  final String coverUrl;

  LibraryReel({
    required this.id,
    required this.bookTitle,
    required this.quote,
    required this.coverUrl,
  });
}

class LibraryHighlight {
  final String id;
  final String bookTitle;
  final String author;
  final String quote;
  final String date;
  final String coverUrl;
  final int colorHex;

  LibraryHighlight({
    required this.id,
    required this.bookTitle,
    required this.author,
    required this.quote,
    required this.date,
    required this.coverUrl,
    required this.colorHex,
  });
}

class AudioLibraryViewModel extends ChangeNotifier {
  // Navigation tabs: 0 = المفضلة (Favorites), 1 = الإشارات (Highlights)
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  // Favorites filters: 0 = كتب (Books), 1 = بودكاست (Podcasts), 2 = ريلز (Reels)
  int _activeFavFilterIndex = 0;
  int get activeFavFilterIndex => _activeFavFilterIndex;

  // 1. Books List (المفضلة)
  final List<LibraryBook> _favoriteBooks = [
    LibraryBook(
      id: 'fav_b1',
      title: 'مئة عام من العزلة',
      author: 'أحمد خالد توفيق',
      coverUrl: 'assets/miah_aam_cover.png',
      progress: 0.75,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'fav_b2',
      title: 'كيف تركت العزلة',
      author: 'رجب البابورجي',
      coverUrl: 'assets/cover_memory_body.png',
      progress: 0.10,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'fav_b3',
      title: 'في انتظار البرابرة',
      author: 'جينيفر إغان',
      coverUrl: 'assets/cover_men_in_sun.png',
      progress: 0.60,
      pdfAssetPath: 'book.pdf',
    ),
    LibraryBook(
      id: 'fav_b4',
      title: 'أيمن محرم',
      author: 'دار سلامة',
      coverUrl: 'assets/cover_salt_cities.png',
      progress: 1.00,
      pdfAssetPath: 'book.pdf',
    ),
  ];

  // 2. Podcast Shows List (المفضلة - البرامج)
  final List<LibraryPodcastShow> _favoritePodcastShows = [
    LibraryPodcastShow(
      id: 'fav_ps1',
      title: 'كيف تبدأ الحروب؟',
      author: 'يوسف عادل',
      coverUrl: 'assets/podcast_bg.png',
      episodesCount: 9,
    ),
    LibraryPodcastShow(
      id: 'fav_ps2',
      title: 'صلاح نفسي',
      author: 'وجدان العلي',
      coverUrl: 'assets/podcast.png',
      episodesCount: 30,
    ),
    LibraryPodcastShow(
      id: 'fav_ps3',
      title: 'كم خسّرنا الطاعون',
      author: 'شهندى رجب',
      coverUrl: 'assets/podcast_icon.png',
      episodesCount: 4,
    ),
    LibraryPodcastShow(
      id: 'fav_ps4',
      title: 'في العيادة',
      author: 'د.كريم تامر',
      coverUrl: 'assets/app_logo.png',
      episodesCount: 12,
    ),
  ];

  // 3. Podcast Episodes List (المفضلة - الحلقات)
  final List<LibraryPodcastEpisode> _favoritePodcastEpisodes = [
    LibraryPodcastEpisode(
      id: 'fav_pe1',
      title: 'صناعة السعادة',
      metaText: 'قبل اسبوع • الموسم الثاني • الحلقه 22',
      duration: '2:55 س',
      coverUrl: 'assets/cover_barefoot_bread.png',
    ),
    LibraryPodcastEpisode(
      id: 'fav_pe2',
      title: 'تحويل الحلم إلى واقع',
      metaText: 'قبل شهر • الحلقة 5',
      duration: '20:30 د',
      coverUrl: 'assets/cover_jewish_girl.png',
    ),
    LibraryPodcastEpisode(
      id: 'fav_pe3',
      title: 'إدارة الحياة قبل الوقت',
      metaText: 'أمس • الموسم الأول • الحلقة 10',
      duration: '15:10 د',
      coverUrl: 'assets/cover_thousand_nights.png',
    ),
  ];

  // 4. Reels List (المفضلة - ريلز)
  final List<LibraryReel> _favoriteReels = [
    LibraryReel(
      id: 'fav_r1',
      bookTitle: 'العادات السبع للأشخاص الأكثر فاعلية',
      quote: '“أنت لست ضحية ظروفك، بل نتيجة ردود أفعالك تجاهها.”',
      coverUrl: 'assets/cover_memory_body.png',
    ),
    LibraryReel(
      id: 'fav_r2',
      bookTitle: 'العادات الذرية',
      quote:
          '“التغيير يبدأ من أصغر عادة تقوم بها يوميًا، وليس من قرارات كبيرة.”',
      coverUrl: 'assets/cover_barefoot_bread.png',
    ),
    LibraryReel(
      id: 'fav_r3',
      bookTitle: 'فكر تصبح غنيًا',
      quote: '“النجاح يبدأ عندما يصبح الهدف أوضح من الخوف.”',
      coverUrl: 'assets/cover_salt_cities.png',
    ),
    LibraryReel(
      id: 'fav_r4',
      bookTitle: 'الإنسان يبحث عن معنى',
      quote: '“المعاناة لا تذهب سدى، بل تصنع معنى جديدًا للحياة.”',
      coverUrl: 'assets/cover_jewish_girl.png',
    ),
    LibraryReel(
      id: 'fav_r5',
      bookTitle: 'قوة الآن',
      quote: '“ما تفعله اليوم هو الذي يحدد نسخة غدك.”',
      coverUrl: 'assets/cover_men_in_sun.png',
    ),
    LibraryReel(
      id: 'fav_r6',
      bookTitle: 'العادات الذرية',
      quote: '“الثقة تُبنى عندما تلتزم بما تقول حتى لو لم يراك أحد.”',
      coverUrl: 'assets/cover_thousand_nights.png',
    ),
  ];

  // 5. Highlights List (الإشارات)
  final List<LibraryHighlight> _highlights = [
    LibraryHighlight(
      id: 'hl_1',
      bookTitle: 'الأمير الصغير',
      author: 'أنطوان دو سانت إكزوبيري',
      quote:
          'التركيز العميق أصبح مهارة نادرة… ومن يتقنه ينجز أكثر من الجميع في وقت أقل.',
      date: '12 نوفمبر',
      coverUrl: 'assets/cover_jewish_girl.png',
      colorHex: 0xFFF46D6E, // Red
    ),
    LibraryHighlight(
      id: 'hl_2',
      bookTitle: 'الخيميائي',
      author: 'باولو كويلو',
      quote: 'عندما ترغب في شيء بشدة، يتآمر الكون كله ليساعدك على تحقيقه.',
      date: '30 ديسمبر',
      coverUrl: 'assets/cover_memory_body.png',
      colorHex: 0xFFFFAE56, // Orange
    ),
    LibraryHighlight(
      id: 'hl_3',
      bookTitle: 'مئة عام من العزلة',
      author: 'غابرييل غارسيا ماركيز',
      quote: 'الزمن ليس سوى وهم نسجناه لأنفسنا للهرب من الحاضر.',
      date: '6 اكتوبر',
      coverUrl: 'assets/miah_aam_cover.png',
      colorHex: 0xFFAA96DA, // Purple
    ),
    LibraryHighlight(
      id: 'hl_4',
      bookTitle: 'في انتظار البرابرة',
      author: 'جوزيه ساراماغو',
      quote: 'الحرية لا تُمنح، بل تُنتزع بشجاعة وإصرار.',
      date: '16 اغسطس',
      coverUrl: 'assets/cover_salt_cities.png',
      colorHex: 0xFF609966, // Green
    ),
    LibraryHighlight(
      id: 'hl_5',
      bookTitle: 'الطريق',
      author: 'كورماك مكارثي',
      quote: 'في عمق الظلام، يتجلى نور الأمل الحقيقي.',
      date: '6 نوفمبر',
      coverUrl: 'assets/cover_barefoot_bread.png',
      colorHex: 0xFFF46D6E, // Red
    ),
    LibraryHighlight(
      id: 'hl_6',
      bookTitle: 'مدن الملح',
      author: 'عبد الرحمن منيف',
      quote:
          'الذاكرة هي الجسر الذي يربط بين الماضي والحاضر، فتُحيي فينا الأمل والتجدد.',
      date: '12 يوليو',
      coverUrl: 'assets/cover_thousand_nights.png',
      colorHex: 0xFFFFDA62, // Yellow
    ),
  ];

  // Getters
  List<LibraryBook> get favoriteBooks => _favoriteBooks;
  List<LibraryPodcastShow> get favoritePodcastShows => _favoritePodcastShows;
  List<LibraryPodcastEpisode> get favoritePodcastEpisodes =>
      _favoritePodcastEpisodes;
  List<LibraryReel> get favoriteReels => _favoriteReels;
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
    }
    notifyListeners();
  }

  void toggleFavoritePodcastShow(String id) {
    _favoritePodcastShows.removeWhere((show) => show.id == id);
    notifyListeners();
  }

  void toggleFavoritePodcastEpisode(String id) {
    _favoritePodcastEpisodes.removeWhere((ep) => ep.id == id);
    notifyListeners();
  }

  void toggleFavoriteReel(String id) {
    _favoriteReels.removeWhere((reel) => reel.id == id);
    notifyListeners();
  }

  void deleteHighlight(String id) {
    _highlights.removeWhere((hl) => hl.id == id);
    notifyListeners();
  }
}
