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
  });

  factory Reel.mock(int index) {
    final titles = ['الخيميائي', 'قواعد العشق الأربعون', 'مقدمة ابن خلدون'];
    final authors = ['باولو كويلو', 'إليف شفق', 'ابن خلدون'];
    final quotes = [
      '"إذا رغبت في شيء ما، فإن الكون كله يطاوعك لتحقيق رغبتك."',
      '"لا تحاول أن تقاوم التغييرات التي تعترض سبيلك، بل دع الحياة تعيش فيك."',
      '"الظلم مؤذن بخراب العمران."',
    ];

    // Mock video URLs (using sample mp4 files)
    final videos = [
      'assets/reels/reel_video.mp4',
      'assets/reels/reel_video.mp4',
      'assets/reels/reel_video.mp4',
    ];

    return Reel(
      id: index.toString(),
      bookTitle: titles[index % titles.length],
      author: authors[index % authors.length],
      quote: quotes[index % quotes.length],
      imageUrl: 'https://picsum.photos/seed/${index}/1080/1920',
      videoUrl: videos[index % videos.length],
      likes: 1200 + (index * 150),
      comments: 84 + (index * 12),
      shares: 45 + (index * 5),
    );
  }
}
