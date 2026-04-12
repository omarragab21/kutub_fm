class Chapter {
  final String id;
  final String title;
  final String duration;
  final bool isCompleted;

  Chapter({
    required this.id,
    required this.title,
    required this.duration,
    this.isCompleted = false,
  });
}

class BookComment {
  final String id;
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;
  final int likes;

  BookComment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
  });
}

class BookDetail {
  final String id;
  final String title;
  final String author;
  final String description;
  final double rating;
  final String playCount;
  final String duration;
  final String category;
  final String imageUrl;
  final List<Chapter> chapters;
  final List<BookComment> comments;

  BookDetail({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.rating,
    required this.playCount,
    required this.duration,
    required this.category,
    required this.imageUrl,
    required this.chapters,
    required this.comments,
  });

  factory BookDetail.mock() {
    return BookDetail(
      id: '1',
      title: 'الخيميائي',
      author: 'باولو كويلو',
      description: 'الخيميائي هي الرواية الثانية التي كتبها باولو كويلو، والتي حققت نجاحاً عالمياً باهراً، جعل كاتبها من أشهر الكتاب العالميين. تتحدث الرواية عن راع أندلسي شاب يدعى سانتياغو. مضى في البحث عن حلمه المتمثل بكنز مدفون قرب أهرامات مصر، بدأت رحلته من أسبانيا عندما التقى الملك ملكي صادق الذي أخبره عن الكنز.',
      rating: 4.8,
      playCount: '1.2M',
      duration: '4h 30m',
      category: 'خيال، فلسفة',
      imageUrl: 'https://m.media-amazon.com/images/I/71aFt4+OTOL._AC_UF1000,1000_QL80_.jpg',
      chapters: [
        Chapter(id: '1', title: 'البداية: الراعي سانتياغو', duration: '12:45', isCompleted: true),
        Chapter(id: '2', title: 'لقاء مع الملك', duration: '18:20', isCompleted: true),
        Chapter(id: '3', title: 'عبور الصحراء', duration: '45:10'),
        Chapter(id: '4', title: 'فن تحول المعادن', duration: '32:15'),
        Chapter(id: '5', title: 'البحث عن الكنز', duration: '55:00'),
      ],
      comments: [
        BookComment(
          id: '101',
          userName: 'سارة خالد',
          userAvatar: 'https://i.pravatar.cc/150?img=1',
          text: 'من أجمل ما قرأت، كتاب يغير نظرتك للحياة ولأحلامك.',
          timeAgo: 'منذ يومين',
          likes: 24,
        ),
        BookComment(
          id: '102',
          userName: 'محمد أحمد',
          userAvatar: 'https://i.pravatar.cc/150?img=2',
          text: 'سرد رائع وأداء صوتي مذهل. شكراً لكم.',
          timeAgo: 'منذ 5 ساعات',
          likes: 12,
        ),
      ],
    );
  }
}
