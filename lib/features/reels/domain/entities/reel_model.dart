import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String id;
  final String bookTitle;
  final String author;
  final String quote;
  final String imageUrl;
  final String videoUrl;
  final int likes;
  final int comments;
  final int shares;
  final String categoryName;
  final DateTime? createdAt;

  Reel({
    required this.id,
    required this.bookTitle,
    required this.author,
    required this.quote,
    required this.imageUrl,
    required this.videoUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.categoryName = '',
    this.createdAt,
  });

  factory Reel.mock(int index) {
    final titles = ['الخيميائي', 'قواعد العشق الأربعون', 'مقدمة ابن خلدون'];
    final authors = ['باولو كويلو', 'إليف شفق', 'ابن خلدون'];
    final quotes = [
      '"إذا رغبت في شيء ما، فإن الكون كله يطاوعك لتحقيق رغبتك."',
      '"لا تحاول أن تقاوم التغييرات التي تعترض سبيلك، بل دع الحياة تعيش فيك."',
      '"الظلم مؤذن بخراب العمران."',
    ];

    final videos = [
      'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/reels/figma_reel_100_years/video_20s_1784714933682.mp4',
      'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/reels/figma_reel_100_years/video_20s_1784714933682.mp4',
      'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/reels/figma_reel_100_years/video_20s_1784714933682.mp4',
    ];

    return Reel(
      id: index.toString(),
      bookTitle: titles[index % titles.length],
      author: authors[index % authors.length],
      quote: quotes[index % quotes.length],
      imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
      videoUrl: videos[index % videos.length],
      likes: 1200 + (index * 150),
      comments: 84 + (index * 12),
      shares: 45 + (index * 5),
      categoryName: 'روايات فكرية',
    );
  }

  factory Reel.fromFirestore(String id, Map<String, dynamic> data) {
    final metrics = data['metrics'] as Map<String, dynamic>?;

    int parseCount(dynamic value, dynamic metricsValue) {
      if (metricsValue is num) return metricsValue.toInt();
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      return 0;
    }

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Reel(
      id: id,
      bookTitle: data['bookTitle']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      quote: data['quote']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      likes: parseCount(data['likes'], metrics?['likesCount']),
      comments: parseCount(data['comments'], metrics?['commentsCount']),
      shares: parseCount(data['shares'], metrics?['sharesCount']),
      categoryName: data['categoryName']?.toString() ?? data['category']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  static final Reel defaultFigmaReel = Reel(
    id: 'figma_reel_100_years',
    bookTitle: 'مئة عام من العزلة',
    author: 'أحمد خالد توفيق',
    quote: '"كان يعلم أن البشر يحكمون على أشياء لا يقدرون على رؤيتها بعيونهم، وأن من يملك اليقين يملك العالم."',
    imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
    videoUrl: 'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/reels/figma_reel_100_years/video_20s_1784714933682.mp4',
    likes: 1,
    comments: 1,
    shares: 1,
    categoryName: 'روايات فكرية',
  );

  static final List<Reel> defaultReelsList = [
    defaultFigmaReel,
    Reel(
      id: 'reel_khimiya',
      bookTitle: 'الخيميائي',
      author: 'باولو كويلو',
      quote: '"إذا رغبت في شيء ما، فإن الكون كله يطاوعك لتحقيق رغبتك."',
      imageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800',
      videoUrl: 'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/reels/figma_reel_100_years/video_20s_1784714933682.mp4',
      likes: 1250,
      comments: 98,
      shares: 42,
      categoryName: 'تطوير الذات',
    ),
    Reel(
      id: 'reel_40_rules',
      bookTitle: 'قواعد العشق الأربعون',
      author: 'إليف شفق',
      quote: '"لا تحاول أن تقاوم التغييرات التي تعترض سبيلك، بل دع الحياة تعيش فيك."',
      imageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800',
      videoUrl: 'https://storage.googleapis.com/kutubfm-1ef89.firebasestorage.app/reels/figma_reel_100_years/video_20s_1784714933682.mp4',
      likes: 890,
      comments: 65,
      shares: 30,
      categoryName: 'روايات فكرية',
    ),
  ];
}

