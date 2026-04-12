import '../domain/entities/active_reader.dart';
import '../domain/entities/reader_comment.dart';
import '../domain/entities/reader_post.dart';

class ReaderFeedMockData {
  ReaderFeedMockData._();

  static List<ActiveReader> buildActiveReaders() {
    return const [
      ActiveReader(
        id: 'reader_1',
        name: 'سلمى',
        avatarUrl: 'https://i.pravatar.cc/150?img=32',
      ),
      ActiveReader(
        id: 'reader_2',
        name: 'عمر',
        avatarUrl: 'https://i.pravatar.cc/150?img=14',
      ),
      ActiveReader(
        id: 'reader_3',
        name: 'إسراء',
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
      ),
      ActiveReader(
        id: 'reader_4',
        name: 'ليان',
        avatarUrl: 'https://i.pravatar.cc/150?img=21',
      ),
      ActiveReader(
        id: 'reader_5',
        name: 'زياد',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
      ),
      ActiveReader(
        id: 'reader_6',
        name: 'نور',
        avatarUrl: 'https://i.pravatar.cc/150?img=49',
      ),
    ];
  }

  static List<ReaderPost> buildPosts() {
    final now = DateTime.now();

    return [
      ReaderPost(
        id: 'post_quote_1',
        userName: 'هديل القارئة',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
        type: ReaderPostType.quote,
        bookTitle: 'قواعد العشق الأربعون',
        content:
            '“الطريق إلى الحقيقة يمر من القلب لا من الرأس.” أعود إلى هذه الجملة كلما شعرت أن القراءة صارت مجرد معلومات بلا أثر.',
        createdAt: now.subtract(const Duration(minutes: 18)),
        likeCount: 132,
        comments: [
          ReaderComment(
            id: 'comment_quote_1',
            userName: 'آية',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=29',
            content: 'هذه من الجمل التي تغيّر مزاج يوم كامل.',
            createdAt: now.subtract(const Duration(minutes: 12)),
            replies: [
              ReaderComment(
                id: 'reply_quote_1',
                userName: 'هديل القارئة',
                userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
                content: 'بالضبط، فيها دفء نادر.',
                createdAt: now.subtract(const Duration(minutes: 9)),
              ),
            ],
          ),
          ReaderComment(
            id: 'comment_quote_2',
            userName: 'رامي',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=17',
            content: 'أشعر أنها تلخص سبب حبنا للكتب الصوفية.',
            createdAt: now.subtract(const Duration(minutes: 8)),
          ),
        ],
      ),
      ReaderPost(
        id: 'post_discussion_1',
        userName: 'يوسف الأدهم',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=11',
        type: ReaderPostType.discussion,
        bookTitle: 'الجريمة والعقاب',
        content:
            'سؤال للنقاش: هل كان راسكولنيكوف يبحث عن العدالة فعلاً، أم كان يهرب من هشاشته الداخلية بفكرة البطولة؟',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 6)),
        likeCount: 284,
        comments: [
          ReaderComment(
            id: 'comment_discussion_1',
            userName: 'مي',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=36',
            content:
                'أراه يختبر نفسه أكثر مما يختبر الفكرة. الجريمة كانت محاولة لإثبات صورة متخيلة عن ذاته.',
            createdAt: now.subtract(const Duration(minutes: 42)),
          ),
          ReaderComment(
            id: 'comment_discussion_2',
            userName: 'نادر',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=52',
            content: 'وأعتقد أن المدينة نفسها كانت تضغطه نفسياً طوال الوقت.',
            createdAt: now.subtract(const Duration(minutes: 35)),
          ),
        ],
      ),
      ReaderPost(
        id: 'post_review_1',
        userName: 'لينا الورّاقة',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=44',
        type: ReaderPostType.review,
        bookTitle: 'الخيميائي',
        content:
            'مراجعتي السريعة: الرواية خفيفة ومباشرة، لكنها تعمل جيداً عندما تحتاج كتاباً يذكّرك بأن الرحلة الداخلية أهم من الوصول السريع.',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 10)),
        likeCount: 198,
        comments: [
          ReaderComment(
            id: 'comment_review_1',
            userName: 'سلمان',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=3',
            content: 'أتفق، ليست معقدة لكنها مريحة في توقيتها.',
            createdAt: now.subtract(const Duration(hours: 2, minutes: 46)),
          ),
        ],
      ),
      ReaderPost(
        id: 'post_quote_2',
        userName: 'رباب',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
        type: ReaderPostType.quote,
        bookTitle: 'في ظلال القرآن',
        content:
            'أحياناً لا أبحث عن “أجمل” اقتباس، بل عن الجملة التي تجعلني أتوقف طويلاً ثم أعود لأكمل بهدوء.',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 28)),
        likeCount: 91,
        comments: [],
      ),
      ReaderPost(
        id: 'post_discussion_2',
        userName: 'حازم',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=60',
        type: ReaderPostType.discussion,
        content:
            'ما الكتاب الذي غيّر طريقتك في وضع ملاحظاتك أثناء القراءة؟ أريد أفكاراً عملية لتطوير هامشي الشخصي.',
        createdAt: now.subtract(const Duration(hours: 7, minutes: 12)),
        likeCount: 76,
        comments: [
          ReaderComment(
            id: 'comment_discussion_3',
            userName: 'نورا',
            userAvatarUrl: 'https://i.pravatar.cc/150?img=24',
            content:
                'كتاب “كيف تقرأ كتاباً” جعلني أفصل بين التلخيص والانطباع الشخصي.',
            createdAt: now.subtract(const Duration(hours: 6, minutes: 58)),
          ),
        ],
      ),
    ];
  }
}
